import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thẻ danh mục — gradient + ảnh to ở trên, label dưới
class CategoryCard extends StatefulWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final Color color;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    this.icon,
    this.imagePath,
    required this.label,
    required this.color,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lighter = Color.lerp(widget.color, Colors.white, 0.18)!;
    final darker = Color.lerp(widget.color, Colors.black, 0.12)!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height ?? 130.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.5, -1),
              end: const Alignment(0.5, 1),
              colors: [lighter, widget.color]),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: darker.withValues(alpha: _pressed ? 0.15 : 0.35),
                blurRadius: 0,
                offset: Offset(0, _pressed ? 2.h : 4.h)),
              BoxShadow(
                color: widget.color.withValues(alpha: 0.20),
                blurRadius: 24.r,
                offset: Offset(0, 10.h)),
            ],
          ),
          child: Column(
            children: [
              // Ảnh to ở trên
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                  child: widget.imagePath != null
                    ? Image.asset(widget.imagePath!, fit: BoxFit.contain)
                    : Center(
                        child: Container(
                          width: 48.w, height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14.r)),
                          child: Icon(widget.icon, color: Colors.white, size: 26.sp),
                        ),
                      ),
                ),
              ),
              // Label nổi bật ở dưới
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w).copyWith(bottom: 10.h),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp, fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h)),
                      ])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
