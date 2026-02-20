import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(
    0xFF8B755C,
  ); // Warm brown - primary brand color
  static const Color secondaryColor = Color(
    0xFFB8A183,
  ); // Muted taupe - secondary accent
  static const Color backgroundColor = Color(
    0xFFE8DCC9,
  ); // Vintage paper background
  static const Color cardColor = Color(0xFFF5F0E8); // Light cream for cards
  static const Color textPrimaryColor = Color(
    0xFF2A1F16,
  ); // Deeper brown for better contrast
  static const Color textSecondaryColor = Color(
    0xFF4A3A2C,
  ); // Darker secondary text

  // Additional states
  static const Color successColor = Color(
    0xFF6B8E6B,
  ); // Muted sage green - correct answers
  static const Color errorColor = Color(
    0xFFB55A5A,
  ); // Dusty rose/terracotta - wrong answers
  static const Color warningColor = Color(
    0xFFC9A87C,
  ); // Warm amber - review later/warning

  // Optional accent colors from the image
  static const Color paperHighlightColor = Color(
    0xFFF5F0E8,
  ); // Lightest paper tone
  static const Color inkDarkColor = Color(
    0xFF3A2E22,
  ); // Darkest ink (same as textPrimary)
  static const Color textureColor = Color(0xFFA58D73); // Speckles/texture tone

  static ThemeData get theme {
    final baseScheme = ColorScheme.fromSeed(seedColor: primaryColor);
    return ThemeData(
      colorScheme: baseScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        onBackground: textPrimaryColor,
        surface: cardColor,
        onSurface: textPrimaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
        indicatorColor: Colors.white,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.18);
          }
          return null;
        }),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return textPrimaryColor;
            }
            return primaryColor;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textSecondaryColor),
        floatingLabelStyle: TextStyle(color: textPrimaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
