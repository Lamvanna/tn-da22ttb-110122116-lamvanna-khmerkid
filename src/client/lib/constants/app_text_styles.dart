import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hệ thống chữ viết - Typography System
/// Sử dụng Google Fonts: Plus Jakarta Sans cho tiếng Việt, Kantumruy Pro cho Khmer
class AppTextStyles {
  AppTextStyles._();

  // ─── Screen Titles (Headers) ──────────────────────────────────────
  static TextStyle screenTitle = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
  );

  static TextStyle screenTitleDark = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // ─── Section Titles ───────────────────────────────────────────────
  static TextStyle sectionTitle = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionTitleWhite = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Card Titles ──────────────────────────────────────────────────
  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle cardTitleWhite = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Body Text ────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Button Text ──────────────────────────────────────────────────
  static TextStyle buttonText = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  static TextStyle buttonTextSmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // ─── Stats / Numbers ──────────────────────────────────────────────
  static TextStyle statNumber = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryPurple,
  );

  static TextStyle statLabel = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ─── Khmer Text ───────────────────────────────────────────────────
  static TextStyle khmerLarge = GoogleFonts.battambang(
    fontSize: 48,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerMedium = GoogleFonts.battambang(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerSmall = GoogleFonts.battambang(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle khmerGrid = GoogleFonts.battambang(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryPurple,
  );

  // ─── Navigation Text ──────────────────────────────────────────────
  static TextStyle navLabel = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.navInactive,
  );

  static TextStyle navLabelActive = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.navActive,
  );

  // ─── Challenge Text ───────────────────────────────────────────────
  static TextStyle challengeTitle = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle challengeReward = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.accentOrange,
  );

  // ─── Badge Text ───────────────────────────────────────────────────
  static TextStyle badge = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ─── Difficulty Badge ─────────────────────────────────────────────
  static TextStyle difficultyBadge = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
}
