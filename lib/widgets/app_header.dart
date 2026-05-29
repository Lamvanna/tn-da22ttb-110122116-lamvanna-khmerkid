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

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.trailing,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [Color(0xFF4580C4), Color(0xFF6A9DD6)];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(0.5, 1),
          colors: colors),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r)),
        boxShadow: [BoxShadow(
          color: colors.first.withValues(alpha: 0.18),
          blurRadius: 12.r, offset: Offset(0, 4.h))],
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -30.w, top: -25.h,
          child: Container(width: 100.w, height: 100.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -20.w, bottom: -15.h,
          child: Container(width: 60.w, height: 60.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
            child: Row(children: [
              // Back button — min 44x44 touch target
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10))),
                  child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20.sp)),
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
                          fontSize: 19.sp, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      SizedBox(height: 1.h),
                      Text(subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp, fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75))),
                    ])
                : Text(title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19.sp, fontWeight: FontWeight.w800,
                      color: Colors.white))),
              // Trailing widget
              if (trailing != null) trailing!,
            ]),
          ),
        ),
      ]),
    );
  }
}
