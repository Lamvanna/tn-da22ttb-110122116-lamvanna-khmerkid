import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/kk/kk.dart';
import '../daily_quest_screen.dart';
import '../../../widgets/app_page_route.dart';

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

  double get _progress => total == 0 ? 0 : (completed / total).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: KkCard(
        variant: KkCardVariant.raised,
        onTap: () => Navigator.push(context,
          AppPageRoute(page: const DailyQuestScreen())),
        padding: EdgeInsets.all(Spacing.s4),
        radius: Radii.md,
        background: KkColors.moduleRewardBg,
        border: Border.all(
          color: KkColors.moduleReward.withValues(alpha: 0.20), width: 1),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: KkColors.moduleReward,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(Icons.flag_circle_rounded,
                    color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: Spacing.s3),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text('Nhiệm vụ hôm nay',
                            style: KkType.h4,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                          SizedBox(width: Spacing.s2),
                          KkChip.counter(
                            label: '+$rewardStars',
                            icon: Icons.star_rounded,
                            color: KkColors.moduleReward,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text('Hoàn thành để nhận thưởng',
                        style: KkType.bodyS.secondary,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                SizedBox(width: Spacing.s2),
                // Arrow
                Container(
                  width: 36.w, height: 36.w,
                  decoration: const BoxDecoration(
                    color: KkColors.moduleReward,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18.sp),
                ),
              ],
            ),
            SizedBox(height: Spacing.v3),
            Row(
              children: [
                Expanded(child: KkLinearProgress(
                  value: _progress,
                  color: KkColors.moduleReward,
                  height: 6,
                )),
                SizedBox(width: Spacing.s2),
                Text('$completed/$total',
                  style: KkType.labelM.copyWith(
                    color: KkColors.moduleReward,
                    fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
