import 'package:flutter/material.dart';

class SportIconHelper {
  static IconData iconForSport(String sportType) {
    switch (sportType.toLowerCase()) {
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
}
