import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF1C1C1E);
  static const surfaceVariant = Color(0xFF3A3A3D);
  static const primary = Color(0xFFB0C4DE);
  static const buttonBackground = Color(0xFFEBEBF5);
  static const buttonText = Colors.black;
  static const text = Color(0xFFE0E0E0);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFFDCE4F2),
        onPrimaryContainer: Color(0xFF001E3A),
        secondary: Color(0xFF535F70),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD7E3F8),
        onSecondaryContainer: Color(0xFF101C2B),
        tertiary: Color(0xFF6B5778),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFF2DAFF),
        onTertiaryContainer: Color(0xFF251431),
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: surface,
        onSurface: text,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: Color(0xFFC1C1C1),
        outline: Color(0xFF8B8B8F),
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
