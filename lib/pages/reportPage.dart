import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _submit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: NMColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: NMColors.border, width: 0.5),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);

    // Reset after 2 s so the user can file another report
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitted = false;
          _selectedCategory = null;
        });
      }
    });
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
            : _FormView(
                selectedCategory: _selectedCategory,
                anonymous: _anonymous,
                onCategorySelected: (id) =>
                    setState(() => _selectedCategory = id),
                onAnonymousChanged: (val) => setState(() => _anonymous = val),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final String? selectedCategory;
  final bool anonymous;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSubmit;

  const _FormView({
    required this.selectedCategory,
    required this.anonymous,
    required this.onCategorySelected,
    required this.onAnonymousChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo zone
          GestureDetector(
            onTap: () {}, // TODO: image_picker integration
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: NMColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: NMColors.green.withOpacity(0.2),
                  width: 1,
                  // dashed border not available natively — use CustomPainter in a real app
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: NMColors.muted,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to photograph the issue',
                    style: TextStyle(color: NMColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'or choose from gallery',
                    style: TextStyle(color: NMColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category label
          const _SectionLabel('Category'),
          const SizedBox(height: 10),

          // Category grid
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
                          height: 1.3,
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

          // Location badge
          const _SectionLabel('Location'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NMColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NMColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: NMColors.green,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '36.8065°N, 10.1815°E · Tunis Centre',
                    style: TextStyle(color: NMColors.muted, fontSize: 12),
                  ),
                ),
                const Icon(Icons.gps_fixed, size: 14, color: NMColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Anonymous toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NMColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NMColors.border, width: 0.5),
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
                        style: TextStyle(
                          color: NMColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
                  activeTrackColor: NMColors.green.withOpacity(0.25),
                  inactiveThumbColor: NMColors.muted,
                  inactiveTrackColor: NMColors.surface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('Submit report'),
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
            'It now appears on the heatmap.',
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
