import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/design_tokens.dart';
import '../daily_quest_screen.dart';
import '../../../widgets/app_page_route.dart';
import '../../../l10n/app_localizations.dart';

/// ════════════════════════════════════════════════════════════════════
///  DailyQuestWidget — Engagement core (2026 redesign)
/// ────────────────────────────────────────────────────────────────────
///  Cải tiến vs CongratsBanner cũ:
///   • Đặt ở vị trí ưu tiên 2 (sau hero) — không phải cuối
///   • Hiển thị progress thực (0/3 quests) thay vì static text
///   • Tap vào → DailyQuestScreen
///   • Touch target full row 64h+ ≥ 48dp
/// ════════════════════════════════════════════════════════════════════
class DailyQuestWidget extends StatelessWidget {
  final int completed;
  final int total;
  final int rewardStars;

  const DailyQuestWidget({
    super.key,
    this.completed = 0,
    this.total = 5,
    this.rewardStars = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          AppPageRoute(page: const DailyQuestScreen()),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF4FF),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFD6E9F8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E9F8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text('📋', style: TextStyle(fontSize: 32.sp)),
                ),
              ),
              SizedBox(width: 14.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('tasks.today_tasks'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.translate('tasks.complete_to_reward'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7F8C8D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    // Progress Chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E9F8),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFFFB300),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            context.translate('tasks.tasks_count', args: {'completed': completed, 'total': total}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              // Arrow Button
              Container(
                width: 42.w,
                height: 42.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF3498DB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
