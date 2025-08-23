import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design System Tokens (as recommended by Perplexity review)
class DesignTokens {
  // Spacing Grid (8dp system)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Typography Scale
  static const double titleLarge = 18.0;
  static const double titleMedium = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;

  // Font Weights
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Chip Standards (28dp height as recommended)
  static const double chipHeight = 28.0;
  static const double chipPadding = 12.0;
  static const double chipRadius = 16.0;

  // Progress Bar Standards
  static const double progressBarHeight = 8.0;
  static const double progressBarRadius = 6.0;

  // Touch Targets (minimum 44dp for accessibility)
  static const double minTouchTarget = 44.0;
}

// Semantic Colors (WCAG AA compliant)
class SemanticColors {
  static const Color primaryGreen = Color(0xFF2E5E37);
  static const Color accentGold = Color(0xFFDAA520);
  static const Color infoBlue = Color(0xFF3F6FE0);
  static const Color successGreen = Color(0xFF2FB36E);
  static const Color warningGold = Color(0xFFF2B538);
  static const Color dangerRed = Color(0xFFD64545);
  static const Color neutralGray = Color(0xFFECEEF2);
}

class MiskTheme {
// MISK Brand Colors - Authentic Islamic Design Palette
  static const Color miskGold = Color(0xFFDAA520); // Primary: Luxury, wisdom
  static const Color miskDarkGreen = Color(0xFF2F5233); // Secondary: Islamic tradition
  static const Color miskLightGreen = Color(0xFF4A7C59); // Tertiary: Harmony
  static const Color miskCream = Color(0xFFFDF6E3); // Background: Purity
  static const Color miskTextDark = Color(0xFF2C2C2C); // Text: Professional readability
  static const Color miskWhite = Color(0xFFFFFFFF); // Pure white
  static const Color miskErrorRed = Color(0xFFD32F2F); // Error states
  static const Color memberPurple = Color(0xFF7C4DFF); // Members
  static const Color eventBlue = Color(0xFF3F6FE0); // Events
  static const Color donationGreen = Color(0xFF2FB36E); // Donations
  static const Color warningOrange = Color(0xFFF2B538); // Tasks/Warnings
  static const Color primaryGreen = Color(0xFF2E5E37); // Primary
  static const Color accentGold = Color(0xFFDAA520); // Accent
  static const Color financeOrange = Color(0xFFFFA726); // Finance
  static const Color darkBlue = Color(0xFF283593); // Projects
  static const Color successGreen = Color(0xFF2FB36E); // Reports/Success
  static const Color textMedium = Color(0xFF757575); // Settings/Text

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
        // background and onBackground deprecated; rely on surface/onSurface + scaffoldBackgroundColor
        error: miskErrorRed,
        brightness: Brightness.light,
        onPrimary: miskWhite,
        onSecondary: miskWhite,
        onSurface: miskTextDark,
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
          color: miskTextDark.withValues(alpha: 0.7),
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
          side: BorderSide(color: Color(0xFFE6E6E6)),
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
          color: miskTextDark.withValues(alpha: 0.6),
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
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: miskTextDark,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        selectedColor: miskGold.withValues(alpha: 0.15),
        backgroundColor: miskWhite,
        shape: const StadiumBorder(),
        iconTheme: const IconThemeData(
          size: 16,
          color: miskDarkGreen,
        ),
      ),
    );
  }
}
