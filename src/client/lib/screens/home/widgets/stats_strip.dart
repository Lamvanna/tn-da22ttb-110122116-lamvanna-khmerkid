import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/kk/kk.dart';

/// ════════════════════════════════════════════════════════════════════
///  StatsStrip — 3 stats compact pinned dưới header
/// ────────────────────────────────────────────────────────────────────
///  Dùng KkCard raised, divider mỏng, type tabular figures.
///  Mỗi cell có Semantics đầy đủ.
/// ════════════════════════════════════════════════════════════════════
class StatsStrip extends StatelessWidget {
  final int streak;
  final int stars;
  final int lessons;

  const StatsStrip({
    super.key,
    required this.streak,
    required this.stars,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: KkCard(
        variant: KkCardVariant.raised,
        padding: EdgeInsets.symmetric(vertical: Spacing.v3),
        radius: Radii.md,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _StatCell(
                icon: Icons.local_fire_department_rounded,
                iconColor: KkColors.modulePlay,
                value: '$streak',
                label: 'Chuỗi ngày',
                semantic: 'Chuỗi học liên tiếp $streak ngày',
              )),
              const _Divider(),
              Expanded(child: _StatCell(
                icon: Icons.star_rounded,
                iconColor: KkColors.moduleReward,
                value: '$stars',
                label: 'Sao thưởng',
                semantic: 'Đã đạt $stars sao thưởng',
              )),
              const _Divider(),
              Expanded(child: _StatCell(
                icon: Icons.menu_book_rounded,
                iconColor: KkColors.brand,
                value: '$lessons',
                label: 'Bài đã học',
                semantic: 'Đã hoàn thành $lessons bài học',
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String semantic;

  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantic,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 18.sp),
                SizedBox(width: 5.w),
                Text(value, style: KkType.statS),
              ],
            ),
            SizedBox(height: 2.h),
            Text(label, style: KkType.labelS.tertiary),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32.h,
      color: KkColors.borderSubtle,
    );
  }
}
