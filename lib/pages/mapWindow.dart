import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

// ── Data model ───────────────────────────────────────────────────────────────
enum ReportCategory { dumping, pollution, pothole, lighting, other }

extension ReportCategoryX on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.dumping:
        return 'Illegal dumping';
      case ReportCategory.pollution:
        return 'Pollution';
      case ReportCategory.pothole:
        return 'Pothole / Road';
      case ReportCategory.lighting:
        return 'Broken light';
      case ReportCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.dumping:
        return Icons.delete_outline;
      case ReportCategory.pollution:
        return Icons.water_drop_outlined;
      case ReportCategory.pothole:
        return Icons.warning_amber_outlined;
      case ReportCategory.lighting:
        return Icons.light_outlined;
      case ReportCategory.other:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case ReportCategory.dumping:
        return NMColors.red;
      case ReportCategory.pollution:
        return NMColors.orange;
      case ReportCategory.pothole:
        return NMColors.amber;
      case ReportCategory.lighting:
        return const Color(0xFF818CF8); // indigo
      case ReportCategory.other:
        return NMColors.muted;
    }
  }
}

class Report {
  final LatLng position;
  final ReportCategory category;
  final String description;
  final String area;
  final int reportCount;
  final int daysOld;
  // neglect score 0-100: decays slowly so old unfixed reports stay high
  final int neglectScore;

  const Report({
    required this.position,
    required this.category,
    required this.description,
    required this.area,
    required this.reportCount,
    required this.daysOld,
    required this.neglectScore,
  });
}

// ── Sample data ───────────────────────────────────────────────────────────────
const _sampleReports = [
  Report(
    position: LatLng(36.810, 10.180),
    category: ReportCategory.dumping,
    description: 'Illegal dumping near Av. Habib Bourguiba',
    area: 'Tunis Centre',
    reportCount: 12,
    daysOld: 18,
    neglectScore: 82,
  ),
  Report(
    position: LatLng(36.830, 10.215),
    category: ReportCategory.lighting,
    description: 'Broken streetlights along Route X2',
    area: 'Lac 2',
    reportCount: 5,
    daysOld: 9,
    neglectScore: 54,
  ),
  Report(
    position: LatLng(36.795, 10.168),
    category: ReportCategory.pollution,
    description: 'Oil spill near drainage channel',
    area: 'Médina',
    reportCount: 3,
    daysOld: 4,
    neglectScore: 31,
  ),
  Report(
    position: LatLng(36.849, 10.193),
    category: ReportCategory.pothole,
    description: 'Multiple potholes, Rue de Marseille',
    area: 'Bab Bhar',
    reportCount: 8,
    daysOld: 22,
    neglectScore: 76,
  ),
];

// ── Time filter enum ──────────────────────────────────────────────────────────
enum TimeFilter { h24, d7, d30, all }

extension TimeFilterX on TimeFilter {
  String get label {
    switch (this) {
      case TimeFilter.h24:
        return '24h';
      case TimeFilter.d7:
        return '7 days';
      case TimeFilter.d30:
        return '30 days';
      case TimeFilter.all:
        return 'All time';
    }
  }
}

