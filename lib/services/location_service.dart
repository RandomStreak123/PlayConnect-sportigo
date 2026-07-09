import 'package:geolocator/geolocator.dart';
import '../data/models/match_model.dart';

class LocationService {
  Position? _lastUserPosition;

  Position? get lastUserPosition => _lastUserPosition;

  Future<Position?> getUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 1),
        forceAndroidLocationManager: true,
      );
      _lastUserPosition = position;
      return position;
    } catch (_) {
      return _lastUserPosition;
    }
  }

  List<MatchModel> applyDistances(List<MatchModel> matches, Position? position) {
    if (position == null) return matches;
    final double userLat = position.latitude;
    final double userLng = position.longitude;

    return matches.map((match) {
      if (match.latitude != null && match.longitude != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLng,
          match.latitude!,
          match.longitude!,
        );
        return match.copyWith(distance: distanceInMeters / 1000.0);
      }
      return match;
    }).toList();
  }
}
