import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header thống nhất cho toàn bộ app KhmerKid.
/// Dùng cho mọi screen: học, chơi, cài đặt, ...
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final List<Color>? gradientColors;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.trailing,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [Color(0xFF4580C4), Color(0xFF6A9DD6)];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(0.5, 1),
          colors: colors),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
        boxShadow: [BoxShadow(
          color: colors.first.withValues(alpha: 0.18),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -30, top: -25,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -20, bottom: -15,
          child: Container(width: 60, height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              // Back button
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10))),
                  child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(child: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      const SizedBox(height: 1),
                      Text(subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75))),
                    ])
                : Text(title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19, fontWeight: FontWeight.w800,
                      color: Colors.white))),
              // Trailing widget
              ?trailing,
            ]),
          ),
        ),
      ]),
    );
  }
}
