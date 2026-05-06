import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../daily_quest_screen.dart';

/// Banner "Nhiệm vụ hôm nay" — nền trắng, tiến trình
class CongratsBanner extends StatelessWidget {
  final String title;
  final String message;

  const CongratsBanner({
    super.key,
    this.title = 'Nhiệm vụ hôm nay',
    this.message = 'Hoàn thành nhiệm vụ để nhận thưởng',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DailyQuestScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFEEF1F8))),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 50, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FF),
                borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('image/Nhiệm vụ.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6EAFF),
                      borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: const Color(0xFFFFB340), size: 16),
                      const SizedBox(width: 4),
                      Text('0/5 nhiệm vụ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1976D2))),
                    ]),
                  ),
                ],
              ),
            ),
            // Arrow button
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                  blurRadius: 8, offset: const Offset(0, 3))]),
              child: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
