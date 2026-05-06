import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../daily_quest_screen.dart';

/// Banner "Nhiệm vụ hôm nay" — gradient sáng + shimmer + arrow
class CongratsBanner extends StatefulWidget {
  final String title;
  final String message;

  const CongratsBanner({
    super.key,
    this.title = 'Nhiệm vụ hôm nay',
    this.message = 'Hoàn thành nhiệm vụ để nhận thưởng ⭐',
  });

  @override
  State<CongratsBanner> createState() => _CongratsBannerState();
}

class _CongratsBannerState extends State<CongratsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DailyQuestScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer sweep
            AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) {
                final dx = _shimmerCtrl.value * 400 - 100;
                return Positioned(
                  left: dx, top: -20, bottom: -20,
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.0),
                        ]),
                    ),
                  ),
                );
              },
            ),
            // Content row
            Row(
              children: [
                // Mascot
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(15)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('image/Nhiệm vụ.png', fit: BoxFit.cover)),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(widget.message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92))),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
