import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/khmer_number.dart';

/// Widget hiển thị một ô số Khmer trong lưới
class NumberGridItem extends StatelessWidget {
  final KhmerNumber number;
  final VoidCallback? onTap;

  const NumberGridItem({
    super.key,
    required this.number,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: number.isLearned
              ? AppColors.cardWhite
              : AppColors.backgroundLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: number.isLearned
                ? AppColors.primaryPurple.withValues(alpha: 0.2)
                : AppColors.textHint.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: number.isLearned
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ký tự số Khmer
            Text(
              number.character,
              style: GoogleFonts.kantumruyPro(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: number.isLearned
                    ? AppColors.primaryPurple
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            // Star rating hoặc "Không"
            if (number.isLearned)
              _buildStarRating(number.starRating)
            else
              Text(
                'Không',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 8,
          color: index < rating
              ? AppColors.starFilled
              : AppColors.starEmpty,
        );
      }),
    );
  }
}
