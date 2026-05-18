import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// GameXpProgressBar
/// A cartoon-style, bouncy-animated, highly-polished XP progress bar designed
/// specifically for modern kids learning and educational games.
class GameXpProgressBar extends StatelessWidget {
  final int xpInLevel;
  final int xpNeeded;
  final int level;
  final double height;
  final double trackHeight;
  final double starSize;
  final double fontSize;
  final Duration animationDuration;
  final bool showSubtext;

  const GameXpProgressBar({
    super.key,
    required this.xpInLevel,
    required this.xpNeeded,
    this.level = 1,
    this.height = 36,
    this.trackHeight = 24,
    this.starSize = 36,
    this.fontSize = 10.5,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.showSubtext = false,
  });

  @override
  Widget build(BuildContext context) {
    final targetFactor = (xpInLevel / xpNeeded).clamp(0.0, 1.0);
    final xpRemaining = xpNeeded - xpInLevel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: height.h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // ─── Track (deep blue with beautiful white and light-blue glowing border) ───
              Container(
                height: trackHeight.h,
                margin: EdgeInsets.only(left: (starSize / 2 + 2).w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.95), // deep blue track
                  borderRadius: BorderRadius.circular((trackHeight / 2).r),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.w,
                  ),
                  boxShadow: [
                    // Glowing white-blue border shadow
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withOpacity(0.35),
                      blurRadius: 5.r,
                      spreadRadius: 1.r,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular((trackHeight / 2 - 2).r),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Animated Yellow/Gold progress fill with elastic out bounce curve!
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: targetFactor),
                        duration: animationDuration,
                        curve: Curves.easeOutBack, // Bouncy cartoon animation curve
                        builder: (context, animatedFactor, child) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: animatedFactor.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular((trackHeight / 2 - 2).r),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFFEE58), // Bright gold-yellow
                                      Color(0xFFFBBF24), // Rich amber gold
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Glossy white highlight strip on top half of the progress fill
                                    Positioned(
                                      top: 0, left: 0, right: 0,
                                      height: (trackHeight * 0.25).h,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular((trackHeight / 2 - 2).r),
                                            topRight: Radius.circular((trackHeight / 2 - 2).r),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Glossy glassmorphism overlay on the entire track
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: (trackHeight * 0.25).h,
                        child: Container(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),

                      // Value text — perfectly centered on top of everything
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '$xpInLevel / $xpNeeded XP',
                            maxLines: 1,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: fontSize.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A), // Slate-900 for premium contrast
                              letterSpacing: 0.3,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.40),
                                  blurRadius: 2.r,
                                  offset: const Offset(0, 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Star badge (overlap left, mập mạp & sắc nét) ───────────────
              Positioned(
                left: 3.w,
                child: SizedBox(
                  width: starSize.w, height: starSize.w,
                  child: CustomPaint(
                    painter: _StarBadgePainter(),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Text(
                          'XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: (fontSize - 0.5).sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF78350F), // Dark gold text
                            letterSpacing: 0.2,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showSubtext) ...[
          SizedBox(height: 8.h),
          Text(
            'Còn $xpRemaining XP để lên cấp ${level + 1}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _StarBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.48;
    final innerR = size.width * 0.25;

    final path = _buildStarPath(cx, cy, outerR, innerR, 5);

    // 1. Drop shadow nhẹ nhàng, tự nhiên cho toàn bộ ngôi sao
    canvas.drawShadow(
      path.shift(const Offset(0, 1.5)),
      const Color(0xFF78350F).withOpacity(0.25),
      3.0,
      false,
    );

    // 2. VIỀN TRẮNG DÀY BÊN NGOÀI (Thoát viền cực đẹp)
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, whiteStroke);

    // 3. FILL MÀU GRADIENT VÀNG GOLD SÁNG CỰC ĐẸP
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF59D), // Vàng sáng
          Color(0xFFFBBF24), // Vàng gold đậm đà
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fill);

    // 4. VIỀN VÀNG-CAM BO GÓC MƯỢT MÀ BÊN TRONG VIỀN TRẮNG
    final goldStroke = Paint()
      ..color = const Color(0xFFF59E0B) // Amber stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, goldStroke);
  }

  Path _buildStarPath(
      double cx, double cy, double outerR, double innerR, int points) {
    final path = Path();
    final step = math.pi / points;
    double angle = -math.pi / 2; // Bắt đầu ở đỉnh trên cùng
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
