import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6750A4);
  static const secondaryColor = Color(0xFF958DA5);
  static const errorColor = Color(0xFFBA1A1A);
  static const surfaceColor = Color(0xFFFFFBFF);
  static const backgroundColor = Color(0xFFF6F6F9);
  
  static ThemeData lightTheme = _createTheme(Brightness.light);
  static ThemeData darkTheme = _createTheme(Brightness.dark);
  
  static ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isLight ? null : ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}