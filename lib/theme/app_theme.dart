import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Theme chính - Design System: "Playful & Educational Adventure"
/// Font: Plus Jakarta Sans · No pure black · Warm tonal layering
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.surface,
        error: AppColors.accentRed,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textWhite,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: AppColors.onBackground, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.onBackground),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.onBackground),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.onBackground),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textWhite),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.onBackground),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
