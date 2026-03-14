import 'package:flutter/material.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class DebugMbtilesPage extends StatefulWidget {
  const DebugMbtilesPage({super.key});

  @override
  State<DebugMbtilesPage> createState() => _DebugMbtilesPageState();
}

class _DebugMbtilesPageState extends State<DebugMbtilesPage> {
  String _debugOutput = "Starting debug...\n";
  bool _isLoading = false;

  void _addOutput(String text) {
    setState(() {
      _debugOutput += "$text\n";
    });
    print(text); // Also print to console
  }

  Future<void> _debugMbtilesFile() async {
    _isLoading = true;
    _addOutput("=== DEBUGGING MBTILES FILE ===\n");

    try {
      // Step 1: Check if assets file exists
      _addOutput("Step 1: Checking assets...");
      try {
        final manifest = await rootBundle.loadString('AssetManifest.json');
        final testData = await rootBundle.loadString('assets/test.txt');
        _addOutput("  ✓ Test file loaded: $testData");
        _addOutput("  ✓ Asset manifest loaded");
        if (manifest.contains('mbtiles')) {
          _addOutput("  ✓ MBTiles file found in manifest");
        } else {
          _addOutput("  ✗ MBTiles file NOT in manifest");
          _addOutput(
            "  Files in manifest: ${manifest.split('\n').where((line) => line.contains('mbtiles')).join('\n')}",
          );
        }
      } catch (e) {
        _addOutput("  ✗ Could not load manifest: $e");
        _addOutput("  ✗ Test file failed: $e");
      }

      // Step 2: Try to load file from assets
      _addOutput("\nStep 2: Loading file from assets...");
      ByteData? byteData;
      try {
        byteData = await rootBundle.load('assets/mapTiles/tunisia.mbtiles');
        _addOutput(
          "  ✓ File loaded from assets: ${byteData.lengthInBytes} bytes",
        );
      } catch (e) {
        _addOutput("  ✗ Failed to load from assets: $e");
        _addOutput("  Make sure the path in pubspec.yaml is correct:");
        _addOutput("    assets:");
        _addOutput("      - assets/mapTiles/tunisia.mbtiles");
      }

      // Step 3: Copy to documents directory
      _addOutput("\nStep 3: Copying to documents directory...");
      final appDir = await getApplicationDocumentsDirectory();
      _addOutput("  Documents dir: ${appDir.path}");

      final filePath = '${appDir.path}/debug_test.mbtiles';
      final file = File(filePath);

      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
        _addOutput("  ✓ File copied to: $filePath");
        _addOutput("  ✓ File size: ${await file.length()} bytes");
      } else {
        _addOutput("  ✗ Cannot copy - byteData is null");
      }

      // Step 4: Try to open with MbTiles
      _addOutput("\nStep 4: Opening with MbTiles...");
      MbTiles? mbtiles;
      if (await file.exists()) {
        try {
          mbtiles = MbTiles(path: filePath);
          _addOutput("  ✓ MbTiles object created");

          // Step 5: Try to read metadata
          _addOutput("\nStep 5: Reading metadata...");
          try {
            final metadata = mbtiles.getMetadata();
            _addOutput("  ✓ Metadata retrieved");

            // Print metadata as string since we can't iterate
            _addOutput("  Metadata: $metadata");

            // Try to access individual metadata values if possible
            // You might need to check the actual properties of MbTilesMetadata
            // For now, we'll just print the whole object
          } catch (e) {
            _addOutput("  ✗ Failed to get metadata: $e");
          }

          // Step 6: Try to read a tile
          _addOutput("\nStep 6: Reading sample tiles...");

          // Test coordinates (try different zoom levels)
          final testTiles = [
            [0, 0, 0], // World tile
            [5, 14, 10], // Tunisia area (from your logs)
            [5, 15, 10],
            [6, 33, 39], // From your logs where tiles were found
            [6, 34, 39],
          ];

          for (var tile in testTiles) {
            int z = tile[0];
            int x = tile[1];
            int y = tile[2];

            _addOutput("  Testing tile z=$z, x=$x, y=$y:");

            // Try original Y
            try {
              final tileData = mbtiles.getTile(z: z, x: x, y: y);
              if (tileData != null) {
                _addOutput(
                  "    ✓ Original Y: Found (${tileData.length} bytes)",
                );
                _analyzeTileData(tileData);
              } else {
                _addOutput("    ✗ Original Y: Not found");
              }
            } catch (e) {
              _addOutput("    ✗ Error with original Y: $e");
            }

            // Try flipped Y
            try {
              final flippedY = (1 << z) - 1 - y;
              final flippedData = mbtiles.getTile(z: z, x: x, y: flippedY);
              if (flippedData != null) {
                _addOutput(
                  "    ✓ Flipped Y: Found (${flippedData.length} bytes)",
                );
                _analyzeTileData(flippedData);
              } else {
                _addOutput("    ✗ Flipped Y: Not found");
              }
            } catch (e) {
              _addOutput("    ✗ Error with flipped Y: $e");
            }
          }
          // Step 6b: Tunisia specific test (MOVE THIS HERE)
          _addOutput("\n  Testing Tunisia tile z=5, x=14, y=10:");
          try {
            final tileData = mbtiles.getTile(z: 5, x: 14, y: 10);
            if (tileData != null) {
              _addOutput("    ✓ Found (${tileData.length} bytes)");
              _analyzeTileData(tileData);
            } else {
              _addOutput("    ✗ Not found");
              final flippedY = (1 << 5) - 1 - 10;
              final flippedData = mbtiles.getTile(z: 5, x: 14, y: flippedY);
              if (flippedData != null) {
                _addOutput(
                  "    ✓ Flipped Y found (${flippedData.length} bytes)",
                );
                _analyzeTileData(flippedData);
              }
            }
          } catch (e) {
            _addOutput("    ✗ Error: $e");
          }

          // Step 7: Close the database
          _addOutput("\nStep 7: Closing database...");
          mbtiles.close(); // Remove await
          _addOutput("  ✓ Database closed");
        } catch (e) {
          _addOutput("  ✗ Failed to open MbTiles: $e");
        }
      } else {
        _addOutput("  ✗ File does not exist at: $filePath");
      }
    } catch (e) {
      _addOutput("ERROR: $e");
    }

