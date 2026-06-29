import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thẻ bài học trên bản đồ phiêu lưu
/// Card hiển thị: emoji nhân vật, tiến độ vòng tròn, nút hành động
class LearningPathCard extends StatelessWidget {
  final String title;
  final String animalEmoji;
  final double progress; // 0.0 - 1.0
  final String buttonText;
  final Color progressColor;
  final Color cardBorderColor;
  final VoidCallback? onTap;

  const LearningPathCard({
    super.key,
    required this.title,
    required this.animalEmoji,
    required this.progress,
    required this.buttonText,
    this.progressColor = const Color(0xFF4CAF50),
    this.cardBorderColor = const Color(0xFFE0E0E0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF37474F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Animal + Progress circle
            SizedBox(
              width: 75,
              height: 75,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress circle background
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 5,
                      color: progressColor.withValues(alpha: 0.15),
                    ),
                  ),
                  // Progress circle fill
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      color: progressColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Animal emoji
                  Text(
                    animalEmoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                  // Star badge at top-right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('⭐', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  // Percentage at bottom
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: progressColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
