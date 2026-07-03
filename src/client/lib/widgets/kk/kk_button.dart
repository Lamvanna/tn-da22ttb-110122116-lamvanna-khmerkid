import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_typography.dart';
import 'package:khmerkid/utils/app_haptics.dart';

/// ════════════════════════════════════════════════════════════════════
///  KkButton — Button hệ thống KhmerKid 2026
/// ────────────────────────────────────────────────────────────────────
///  • 4 variants: primary / secondary / ghost / destructive
///  • 3 sizes:    sm (40dp) / md (48dp) ⭐ / lg (56dp)
///  • Touch target ≥ 48dp (md, lg) — sm bọc trong gesture detector
///  • Haptic + scale press animation
///  • Loading + disabled state đầy đủ
///  • Optional leading/trailing icon
///
///  Usage:
///    KkButton.primary(label: 'Tiếp tục học', onPressed: () {})
///    KkButton.secondary(label: 'Hủy', onPressed: () {})
///    KkButton.primary(label: '...', size: KkButtonSize.lg, fullWidth: true)
/// ════════════════════════════════════════════════════════════════════

enum KkButtonVariant { primary, secondary, ghost, destructive }
enum KkButtonSize { sm, md, lg }

class KkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final KkButtonVariant variant;
  final KkButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool isLoading;
  final Color? customBackground;
  final Color? customForeground;

  const KkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KkButtonVariant.primary,
    this.size = KkButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
    this.isLoading = false,
    this.customBackground,
    this.customForeground,
  });

  factory KkButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkButtonSize size = KkButtonSize.md,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool fullWidth = false,
    bool isLoading = false,
  }) => KkButton(
    key: key, label: label, onPressed: onPressed,
    variant: KkButtonVariant.primary, size: size,
    leadingIcon: leadingIcon, trailingIcon: trailingIcon,
    fullWidth: fullWidth, isLoading: isLoading);

  factory KkButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkButtonSize size = KkButtonSize.md,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool fullWidth = false,
  }) => KkButton(
    key: key, label: label, onPressed: onPressed,
    variant: KkButtonVariant.secondary, size: size,
    leadingIcon: leadingIcon, trailingIcon: trailingIcon,
    fullWidth: fullWidth);

  factory KkButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkButtonSize size = KkButtonSize.md,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) => KkButton(
    key: key, label: label, onPressed: onPressed,
    variant: KkButtonVariant.ghost, size: size,
    leadingIcon: leadingIcon, trailingIcon: trailingIcon);

  factory KkButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    KkButtonSize size = KkButtonSize.md,
    bool fullWidth = false,
  }) => KkButton(
    key: key, label: label, onPressed: onPressed,
    variant: KkButtonVariant.destructive, size: size,
    fullWidth: fullWidth);

  @override
  State<KkButton> createState() => _KkButtonState();
}

class _KkButtonState extends State<KkButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  ({Color bg, Color fg, Color? border, List<BoxShadow>? shadow}) _styleFor() {
    if (_disabled) {
      return (
        bg: KkColors.surfaceSunken,
        fg: KkColors.textDisabled,
        border: null,
        shadow: null,
      );
    }
    switch (widget.variant) {
      case KkButtonVariant.primary:
        return (
          bg: widget.customBackground ?? KkColors.brand,
          fg: widget.customForeground ?? KkColors.textOnBrand,
          border: null,
          shadow: _pressed ? null : Elevation.brand(opacity: 0.20),
        );
      case KkButtonVariant.secondary:
        return (
          bg: KkColors.brandSubtle,
          fg: KkColors.brand,
          border: null,
          shadow: null,
        );
      case KkButtonVariant.ghost:
        return (
          bg: Colors.transparent,
          fg: KkColors.brand,
          border: KkColors.borderStrong,
          shadow: null,
        );
      case KkButtonVariant.destructive:
        return (
          bg: KkColors.danger,
          fg: KkColors.textOnBrand,
          border: null,
          shadow: _pressed ? null : null,
        );
    }
  }

  ({double height, double padH, double iconSize, TextStyle text}) _sizeFor() {
    switch (widget.size) {
      case KkButtonSize.sm:
        return (
          height: 40,
          padH: 16,
          iconSize: 16,
          text: KkType.buttonM);
      case KkButtonSize.md:
        return (
          height: 48,
          padH: 20,
          iconSize: 18,
          text: KkType.buttonL);
      case KkButtonSize.lg:
        return (
          height: 56,
          padH: 24,
          iconSize: 20,
          text: KkType.buttonL.copyWith(fontSize: 17.sp));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _styleFor();
    final sz = _sizeFor();

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        onTapUp: _disabled ? null : (_) {
          setState(() => _pressed = false);
          AppHaptics.lightImpact();
          widget.onPressed?.call();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: Motion.micro,
          curve: Motion.standard,
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.standard,
            width: widget.fullWidth ? double.infinity : null,
            height: sz.height.h,
            padding: EdgeInsets.symmetric(horizontal: sz.padH.w),
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(Radii.full),
              border: s.border != null
                ? Border.all(color: s.border!, width: 1.5)
                : null,
              boxShadow: s.shadow,
            ),
            child: _buildContent(s.fg, sz),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fg, ({double height, double padH, double iconSize, TextStyle text}) sz) {
    if (widget.isLoading) {
      return Center(child: SizedBox(
        width: sz.iconSize.w, height: sz.iconSize.w,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: sz.iconSize.sp, color: fg),
          SizedBox(width: 8.w),
        ],
        Flexible(child: Text(
          widget.label,
          style: sz.text.copyWith(color: fg),
          overflow: TextOverflow.ellipsis,
          maxLines: 1)),
        if (widget.trailingIcon != null) ...[
          SizedBox(width: 8.w),
          Icon(widget.trailingIcon, size: sz.iconSize.sp, color: fg),
        ],
      ],
    );
  }
}
