import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_writing.dart';
import 'writing_detail_screen.dart';
import '../../services/storage_service.dart';
import '../../repositories/progress_repository.dart';

/// Bản đồ tập viết Khmer — Premium learning path (zigzag)
class WritingMapScreen extends StatefulWidget {
  const WritingMapScreen({super.key});
  @override
  State<WritingMapScreen> createState() => _WritingMapScreenState();
}

class _WritingMapScreenState extends State<WritingMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerWriting> _lessons = KhmerWritingData.lessons;

  static const double _nodeSpacingY = 100.0;
  static const double _topPadding = 28.0;
  static const double _nodeSize = 62.0;

  int get _currentIdx {
    final idx = _lessons.indexWhere((l) => !l.isLearned);
    return idx == -1 ? _lessons.length - 1 : idx;
  }

  int get _doneCount => _lessons.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    _loadProgress().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    });
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await ProgressRepository.instance.getProgressMap('writing');
      if (mounted) {
        setState(() {
          for (int i = 0; i < _lessons.length; i++) {
            if (progress.containsKey(i)) {
              _lessons[i].isLearned = true;
              _lessons[i].starRating = progress[i]!;
            } else {
              _lessons[i].isLearned = false;
              _lessons[i].starRating = 0;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading writing progress: $e');
    }
  }

  void _scrollToCurrent() {
    final target = _currentIdx * _nodeSpacingY - 200;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18;
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  Color _nodeColor(int idx) {
    const colors = [
      AppColors.tertiary, AppColors.primary, AppColors.coral,
      AppColors.secondary, AppColors.violet,
    ];
    return colors[(idx ~/ 5) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _lessons.length * _nodeSpacingY + 120;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
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
                  painter: _WritingMapPainter(
                    count: _lessons.length,
                    width: w,
                    getX: _nodeX,
                    getY: _nodeY,
                    doneCount: _doneCount),
                  child: Stack(children: _buildAllNodes(w)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final progress = _doneCount / _lessons.length;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
          blurRadius: 20, offset: const Offset(0, 6))]),
      child: Stack(children: [
        Positioned(right: -40, top: -30,
          child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25, bottom: -20,
          child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tập viết Khmer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 1),
                    Text('$_doneCount/${_lessons.length} đã hoàn thành',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8))),
                  ],
                )),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('✍️', style: TextStyle(fontSize: 20)))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4)),
                  child: Stack(children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0F0E0)]),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 6)])))]),
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('$pct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── ALL NODES ───
  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];

    for (int i = 0; i < _lessons.length; i++) {
      final ri = _lessons.length - 1 - i;
      final lesson = _lessons[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = lesson.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = _nodeColor(ri);

      widgets.add(
        Positioned(
          left: x - _nodeSize / 2,
          top: y - _nodeSize / 2,
          child: GestureDetector(
            onTap: locked ? null : () => _openLesson(ri),
            child: SizedBox(
              width: _nodeSize,
              height: _nodeSize + (done ? 20 : 0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                curr
                  ? AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value, child: child),
                      child: _circle(lesson, color, done, curr, locked))
                  : _circle(lesson, color, done, curr, locked),
                if (done && lesson.starRating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        min(lesson.starRating, 3),
                        (_) => Icon(Icons.star_rounded, color: AppColors.secondary, size: 13)))),
              ]),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _circle(KhmerWriting lesson, Color color, bool done, bool curr, bool locked) {
    if (locked) {
      return Container(
        width: _nodeSize, height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 3)),
        child: Icon(Icons.lock_rounded, color: AppColors.textHint, size: 22));
    }

    return Container(
      width: _nodeSize, height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.20)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!],
          stops: const [0.0, 0.45, 1.0]),
        border: Border.all(color: Color.lerp(color, Colors.white, 0.4)!, width: 3),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
            blurRadius: 0, offset: const Offset(0, 4)),
          if (curr) BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 18, spreadRadius: 2),
        ]),
      child: Center(
        child: Text(lesson.character,
          style: GoogleFonts.battambang(
            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
            height: 1.2,
            shadows: [Shadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 2, offset: const Offset(0, 1))]))),
    );
  }

  void _openLesson(int idx) {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => WritingDetailScreen(initialIndex: idx)),
    ).then((_) {
      if (mounted) {
        _loadProgress();
      }
    });
  }
}

// ═══════════════════════════════════════════════
// MAP PAINTER
// ═══════════════════════════════════════════════

class _WritingMapPainter extends CustomPainter {
  final int count;
  final double width;
  final double Function(int, double) getX;
  final double Function(int) getY;
  final int doneCount;

  _WritingMapPainter({
    required this.count, required this.width,
    required this.getX, required this.getY,
    required this.doneCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = getX(i, width);
      final y = getY(i);
      if (i == 0) { path.moveTo(x, y); }
      else {
        final px = getX(i - 1, width);
        final py = getY(i - 1);
        path.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
      }
    }

    canvas.drawPath(path, Paint()
      ..color = AppColors.surfaceContainerHighest
      ..strokeWidth = 10 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);

    if (doneCount > 1) {
      final dp = Path();
      final si = count - 1;
      final ei = count - doneCount;
      for (int i = si; i >= ei; i--) {
        final x = getX(i, width);
        final y = getY(i);
        if (i == si) { dp.moveTo(x, y); }
        else {
          final px = getX(i + 1, width);
          final py = getY(i + 1);
          dp.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
        }
      }

      canvas.drawPath(dp, Paint()
        ..color = AppColors.tertiary.withValues(alpha: 0.3)
        ..strokeWidth = 12 ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()
        ..color = AppColors.tertiary
        ..strokeWidth = 8 ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()
        ..color = AppColors.tertiaryLight.withValues(alpha: 0.5)
        ..strokeWidth = 3 ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
