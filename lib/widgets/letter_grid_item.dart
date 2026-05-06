import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/khmer_letter.dart';

/// Widget hiển thị một ô chữ Khmer trong lưới
/// Có star rating bên dưới nếu đã học
class LetterGridItem extends StatelessWidget {
  final KhmerLetter letter;
  final VoidCallback? onTap;

  const LetterGridItem({
    super.key,
    required this.letter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: letter.isLearned
              ? AppColors.cardWhite
              : AppColors.backgroundLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: letter.isLearned
                ? AppColors.primaryPurple.withValues(alpha: 0.2)
                : AppColors.textHint.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: letter.isLearned
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
            // Ký tự Khmer
            Text(
              letter.character,
              style: GoogleFonts.kantumruyPro(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: letter.isLearned
                    ? AppColors.primaryPurple
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            // Star rating hoặc "Không"
            if (letter.isLearned)
              _buildStarRating(letter.starRating)
            else
              Text(
                'Không',
                style: GoogleFonts.plusJakartaSans(
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
