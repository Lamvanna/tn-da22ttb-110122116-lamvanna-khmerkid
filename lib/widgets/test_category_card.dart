import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Widget thẻ loại bài kiểm tra (Kiểm tra nói, nghe, viết, tổng hợp)
/// Sử dụng trên màn hình Học (Learn Screen)
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitleWhite,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (starRating > 0 || difficulty.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Star rating
                        if (starRating > 0) ...[
                          ...List.generate(5, (index) => Icon(
                            index < starRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: AppColors.accentYellow,
                          )),
                          const SizedBox(width: 8),
                        ],
                        // Difficulty badge
                        if (difficulty.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textWhite,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
