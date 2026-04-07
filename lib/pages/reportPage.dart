import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';

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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera].request();
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

      // Compress image
      final compressedImage = await _compressImage(File(photo.path));

      setState(() {
        _capturedImage = compressedImage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to take photo: $e');
    }
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

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate upload (replace with actual upload later)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _submitted = true;
      _isLoading = false;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitted = false;
          _selectedCategory = null;
          _capturedImage = null;
        });
      }
    });
  }

  void _cancelPhoto() {
    setState(() {
      _capturedImage = null;
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
          ],
        ),
      ),
    );
  }
}

// ── Confirmation view ─────────────────────────────────────────────────────────
class _ConfirmationView extends StatelessWidget {
  final File image;
  final String? selectedCategory;
  final bool anonymous;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _ConfirmationView({
    required this.image,
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
