import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// Dialog phản hồi kết quả: Đúng rồi! / Chưa đúng!
/// Hiển thị overlay xanh/đỏ với animation
class FeedbackDialog {
  /// Hiện dialog "Đúng rồi!" với animation check xanh
  static void showSuccess(
    BuildContext context, {
    int xpEarned = 0,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FeedbackOverlay(
        isCorrect: true,
        xpEarned: xpEarned,
        message: message ?? AppStrings.correctMessage,
      ),
    );
  }

  /// Hiện dialog "Chưa đúng!"
  static void showFailure(
    BuildContext context, {
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FeedbackOverlay(
        isCorrect: false,
        message: message ?? 'Hãy thử lại nhé!',
      ),
    );
  }
}

class _FeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final int xpEarned;
  final String message;

  const _FeedbackOverlay({
    required this.isCorrect,
    this.xpEarned = 0,
    required this.message,
  });

  @override
  State<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<_FeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (widget.isCorrect
                          ? AppColors.accentGreen
                          : AppColors.accentRed)
                      .withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon lớn (check hoặc X)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.isCorrect
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isCorrect
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 48,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                Text(
                  widget.isCorrect
                      ? AppStrings.correct
                      : AppStrings.incorrect,
                  style: AppTextStyles.screenTitleDark.copyWith(
                    color: widget.isCorrect
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  widget.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // XP earned (nếu đúng)
                if (widget.isCorrect && widget.xpEarned > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.normalScore,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'កករ',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 16,
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.xpEarned}',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.accentOrange,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColors.accentYellow,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Nút tiếp tục
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCorrect
                          ? AppColors.accentGreen
                          : AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      AppStrings.continueBtn,
                      style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
