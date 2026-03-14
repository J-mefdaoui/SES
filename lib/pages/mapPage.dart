import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class offlineMap extends StatefulWidget {
  const offlineMap({super.key});

  @override
  State<offlineMap> createState() => _offlineMapState();
}

class _offlineMapState extends State<offlineMap> {
  MbTiles? _mbTiles;
  bool _isLoading = true;
  String? _errorMessage;

  final List<Marker> _markers = [
    Marker(
      point: const LatLng(36.8065, 10.1815),
      width: 40,
      height: 40,
      child: const Icon(Icons.location_pin, color: Colors.red, size: 35),
    ),
    Marker(
      point: const LatLng(34.7395, 10.7603),
      width: 40,
      height: 40,
      child: const Icon(Icons.location_pin, color: Colors.blue, size: 35),
    ),
    Marker(
      point: const LatLng(35.6789, 10.1033),
      width: 40,
      height: 40,
      child: const Icon(Icons.location_pin, color: Colors.green, size: 35),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMbtilesFromAssets();
  }

  Future<void> _loadMbtilesFromAssets() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/tunisia.mbtiles';
      final file = File(filePath);

      if (!await file.exists()) {
        print('Copying vector MBTiles file from assets...');
        final byteData = await rootBundle.load(
          'assets/mapTiles/tunisia.mbtiles',
        );
        await file.writeAsBytes(byteData.buffer.asUint8List());
        print('File copied successfully');
      }

      final mbtiles = MbTiles(path: filePath);

      setState(() {
        _mbTiles = mbtiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mbTiles?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadMbtilesFromAssets();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunisia Map'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: _addMarker,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(34.0, 9.0),
              initialZoom: 6,
              maxZoom: 18,
              minZoom: 4,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Attribution at bottom right
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                  'https://www.openstreetmap.org/copyright',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addMarker() {
    setState(() {
      _markers.add(
        Marker(
          point: LatLng(
            34.0 + (DateTime.now().millisecond % 100) / 100.0,
            9.0 + (DateTime.now().millisecond % 100) / 100.0,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.purple, size: 35),
        ),
      );
    });
  }
}
