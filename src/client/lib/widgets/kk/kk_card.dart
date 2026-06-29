import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/design_tokens.dart';

/// ════════════════════════════════════════════════════════════════════
///  KkCard — Card hệ thống
/// ────────────────────────────────────────────────────────────────────
///  • Variants: surface / raised / hero / interactive
///  • Mỗi variant có default radius + shadow đúng spec
///  • `onTap` tự động enable scale press + haptic
///  • Hỗ trợ gradient overlay cho hero card
/// ════════════════════════════════════════════════════════════════════

enum KkCardVariant { surface, raised, hero, interactive }

class KkCard extends StatefulWidget {
  final Widget child;
  final KkCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Color? background;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? shadow;

  const KkCard({
    super.key,
    required this.child,
    this.variant = KkCardVariant.raised,
    this.onTap,
    this.padding,
    this.margin,
    this.radius,
    this.background,
    this.gradient,
    this.border,
    this.shadow,
  });

  @override
  State<KkCard> createState() => _KkCardState();
}

class _KkCardState extends State<KkCard> {
  bool _pressed = false;

  ({Color bg, List<BoxShadow>? shadow, double radius}) _styleFor() {
    switch (widget.variant) {
      case KkCardVariant.surface:
        return (bg: KkColors.surfaceMuted, shadow: null, radius: 16);
      case KkCardVariant.raised:
        return (bg: KkColors.surfaceRaised, shadow: Elevation.e1, radius: 16);
      case KkCardVariant.hero:
        return (bg: KkColors.surfaceRaised, shadow: Elevation.e2, radius: 20);
      case KkCardVariant.interactive:
        return (bg: KkColors.surfaceRaised, shadow: Elevation.e1, radius: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _styleFor();
    final radius = widget.radius ?? s.radius;
    final isInteractive = widget.onTap != null;

    final card = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.standard,
      margin: widget.margin,
      padding: widget.padding ?? EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: widget.gradient == null ? (widget.background ?? s.bg) : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(radius),
        border: widget.border,
        boxShadow: _pressed ? null : (widget.shadow ?? s.shadow),
      ),
      child: widget.child,
    );

    if (!isInteractive) return card;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: Motion.micro,
          curve: Motion.standard,
          child: card,
        ),
      ),
    );
  }
}
