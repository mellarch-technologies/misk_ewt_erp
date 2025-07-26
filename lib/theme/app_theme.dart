import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MiskTheme {
  // MISK Brand Colors - Authentic Islamic Design Palette
  static const Color miskGold = Color(0xFFDAA520);        // Primary: Luxury, wisdom
  static const Color miskDarkGreen = Color(0xFF2F5233);   // Secondary: Islamic tradition
  static const Color miskLightGreen = Color(0xFF4A7C59);  // Tertiary: Harmony
  static const Color miskCream = Color(0xFFFDF6E3);       // Background: Purity
  static const Color miskTextDark = Color(0xFF2C2C2C);    // Text: Professional readability
  static const Color miskWhite = Color(0xFFFFFFFF);       // Pure white
  static const Color miskErrorRed = Color(0xFFD32F2F);    // Error states

  // Gradient Colors for Enhanced UI
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFDAA520), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2F5233), Color(0xFF4A7C59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creamGradient = LinearGradient(
    colors: [Color(0xFFFDF6E3), Color(0xFFF4F1E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glass Morphism Effects
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.1;

  // Border Radius Constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  // Elevation Constants
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Spacing Constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: miskGold,
        primary: miskGold,
        secondary: miskDarkGreen,
        tertiary: miskLightGreen,
        surface: miskWhite,
        background: miskCream,
        error: miskErrorRed,
        brightness: Brightness.light,
        onPrimary: miskWhite,
        onSecondary: miskWhite,
        onSurface: miskTextDark,
        onBackground: miskTextDark,
      ),

      scaffoldBackgroundColor: miskCream,

      // Typography - Using Google Fonts instead of custom font
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: miskDarkGreen,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: miskDarkGreen,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: miskDarkGreen,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: miskTextDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: miskTextDark,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: miskTextDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: miskTextDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: miskTextDark,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: miskTextDark.withOpacity(0.7),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: miskWhite,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: miskDarkGreen,
        foregroundColor: miskWhite,
        elevation: elevationMedium,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: miskWhite,
        ),
        iconTheme: const IconThemeData(
          color: miskWhite,
          size: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(borderRadiusMedium),
          ),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: miskWhite,
        elevation: elevationMedium,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusLarge),
          ),
        ),
        margin: EdgeInsets.all(spacingSmall),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: miskGold,
          foregroundColor: miskWhite,
          elevation: elevationMedium,
          padding: const EdgeInsets.symmetric(
            vertical: spacingMedium,
            horizontal: spacingXLarge,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadiusMedium),
            ),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: miskGold,
          padding: const EdgeInsets.symmetric(
            vertical: spacingMedium,
            horizontal: spacingLarge,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadiusMedium),
            ),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: miskDarkGreen,
          side: const BorderSide(color: miskDarkGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(
            vertical: spacingMedium,
            horizontal: spacingLarge,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadiusMedium),
            ),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: miskWhite,
        contentPadding: const EdgeInsets.symmetric(
          vertical: spacingMedium,
          horizontal: spacingLarge,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusMedium),
          ),
          borderSide: BorderSide(color: miskLightGreen, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusMedium),
          ),
          borderSide: BorderSide(color: miskLightGreen, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusMedium),
          ),
          borderSide: BorderSide(color: miskGold, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusMedium),
          ),
          borderSide: BorderSide(color: miskErrorRed, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadiusMedium),
          ),
          borderSide: BorderSide(color: miskErrorRed, width: 2.0),
        ),
        labelStyle: GoogleFonts.poppins(
          color: miskTextDark,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        hintStyle: GoogleFonts.poppins(
          color: miskTextDark.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIconColor: miskDarkGreen,
        suffixIconColor: miskDarkGreen,
      ),

      // Additional theme components
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return miskGold;
          return miskWhite;
        }),
        checkColor: WidgetStateProperty.all(miskWhite),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: miskGold,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: miskDarkGreen,
        contentTextStyle: GoogleFonts.poppins(color: miskWhite),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
      ),
    );
  }
}
