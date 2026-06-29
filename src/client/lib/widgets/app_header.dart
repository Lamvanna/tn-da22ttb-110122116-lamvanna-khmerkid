import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header thống nhất cho toàn bộ app KhmerKid — RESPONSIVE
/// Dùng cho mọi screen: học, chơi, cài đặt, ...
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final List<Color>? gradientColors;
  final double? bottomPadding;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.trailing,
    this.gradientColors,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [
      Color(0xFF1565C0),
      Color(0xFF42A5F5),
      Color(0xFF29B6F6),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(0.5, 1),
          colors: colors),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: colors.first.withValues(alpha: 0.35),
          blurRadius: 24.r, offset: Offset(0, 8.h))],
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -40.w, top: -30.h,
          child: Container(width: 120.w, height: 120.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25.w, bottom: -20.h,
          child: Container(width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, bottomPadding ?? 40.h),
            child: Row(children: [
              // Back button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10))),
                    child: Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18.sp)),
                  ),
                ),
              SizedBox(width: 14.w),
              // Title + subtitle
              Expanded(child: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22.sp, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      SizedBox(height: 2.h),
                      Text(subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp, fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75))),
                    ])
                : Text(title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22.sp, fontWeight: FontWeight.w800,
                      color: Colors.white))),
              // Reserve space for trailing stats
              if (trailing != null) SizedBox(width: 65.w),
            ]),
          ),
        ),
        // Stats positioned at top right of the header, exactly like LearnScreen
        if (trailing != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 2.h,
            right: 16.w,
            child: trailing!,
          ),
      ]),
    );
  }
}
