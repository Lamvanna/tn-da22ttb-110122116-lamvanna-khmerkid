import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_writing.dart';
import '../../widgets/app_header.dart';
import '../../services/score_service.dart';
import '../../services/khmer_handwriting_service.dart';
import '../../services/handwriting_websocket_client.dart';
import 'dart:async';

/// Trang chi tiết tập viết — Canvas lớn với chữ mẫu mờ
class WritingDetailScreen extends StatefulWidget {
  final int initialIndex;
  const WritingDetailScreen({super.key, this.initialIndex = 0});
  @override
  State<WritingDetailScreen> createState() => _WritingDetailScreenState();
}

class _WritingDetailScreenState extends State<WritingDetailScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<KhmerWriting> _lessons = KhmerWritingData.lessons;
  final FlutterTts _tts = FlutterTts();
  late int _current;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  final List<List<StrokePoint>> _strokeTimestamps = [];
  List<StrokePoint> _currentStrokeTimestamped = [];
  int? _expectedStrokeCount;
  bool _showGuide = true;
  bool _showFeedback = false;
  List<StrokeSegment> _feedbackSegments = []; // Danh sách nét vẽ phản hồi cục bộ
  bool _isLoading = false;

  KhmerWriting get _lesson => _lessons[_current];
  int get _doneCount => _lessons.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _initTts();

    // Initialize Tier 1 (ML Kit)
    KhmerHandwritingService.instance.initialize().catchError((e) {
      debugPrint('[WritingDetailScreen] ML Kit init error: $e');
    });

    // Initialize Tier 2 (WebSocket)
    HandwritingWebSocketClient.instance.connect();

    _fetchCharacterInfo();
  }

  Future<void> _fetchCharacterInfo() async {
    try {
      final info = await HandwritingWebSocketClient.instance
          .getCharacterInfo(_lesson.character);
      if (info != null && mounted) {
        setState(() => _expectedStrokeCount = info.totalStrokes);
      }
    } catch (e) {
      debugPrint('[WritingDetailScreen] Character info fetch error: $e');
    }
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
    _strokeTimestamps.clear();
    _currentStrokeTimestamped.clear();
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
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text('Hãy viết chữ trước nhé! ✍️',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final targetChar = _lesson.character;

      // ── Tier 1: ML Kit on-device recognition ──────────────────
      bool mlPassed = false;
      String mlFeedback = 'Hãy thử viết lại nhé! 💪';

      try {
        final mlResult = await KhmerHandwritingService.instance.recognizeAndValidate(
          strokes: _strokeTimestamps,
          targetCharacter: targetChar,
          expectedStrokeCount: _expectedStrokeCount,
        );

        mlPassed = mlResult.isCorrect;
        mlFeedback = mlResult.message;
      } catch (e) {
        debugPrint('[WritingDetail] Tier 1 error: $e');
        mlPassed = true; // fallback
        mlFeedback = 'Viết tốt lắm! 👍';
      }

      bool finalPassed = false;
      double finalScore = 30.0;
      int stars = 0;
      String feedback = mlFeedback;

      // ── Tier 2: WebSocket backend geometric analysis ──────────
      StrokeAnalysisResult? backendResult;
      try {
        backendResult = await HandwritingWebSocketClient.instance.analyzeStrokes(
          strokes: _strokeTimestamps,
          targetCharacter: targetChar,
        );

        if (backendResult.success) {
          finalPassed = mlPassed && backendResult.passed;
          finalScore = finalPassed ? backendResult.similarityScore.toDouble() : 30.0;
          stars = finalPassed ? backendResult.stars : 0;
          feedback = finalPassed ? backendResult.feedback : (mlPassed ? backendResult.feedback : mlFeedback);
        } else {
          // Fallback if backend returned success=false
          finalPassed = mlPassed;
          finalScore = mlPassed ? 75.0 : 30.0;
          stars = mlPassed ? 2 : 0;
        }
      } catch (e) {
        debugPrint('[WritingDetail] Tier 2 error: $e');
        // Fallback on exception
        finalPassed = mlPassed;
        finalScore = mlPassed ? 75.0 : 30.0;
        stars = mlPassed ? 2 : 0;
      }

      // ── Build feedback segments ──────────────────────────────
      final errorIndex = (backendResult != null && backendResult.success)
          ? backendResult.errorStrokeIndex
          : -1;
      final feedbackSegments = <StrokeSegment>[];
      for (int i = 0; i < _strokes.length; i++) {
        final isError = (i == errorIndex);
        feedbackSegments.add(StrokeSegment(
          points: _strokes[i],
          color: isError ? Colors.red : Colors.green,
        ));
      }

      // ── Save progress via ScoreService ─────────────────────────
      try {
        final scoreService = await ScoreService.getInstance();
        await scoreService.completeWritingLesson(
          _current,
          stars,
          lessonId: null,
          strokes: _strokes,
          targetCharacter: targetChar,
          passed: finalPassed,
        );
      } catch (e) {
        debugPrint('[WritingDetail] Save score error: $e');
      }

      setState(() {
        _isLoading = false;
        _showFeedback = true;
        _feedbackSegments = feedbackSegments;
        if (finalPassed) {
          _lesson.isLearned = true;
          _lesson.starRating = stars;
        }
      });

      if (finalPassed) {
        _speak(targetChar);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(finalPassed ? Icons.check_circle_rounded : Icons.info_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              finalPassed
                  ? 'Hoàn thành "$targetChar" (${finalScore.round()}%) - $stars ⭐!\n$feedback'
                  : 'Chưa đạt! (${finalScore.round()}%) - Hãy sửa nét vẽ màu đỏ nhé.\n$feedback',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        backgroundColor: finalPassed ? AppColors.tertiary : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4)));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error saving writing progress: $e');
    }
  }

  void _next() {
    if (_current < _lessons.length - 1) {
      setState(() {
        _current++;
        _clearCanvas();
      });
      _fetchCharacterInfo();
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
      _fetchCharacterInfo();
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
          key: _canvasKey,
          onPanStart: (d) => setState(() {
            final now = DateTime.now().millisecondsSinceEpoch;
            _currentStroke = [d.localPosition];
            _currentStrokeTimestamped = [
              StrokePoint(
                x: d.localPosition.dx,
                y: d.localPosition.dy,
                t: now,
              ),
            ];
            _showFeedback = false; // Hide feedback when drawing
          }),
          onPanUpdate: (d) => setState(() {
            _currentStroke.add(d.localPosition);
            _currentStrokeTimestamped.add(
              StrokePoint(
                x: d.localPosition.dx,
                y: d.localPosition.dy,
                t: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }),
          onPanEnd: (_) => setState(() {
            if (_currentStroke.isNotEmpty) {
              _strokes.add(List.from(_currentStroke));
              _strokeTimestamps.add(List.from(_currentStrokeTimestamped));
              _currentStroke = [];
              _currentStrokeTimestamped = [];
            }
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

/// Lớp đoạn nét vẽ phản hồi cục bộ thay thế cho Tracing Service đã xóa
class StrokeSegment {
  final List<Offset> points;
  final Color color;
  const StrokeSegment({required this.points, required this.color});
}
