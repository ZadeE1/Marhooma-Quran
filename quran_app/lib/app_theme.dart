import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF3AB56B); // central brand colour

  /// Common spacing constants for padding/margins throughout the app.
  static const double spaceXs = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXl = 32;

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(seedColor: _seedColor);
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);

  static final ThemeData lightTheme = ThemeData(colorScheme: _lightColorScheme, useMaterial3: true, textTheme: TextTheme(headlineLarge: GoogleFonts.lato(fontSize: 24.0, fontWeight: FontWeight.bold), titleMedium: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.w600), bodyLarge: GoogleFonts.amiri(fontSize: 24.0), bodyMedium: GoogleFonts.amiri(fontSize: 18.0), labelLarge: GoogleFonts.lato(fontSize: 14.0, fontWeight: FontWeight.w600)));

  static final ThemeData darkTheme = ThemeData(colorScheme: _darkColorScheme, useMaterial3: true, brightness: Brightness.dark, textTheme: TextTheme(headlineLarge: GoogleFonts.lato(fontSize: 24.0, fontWeight: FontWeight.bold), titleMedium: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.w600), bodyLarge: GoogleFonts.amiri(fontSize: 24.0), bodyMedium: GoogleFonts.amiri(fontSize: 18.0), labelLarge: GoogleFonts.lato(fontSize: 14.0, fontWeight: FontWeight.w600)));
}
