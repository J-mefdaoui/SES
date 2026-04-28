import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../main.dart';
import '../config.dart';
import '../components/statefinder.dart';

// ── Category definition ───────────────────────────────────────────────────────
class _Category {
  final String id;
  final String label;
  final IconData icon;
  const _Category(this.id, this.label, this.icon);
}

const _categories = [
  _Category('dumping', 'Illegal dumping', Icons.delete_outline),
  _Category('pollution', 'Pollution', Icons.water_drop_outlined),
  _Category('pothole', 'Pothole / Road', Icons.warning_amber_outlined),
  _Category('lighting', 'Broken light', Icons.light_outlined),
  _Category('noise', 'Noise / waste', Icons.volume_up_outlined),
  _Category('other', 'Other', Icons.more_horiz),
];

// ── Report page ───────────────────────────────────────────────────────────────
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? _selectedCategory;
  bool _anonymous = true;
  bool _submitted = false;

  // Camera state
  File? _capturedImage;
  bool _isLoading = false;

  // GPS state
  double? _capturedLat;
  double? _capturedLng;
  String? _locationSource;
  String? _flagReason;

  //Pocketbase instance
  late final PocketBase _pb;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initPocketbase();
  }

  void _initPocketbase() {
    _pb = PocketBase(Appconfig.pocketbaseUrl); // -------- the cloudflare URL
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.location].request();
  }

  Future<void> _takePhoto() async {
    // Check camera permission
    if (!await Permission.camera.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        _showSnackBar('Camera permission is required');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _capturedLat = null;
      _capturedLng = null;
      _locationSource = null;
      _flagReason = null;
    });

    try {
      // Take photo with camera only (no gallery)
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Extract GPS from photo
      final location = await _getLocationWithFallback(photo.path);

      if (location == null) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Please enable GPS and retake photo');
        return;
      }

      // Compress image
      final compressedImage = await _compressImage(File(photo.path));

      setState(() {
        _capturedImage = compressedImage;
        _capturedLat = location.latitude;
        _capturedLng = location.longitude;
        _locationSource = location.source;
        _flagReason = location.flagReason;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to take photo: $e');
    }
  }

  Future<
    ({double latitude, double longitude, String source, String? flagReason})?
  >
  _getLocationWithFallback(String imagePath) async {
    // Try 1: Extract from EXIF
    final exifLocation = await _getLocationFromExif(imagePath);

    // Try 2: Get phone GPS
    final phoneLocation = await _getCurrentPhoneLocation();

    // Case 1: EXIF has GPS
    if (exifLocation != null) {
      String? flagReason;
      String source = 'exif';

      // Compare with phone GPS if available (bot detection)
      if (phoneLocation != null) {
        final distance = _calculateDistance(
          exifLocation.latitude,
          exifLocation.longitude,
          phoneLocation.latitude,
          phoneLocation.longitude,
        );

        if (distance > 300) {
          // Generous threshold in meters
          flagReason = 'Suspicious: Location mismatch (${distance.round()}m)';
        }
      }

      return (
        latitude: exifLocation.latitude,
        longitude: exifLocation.longitude,
        source: source,
        flagReason: flagReason,
      );
    }

    // Case 2: EXIF has no GPS, use phone GPS as fallback
    if (phoneLocation != null) {
      return (
        latitude: phoneLocation.latitude,
        longitude: phoneLocation.longitude,
        source: 'phone_fallback',
        flagReason: null,
      );
    }

    // Case 3: Both failed
    return null;
  }

  Future<({double latitude, double longitude})?> _getLocationFromExif(
    String imagePath,
  ) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final exifData = await readExifFromBytes(bytes);

      if (exifData.containsKey('GPS Latitude') &&
          exifData.containsKey('GPS Longitude')) {
        final lat = _convertDmsToDecimal(
          exifData['GPS Latitude']!,
          exifData['GPS LatitudeRef']?.toString() ?? 'N',
        );
        final lng = _convertDmsToDecimal(
          exifData['GPS Longitude']!,
          exifData['GPS LongitudeRef']?.toString() ?? 'E',
        );

        if (lat != null && lng != null) {
          return (latitude: lat, longitude: lng);
        }
      }
    } catch (e) {
      print('EXIF extraction failed: $e');
    }
    return null;
  }

  Future<({double latitude, double longitude})?>
  _getCurrentPhoneLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      print('Phone GPS failed: $e');
      return null;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => math.sin(x);
  double _cos(double x) => math.cos(x);
  double _sqrt(double x) => math.sqrt(x);
  double _atan2(double y, double x) => math.atan2(y, x);

  double? _convertDmsToDecimal(dynamic dms, String ref) {
    if (dms == null) return null;

    double degrees = 0;
    double minutes = 0;
    double seconds = 0;

    final dmsStr = dms.toString();
    final parts = dmsStr.split(',');

    if (parts.length >= 3) {
      degrees = double.parse(parts[0].trim());
      minutes = double.parse(parts[1].trim());
      seconds = double.parse(parts[2].trim());
    } else {
      return null;
    }

    double decimal = degrees + minutes / 60 + seconds / 3600;
    if (ref == 'S' || ref == 'W') decimal = -decimal;

    return decimal;
  }

  Future<File> _compressImage(File imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    return File(result?.path ?? imageFile.path);
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category');
      return;
    }

    if (_capturedImage == null) {
      _showSnackBar('Please take a photo');
      return;
    }

    if (_capturedLat == null || _capturedLng == null) {
      _showSnackBar(
        'Location not detected. Please retake photo with GPS enabled.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // Upload to PocketBase using raw HTTP multipart
      final uri = Uri.parse('${_pb.baseUrl}/api/collections/GeoTags/records');

      var request = http.MultipartRequest('POST', uri);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _capturedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add the flag fiel
      request.fields['flag'] = _flagReason ?? '';
      request.fields['location'] = jsonEncode({
        'lon': _capturedLng,
        'lat': _capturedLat,
      });
      print('Sending to: $uri');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('PocketBase upload failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final imageId = responseData['id'];

      print('Upload successful! Image ID: $imageId');

      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';

      await FirebaseFirestore.instance.collection('reports').add({
        'category': _selectedCategory,
        'geotag': GeoPoint(_capturedLat!, _capturedLng!),
        'locationSource': _locationSource,
        'flagReason': _flagReason,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid ?? 'anonymous',
        'anonymous': _anonymous,
        'imageId': imageId,
      });

      final _whereAmI = await GetState.getGovernorat(
        _capturedLat!,
        _capturedLng!,
      );
      final userRef = FirebaseFirestore.instance
          .collection('usersStats')
          .doc(userId);

      await userRef.set({
        'totalReports': FieldValue.increment(1),
        'lastReportDate': FieldValue.serverTimestamp(),
        'lastReportlocation': GeoPoint(_capturedLat!, _capturedLng!),
        'categories.${_selectedCategory}': FieldValue.increment(1),
        'totalstateVisted.${_whereAmI}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      //TODO: global status
      final globalref = FirebaseFirestore.instance
          .collection('globalStats')
          .doc('governorateCount');
      await globalref.set({
        '${_whereAmI}': FieldValue.increment(1),
        'G-totalReports': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Firestore save successful');

      setState(() {
        _submitted = true;
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _selectedCategory = null;
            _capturedImage = null;
            _capturedLat = null;
            _capturedLng = null;
            _locationSource = null;
            _flagReason = null;
          });
        }
      });
    } catch (e) {
      print('ERROR: $e');
      _showSnackBar("Failed to submit: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelPhoto() {
    setState(() {
      _capturedImage = null;
      _capturedLat = null;
      _capturedLng = null;
      _locationSource = null;
      _flagReason = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NMColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NMColors.bg,
      appBar: AppBar(
        title: const Text('New report'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Guidelines',
              style: TextStyle(color: NMColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _submitted
            ? _SuccessView()
            : _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _capturedImage == null
            ? _PhotoCaptureView(onTakePhoto: _takePhoto)
            : _ConfirmationView(
                image: _capturedImage!,
                latitude: _capturedLat,
                longitude: _capturedLng,
                locationSource: _locationSource,
                flagReason: _flagReason,
                selectedCategory: _selectedCategory,
                anonymous: _anonymous,
                onCategorySelected: (id) =>
                    setState(() => _selectedCategory = id),
                onAnonymousChanged: (val) => setState(() => _anonymous = val),
                onSubmit: _submitReport,
                onCancel: _cancelPhoto,
              ),
      ),
    );
  }
}

// ── Photo capture view ────────────────────────────────────────────────────────
class _PhotoCaptureView extends StatelessWidget {
  final VoidCallback onTakePhoto;
  const _PhotoCaptureView({required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTakePhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: NMColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: NMColors.green, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: NMColors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to take a photo',
              style: TextStyle(color: NMColors.text, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'GPS will automatically tag your location',
              style: TextStyle(color: NMColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation view ─────────────────────────────────────────────────────────
class _ConfirmationView extends StatelessWidget {
  final File image;
  final double? latitude;
  final double? longitude;
  final String? locationSource;
  final String? flagReason;
  final String? selectedCategory;
  final bool anonymous;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _ConfirmationView({
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.locationSource,
    required this.flagReason,
    required this.selectedCategory,
    required this.anonymous,
    required this.onCategorySelected,
    required this.onAnonymousChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo preview
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),

          // Location info
          if (latitude != null && longitude != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NMColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: NMColors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${latitude!.toStringAsFixed(4)}°N, ${longitude!.toStringAsFixed(4)}°E',
                          style: const TextStyle(
                            color: NMColors.text,
                            fontSize: 12,
                          ),
                        ),
                        if (locationSource != null)
                          Text(
                            'Source: $locationSource',
                            style: const TextStyle(
                              color: NMColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        if (flagReason != null)
                          Text(
                            flagReason!,
                            style: const TextStyle(
                              color: NMColors.orange,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Retake/Cancel buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NMColors.border),
                    foregroundColor: NMColors.muted,
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NMColors.green,
                    foregroundColor: const Color(0xFF0A1A0C),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category selector
          const _SectionLabel('Category'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = selectedCategory == cat.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(cat.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected
                        ? NMColors.green.withOpacity(0.1)
                        : NMColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? NMColors.green.withOpacity(0.5)
                          : NMColors.border,
                      width: selected ? 1 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.icon,
                        color: selected ? NMColors.green : NMColors.muted,
                        size: 22,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: selected ? NMColors.green : NMColors.muted,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Anonymous toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NMColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  size: 16,
                  color: NMColors.muted,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit anonymously',
                        style: TextStyle(color: NMColors.text, fontSize: 13),
                      ),
                      Text(
                        'Your identity will not be stored',
                        style: TextStyle(color: NMColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: anonymous,
                  onChanged: onAnonymousChanged,
                  activeColor: NMColors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NMColors.green.withOpacity(0.12),
              border: Border.all(
                color: NMColors.green.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Icon(Icons.check, color: NMColors.green, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Report submitted',
            style: TextStyle(
              color: NMColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'It now appears on the map.',
            style: TextStyle(color: NMColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: NMColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
