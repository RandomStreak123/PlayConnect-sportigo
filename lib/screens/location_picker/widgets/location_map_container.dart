import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../core/constants/api_constants.dart';

class UnifiedMapController {
  osm.MapController? osmController;
  gmaps.GoogleMapController? googleController;

  void move(double lat, double lng, double zoom) {
    if (osmController != null) {
      osmController!.move(osm_latlong.LatLng(lat, lng), zoom);
    }
    if (googleController != null) {
      googleController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), zoom),
      );
    }
  }

  void dispose() {
    osmController?.dispose();
    googleController?.dispose();
  }
}

class LocationMapContainer extends StatefulWidget {
  final UnifiedMapController mapController;
  final double initialLatitude;
  final double initialLongitude;
  final Function(double lat, double lng, bool hasGesture) onPositionChanged;
  final Function(double lat, double lng) onTap;

  const LocationMapContainer({
    super.key,
    required this.mapController,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onPositionChanged,
    required this.onTap,
  });

  @override
  State<LocationMapContainer> createState() => _LocationMapContainerState();
}

class _LocationMapContainerState extends State<LocationMapContainer> {
  // Keep track of center for callbacks where Google Map doesn't provide hasGesture directly in onCameraMove
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude;
    _currentLng = widget.initialLongitude;
    if (!ApiConstants.isGoogleMapsConfigured) {
      widget.mapController.osmController = osm.MapController();
    }
  }

  @override
  void dispose() {
    // Controller disposal is handled by the screen.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ApiConstants.isGoogleMapsConfigured) {
      return gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(widget.initialLatitude, widget.initialLongitude),
          zoom: 15.0,
        ),
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          widget.mapController.googleController = controller;
        },
        onCameraMoveStarted: () {
          _isMoving = true;
        },
        onCameraMove: (position) {
          _currentLat = position.target.latitude;
          _currentLng = position.target.longitude;
        },
        onCameraIdle: () {
          if (_isMoving) {
            _isMoving = false;
            widget.onPositionChanged(_currentLat, _currentLng, true);
          }
        },
        onTap: (latLng) {
          widget.onTap(latLng.latitude, latLng.longitude);
        },
      );
    } else {
      return osm.FlutterMap(
        mapController: widget.mapController.osmController,
        options: osm.MapOptions(
          initialCenter: osm_latlong.LatLng(widget.initialLatitude, widget.initialLongitude),
          initialZoom: 15.0,
          maxZoom: 18.0,
          minZoom: 3.0,
          onPositionChanged: (camera, hasGesture) {
            widget.onPositionChanged(
              camera.center.latitude,
              camera.center.longitude,
              hasGesture,
            );
          },
          onTap: (tapPosition, point) {
            widget.onTap(point.latitude, point.longitude);
          },
        ),
        children: [
          osm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sportigo',
          ),
        ],
      );
    }
  }
}
