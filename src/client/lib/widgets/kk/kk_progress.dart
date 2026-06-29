import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_typography.dart';

/// ════════════════════════════════════════════════════════════════════
///  KkProgress — Progress indicators
/// ────────────────────────────────────────────────────────────────────
///  • KkLinearProgress: thanh ngang, animated, có rounded cap
///  • KkCircularProgress: vòng tròn với label center
/// ════════════════════════════════════════════════════════════════════

class KkLinearProgress extends StatelessWidget {
  /// 0.0 – 1.0
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final Duration animationDuration;

  const KkLinearProgress({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 6,
    this.animationDuration = Motion.medium,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? KkColors.brand;
    return Semantics(
      label: 'Tiến trình ${(value * 100).toInt()}%',
      value: '${(value * 100).toInt()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.full),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: animationDuration,
          curve: Motion.emphasis,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: height.h,
            backgroundColor: trackColor ?? c.withValues(alpha: 0.12),
            color: c,
          ),
        ),
      ),
    );
  }
}

class KkCircularProgress extends StatelessWidget {
  /// 0.0 – 1.0
  final double value;
  final Color? color;
  final Color? trackColor;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const KkCircularProgress({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.size = 64,
    this.strokeWidth = 5,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? KkColors.brand;
    return Semantics(
      label: 'Tiến trình ${(value * 100).toInt()}%',
      value: '${(value * 100).toInt()}%',
      child: SizedBox(
        width: size.w, height: size.w,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: Motion.medium,
          curve: Motion.emphasis,
          builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
            SizedBox.expand(child: CircularProgressIndicator(
              value: 1.0, strokeWidth: strokeWidth.w,
              color: trackColor ?? c.withValues(alpha: 0.15))),
            SizedBox.expand(child: CircularProgressIndicator(
              value: v, strokeWidth: strokeWidth.w,
              color: c, strokeCap: StrokeCap.round)),
            if (center != null)
              center!
            else
              Text('${(v * 100).toInt()}%',
                style: KkType.statS.copyWith(color: KkColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}