    _addOutput("\n=== DEBUG COMPLETE ===");
    _isLoading = false;
  }

  void _analyzeTileData(Uint8List data) {
    if (data.isEmpty) {
      _addOutput("      Data is empty");
      return;
    }

    _addOutput("      Size: ${data.length} bytes");

    if (data.length > 4) {
      // Show first few bytes in hex
      String hexBytes = data
          .sublist(0, data.length > 8 ? 8 : data.length)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      _addOutput("      Hex header: $hexBytes");

      // Check for common image formats
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        _addOutput("      ✓ Format: PNG image");
      } else if (data[0] == 0xFF && data[1] == 0xD8) {
        _addOutput("      ✓ Format: JPEG image");
      } else if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
        _addOutput("      ✓ Format: GIF image");
      } else if (data[0] == 0x52 &&
          data[1] == 0x49 &&
          data[2] == 0x46 &&
          data[3] == 0x46) {
        _addOutput("      ✓ Format: WebP image");
      }
      // PBF (vector tile) indicators
      else if (data[0] == 0x78) {
        _addOutput(
          "      ℹ️ Format: Possible PBF vector tile (starts with 0x78)",
        );
      } else if (data[0] == 0x1F && data[1] == 0x8B) {
        _addOutput("      ℹ️ Format: GZIP compressed (possibly vector tiles)");
      } else {
        // Try to decode as string to see if it's text/JSON
        try {
          final sample = String.fromCharCodes(
            data.sublist(0, data.length > 50 ? 50 : data.length),
          );
          if (sample.contains('{') || sample.contains('[')) {
            _addOutput("      ℹ️ Contains JSON-like structure");
          }
          _addOutput("      Sample text: $sample");
        } catch (e) {
          _addOutput("      Binary data (not text)");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug MBTiles'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _debugMbtilesFile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_isLoading ? 'Running...' : 'Start Debug'),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
