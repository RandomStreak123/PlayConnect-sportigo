import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { system, activeSteelBlue, elegantLavender }

class ThemeManager extends ChangeNotifier {
  static const String _keyThemePref = 'theme_preference_choice';

  ThemePreference _preference = ThemePreference.system;
  String? _userGender;
  String? _lastKnownGender;

  ThemeManager() {
    _loadThemeSettings();
  }

  ThemePreference get preference => _preference;
  String? get userGender => _userGender;

  /// True when the app should use the lavender/pink palette (MaterialApp theme).
  /// - [elegantLavender]: always on
  /// - [activeSteelBlue]: always off
  /// - [system]: on for female users only (default gender-based)
  bool get isWomenMode {
    if (_preference == ThemePreference.elegantLavender) return true;
    if (_preference == ThemePreference.activeSteelBlue) return false;
    return _userGender == 'female';
  }

  static String _prefToKey(ThemePreference pref) {
    return switch (pref) {
      ThemePreference.system => 'system',
      ThemePreference.activeSteelBlue => 'steel',
      ThemePreference.elegantLavender => 'lavender',
    };
  }

  static ThemePreference _keyToPref(String key) {
    return switch (key) {
      'lavender' => ThemePreference.elegantLavender,
      'steel' => ThemePreference.activeSteelBlue,
      _ => ThemePreference.system,
    };
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final prefStr = prefs.getString(_keyThemePref);
    if (prefStr != null) {
      if (prefStr.contains('.')) {
        // Migrate legacy enum.toString() values
        _preference = ThemePreference.values.firstWhere(
          (e) => e.toString() == prefStr,
          orElse: () => ThemePreference.system,
        );
        await prefs.setString(_keyThemePref, _prefToKey(_preference));
      } else {
        _preference = _keyToPref(prefStr);
      }
    }
    notifyListeners();
  }

  void updateGender(String? gender) {
    if (_userGender != gender) {
      _userGender = gender;
      if (gender != null &&
          _lastKnownGender != null &&
          _lastKnownGender != gender) {
        _preference = ThemePreference.system;
        _clearSavedPreference();
      }
      if (gender != null) {
        _lastKnownGender = gender;
      }
      notifyListeners();
    }
  }

  Future<void> setThemePreference(ThemePreference pref) async {
    _preference = pref;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemePref, _prefToKey(pref));
    notifyListeners();
  }

  Future<void> _clearSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyThemePref);
  }
}
