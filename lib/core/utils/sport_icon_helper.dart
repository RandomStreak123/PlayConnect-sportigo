import 'package:flutter/material.dart';

class SportIconHelper {
  static final Map<String, String> _sportIconAssetPaths = {
    'football': 'assets/images/football_icon.png',
    'basketball': 'assets/images/basketball_icon.png',
    'badminton': 'assets/images/badminton_icon.png',
    'tennis': 'assets/images/tennis_icon.png',
    'padel': 'assets/images/padel_icon.png',
    'pedal': 'assets/images/padel_icon.png',
    'cricket': 'assets/images/cricket_icon.png',
  };

  static IconData iconForSport(String sportType) {
    switch (sportType.toLowerCase().trim()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'padel':
      case 'pedal':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis;
      case 'cricket':
        return Icons.sports_baseball;
      default:
        return Icons.sports;
    }
  }

  static Widget widgetForSport(String sportType, {double size = 24, Color? color}) {
    final lowerSport = sportType.toLowerCase().trim();
    final assetPath = _sportIconAssetPaths[lowerSport];
    if (assetPath == null) {
      return Icon(
        iconForSport(sportType),
        size: size,
        color: color,
      );
    }
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          iconForSport(sportType),
          size: size,
          color: color,
        );
      },
    );
  }
}
