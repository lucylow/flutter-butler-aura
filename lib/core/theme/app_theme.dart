import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aura_colors.dart';

class AppTheme {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 999.0;

  static final _baseTextTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
    displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: 0),
    displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 0),
    headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0),
    headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0),
    headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
    titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0),
    titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
    bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25),
    bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.4),
    labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  );

  /// Dark theme for Landing (slate bg, teal/coral accents).
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuraColors.darkSlate,
        colorScheme: const ColorScheme.dark(
          primary: AuraColors.teal,
          secondary: AuraColors.coral,
          tertiary: AuraColors.tealLight,
          surface: AuraColors.darkSlateBg,
          surfaceContainerHighest: AuraColors.surfaceDark,
          error: Color(0xFFEF4444),
          onPrimary: AuraColors.textOnTeal,
          onSecondary: AuraColors.textOnDark,
          onSurface: AuraColors.textOnDark,
          onError: AuraColors.textOnDark,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: _baseTextTheme.apply(
          bodyColor: AuraColors.textOnDark,
          displayColor: AuraColors.textOnDark,
        ),
        cardTheme: CardThemeData(
          color: AuraColors.darkSlateBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
          elevation: 0,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textOnDark),
          iconTheme: const IconThemeData(color: AuraColors.textOnDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraColors.teal,
            foregroundColor: AuraColors.textOnTeal,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AuraColors.surfaceDark,
          contentTextStyle: GoogleFonts.inter(color: AuraColors.textOnDark, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          behavior: SnackBarBehavior.floating,
        ),
      );

  /// Light theme for Dashboard, Chat, Devices (light grey bg, white cards, teal/coral).
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AuraColors.lightGrey,
        colorScheme: const ColorScheme.light(
          primary: AuraColors.teal,
          secondary: AuraColors.coral,
          tertiary: AuraColors.tealLight,
          surface: AuraColors.surfaceLight,
          surfaceContainerHighest: AuraColors.lightGreyCard,
          error: Color(0xFFEF4444),
          onPrimary: AuraColors.textOnTeal,
          onSecondary: AuraColors.textOnDark,
          onSurface: AuraColors.textDark,
          onError: AuraColors.textOnDark,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: _baseTextTheme.apply(
          bodyColor: AuraColors.textDark,
          displayColor: AuraColors.textDark,
        ),
        cardTheme: CardThemeData(
          color: AuraColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
          elevation: 2,
          shadowColor: Colors.black26,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AuraColors.surfaceLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AuraColors.textDark),
          iconTheme: const IconThemeData(color: AuraColors.textDark),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide(color: AuraColors.textLight.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide(color: AuraColors.textLight.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: AuraColors.teal, width: 2),
          ),
          labelStyle: const TextStyle(color: AuraColors.textLight),
          hintStyle: TextStyle(color: AuraColors.textLight.withValues(alpha: 0.7)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraColors.teal,
            foregroundColor: AuraColors.textOnTeal,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AuraColors.textDark,
          contentTextStyle: GoogleFonts.inter(color: AuraColors.textOnDark, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
