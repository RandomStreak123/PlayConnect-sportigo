import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMapContainer extends StatelessWidget {
  final MapController mapController;
  final LatLng currentCenter;
  final PositionCallback onPositionChanged;
  final TapCallback onTap;

  const LocationMapContainer({
    super.key,
    required this.mapController,
    required this.currentCenter,
    required this.onPositionChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentCenter,
        initialZoom: 15.0,
        maxZoom: 18.0,
        minZoom: 3.0,
        onPositionChanged: onPositionChanged,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sportigo',
        ),
      ],
    );
  }
}
