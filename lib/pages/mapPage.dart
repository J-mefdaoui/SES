import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class offlineMap extends StatefulWidget {
  const offlineMap({super.key});

  @override
  State<offlineMap> createState() => _offlineMapState();
}

class _offlineMapState extends State<offlineMap> {
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
  Widget build(BuildContext context) {
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
