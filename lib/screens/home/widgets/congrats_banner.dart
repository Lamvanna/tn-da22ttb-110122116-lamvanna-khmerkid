import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../daily_quest_screen.dart';

/// Banner "Nhiệm vụ hôm nay" — nền trắng, tiến trình
class CongratsBanner extends StatelessWidget {
  final String title;
  final String message;

  const CongratsBanner({
    super.key,
    this.title = 'Nhiệm vụ hôm nay',
    this.message = 'Hoàn thành nhiệm vụ để nhận thưởng',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DailyQuestScreen())),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FF),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16.r, offset: Offset(0, 4.h))],
          border: Border.all(color: const Color(0xFFD6E9FF), width: 1.5)),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 48.w, height: 52.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E9FF),
                borderRadius: BorderRadius.circular(14.r)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.asset('image/Nhiệm vụ.png', fit: BoxFit.cover)),
            ),
            SizedBox(width: 14.w),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  SizedBox(height: 2.h),
                  Text(message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp, fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCE5FF),
                      borderRadius: BorderRadius.circular(12.r)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: const Color(0xFFFFA726), size: 14.sp),
                      SizedBox(width: 4.w),
                      Text('0/5 nhiệm vụ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp, fontWeight: FontWeight.w700,
                          color: AppColors.headerDark)),
                    ]),
                  ),
                ],
              ),
            ),
            // Arrow button
            Container(
              width: 38.w, height: 38.w,
              decoration: BoxDecoration(
                color: AppColors.headerMid.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.headerMid.withValues(alpha: 0.25),
                  blurRadius: 8.r, offset: Offset(0, 3.h))]),
              child: Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 19.sp),
            ),
          ],
        ),
      ),
    );
  }
}
