import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../config.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

final _tunisiaBounds = LatLngBounds(
  const LatLng(29.0, 6.0),
  const LatLng(38.5, 12.5),
);
const _tunisiaCenter = LatLng(34.0, 9.0);

// =============================================================================
// VIEW MODE
// Toggles between heatmap overlay and point markers
// =============================================================================

enum MapViewMode { heatmap, points }

// =============================================================================
// REPORT MODEL
// No hardcoded data — fetched from Firebase (wired via ReportService)
// =============================================================================

class Report {
  final String id;
  final LatLng position;
  final String category;
  final String description;
  final String area;
  final int reportCount;
  final int daysOld;
  final int neglectScore; // 0–100

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

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      position: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      category: data['category'] as String? ?? 'other',
      description: data['description'] as String? ?? '',
      area: data['area'] as String? ?? '',
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 1,
      daysOld: (data['daysOld'] as num?)?.toInt() ?? 0,
      neglectScore: (data['neglectScore'] as num?)?.toInt() ?? 0,
    );
  }
}

// =============================================================================
// REPORT SERVICE
// Swap _mockFetch → _firebaseFetch when backend is ready.
// =============================================================================

class ReportService {
  static Future<List<Report>> fetch() async {
    // TODO: replace with Firebase fetch
    // final snap = await FirebaseFirestore.instance
    //     .collection('reports')
    //     .orderBy('neglectScore', descending: true)
    //     .get();
    // return snap.docs.map((d) => Report.fromFirestore(d.data(), d.id)).toList();

    // Return empty list until Firebase is wired — heatmap tiles
    // from the KDE server will still render independently.
    return [];
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
  // ── State ──────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  List<Report> _reports = [];
  bool _locationLoading = true;
  LatLng? _userPosition;
  Report? _selectedReport;
  MapViewMode _viewMode = MapViewMode.heatmap;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadReports();
  }

  // ── Location ───────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackCenter();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _fallbackCenter();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _userPosition = userLatLng;
        _locationLoading = false;
      });

      // Move camera to user if inside Tunisia, else stay on Tunisia overview
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tunisiaBounds.contains(userLatLng)) {
          _mapController.move(userLatLng, 13.0);
        }
      });
    } catch (_) {
      _fallbackCenter();
    }
  }

  void _fallbackCenter() {
    if (!mounted) return;
    setState(() => _locationLoading = false);
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _loadReports() async {
    final reports = await ReportService.fetch();
    if (!mounted) return;
    setState(() => _reports = reports);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _scoreColor(int score) {
    if (score >= 70) return NMColors.red;
    if (score >= 40) return NMColors.orange;
    return NMColors.amber;
  }

  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NMColors.bg,
      body: Column(
        children: [
          // ── Top bar — lives in normal Column flow, no gesture conflicts
          SafeArea(
            bottom: false,
            child: Container(
              color: NMColors.bg,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ViewModeToggle(
                    mode: _viewMode,
                    onChanged: (m) => setState(() => _viewMode = m),
                  ),
                ],
              ),
            ),
          ),

          // ── Map fills remaining space
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(34.0, 9.0),
                    cameraConstraint: CameraConstraint.contain(
                      bounds: _tunisiaBounds,
                    ),
                    maxZoom: 18,
                    minZoom: 6,
                    onTap: (_, __) => setState(() => _selectedReport = null),
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

                    // 2 — KDE heatmap tile layer
                    if (_viewMode == MapViewMode.heatmap)
                      TileLayer(
                        urlTemplate:
                            '${Appconfig.heatmapUrl}/heatmap/{z}/{x}/{y}.png',
                        tileProvider: NetworkTileProvider(),
                      ),

                    // 3 — Point markers (points mode, from Firebase)
                    if (_viewMode == MapViewMode.points && _reports.isNotEmpty)
                      MarkerLayer(
                        markers: _reports.map((report) {
                          final color = _scoreColor(report.neglectScore);
                          return Marker(
                            point: report.position,
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedReport = report),
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

                    // 4 — User location dot
                    if (_userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: NMColors.green,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: NMColors.green.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Right rail buttons
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.my_location,
                        onTap: () {
                          if (_userPosition != null) {
                            _mapController.move(_userPosition!, 14.0);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _MapButton(
                        icon: Icons.filter_list,
                        onTap: () {
                          // TODO: category filter sheet
                        },
                      ),
                    ],
                  ),
                ),

                // ── Attribution
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
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

                // ── Report detail panel
                if (_selectedReport != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _ReportDetail(
                      key: ValueKey(_selectedReport!.id),
                      report: _selectedReport!,
                      onClose: () => setState(() => _selectedReport = null),
                      scoreColor: _scoreColor(_selectedReport!.neglectScore),
                    ),
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
// VIEW MODE TOGGLE
// =============================================================================

class _ViewModeToggle extends StatelessWidget {
  final MapViewMode mode;
  final ValueChanged<MapViewMode> onChanged;

  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            icon: Icons.whatshot_outlined,
            label: 'Heatmap',
            active: mode == MapViewMode.heatmap,
            onTap: () => onChanged(MapViewMode.heatmap),
            isFirst: true,
          ),
          Container(width: 0.5, height: 28, color: NMColors.border),
          _ToggleOption(
            icon: Icons.location_on_outlined,
            label: 'Points',
            active: mode == MapViewMode.points,
            onTap: () => onChanged(MapViewMode.points),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isFirst;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? NMColors.green.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isFirst ? Radius.zero : const Radius.circular(7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? NMColors.green : NMColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? NMColors.green : NMColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MAP BUTTON
// =============================================================================

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: NMColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: NMColors.border, width: 0.5),
        ),
        child: Icon(icon, color: NMColors.muted, size: 18),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: scoreColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  report.category,
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
          const SizedBox(height: 12),
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
