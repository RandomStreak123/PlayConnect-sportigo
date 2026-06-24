import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileThemeHelper {
  static const String themeKey = 'profile_theme_key';

  static const Map<String, List<Color>> premiumGradients = {
    'Default': [],
    'Lavender Dusk': [
      Color(0xFF2E0854),
      Color(0xFF8A2BE2),
      Color(0xFFE6E6FA),
    ],
    'Gold Rush': [
      Color(0xFF3A2D00),
      Color(0xFF8A7300),
      Color(0xFFD4AF37),
    ],
    'Golden Legend': [
      Color(0xFF8B6C05),
      Color(0xFFD4AF37),
      Color(0xFFFFDF73),
    ],
  };

  static Future<String> loadSelectedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(themeKey) ?? 'Default';
    } catch (_) {
      return 'Default';
    }
  }

  static Future<void> saveSelectedTheme(String themeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeKey, themeName);
    } catch (_) {}
  }

  static List<Color> getGradient(String themeName) {
    return premiumGradients[themeName] ?? [];
  }
}
