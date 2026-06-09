import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _textTheme({
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.lexend(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05 * 12,
        color: onSurfaceVariant,
      ),
    );
  }

  static ThemeData themeData(bool isWomenMode) {
    if (isWomenMode) return _womenTheme;
    return _defaultTheme;
  }

  static final ThemeData _defaultTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF000666),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1a237e),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF1b6d24),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFa0f399),
      onSecondaryContainer: Color(0xFF002200),
      tertiary: Color(0xFF000666),
      onTertiary: Colors.white,
      surface: Color(0xFFfbf8ff),
      onSurface: Color(0xFF1b1b21),
      surfaceDim: Color(0xFFdbd9e1),
      surfaceBright: Color(0xFFfbf8ff),
      onSurfaceVariant: Color(0xFF454652),
      outline: Color(0xFF767683),
      outlineVariant: Color(0xFFc6c5d4),
      error: Color(0xFFba1a1a),
      onError: Colors.white,
      errorContainer: Color(0xFFffdad6),
      onErrorContainer: Color(0xFF93000a),
    ),
    scaffoldBackgroundColor: const Color(0xFFfbf8ff),
    textTheme: _textTheme(
      onSurface: const Color(0xFF1b1b21),
      onSurfaceVariant: const Color(0xFF454652),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData _womenTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFFF4D8D),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF06292),
      onPrimaryContainer: Color(0xFF3E0020),
      secondary: Color(0xFF7B61FF),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE1BEE7),
      onSecondaryContainer: Color(0xFF1A0050),
      tertiary: Color(0xFFFF4D8D),
      onTertiary: Colors.white,
      surface: Color(0xFFFFF0F5),
      onSurface: Color(0xFF1b1b21),
      surfaceDim: Color(0xFFE8D4E0),
      surfaceBright: Color(0xFFFFF0F5),
      onSurfaceVariant: Color(0xFF454652),
      outline: Color(0xFF767683),
      outlineVariant: Color(0xFFc6c5d4),
      error: Color(0xFFba1a1a),
      onError: Colors.white,
      errorContainer: Color(0xFFffdad6),
      onErrorContainer: Color(0xFF93000a),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF6F9),
    textTheme: _textTheme(
      onSurface: const Color(0xFF1b1b21),
      onSurfaceVariant: const Color(0xFF454652),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get lightTheme => _defaultTheme;
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
