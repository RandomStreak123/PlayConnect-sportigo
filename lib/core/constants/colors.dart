import 'package:flutter/material.dart';

// Custom/brand colors that don't change with theme mode.
// For standard colors (primary, surface, etc.), use Theme.of(context).colorScheme.
class AppColors {
  static const Color deepBlue = Color(0xFF1A237E);
  static const Color sportsGreen = Color(0xFF2E7D32);
  static const Color softWhite = Color(0xFFF8F9FA);
  static const Color charcoalBlack = Color(0xFF121212);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color warmOrange = Color(0xFFFF9100);
  static const Color womenOnlyPink = Color(0xFFFF4D8D);
  static const Color lockPurple = Color(0xFF7B61FF);

  static final Gradient womenOnlyGradient = LinearGradient(
    colors: [
      womenOnlyPink.withValues(alpha: 0.1),
      lockPurple.withValues(alpha: 0.05),
    ],
  );
}
