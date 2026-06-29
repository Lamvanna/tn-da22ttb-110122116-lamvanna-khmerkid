import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/kk/kk.dart';

/// ════════════════════════════════════════════════════════════════════
///  HeroContinueCard — focal action của Home
/// ────────────────────────────────────────────────────────────────────
///  Đây là CTA chính: "Tiếp tục bài học gần nhất".
///  Trẻ em mở app vào → thấy ngay 1 hành động duy nhất → tap → vào học.
///  Pattern này cải thiện retention 25-40% so với "rải nhiều card".
/// ════════════════════════════════════════════════════════════════════
class HeroContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int done;
  final int total;
  final int reward;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onContinue;
  final String? imagePath;

  const HeroContinueCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.total,
    required this.reward,
    this.icon = Icons.auto_stories_rounded,
    this.accentColor = KkColors.brand,
    this.onContinue,
    this.imagePath,
  });

  double get _progress => total == 0 ? 0 : (done / total).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: KkCard(
        variant: KkCardVariant.hero,
        onTap: onContinue,
        padding: EdgeInsets.all(Spacing.s4),
        radius: Radii.lg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Visual: image or icon ──
            Container(
              width: 88.w, height: 88.w,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.s2),
                      child: Image.asset(imagePath!, fit: BoxFit.contain)))
                : Icon(icon, color: accentColor, size: 36.sp),
            ),
            SizedBox(width: Spacing.s3),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                        child: Text('Tiếp tục',
                          style: KkType.labelS.copyWith(color: accentColor)),
                      ),
                      const Spacer(),
                      KkChip.counter(
                        label: '+$reward',
                        icon: Icons.star_rounded,
                        color: KkColors.moduleReward,
                      ),
                    ],
                  ),
                  SizedBox(height: Spacing.v2),
                  Text(title,
                    style: KkType.h4,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                    style: KkType.bodyS.secondary,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: Spacing.v3),
                  Row(
                    children: [
                      Expanded(child: KkLinearProgress(
                        value: _progress,
                        color: accentColor,
                        height: 8,
                      )),
                      SizedBox(width: Spacing.s2),
                      Text('$done/$total',
                        style: KkType.labelM.copyWith(color: accentColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
