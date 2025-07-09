import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF00C851);
  static const Color error = Color(0xFFFF4444);
  static const Color muted = Color(0xFF666666);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        surface: surface,
        background: background,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: primary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: primary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          color: muted,
        ),
      ),
    );
  }
}