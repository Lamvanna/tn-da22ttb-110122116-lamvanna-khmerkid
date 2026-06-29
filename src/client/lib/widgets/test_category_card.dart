import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Widget thẻ loại bài kiểm tra — RESPONSIVE
class TestCategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int starRating;
  final String difficulty;
  final VoidCallback? onTap;

  const TestCategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.starRating = 0,
    this.difficulty = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container — 48x48 min touch target
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                icon,
                size: 28.sp,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(width: 14.w),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitleWhite,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (starRating > 0 || difficulty.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        // Star rating
                        if (starRating > 0) ...[
                          ...List.generate(5, (index) => Icon(
                            index < starRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14.sp,
                            color: AppColors.accentYellow,
                          )),
                          SizedBox(width: 8.w),
                        ],
                        // Difficulty badge
                        if (difficulty.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              difficulty,
                              style: AppTextStyles.difficultyBadge,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textWhite,
              size: 28.sp,
            ),
          ],
        ),
      ),
    );
  }
}