// ── Main map page ─────────────────────────────────────────────────────────────
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  TimeFilter _timeFilter = TimeFilter.d7;
  Report? _selectedReport;

  List<Report> get _filteredReports {
    int maxDays;
    switch (_timeFilter) {
      case TimeFilter.h24:
        maxDays = 1;
        break;
      case TimeFilter.d7:
        maxDays = 7;
        break;
      case TimeFilter.d30:
        maxDays = 30;
        break;
      case TimeFilter.all:
        maxDays = 9999;
        break;
    }
    return _sampleReports.where((r) => r.daysOld <= maxDays).toList();
  }

  // Neglect score → marker color
  Color _scoreColor(int score) {
    if (score >= 70) return NMColors.red;
    if (score >= 40) return NMColors.orange;
    return NMColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.insideBounds(
                bounds: LatLngBounds(
                  const LatLng(36.75, 10.10),
                  const LatLng(36.90, 10.26),
                ),
                padding: const EdgeInsets.all(24),
              ),

              maxZoom: 18,
              minZoom: 8,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(30.2, 7.5),
                  const LatLng(37.5, 11.6),
                ),
              ),
              onTap: (_, __) => setState(() => _selectedReport = null),
            ),
            children: [
              // Tile layer — dark CartoDB Positron fork looks great on dark UI
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.neglectmap.app',
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),

              // Report markers
              MarkerLayer(
                markers: _filteredReports.map((report) {
                  final color = _scoreColor(report.neglectScore);
                  return Marker(
                    point: report.position,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedReport = report),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing ring
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.15),
                              border: Border.all(
                                color: color.withOpacity(0.4),
                                width: 0.5,
                              ),
                            ),
                          ),
                          // Core dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Top overlay: title + filter pills ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NMColors.bg.withOpacity(0.95),
                    NMColors.bg.withOpacity(0),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          const Text(
                            'Bayanati',
                            style: TextStyle(
                              color: NMColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: NMColors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: NMColors.green.withOpacity(0.4),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              '● LIVE',
                              style: TextStyle(
                                color: NMColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_filteredReports.length} active',
                            style: const TextStyle(
                              color: NMColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: TimeFilter.values.map((f) {
                          final active = f == _timeFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _timeFilter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? NMColors.green.withOpacity(0.15)
                                      : NMColors.surface.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? NMColors.green.withOpacity(0.5)
                                        : NMColors.border,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  f.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: active
                                        ? NMColors.green
                                        : NMColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── OpenStreetMap attribution ───────────────────────────────────────
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                  'https://www.openstreetmap.org/copyright',
                );
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: NMColors.bg.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: NMColors.muted),
                ),
              ),
            ),
          ),

          // ── Bottom sheet: report list or selected report detail ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedReport != null
                  ? _ReportDetail(
                      key: ValueKey(_selectedReport),
                      report: _selectedReport!,
                      onClose: () => setState(() => _selectedReport = null),
                    )
                  : _ReportList(reports: _filteredReports),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report list bottom sheet ──────────────────────────────────────────────────
class _ReportList extends StatelessWidget {
  final List<Report> reports;

  const _ReportList({required this.reports});

  @override
  Widget build(BuildContext context) {
    final sorted = [...reports]
      ..sort((a, b) => b.neglectScore.compareTo(a.neglectScore));

    return Container(
      decoration: const BoxDecoration(
        color: NMColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: NMColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: NMColors.muted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Persistent issues',
                  style: TextStyle(
                    color: NMColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sorted.length} found',
                  style: const TextStyle(color: NMColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),

          // List
          ...sorted.take(3).map((r) => _ReportListTile(report: r)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final Report report;

  const _ReportListTile({required this.report});

  Color get _scoreColor {
    if (report.neglectScore >= 70) return NMColors.red;
    if (report.neglectScore >= 40) return NMColors.orange;
    return NMColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category dot
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: report.category.color,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text + neglect bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.description,
                  style: const TextStyle(
                    color: NMColors.text,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${report.reportCount} reports · ${report.daysOld}d persistent',
                  style: const TextStyle(color: NMColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                // Neglect score bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: report.neglectScore / 100,
                          minHeight: 3,
                          backgroundColor: NMColors.border,
                          valueColor: AlwaysStoppedAnimation(_scoreColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${report.neglectScore}',
                      style: TextStyle(
                        color: _scoreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selected report detail panel ──────────────────────────────────────────────
class _ReportDetail extends StatelessWidget {
  final Report report;
  final VoidCallback onClose;

  const _ReportDetail({super.key, required this.report, required this.onClose});

  Color get _scoreColor {
    if (report.neglectScore >= 70) return NMColors.red;
    if (report.neglectScore >= 40) return NMColors.orange;
    return NMColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NMColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: NMColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + close
          Row(
            children: [
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: NMColors.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: NMColors.muted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report.category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: report.category.color.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.category.icon,
                      size: 12,
                      color: report.category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.category.label,
                      style: TextStyle(
                        color: report.category.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.area,
                style: const TextStyle(color: NMColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            report.description,
            style: const TextStyle(
              color: NMColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Reports',
                value: '${report.reportCount}',
                color: NMColors.muted,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Days old',
                value: '${report.daysOld}d',
                color: NMColors.muted,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Neglect',
                value: '${report.neglectScore}',
                color: _scoreColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Neglect bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.neglectScore / 100,
              minHeight: 5,
              backgroundColor: NMColors.border,
              valueColor: AlwaysStoppedAnimation(_scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(color: NMColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
