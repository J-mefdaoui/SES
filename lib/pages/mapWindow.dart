import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

// =============================================================================
// DATA MODEL
// =============================================================================

enum ReportCategory { dumping, pollution, pothole, lighting, other }

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

  int get maxDays {
    switch (this) {
      case TimeFilter.h24:
        return 1;
      case TimeFilter.d7:
        return 7;
      case TimeFilter.d30:
        return 30;
      case TimeFilter.all:
        return 9999;
    }
  }
}

class Report {
  final String id;
  final LatLng position;
  final ReportCategory category;
  final String description;
  final String area;
  final int reportCount;
  final int daysOld;
  final int neglectScore; // 0-100

  const Report({
    required this.id,
    required this.position,
    required this.category,
    required this.description,
    required this.area,
    required this.reportCount,
    required this.daysOld,
    required this.neglectScore,
  });

  // Ready for Firebase — swap ReportService.fetch() when backend is ready
  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      position: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      category: ReportCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ReportCategory.other,
      ),
      description: data['description'] as String,
      area: data['area'] as String,
      reportCount: data['reportCount'] as int,
      daysOld: data['daysOld'] as int,
      neglectScore: data['neglectScore'] as int,
    );
  }
}

// =============================================================================
// DATA SERVICE
// Switch _mockFetch to _firebaseFetch when backend is ready.
// Nothing outside this class needs to change.
// =============================================================================

class ReportService {
  static Future<List<Report>> fetch() => _mockFetch();

  // -- Mock (active now) ------------------------------------------------------
  static Future<List<Report>> _mockFetch() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockReports;
  }

  // -- Firebase (uncomment when ready) ----------------------------------------
  // static Future<List<Report>> _firebaseFetch() async {
  //   final snap = await FirebaseFirestore.instance
  //       .collection('reports')
  //       .orderBy('neglectScore', descending: true)
  //       .get();
  //   return snap.docs
  //       .map((d) => Report.fromFirestore(d.data(), d.id))
  //       .toList();
  // }
}

// =============================================================================
// MOCK DATA
// =============================================================================

const List<Report> _mockReports = [
  Report(
    id: '1',
    position: LatLng(36.8100, 10.1800),
    category: ReportCategory.dumping,
    description: 'Illegal dumping near Av. Habib Bourguiba',
    area: 'Tunis Centre',
    reportCount: 12,
    daysOld: 18,
    neglectScore: 82,
  ),
  Report(
    id: '2',
    position: LatLng(36.8150, 10.1850),
    category: ReportCategory.dumping,
    description: 'Trash pile at corner of Rue de Grece',
    area: 'Tunis Centre',
    reportCount: 7,
    daysOld: 12,
    neglectScore: 70,
  ),
  Report(
    id: '3',
    position: LatLng(36.8080, 10.1760),
    category: ReportCategory.pollution,
    description: 'Sewage smell near central market',
    area: 'Tunis Centre',
    reportCount: 4,
    daysOld: 6,
    neglectScore: 48,
  ),
  Report(
    id: '4',
    position: LatLng(36.8300, 10.2150),
    category: ReportCategory.lighting,
    description: 'Broken streetlights along Route X2',
    area: 'Lac 2',
    reportCount: 5,
    daysOld: 9,
    neglectScore: 54,
  ),
  Report(
    id: '5',
    position: LatLng(36.8320, 10.2100),
    category: ReportCategory.lighting,
    description: 'Three consecutive poles not working',
    area: 'Lac 2',
    reportCount: 3,
    daysOld: 3,
    neglectScore: 30,
  ),
  Report(
    id: '6',
    position: LatLng(36.7950, 10.1680),
    category: ReportCategory.pollution,
    description: 'Oil spill near drainage channel',
    area: 'Medina',
    reportCount: 3,
    daysOld: 4,
    neglectScore: 31,
  ),
  Report(
    id: '7',
    position: LatLng(36.8490, 10.1930),
    category: ReportCategory.pothole,
    description: 'Multiple potholes, Rue de Marseille',
    area: 'Bab Bhar',
    reportCount: 8,
    daysOld: 22,
    neglectScore: 76,
  ),
  Report(
    id: '8',
    position: LatLng(36.8460, 10.1960),
    category: ReportCategory.pothole,
    description: 'Large crater near bus stop',
    area: 'Bab Bhar',
    reportCount: 11,
    daysOld: 30,
    neglectScore: 90,
  ),
  Report(
    id: '9',
    position: LatLng(36.8510, 10.1910),
    category: ReportCategory.dumping,
    description: 'Construction waste dumped on sidewalk',
    area: 'Bab Bhar',
    reportCount: 6,
    daysOld: 14,
    neglectScore: 65,
  ),
  Report(
    id: '10',
    position: LatLng(36.7800, 10.1600),
    category: ReportCategory.other,
    description: 'Abandoned vehicle blocking road',
    area: 'Bab Jedid',
    reportCount: 2,
    daysOld: 2,
    neglectScore: 20,
  ),
];

// =============================================================================
// HEATMAP PAINTER
// Draws radial blobs on a canvas using flutter_map's coordinate projection.
// No external package — uses only flutter_map's built-in CustomPainter layer.
// =============================================================================

/// One data point fed into the painter.
class HeatPoint {
  final LatLng position;
  final double weight; // 0.0 - 1.0

  const HeatPoint(this.position, this.weight);
}

