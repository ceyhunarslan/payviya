import 'package:flutter/material.dart';

class AppTheme {
  // App color palette - Updated for better UX
  static const Color primaryColor = Color(0xFF2C7CFF); // Main brand color
  static const Color secondaryColor = Color(0xFF2563EB); // Secondary brand color
  static const Color accentColor = Color(0xFFFF5757); // Accent for highlights
  static const Color backgroundColor = Colors.white; // Changed to white as required
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF333333); // Dark text for good contrast
  static const Color textSecondaryColor = Color(0xFF666666); // Medium gray for secondary text
  static const Color dividerColor = Color(0xFFF2F2F2); // Lighter divider color
  static const Color successColor = Color(0xFF4BB543);
  static const Color warningColor = Color(0xFFFFD166);
  static const Color errorColor = Color(0xFFE63946);
  
  // New color additions for enhanced UI
  static const Color lightBlue = Color(0xFFEEF6FF); // Lighter blue for backgrounds
  static const Color mediumBlue = Color(0xFF64B5F6);
  static const Color greenSuccess = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFF1F8E9); // Lighter green for backgrounds
  static const Color chartLine = Color(0xFFEEEEEE);

  // Chart-specific colors for improved visualization
  static const Color chartPrimary = Color(0xFF3A86FF);
  static const Color chartSecondary = Color(0xFF64B5F6);
  static const Color chartBackground = Color(0xFFFAFAFA);
  static const Color chartAxisLine = Color(0xFFEEEEEE);
  static const Color chartLabelColor = Color(0xFF666666);
  
  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimaryColor = Color(0xFFF5F5F5);
  static const Color darkTextSecondaryColor = Color(0xFFBBBBBB);
  static const Color darkDividerColor = Color(0xFF2C2C2C);

  // Font families with fallbacks to ensure text always displays
  static const String primaryFontFamily = 'Roboto';
  
  // Text styles with fallback fonts
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    fontFamily: primaryFontFamily,
  );

  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    fontFamily: primaryFontFamily,
  );

  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
    fontFamily: primaryFontFamily,
  );

  static TextStyle get smallStyle => const TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
    fontFamily: primaryFontFamily,
  );

  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
    fontFamily: primaryFontFamily,
  );

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.4),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    minimumSize: const Size(double.infinity, 56),
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Card styles with improved shadows
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );

  // Light theme
  static ThemeData get lightTheme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: cardColor,
    ),
    scaffoldBackgroundColor: backgroundColor, // Ensures white background
    fontFamily: 'Roboto', // Simple font family name without any commas or fallbacks
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white, // White app bar
      foregroundColor: textPrimaryColor, // Dark text for contrast
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryColor), // Icons in primary color
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      displayMedium: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      displaySmall: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      headlineMedium: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      headlineSmall: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      titleLarge: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      titleMedium: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      titleSmall: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      bodyLarge: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      bodyMedium: TextStyle(color: textPrimaryColor, fontFamily: primaryFontFamily),
      bodySmall: TextStyle(color: textSecondaryColor, fontFamily: primaryFontFamily),
      labelLarge: TextStyle(color: Colors.white, fontFamily: primaryFontFamily),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: secondaryButtonStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: const TextStyle(color: textPrimaryColor),
      labelStyle: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      suffixStyle: const TextStyle(color: textPrimaryColor),
      prefixStyle: const TextStyle(color: textPrimaryColor),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.white, // White cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
  );

  // Dark theme
  static ThemeData get darkTheme => ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBackgroundColor,
      surface: darkCardColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    fontFamily: 'Roboto', // Simple font family name without any commas or fallbacks
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: darkCardColor,
      foregroundColor: darkTextPrimaryColor,
      centerTitle: true,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      displayMedium: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      displaySmall: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      headlineMedium: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      headlineSmall: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      titleLarge: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      titleMedium: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      titleSmall: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      bodyLarge: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      bodyMedium: TextStyle(color: darkTextPrimaryColor, fontFamily: primaryFontFamily),
      bodySmall: TextStyle(color: darkTextSecondaryColor, fontFamily: primaryFontFamily),
      labelLarge: TextStyle(color: Colors.white, fontFamily: primaryFontFamily),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: const TextStyle(color: darkTextPrimaryColor),
      labelStyle: const TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      suffixStyle: const TextStyle(color: darkTextPrimaryColor),
      prefixStyle: const TextStyle(color: darkTextPrimaryColor),
    ),
    dividerTheme: const DividerThemeData(
      color: darkDividerColor,
      thickness: 1,
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
} 