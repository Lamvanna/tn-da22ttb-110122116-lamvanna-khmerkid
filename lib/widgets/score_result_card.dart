import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// ════════════════════════════════════════════════════════════════════
/// ScoreResultCard — Widget hiện kết quả chấm điểm
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Điểm phần trăm lớn ở giữa (animated counter)
///   • Stars rating (0-3 sao)
///   • XP earned badge
///   • Nút "Thử lại" / "Tiếp tục"
///   • Background color theo kết quả
/// ════════════════════════════════════════════════════════════════════

class ScoreResultCard extends StatefulWidget {
  final int score; // 0-100
  final int stars; // 0-3
  final int xpEarned;
  final bool passed;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;

  const ScoreResultCard({
    super.key,
    required this.score,
    required this.stars,
    this.xpEarned = 0,
    required this.passed,
    this.title = '',
    this.subtitle = '',
    this.onRetry,
    this.onContinue,
  });

  @override
  State<ScoreResultCard> createState() => _ScoreResultCardState();
}

class _ScoreResultCardState extends State<ScoreResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scoreAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreAnim = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.passed
        ? AppColors.tertiarySurface
        : AppColors.coralSurface;
    final accentColor = widget.passed
        ? AppColors.tertiary
        : AppColors.coral;
    final textColor = widget.passed
        ? AppColors.tertiaryDark
        : AppColors.coralDark;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) => Transform.scale(
        scale: _scaleAnim.value,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Text(
                widget.passed ? '🎉' : '😅',
                style: TextStyle(fontSize: 48.sp),
              ),
              SizedBox(height: 12.h),

              // Title
              Text(
                widget.title.isNotEmpty
                    ? widget.title
                    : widget.passed
                        ? 'Tuyệt vời!'
                        : 'Chưa chính xác',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),

              // Subtitle
              if (widget.subtitle.isNotEmpty)
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              SizedBox(height: 12.h),

              // Score circle
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(color: accentColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${_scoreAnim.value.round()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Icon(
                      i < widget.stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32.w,
                      color: i < widget.stars
                          ? AppColors.secondary
                          : AppColors.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),

              // XP
              if (widget.xpEarned > 0 && widget.passed) ...[
                SizedBox(height: 8.h),
                Text(
                  '+${widget.xpEarned} XP ⭐',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
              SizedBox(height: 20.h),

              // Buttons
              if (widget.onContinue != null && widget.passed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Tiếp tục ✅',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              if (widget.onRetry != null) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onRetry,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      side: BorderSide(color: AppColors.violet),
                    ),
                    child: Text(
                      'Thử lại',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
