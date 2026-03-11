import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color lightPurple = Color(0xFFD0BCFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: const Color(0xFFF5F5F5),
      disabledColor: const Color(0xFF666666),
      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF5F5F5),
        onPrimary: Colors.black,
        secondary: lightPurple,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Color(0xFFF5F5F5),
        error: Color(0xFFF2B8B5),
      ),
      
      // Text Theme
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
          bodyMedium: TextStyle(color: Color(0xFFF5F5F5)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
        ),
      ),

      // Card Theme (Rounded Corners)
      cardTheme: CardThemeData(
        color: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),

      // Button Theme (Rounded Corners, White Outlines)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF5F5F5),
          side: const BorderSide(color: Color(0xFFF5F5F5), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input Theme (2px White Outlines, Rounded)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF5F5F5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF5F5F5), width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFF5F5F5)),
        hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),

      // TabBar Theme
      tabBarTheme: const TabBarThemeData(
        indicatorColor: Color(0xFFF5F5F5),
        labelColor: Color(0xFFF5F5F5),
        unselectedLabelColor: Color(0xFF666666),
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: lightPurple,
        inactiveTrackColor: lightPurple.withValues(alpha: 0.24),
        thumbColor: lightPurple,
        overlayColor: lightPurple.withValues(alpha: 0.16),
        valueIndicatorColor: lightPurple,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
    );
  }
}
