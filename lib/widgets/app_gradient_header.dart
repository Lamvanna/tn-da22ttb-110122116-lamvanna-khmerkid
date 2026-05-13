import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Widget header gradient dùng chung cho toàn app
/// Đảm bảo đồng bộ visual giữa tất cả screens
class AppGradientHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final LinearGradient? gradient;

  const AppGradientHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottom,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerDark.withValues(alpha: 0.15),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -15.w, top: -15.h,
            child: Container(
              width: 80.w, height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20.w, bottom: -10.h,
            child: Container(
              width: 60.w, height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottom != null ? 12.h : 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: leading != null ? TextAlign.start : TextAlign.center,
                        ),
                      ),
                      if (trailing != null) ...[
                        SizedBox(width: 12.w),
                        trailing!,
                      ],
                    ],
                  ),
                  if (bottom != null) ...[
                    SizedBox(height: 16.h),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
