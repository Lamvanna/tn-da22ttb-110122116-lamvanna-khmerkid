import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_writing.dart';
import '../../widgets/app_header.dart';
import '../../services/score_service.dart';
import '../../services/handwriting_tracing_service.dart';

/// Trang chi tiết tập viết — Canvas lớn với chữ mẫu mờ
class WritingDetailScreen extends StatefulWidget {
  final int initialIndex;
  const WritingDetailScreen({super.key, this.initialIndex = 0});
  @override
  State<WritingDetailScreen> createState() => _WritingDetailScreenState();
}

class _WritingDetailScreenState extends State<WritingDetailScreen> {
  final List<KhmerWriting> _lessons = KhmerWritingData.lessons;
  final FlutterTts _tts = FlutterTts();
  late int _current;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _showGuide = true;
  bool _showFeedback = false;
  List<dynamic> _feedbackSegments = []; // StrokeSegment list from tracing service

  KhmerWriting get _lesson => _lessons[_current];
  int get _doneCount => _lessons.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
    await _tts.setSpeechRate(0.35);
    await _tts.setVolume(1.0);
  }

  void _speak(String text) => _tts.speak(text);

  void _clearCanvas() => setState(() {
    _strokes.clear();
    _currentStroke.clear();
    _showFeedback = false;
    _feedbackSegments.clear();
  });

  double get _guideShiftY {
    final height = 320.0; // Fixed canvas height in WritingDetailScreen is 320
    
    final isBelow = _lesson.character.contains('ុ') ||
        _lesson.character.contains('ូ') ||
        _lesson.character.contains('ួ') ||
        _lesson.character.contains('្');
    if (isBelow) return -height * 0.08;
    
    final isAbove = _lesson.character.contains('ិ') ||
        _lesson.character.contains('ី') ||
        _lesson.character.contains('ឹ') ||
        _lesson.character.contains('ឺ') ||
        _lesson.character.contains('ំ') ||
        _lesson.character.contains('៏');
    if (isAbove) return height * 0.06;
    
    return 0.0;
  }

  Future<void> _markDone() async {
    final canvasBox = context.findRenderObject() as RenderBox?;
    final size = canvasBox?.size ?? const Size(300, 300);

    // Get tracing result with visual feedback
    final tracingResult = HandwritingTracingService.instance.scoreTracing(
      character: _lesson.character,
      userStrokes: _strokes,
      canvasSize: size,
    );

    // Show visual feedback with colored strokes
    setState(() {
      _showFeedback = true;
      _feedbackSegments = tracingResult.visualFeedback;
    });

    if (!tracingResult.passed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Chưa đạt! Điểm viết: ${tracingResult.finalScore.round()}%',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            Text('Nét đúng: ${tracingResult.insideCoverage.round()}% | Nét sai: ${tracingResult.outsideCoverage.round()}%',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
            const SizedBox(height: 4),
            ...tracingResult.tips.map((tip) => Text('• $tip',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)))),
          ],
        ),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5)));
      return;
    }

    setState(() {
      _lesson.isLearned = true;
      _lesson.starRating = tracingResult.stars;
    });

    try {
      final scoreService = await ScoreService.getInstance();
      await scoreService.completeWritingLesson(_current, tracingResult.stars, lessonId: null);
    } catch (e) {
      debugPrint('Error saving writing progress: $e');
    }

    _speak(_lesson.character);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Hoàn thành "${_lesson.character}" (${tracingResult.finalScore.round()}%) - ${tracingResult.stars} ⭐!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
      backgroundColor: AppColors.tertiary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3)));
  }

  void _next() {
    if (_current < _lessons.length - 1) {
      setState(() {
        _current++;
        _clearCanvas();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _clearCanvas();
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _lessons.isEmpty ? 0.0 : (_current + 1) / _lessons.length;
    final typeLabel = _lesson.type == 'consonant' ? 'Phụ âm'
      : _lesson.type == 'vowel' ? 'Nguyên âm' : 'Chữ ghép';
    final typeColor = _lesson.type == 'consonant' ? AppColors.primary
      : _lesson.type == 'vowel' ? AppColors.coral : AppColors.tertiary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AppHeader(
          title: '✍️ Tập viết',
          subtitle: '$_doneCount/${_lessons.length} bài đã học',
          gradientColors: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          onBack: () => Navigator.pop(context),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)),
            child: Text('${_current + 1}/${_lessons.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(children: [
            Row(children: [
              Text('Bài ${_current + 1}', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
            ]),
            const SizedBox(height: 6),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tertiary, AppColors.tertiaryLight]),
                    borderRadius: BorderRadius.circular(4))))),
          ]),
        ),
        // Content
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(children: [
            // Character info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16, offset: const Offset(0, 4))]),
              child: Row(children: [
                // Character display
                GestureDetector(
                  onTap: () => _speak(_lesson.character),
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color.lerp(typeColor, Colors.white, 0.2)!, typeColor]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Center(child: Text(_lesson.character,
                      style: GoogleFonts.battambang(
                        fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(typeLabel, style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w700, color: typeColor))),
                      const SizedBox(width: 8),
                      Text(_lesson.romanized, style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Viết chữ "${_lesson.character}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _speak(_lesson.character),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.volume_up_rounded, color: typeColor, size: 16),
                        const SizedBox(width: 4),
                        Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: typeColor)),
                      ]),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 16),
            // Hint card
            if (_lesson.hint.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.15))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.lightbulb_rounded, color: AppColors.tertiary, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hướng dẫn viết', style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tertiary)),
                      const SizedBox(height: 2),
                      Text(_lesson.hint, style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    ],
                  )),
                ]),
              ),
            const SizedBox(height: 16),
            // Writing canvas
            _buildCanvas(typeColor),
            const SizedBox(height: 16),
            // Action buttons
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Xóa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.coral.withValues(alpha: 0.3))))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => setState(() => _showGuide = !_showGuide),
                icon: Icon(_showGuide ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                label: Text(_showGuide ? 'Ẩn mẫu' : 'Hiện mẫu',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.surfaceContainerHighest)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: _strokes.isEmpty ? null : _markDone,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Xong', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
            const SizedBox(height: 16),
            // Nav buttons
            Row(children: [
              if (_current > 0) Expanded(child: OutlinedButton.icon(
                onPressed: _prev,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('Bài trước', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.surfaceContainerHighest)))),
              if (_current > 0 && _current < _lessons.length - 1) const SizedBox(width: 12),
              if (_current < _lessons.length - 1) Expanded(child: ElevatedButton.icon(
                onPressed: _next,
                icon: Text('Bài tiếp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                label: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          ]),
        )),
      ]),
    );
  }

  // ═══════════ WRITING CANVAS ═══════════
  Widget _buildCanvas(Color accentColor) {
    return Container(
      width: double.infinity,
      height: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16, offset: const Offset(0, 4))]),
      child: Stack(children: [
        // Grid lines
        CustomPaint(
          size: const Size(double.infinity, 320),
          painter: _GridPainter()),
        // Guide character
        if (_showGuide)
          Center(
            child: Transform.translate(
              offset: Offset(0, _guideShiftY),
              child: Text(
                _lesson.character,
                style: GoogleFonts.battambang(
                  fontSize: (_lesson.character.contains('◌') ||
                          _lesson.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3))
                      ? 155
                      : 180,
                  fontWeight: FontWeight.w700,
                  color: accentColor.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        // Drawing area
        GestureDetector(
          onPanStart: (d) => setState(() {
            _currentStroke = [d.localPosition];
            _showFeedback = false; // Hide feedback when drawing
          }),
          onPanUpdate: (d) => setState(() => _currentStroke.add(d.localPosition)),
          onPanEnd: (_) => setState(() {
            _strokes.add(List.from(_currentStroke));
            _currentStroke = [];
          }),
          child: CustomPaint(
            size: const Size(double.infinity, 320),
            painter: _StrokePainter(_strokes, _currentStroke, accentColor, _showFeedback, _feedbackSegments))),
        // Top-left label
        Positioned(top: 10, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6)),
            child: Text('Vẽ ở đây',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)))),
        // Stroke count
        if (_strokes.isNotEmpty)
          Positioned(top: 10, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6)),
              child: Text('${_strokes.length} nét',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint)))),
      ]),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Hoàn thành!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Bạn đã hoàn thành tất cả bài tập viết!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Quay về',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)))),
          ]),
        ),
      ),
    );
  }
}

