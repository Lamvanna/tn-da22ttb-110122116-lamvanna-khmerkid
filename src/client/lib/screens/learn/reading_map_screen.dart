import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/khmer_reading.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import 'reading_screen.dart';
import '../../repositories/progress_repository.dart';
import 'package:khmerkid/utils/app_haptics.dart';

/// Bản đồ học tập đọc tiếng Khmer dạng Zigzag Timeline - Đồng bộ 100% LetterMapView
class ReadingMapScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ReadingMapScreen({super.key, required this.onBack});

  @override
  State<ReadingMapScreen> createState() => _ReadingMapScreenState();
}

class _ReadingMapScreenState extends State<ReadingMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerReading> _items = KhmerReadingData.lessons;
  ScoreService? _score;

  double get _nodeSpacingY => 140.h;
  double get _topPadding => 80.h;
  double get _nodeSize => 78.w;

  int get _currentIdx {
    final idx = _items.indexWhere((l) => !l.isLearned);
    return idx == -1 ? _items.length - 1 : idx;
  }

  int get _doneCount => _items.where((l) => l.isLearned).length;

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
    _loadScore().then((_) => WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent()));
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    try {
      final progressMap = await ProgressRepository.instance.getProgressMap('reading');
      for (int i = 0; i < _items.length; i++) {
        final stars = progressMap[i] ?? 0;
        _items[i].starRating = stars;
        _items[i].isLearned = stars > 0;
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading reading progress: $e');
    }
  }

  void _scrollToCurrent() {
    final target = _currentIdx * _nodeSpacingY - 200.h;
    if (_scrollCtrl.hasClients) {
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _items.length * _nodeSpacingY + 200.h;

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
                      count: _items.length,
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

  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.learnHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: AppColors.headerDark.withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(children: [
        Positioned(right: -40.w, top: -30.h,
          child: Container(width: 120.w, height: 120.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25.w, bottom: -20.h,
          child: Container(width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 105.w, 32.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBack,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Flexible(child: Text(context.translate('learn.reading_khmer'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
            ]))),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4.h,
          right: 16.w,
          child: _buildHeaderStats(),
        ),
      ]),
    );
  }

  Widget _buildHeaderStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('image/sao.png', width: 14.w, height: 14.h, fit: BoxFit.contain),
              SizedBox(width: 4.w),
              Text('${_score?.totalStars ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('image/Lửa chuổi.png', width: 14.w, height: 14.h, fit: BoxFit.contain),
              SizedBox(width: 4.w),
              Text('${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];

    for (int i = 0; i < _items.length; i++) {
      final ri = _items.length - 1 - i;
      final item = _items[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = item.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = item.color;
      final baiNum = ri + 1;

      // Determine label position based on node horizontal position
      final isNodeOnRight = x > w / 2;
      final labelOnLeft = isNodeOnRight;

      // ── Label card ──
      final labelW = 110.w;
      final labelX = labelOnLeft
          ? x - _nodeSize / 2 - labelW - 10.w
          : x + _nodeSize / 2 + 10.w;
      final labelY = y - 48.h;

      widgets.add(
        Positioned(
          left: labelX,
          top: labelY,
          child: Container(
            width: labelW,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    context.translate('learn.lesson_n', args: {'number': baiNum}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: locked
                          ? const Color(0xFFB0BEC5)
                          : color,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  context.translate('reading_topics.topic_$baiNum'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.battambang(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: locked
                        ? const Color(0xFFB0BEC5)
                        : const Color(0xFF1A202C),
                  ),
                ),
                Text(
                  context.translate('reading_subtitles.topic_$baiNum'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: locked
                        ? const Color(0xFFCFD8DC)
                        : const Color(0xFF718096),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (si) => Icon(
                      Icons.star_rounded,
                      size: 14.w,
                      color: (done && si < item.starRating)
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
            onTap: locked ? null : () => _openLesson(ri),
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
                      child: _circle(baiNum, item, color, done, curr, locked),
                    )
                  : _circle(baiNum, item, color, done, curr, locked),
            ),
          ),
        ),
      );

    }

    return widgets;
  }

  Widget _circle(
    int baiNum,
    KhmerReading item,
    Color color,
    bool done,
    bool curr,
    bool locked,
  ) {
    // ── Locked node ──
    if (locked) {
      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8EEF5), Color(0xFFD0DAE8)],
          ),
          border: Border.all(color: const Color(0xFFBCC8D9), width: 3.w),
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
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.5)!.withValues(alpha: 0.45),
            blurRadius: 1,
            offset: Offset(0, 5.h),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
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
          '$baiNum',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
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

  void _openLesson(int idx) {
    AppHaptics.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen(initialIndex: idx),
      ),
    ).then((_) {
      if (mounted) {
        _loadScore();
        setState(() {});
      }
    });
  }
}

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

    // Undone path
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC5D5E8)
        ..strokeWidth = undoneStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Done portion
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
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
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