/// Converts a 0.0-1.0 weight to a colour along the yellow->red danger ramp.
Color _weightToColor(double weight) {
  if (weight < 0.3) {
    return Color.lerp(Colors.yellow, Colors.orange, weight / 0.3)!;
  } else if (weight < 0.7) {
    return Color.lerp(Colors.orange, Colors.deepOrange, (weight - 0.3) / 0.4)!;
  } else {
    return Color.lerp(Colors.deepOrange, Colors.red, (weight - 0.7) / 0.3)!;
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;
  final MapCamera camera;

  // Radius in logical pixels of each heat blob.
  // Larger zoom = we want the blob to cover roughly the same geographic area,
  // so we scale with zoom level.
  static const double _baseRadius = 60.0;

  _HeatmapPainter({required this.points, required this.camera});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale radius with zoom so blobs feel geographically consistent
    final double radius = _baseRadius * (camera.zoom / 12.0).clamp(0.5, 3.0);

    for (final point in points) {
      // Project LatLng to screen pixel offset

      final screenPt = camera.latLngToScreenOffset(point.position);

      final color = _weightToColor(point.weight);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.55 * point.weight),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: screenPt, radius: radius))
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(screenPt, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.points != points || old.camera != camera;
}

/// flutter_map layer widget that renders the heatmap via CustomPainter.
class HeatmapLayer extends StatelessWidget {
  final List<HeatPoint> points;

  const HeatmapLayer({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return CustomPaint(
      painter: _HeatmapPainter(points: points, camera: camera),
      // Fill the entire map viewport
      child: const SizedBox.expand(),
    );
  }
}

// =============================================================================
// MAP PAGE
// =============================================================================

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Report> _allReports = [];
  bool _loading = true;
  TimeFilter _filter = TimeFilter.d7;
  Report? _selected;

  List<Report> get _filtered =>
      _allReports.where((r) => r.daysOld <= _filter.maxDays).toList();

  // Convert filtered reports to heatmap points
  List<HeatPoint> get _heatPoints => _filtered
      .map((r) => HeatPoint(r.position, r.neglectScore / 100.0))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final reports = await ReportService.fetch();
    if (!mounted) return;
    setState(() {
      _allReports = reports;
      _loading = false;
    });
  }

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
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              // 1 — Dark base tiles
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.neglectmap.app',
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),

              // 2 — Custom heatmap (above tiles, below markers)
              if (!_loading && _heatPoints.isNotEmpty)
                HeatmapLayer(points: _heatPoints),

              // 3 — Report marker dots (tappable)
              MarkerLayer(
                markers: _filtered.map((report) {
                  final color = _scoreColor(report.neglectScore);
                  return Marker(
                    point: report.position,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = report),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
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
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
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

          // ── Loading indicator ───────────────────────────────────────────────
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: NMColors.green),
            ),

          // ── Top bar: title + filter pills ───────────────────────────────────
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
                    NMColors.bg.withOpacity(0.0),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          const Text(
                            'NeglectMap',
                            style: TextStyle(
                              color: NMColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: NMColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: NMColors.green.withOpacity(0.35),
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
                          if (!_loading)
                            Text(
                              '${_filtered.length} active',
                              style: const TextStyle(
                                color: NMColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _loadReports,
                            child: const Icon(
                              Icons.refresh,
                              color: NMColors.muted,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time filter pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: TimeFilter.values.map((f) {
                          final active = f == _filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? NMColors.green.withOpacity(0.15)
                                      : NMColors.surface.withOpacity(0.85),
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

          // ── Attribution ─────────────────────────────────────────────────────
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

          // ── Bottom sheet ────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selected != null
                  ? _ReportDetail(
                      key: ValueKey(_selected!.id),
                      report: _selected!,
                      onClose: () => setState(() => _selected = null),
                      scoreColor: _scoreColor(_selected!.neglectScore),
                    )
                  : _ReportList(reports: _filtered, scoreColor: _scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REPORT LIST BOTTOM SHEET
// =============================================================================

class _ReportList extends StatelessWidget {
  final List<Report> reports;
  final Color Function(int) scoreColor;

  const _ReportList({required this.reports, required this.scoreColor});

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
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: NMColors.muted.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          ...sorted
              .take(3)
              .map(
                (r) =>
                    _ReportTile(report: r, color: scoreColor(r.neglectScore)),
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;
  final Color color;

  const _ReportTile({required this.report, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          const SizedBox(width: 10),
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
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: report.neglectScore / 100,
                          minHeight: 3,
                          backgroundColor: NMColors.border,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${report.neglectScore}',
                      style: TextStyle(
                        color: color,
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

// =============================================================================
// REPORT DETAIL PANEL
// =============================================================================

class _ReportDetail extends StatelessWidget {
  final Report report;
  final VoidCallback onClose;
  final Color scoreColor;

  const _ReportDetail({
    super.key,
    required this.report,
    required this.onClose,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NMColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: NMColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: NMColors.muted.withOpacity(0.35),
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
          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: scoreColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  report.category.name,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
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

          Text(
            report.description,
            style: const TextStyle(
              color: NMColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _Chip(
                label: 'Reports',
                value: '${report.reportCount}',
                color: NMColors.muted,
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'Age',
                value: '${report.daysOld}d',
                color: NMColors.muted,
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'Neglect',
                value: '${report.neglectScore}',
                color: scoreColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.neglectScore / 100,
              minHeight: 5,
              backgroundColor: NMColors.border,
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

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