// ═══════════ GRID PAINTER ═══════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHighest.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Horizontal center
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2), paint);
    // Vertical center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height), paint);

    // Dashed border guide
    final dashPaint = Paint()
      ..color = AppColors.surfaceContainerHighest.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    // Quarter lines
    canvas.drawLine(
      Offset(0, size.height / 4),
      Offset(size.width, size.height / 4), dashPaint);
    canvas.drawLine(
      Offset(0, size.height * 3 / 4),
      Offset(size.width, size.height * 3 / 4), dashPaint);
    canvas.drawLine(
      Offset(size.width / 4, 0),
      Offset(size.width / 4, size.height), dashPaint);
    canvas.drawLine(
      Offset(size.width * 3 / 4, 0),
      Offset(size.width * 3 / 4, size.height), dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════ STROKE PAINTER ═══════════
class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color color;
  final bool showFeedback;
  final List<dynamic> feedbackSegments;

  _StrokePainter(this.strokes, this.current, this.color, this.showFeedback, this.feedbackSegments);

  @override
  void paint(Canvas canvas, Size size) {
    if (showFeedback && feedbackSegments.isNotEmpty) {
      // Draw feedback with colored segments
      for (final segment in feedbackSegments) {
        final points = segment.points as List<Offset>;
        final segmentColor = segment.color as Color;
        final paint = Paint()
          ..color = segmentColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        _draw(canvas, points, paint);
      }
    } else {
      // Draw normal strokes
      final paint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final s in strokes) { _draw(canvas, s, paint); }
      _draw(canvas, current, paint);
    }
  }

  void _draw(Canvas canvas, List<Offset> pts, Paint p) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
