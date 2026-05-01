import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hệ thống chữ viết - Typography System
/// Sử dụng Google Fonts: Nunito cho tiếng Việt, Kantumruy Pro cho Khmer
class AppTextStyles {
  AppTextStyles._();

  // ─── Screen Titles (Headers) ──────────────────────────────────────
  static TextStyle screenTitle = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
  );

  static TextStyle screenTitleDark = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // ─── Section Titles ───────────────────────────────────────────────
  static TextStyle sectionTitle = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionTitleWhite = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Card Titles ──────────────────────────────────────────────────
  static TextStyle cardTitle = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle cardTitleWhite = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Body Text ────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Button Text ──────────────────────────────────────────────────
  static TextStyle buttonText = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  static TextStyle buttonTextSmall = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // ─── Stats / Numbers ──────────────────────────────────────────────
  static TextStyle statNumber = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryPurple,
  );

  static TextStyle statLabel = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ─── Khmer Text ───────────────────────────────────────────────────
  static TextStyle khmerLarge = GoogleFonts.kantumruyPro(
    fontSize: 48,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerMedium = GoogleFonts.kantumruyPro(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerSmall = GoogleFonts.kantumruyPro(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerGrid = GoogleFonts.kantumruyPro(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryPurple,
  );

  // ─── Navigation Text ──────────────────────────────────────────────
  static TextStyle navLabel = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.navInactive,
  );

  static TextStyle navLabelActive = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.navActive,
  );

  // ─── Challenge Text ───────────────────────────────────────────────
  static TextStyle challengeTitle = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle challengeReward = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.accentOrange,
  );

  // ─── Badge Text ───────────────────────────────────────────────────
  static TextStyle badge = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Difficulty Badge ─────────────────────────────────────────────
  static TextStyle difficultyBadge = GoogleFonts.nunito(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
}
