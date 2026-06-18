import 'package:flutter/material.dart';

class SportIconHelper {
  static final Map<String, String> _sportIconUrls = {
    'football': 'https://cdn-icons-png.flaticon.com/128/1165/1165187.png',
    'basketball': 'https://cdn-icons-png.flaticon.com/128/1041/1041168.png',
    'badminton': 'https://cdn-icons-png.flaticon.com/128/11865/11865449.png',
    'tennis': 'https://cdn-icons-png.flaticon.com/128/7430/7430195.png',
    'padel': 'https://cdn-icons-png.flaticon.com/128/19030/19030325.png',
    'pedal': 'https://cdn-icons-png.flaticon.com/128/19030/19030325.png',
    'cricket': 'https://cdn-icons-png.flaticon.com/128/2160/2160064.png',
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

  static Widget widgetForSport(String sportType, {double size = 24}) {
    final lowerSport = sportType.toLowerCase().trim();
    final url = _sportIconUrls[lowerSport];
    return Image.network(
      url ?? '',
      width: size,
      height: size,
    );
  }
}
