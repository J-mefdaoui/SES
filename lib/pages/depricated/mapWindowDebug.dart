import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWindowDebug extends StatelessWidget {
  const MapWindowDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(36.5011, 8.7802),
          initialZoom: 12,
          maxZoom: 18,
          minZoom: 6,
        ),
        children: [
          // Base map (light tiles for contrast)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.neglectmap.debug',
          ),
          // Heatmap overlay
          TileLayer(
            urlTemplate:
                'https://eau-purchases-sen-priest.trycloudflare.com/heatmap/{z}/{x}/{y}.png',
            tileProvider: NetworkTileProvider(),
          ),
        ],
      ),
    );
  }
}
