import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_typography.dart';

/// ════════════════════════════════════════════════════════════════════
///  KkChip — Chip / Badge / Pill nhỏ
/// ────────────────────────────────────────────────────────────────────
///  Use cases:
///    • Status: KkChip.status('Đang học', color: KkColors.success)
///    • Counter: KkChip.counter(icon: Icons.star, label: '+10')
///    • Filter: KkChip.filter('Phụ âm', selected: true, onTap: ...)
/// ════════════════════════════════════════════════════════════════════
class KkChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Color color;
  final Color? background;
  final bool tonal;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const KkChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.color = KkColors.brand,
    this.background,
    this.tonal = true,
    this.onTap,
    this.padding,
    this.fontSize,
  });

  /// Status chip: tonal background, colored text
  factory KkChip.status({
    Key? key,
    required String label,
    Color color = KkColors.success,
    IconData? icon,
  }) => KkChip(
    key: key, label: label, icon: icon, color: color, tonal: true);

  /// Counter chip: cho điểm số, sao
  factory KkChip.counter({
    Key? key,
    required String label,
    IconData? icon,
    Widget? leading,
    Color color = KkColors.moduleReward,
    double? fontSize,
  }) => KkChip(
    key: key, label: label, icon: icon, leading: leading,
    color: color, tonal: true, fontSize: fontSize);

  /// Solid chip: background đậm
  factory KkChip.solid({
    Key? key,
    required String label,
    IconData? icon,
    Color color = KkColors.brand,
    VoidCallback? onTap,
  }) => KkChip(
    key: key, label: label, icon: icon, color: color, tonal: false, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (tonal ? color.withValues(alpha: 0.12) : color);
    final fg = tonal ? color : KkColors.textOnBrand;

    final content = Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: 4.w),
          ] else if (icon != null) ...[
            Icon(icon, size: (fontSize ?? 12) + 2, color: fg),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: KkType.labelM.copyWith(
              color: fg,
              fontSize: (fontSize ?? 12).sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.full),
      child: content,
    );
  }
}
