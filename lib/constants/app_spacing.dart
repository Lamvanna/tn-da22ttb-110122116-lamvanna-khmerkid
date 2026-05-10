import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Design tokens — Spacing & Radius chuẩn cho toàn app KhmerKid
/// Sử dụng hệ 4px base với ScreenUtil responsive
class AppSpacing {
  AppSpacing._();

  // ─── Spacing Scale ─────────────────────────────────────────────
  static double get xs   => 4.w;
  static double get sm   => 8.w;
  static double get md   => 12.w;
  static double get lg   => 16.w;
  static double get xl   => 24.w;
  static double get xxl  => 32.w;
  static double get xxxl => 48.w;

  // ─── Border Radius ─────────────────────────────────────────────
  static double get radiusSm   => 12.r;
  static double get radiusMd   => 16.r;
  static double get radiusLg   => 20.r;
  static double get radiusXl   => 24.r;
  static double get radiusXxl  => 28.r;
  static double get radiusFull => 50.r;
}
