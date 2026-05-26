import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_letter.dart';
import 'letter_detail_screen.dart';

/// Bản đồ chữ cái Khmer — Premium learning path
class LetterMapView extends StatefulWidget {
  final VoidCallback onBack;
  const LetterMapView({super.key, required this.onBack});

  @override
  State<LetterMapView> createState() => _LetterMapViewState();
}

class _LetterMapViewState extends State<LetterMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerLetter> _letters = KhmerLetterData.consonants;

  // Responsive constants — sử dụng getter thay vì static const
  double get _nodeSpacingY => 140.h;
  double get _topPadding => 80.h;
  double get _nodeSize => 78.w;

  int get _currentIdx {
    final idx = _letters.indexWhere((l) => !l.isLearned);
    return idx == -1 ? _letters.length - 1 : idx;
  }

  int get _doneCount => _letters.where((l) => l.isLearned && !l.isTest).length;
  int get _totalLessons => _letters.where((l) => !l.isTest).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final target = (_letters.length - 1 - _currentIdx) * _nodeSpacingY - 200.h;
    if (_scrollCtrl.hasClients && target > 0) {
      _scrollCtrl.animateTo(
        target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Zigzag positions
  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18;
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  // 5 màu xoay vòng theo nhóm 5 chữ
  Color _nodeColor(int idx) {
    final letter = _letters[idx];
    if (letter.isTest) {
      return letter.testRange == '1-40'
          ? const Color(0xFFFF6B00)  // 🟠 Final test - orange
          : const Color(0xFF7C4DFF); // 🟣 Regular test - purple
    }
    const colors = [
      Color(0xFF2979FF), // 🔵 xanh tươi
      Color(0xFF00E676), // 🟢 xanh lá neon
      Color(0xFFFFD600), // 🟡 vàng tươi
      Color(0xFFAA00FF), // 🟣 tím neon
      Color(0xFFFF1744), // 🔴 đỏ tươi
    ];
    return colors[(idx ~/ 5) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _letters.length * _nodeSpacingY + 200.h;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                reverse: true,
                child: SizedBox(
                  width: w,
                  height: mapH,
                  child: CustomPaint(
                    painter: _MapPainter(
                      count: _letters.length,
                      width: w,
                      getX: _nodeX,
                      getY: _nodeY,
                      doneCount: _doneCount,
                      undoneStroke: 10.w,
                      shadowStroke: 12.w,
                      mainStroke: 8.w,
                      highlightStroke: 3.w,
                    ),
                    child: Stack(children: _buildAllNodes(w)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final progress = _totalLessons > 0 ? _doneCount / _totalLessons : 0.0;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40.w,
            top: -30.h,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -25.w,
            bottom: -20.h,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Mascot elephant
          Positioned(
            right: 0,
            bottom: -2.h,
            child: Image.asset(
              'image/Voi nguyên âm.png',
              width: 100.w,
              height: 100.w,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 105.w, 5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Back + Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Text(
                          'Học phụ âm',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.h),
                  Padding(
                    padding: EdgeInsets.only(left: 48.w),
                    child: Text(
                      '$_doneCount/$_totalLessons đã hoàn thành',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Progress bar
                  Padding(
                    padding: EdgeInsets.only(left: 48.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF66BB6A),
                                          Color(0xFF43A047),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF43A047,
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$pct%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ALL NODES ───
  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];

    // Pre-compute lesson numbers (excluding tests)
    final lessonNumbers = <int, int>{};
    int lessonNum = 0;
    for (int j = 0; j < _letters.length; j++) {
      if (!_letters[j].isTest) {
        lessonNum++;
        lessonNumbers[j] = lessonNum;
      }
    }

    for (int i = 0; i < _letters.length; i++) {
      final ri = _letters.length - 1 - i;
      final letter = _letters[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = letter.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = _nodeColor(ri);
      final baiNum = lessonNumbers[ri] ?? 0;

      // Determine label position: alternate left/right based on node position
      final isNodeOnRight = x > w / 2;
      final labelOnLeft = isNodeOnRight;

      // ── Label card ──
      final labelW = 95.w;
      final labelX = labelOnLeft
          ? x - _nodeSize / 2 - labelW - 10.w
          : x + _nodeSize / 2 + 10.w;
      final labelY = y - 45.h;

      widgets.add(
        Positioned(
          left: labelX,
          top: labelY,
          child: Container(
            width: labelW,
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
            decoration: BoxDecoration(
              color: locked
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: locked ? null : Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: locked
                      ? Colors.black.withValues(alpha: 0.03)
                      : color.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                if (!locked)
                  BoxShadow(
                    color: color.withValues(alpha: 0.06),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: locked
                        ? const Color(0xFFE8EEF5)
                        : letter.isTest
                            ? const Color(0xFFF3E5F5)
                            : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    letter.isTest ? 'Kiểm tra' : 'Bài $baiNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: locked
                          ? const Color(0xFFB0BEC5)
                          : letter.isTest
                              ? const Color(0xFF7C4DFF)
                              : color,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                if (letter.isTest) ...[
                  Text(
                    letter.testRange == '1-40' ? 'Tổng hợp' : 'Bài ${letter.testRange}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: locked
                          ? const Color(0xFFB0BEC5)
                          : const Color(0xFF1A202C),
                    ),
                  ),
                  Text(
                    letter.testRange == '1-40' ? 'Tất cả' : 'Ôn tập',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: locked
                          ? const Color(0xFFCFD8DC)
                          : const Color(0xFF718096),
                    ),
                  ),
                ] else ...[
                  Text(
                    letter.character,
                    style: GoogleFonts.battambang(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: locked
                          ? const Color(0xFFB0BEC5)
                          : const Color(0xFF1A202C),
                    ),
                  ),
                  Text(
                    letter.romanized.isNotEmpty
                        ? letter.romanized[0].toUpperCase() + letter.romanized.substring(1)
                        : '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: locked
                          ? const Color(0xFFCFD8DC)
                          : const Color(0xFF718096),
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (si) => Icon(
                      Icons.star_rounded,
                      size: 16.w,
                      color: (done && si < letter.starRating)
                          ? const Color(0xFFFFB300)
                          : locked
                              ? const Color(0xFFE0E0E0).withValues(alpha: 0.4)
                              : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // ── Arrow pointer ──
      final arrowX = labelOnLeft
          ? labelX + labelW - 2.w
          : labelX - 8.w;
      widgets.add(
        Positioned(
          left: arrowX,
          top: y - 6.h,
          child: CustomPaint(
            size: Size(14.w, 16.h),
            painter: _ArrowPainter(
              pointsRight: labelOnLeft,
              color: locked
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white,
            ),
          ),
        ),
      );

      // ── Node circle ──
      widgets.add(
        Positioned(
          left: x - _nodeSize / 2,
          top: y - _nodeSize / 2,
          child: GestureDetector(
            onTap: locked ? null : () => _openLetter(ri),
            child: SizedBox(
              width: _nodeSize,
              height: _nodeSize,
              child: curr
                  ? AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: _circle(letter, color, done, curr, locked),
                    )
                  : _circle(letter, color, done, curr, locked),
            ),
          ),
        ),
      );

      // ── Lesson number badge ──
      if (!locked) {
        widgets.add(
          Positioned(
            left: x + _nodeSize / 2 - 16.w,
            top: y - _nodeSize / 2 - 4.h,
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${letter.isTest ? "KT" : baiNum}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _circle(
    KhmerLetter letter,
    Color color,
    bool done,
    bool curr,
    bool locked,
  ) {
    // ── Test node ──
    if (letter.isTest) {
      final testColor = letter.testRange == '1-40'
          ? const Color(0xFFFF6B00) // Final test - orange
          : const Color(0xFF7C4DFF); // Regular test - purple

      if (locked) {
        return Container(
          width: _nodeSize,
          height: _nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFEDE7F6),
                const Color(0xFFD1C4E9),
              ],
            ),
            border: Border.all(color: const Color(0xFFB39DDB), width: 3.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9575CD).withValues(alpha: 0.3),
                blurRadius: 0,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Icon(Icons.lock_rounded, color: const Color(0xFF9575CD), size: 28.w),
        );
      }

      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(testColor, Colors.white, 0.25)!,
              testColor,
              Color.lerp(testColor, Colors.black, 0.15)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: Border.all(
            color: Color.lerp(testColor, Colors.white, 0.45)!,
            width: 3.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(testColor, Colors.black, 0.4)!.withValues(alpha: 0.5),
              blurRadius: 0,
              offset: Offset(0, 4.h),
            ),
            if (curr)
              BoxShadow(
                color: testColor.withValues(alpha: 0.5),
                blurRadius: 22,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Icon(
          letter.testRange == '1-40' ? Icons.emoji_events_rounded : Icons.quiz_rounded,
          color: Colors.white,
          size: 32.w,
        ),
      );
    }

    // ── Locked node ──
    if (locked) {
      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8EEF5),
              const Color(0xFFD0DAE8),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFBCC8D9),
            width: 3.w,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E9DB3).withValues(alpha: 0.3),
              blurRadius: 0,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Icon(Icons.lock_rounded, color: const Color(0xFF8E9DB3), size: 28.w),
      );
    }

    // ── Unlocked / Done node ──
    return Container(
      width: _nodeSize,
      height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 0.85,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.08)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.5)!,
          width: 4.w,
        ),
        boxShadow: [
          // 3D platform shadow
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.5)!.withValues(alpha: 0.45),
            blurRadius: 1,
            offset: Offset(0, 5.h),
          ),
          // Outer glow
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          // Strong glow for current
          if (curr)
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 24,
              spreadRadius: 6,
            ),
        ],
      ),
      child: Center(
        child: Text(
          letter.character,
          style: GoogleFonts.battambang(
            fontSize: 32.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLetter(int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LetterDetailScreen(initialIndex: idx)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

// ═══════════════════════════════════════════════
// MAP PAINTER — path + subtle decorations
// ═══════════════════════════════════════════════

class _MapPainter extends CustomPainter {
  final int count;
  final double width;
  final double Function(int, double) getX;
  final double Function(int) getY;
  final int doneCount;
  final double undoneStroke;
  final double shadowStroke;
  final double mainStroke;
  final double highlightStroke;

  _MapPainter({
    required this.count,
    required this.width,
    required this.getX,
    required this.getY,
    required this.doneCount,
    required this.undoneStroke,
    required this.shadowStroke,
    required this.mainStroke,
    required this.highlightStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    // Build full path
    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = getX(i, width);
      final y = getY(i);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = getX(i - 1, width);
        final py = getY(i - 1);
        path.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
      }
    }

    // Undone path — subtle
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC5D5E8)
        ..strokeWidth = undoneStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Done portion — blue gradient path
    if (doneCount > 1) {
      final dp = Path();
      final si = count - 1;
      final ei = count - doneCount;
      for (int i = si; i >= ei; i--) {
        final x = getX(i, width);
        final y = getY(i);
        if (i == si) {
          dp.moveTo(x, y);
        } else {
          final px = getX(i + 1, width);
          final py = getY(i + 1);
          dp.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
        }
      }

      // Shadow
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: 0.4)
          ..strokeWidth = shadowStroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Main
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF2979FF)
          ..strokeWidth = mainStroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Highlight
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF82B1FF).withValues(alpha: 0.6)
          ..strokeWidth = highlightStroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════
// ARROW PAINTER — speech bubble pointer
// ═══════════════════════════════════════════════

class _ArrowPainter extends CustomPainter {
  final bool pointsRight;
  final Color color;

  _ArrowPainter({required this.pointsRight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      // Card on left, arrow points right toward node
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      // Card on right, arrow points left toward node
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
