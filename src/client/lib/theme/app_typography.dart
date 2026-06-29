import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// ════════════════════════════════════════════════════════════════════
///  KHMERKID TYPOGRAPHY — 2026
/// ────────────────────────────────────────────────────────────────────
///  Type scale: Major Third (1.25 ratio)
///  Latin/Vietnamese: Plus Jakarta Sans
///  Khmer: Battambang (lớn hơn 20% để legible cho dấu phụ)
///
///  Quy tắc:
///    1. CHỈ dùng 4 weights: 400 / 500 / 600 / 700
///    2. Mọi style PHẢI có `height` (line-height) — fix Khmer clip
///    3. Tracking (letter-spacing) chỉ âm cho heading lớn
///    4. Dùng .sp để tôn trọng Dynamic Type, nhưng KHÔNG cho hero text
/// ════════════════════════════════════════════════════════════════════
class KkType {
  KkType._();

  // ─── DISPLAY (chỉ cho onboarding / hero screen) ────────────────────
  static TextStyle get display => _jakarta(
    size: 44, weight: FontWeight.w700,
    height: 1.1, tracking: -0.02);

  // ─── HEADING ───────────────────────────────────────────────────────
  static TextStyle get h1 => _jakarta(
    size: 32, weight: FontWeight.w700,
    height: 1.2, tracking: -0.01);

  static TextStyle get h2 => _jakarta(
    size: 26, weight: FontWeight.w700,
    height: 1.25, tracking: -0.005);

  static TextStyle get h3 => _jakarta(
    size: 20, weight: FontWeight.w600,
    height: 1.3);

  static TextStyle get h4 => _jakarta(
    size: 18, weight: FontWeight.w600,
    height: 1.35);

  // ─── BODY ──────────────────────────────────────────────────────────
  static TextStyle get bodyL => _jakarta(
    size: 17, weight: FontWeight.w500,
    height: 1.5);

  /// Body default ⭐
  static TextStyle get bodyM => _jakarta(
    size: 15, weight: FontWeight.w400,
    height: 1.5);

  static TextStyle get bodyS => _jakarta(
    size: 13, weight: FontWeight.w400,
    height: 1.45);

  // ─── LABEL / UI ────────────────────────────────────────────────────
  static TextStyle get labelL => _jakarta(
    size: 15, weight: FontWeight.w600,
    height: 1.3);

  static TextStyle get labelM => _jakarta(
    size: 13, weight: FontWeight.w600,
    height: 1.3);

  /// Label nhỏ — UPPERCASE, có tracking dương
  static TextStyle get labelS => _jakarta(
    size: 11, weight: FontWeight.w700,
    height: 1.2, tracking: 0.04);

  // ─── BUTTON ────────────────────────────────────────────────────────
  static TextStyle get buttonL => _jakarta(
    size: 16, weight: FontWeight.w600,
    height: 1.2, tracking: 0.005);

  static TextStyle get buttonM => _jakarta(
    size: 14, weight: FontWeight.w600,
    height: 1.2, tracking: 0.005);

  static TextStyle get buttonS => _jakarta(
    size: 12, weight: FontWeight.w600,
    height: 1.2, tracking: 0.01);

  // ─── KHMER (lớn hơn 20% để legible) ────────────────────────────────
  static TextStyle get khmerHero => _khmer(
    size: 56, weight: FontWeight.w500,
    height: 1.4);

  static TextStyle get khmerLarge => _khmer(
    size: 40, weight: FontWeight.w500,
    height: 1.4);

  static TextStyle get khmerMedium => _khmer(
    size: 28, weight: FontWeight.w500,
    height: 1.45);

  static TextStyle get khmerBody => _khmer(
    size: 22, weight: FontWeight.w400,
    height: 1.5);

  static TextStyle get khmerSmall => _khmer(
    size: 18, weight: FontWeight.w400,
    height: 1.5);

  // ─── NUMERIC (tabular figures cho stats) ───────────────────────────
  static TextStyle get statL => _jakarta(
    size: 28, weight: FontWeight.w700,
    height: 1.1, tracking: -0.01,
    features: [const FontFeature.tabularFigures()]);

  static TextStyle get statM => _jakarta(
    size: 20, weight: FontWeight.w700,
    height: 1.1,
    features: [const FontFeature.tabularFigures()]);

  static TextStyle get statS => _jakarta(
    size: 16, weight: FontWeight.w700,
    height: 1.2,
    features: [const FontFeature.tabularFigures()]);

  // ────────────────────────────────────────────────────────────────────
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    required double height,
    double? tracking,
    Color? color,
    List<FontFeature>? features,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size.sp,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking == null ? null : tracking * size.sp,
      color: color ?? KkColors.textPrimary,
      fontFeatures: features,
    );
  }

  static TextStyle _khmer({
    required double size,
    required FontWeight weight,
    required double height,
    Color? color,
  }) {
    return GoogleFonts.battambang(
      fontSize: size.sp,
      fontWeight: weight,
      height: height,
      color: color ?? KkColors.textPrimary,
    );
  }
}

/// ─── Convenience extension ────────────────────────────────────────────
/// Cho phép viết: `KkType.h2.onBrand` thay vì `.copyWith(color: ...)`
extension KkTextStyleX on TextStyle {
  TextStyle get onBrand    => copyWith(color: KkColors.textOnBrand);
  TextStyle get onDark     => copyWith(color: KkColors.textOnDark);
  TextStyle get secondary  => copyWith(color: KkColors.textSecondary);
  TextStyle get tertiary   => copyWith(color: KkColors.textTertiary);
  TextStyle get disabled   => copyWith(color: KkColors.textDisabled);
  TextStyle get success    => copyWith(color: KkColors.success);
  TextStyle get danger     => copyWith(color: KkColors.danger);
  TextStyle get warning    => copyWith(color: KkColors.warning);
  TextStyle colored(Color c) => copyWith(color: c);
  TextStyle weight(FontWeight w) => copyWith(fontWeight: w);
}
