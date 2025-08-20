import 'package:flutter/material.dart';

class AppTheme {
  // MISK Educational & Welfare Trust Brand Colors
  // Based on Islamic values and professional standards
  static const Color primaryGreen = Color(0xFF2E7D4A);    // Islamic green
  static const Color accentGold = Color(0xFFD4AF37);      // Gold accent
  static const Color darkBlue = Color(0xFF1A365D);        // Deep trust blue
  static const Color lightBackground = Color(0xFFF7FAFC); // Clean background
  static const Color whiteBackground = Color(0xFFFFFFFF); // Pure white
  static const Color textDark = Color(0xFF2D3748);        // Dark text
  static const Color textMedium = Color(0xFF4A5568);      // Medium text
  static const Color errorRed = Color(0xFFE53E3E);        // Error state
  static const Color successGreen = Color(0xFF38A169);    // Success state
  static const Color warningOrange = Color(0xFFDD6B20);   // Warning state

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBackground,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        error: errorRed,
        surface: whiteBackground,
        background: lightBackground,
        brightness: Brightness.light,
      ),

      // App Bar Theme - Professional header
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),

      // Elevated Button Theme - MISK branded buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - Form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: whiteBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: TextStyle(color: textMedium, fontSize: 16),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIconColor: primaryGreen,
        suffixIconColor: primaryGreen,
      ),

      // Card Theme - Professional cards
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        color: whiteBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: primaryGreen,
        textColor: textDark,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: whiteBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: textMedium,
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text Theme - Typography hierarchy
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 24),
        headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 22),
        headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        headlineSmall: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textMedium, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: textMedium, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(color: textMedium, fontSize: 14, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: textMedium, fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: primaryGreen,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentGold;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: Colors.grey.shade300,
        circularTrackColor: Colors.grey.shade300,
      ),
    );
  }

  // Custom color extensions for MISK specific use cases
  static const Color donationGreen = Color(0xFF38A169);
  static const Color eventBlue = Color(0xFF3182CE);
  static const Color memberPurple = Color(0xFF805AD5);
  static const Color financeOrange = Color(0xFFED8936);

  // Helper methods for common styling
  static BoxDecoration cardDecoration({double borderRadius = 16}) {
    return BoxDecoration(
      color: whiteBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration({
    Color startColor = primaryGreen,
    Color endColor = darkBlue,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      ),
    );
  }
}
