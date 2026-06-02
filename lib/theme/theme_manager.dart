import 'package:flutter/material.dart';

enum ThemePreference { system, activeSteelBlue, elegantLavender }

class ThemeManager extends ChangeNotifier {
  ThemePreference _preference = ThemePreference.system;
  String? _userGender;

  ThemeManager();

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

  static ThemePreference _stringToPref(String? key) {
    return switch (key) {
      'elegantLavender' => ThemePreference.elegantLavender,
      'activeSteelBlue' => ThemePreference.activeSteelBlue,
      _ => ThemePreference.system,
    };
  }

  void updateUser(String? gender, String? themePreferenceStr) {
    _userGender = gender;
    _preference = _stringToPref(themePreferenceStr);
    notifyListeners();
  }

  void setThemePreference(ThemePreference pref) {
    _preference = pref;
    notifyListeners();
  }
}
