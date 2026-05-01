import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/daily_challenge.dart';

/// Widget hiển thị một thử thách hàng ngày
/// Có icon check (xanh) nếu đã hoàn thành, hoặc số thứ tự (xám) nếu chưa
class ChallengeItem extends StatelessWidget {
  final DailyChallenge challenge;
  final int index;

  const ChallengeItem({
    super.key,
    required this.challenge,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Status icon
          _buildStatusIcon(),
          const SizedBox(width: 12),
          // Challenge title
          Expanded(
            child: Text(
              challenge.title,
              style: AppTextStyles.challengeTitle.copyWith(
                color: challenge.isCompleted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                decoration: challenge.isCompleted
                    ? TextDecoration.none
                    : TextDecoration.none,
              ),
            ),
          ),
          // Reward stars
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${challenge.rewardStars}',
                style: AppTextStyles.challengeReward,
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.accentYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (challenge.isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: AppColors.textWhite,
        ),
      );
    } else {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}
