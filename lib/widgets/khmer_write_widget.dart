import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/scoring_service.dart';
import '../services/score_service.dart';
import '../data/stroke_guide_data.dart';
// import '../data/khmer_stroke_templates.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/khmer_handwriting_service.dart';
import '../services/handwriting_websocket_client.dart';


/// ════════════════════════════════════════════════════════════════════
/// KhmerWriteWidget — Widget VIẾT tái sử dụng
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Chữ mẫu mờ phía sau canvas
///   • Grid guide lines
///   • Stroke guide arrows (từ StrokeGuideData)
///   • Drawing canvas (GestureDetector + CustomPaint)
///   • Toolbar: Xóa / Kiểm tra / Gợi ý
///   • OCR scoring (nếu available) hoặc stroke-based fallback
///   • Animation khi đúng (bounce + glow)
///   • Điểm số hiển thị
/// ════════════════════════════════════════════════════════════════════

class KhmerWriteWidget extends StatefulWidget {
  final String character;
  final String label;
  final VoidCallback? onComplete;
  final bool showStrokeGuide;
  final bool enableOcr;
  final Color accentColor;
  final Color accentColorDark;
  final Color surfaceColor;
  final int? minPointsRequired;
  final int? minStrokesRequired;
  final double? passThreshold;
  final double? outsideThreshold;
  final double? toleranceRadius;
  final bool isCompound;

  const KhmerWriteWidget({
    super.key,
    required this.character,
    this.label = 'chữ',
    this.onComplete,
    this.showStrokeGuide = true,
    this.enableOcr = false,
    this.accentColor = const Color(0xFF3D7FCC),
    this.accentColorDark = const Color(0xFF24559A),
    this.surfaceColor = const Color(0xFFEAF2FC),
    this.minPointsRequired,
    this.minStrokesRequired,
    this.passThreshold,
    this.outsideThreshold,
    this.toleranceRadius,
    this.isCompound = false,
  });

  @override
  State<KhmerWriteWidget> createState() => _KhmerWriteWidgetState();
}

class _KhmerWriteWidgetState extends State<KhmerWriteWidget>
    with SingleTickerProviderStateMixin {
  bool get _isCompound => widget.isCompound || widget.character.trim().replaceAll('\u25CC', '').length > 1;

  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  final List<List<StrokePoint>> _strokeTimestamps = [];
  List<StrokePoint> _currentTimestamped = [];

  bool? _passed;
  bool _showHint = false;
  WritingResult? _result;
  RecognitionResult? _recResult;
  StrokeAnalysisResult? _backendResult;
  StreamSubscription<StrokeAnalysisResult>? _backendSub;
  int? _expectedStrokeCount;

  bool _checking = false;
  final GlobalKey _canvasKey = GlobalKey();

  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Initialize Tier 1 (ML Kit)
    KhmerHandwritingService.instance.initialize().catchError((e) {
      debugPrint('[KhmerWriteWidget] ML Kit init error: $e');
    });

    // Initialize Tier 2 (WebSocket)
    final wsClient = HandwritingWebSocketClient.instance;
    wsClient.connect();

    _backendSub = wsClient.resultStream.listen((result) {
      if (mounted) {
        setState(() => _backendResult = result);
      }
    });

    _fetchCharacterInfo();
  }

  Future<void> _fetchCharacterInfo() async {
    try {
      final info = await HandwritingWebSocketClient.instance
          .getCharacterInfo(widget.character);
      if (info != null && mounted) {
        setState(() => _expectedStrokeCount = info.totalStrokes);
      }
    } catch (e) {
      debugPrint('[KhmerWriteWidget] Character info fetch error: $e');
    }
  }

  @override
  void dispose() {
    _backendSub?.cancel();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
        _strokes.clear();
        _strokeTimestamps.clear();
        _current = [];
        _currentTimestamped = [];
        _passed = null;
        _result = null;
        _recResult = null;
        _backendResult = null;
      });

  Future<void> _check() async {
    if (_checking || _strokes.isEmpty) return;
    setState(() => _checking = true);

    final targetChar = widget.character;

    try {
      // ── Tier 1: ML Kit on-device recognition ──────────────────
      bool isTier1Correct = false;
      bool finalPassed = false;
      double finalScore = 0;
      int finalStars = 0;
      String finalFeedback = 'Hãy thử viết lại nhé! 💪';
      List<String> finalTips = [];

      final bool isVowel = widget.character.contains('◌') ||
          widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3);

      try {
        final mlResult = await KhmerHandwritingService.instance
            .recognizeAndValidate(
          strokes: _strokeTimestamps,
          targetCharacter: targetChar,
          expectedStrokeCount: _expectedStrokeCount,
        );

        if (mlResult.isCorrect) {
          isTier1Correct = true;
          finalPassed = true;
          finalScore = 85.0; // Base score — refined by Tier 2
          finalStars = 2;
          finalFeedback = mlResult.message;
        } else {
          if (mlResult.rejectionReason == RejectionReason.strokeCountMismatch) {
            finalTips.add('Kiểm tra lại số nét viết nhé!');
          }
          if (mlResult.rejectionReason == RejectionReason.notInTopThree) {
            finalTips.add('Quan sát mẫu chữ rồi viết lại cho giống nhé!');
          }
        }

        debugPrint(
          '[KhmerWriteWidget] Tier 1 result: isCorrect=$isTier1Correct, '
          'recognized=${mlResult.recognizedCharacter}, '
          'confidence=${mlResult.confidence}',
        );
      } catch (e) {
        debugPrint('[KhmerWriteWidget] ML Kit error: $e');
      }

      // ── Tier 2: Send to backend for geometric analysis ────────
      // We await the result synchronously to get the definitive evaluation
      try {
        final backendRes = await HandwritingWebSocketClient.instance.analyzeStrokes(
          strokes: _strokeTimestamps,
          targetCharacter: targetChar,
        );
        _backendResult = backendRes;

        if (backendRes.success) {
          if (isTier1Correct) {
            // Tier 1 already passed. Use backend results to refine score/stars.
            finalScore = backendRes.similarityScore.toDouble();
            finalStars = backendRes.stars;
            finalFeedback = backendRes.feedback;
            finalPassed = backendRes.passed;
          } else {
            if (isVowel || _isCompound) {
              // Standalone combining vowels and compound characters relax Tier 1 (ML Kit), so we rely 100% on Tier 2.
              finalPassed = backendRes.passed;
              finalScore = backendRes.similarityScore.toDouble();
              finalStars = backendRes.stars;
              finalFeedback = backendRes.feedback;
            } else {
              // Consonants require BOTH Tier 1 and Tier 2 to pass
              finalPassed = false;
              finalScore = backendRes.similarityScore.toDouble();
              finalStars = 0;
              finalFeedback = backendRes.feedback;
            }
          }
        } else {
          // If Tier 2 fails to analyze properly, default to failed unless Tier 1 was correct
          if (!isTier1Correct) {
            finalPassed = false;
            finalScore = 30.0;
            finalStars = 0;
            finalFeedback = backendRes.feedback.isNotEmpty
                ? backendRes.feedback
                : 'Nét vẽ chưa đúng, con thử viết lại nhé! 💪';
          }
        }
      } catch (e) {
        debugPrint('[KhmerWriteWidget] Tier 2 error: $e');
        if (!isTier1Correct) {
          finalPassed = false;
          finalScore = 30.0;
          finalStars = 0;
          finalFeedback = 'Lỗi kết nối máy chủ phân tích. Hãy thử lại!';
        }
      }

      // ── Save progress via ScoreService ─────────────────────────
      try {
        final scoreService = await ScoreService.getInstance();
        await scoreService.completeWritingLesson(
          0, // dummy index
          finalStars,
          lessonId: null,
          strokes: _strokes,
          targetCharacter: targetChar,
          passed: finalPassed,
        );
      } catch (e) {
        debugPrint('[KhmerWriteWidget] Score save error: $e');
      }

      // ── Update UI ──────────────────────────────────────────────
      final writingResult = WritingResult(
        score: finalScore.round(),
        passed: finalPassed,
        stars: finalStars,
        feedback: finalFeedback,
      );

      setState(() {
        _recResult = RecognitionResult(
          finalScore: finalScore,
          passed: finalPassed,
          shapeScore: finalScore,
          strokeScore: finalScore,
          directionScore: finalScore,
          feedback: finalFeedback,
          tips: finalTips,
          stars: finalStars,
        );
        _result = writingResult;
        _passed = finalPassed;
      });

      if (finalPassed) {
        _bounceCtrl.forward(from: 0);
        widget.onComplete?.call();
      }
    } catch (e) {
      debugPrint('[KhmerWriteWidget] Check error: $e');
      setState(() => _passed = false);
    } finally {
      setState(() => _checking = false);
    }
  }

  double get _guideFontSize {
    final bool isStandaloneMark = widget.character.contains('◌') ||
        (widget.character.length == 1 &&
            widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3));
    return isStandaloneMark ? 220.sp : 260.sp;
  }

  double _getGuideShiftY(double height) {
    final bool isStandaloneMark = widget.character.contains('◌') ||
        (widget.character.length == 1 &&
            widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3));
    if (!isStandaloneMark) return 0.0;
    
    final isBelow = widget.character.contains('ុ') ||
        widget.character.contains('ូ') ||
        widget.character.contains('ួ') ||
        widget.character.contains('្');
    if (isBelow) return -height * 0.08;
    
    final isAbove = widget.character.contains('ិ') ||
        widget.character.contains('ី') ||
        widget.character.contains('ឹ') ||
        widget.character.contains('ឺ') ||
        widget.character.contains('ំ') ||
        widget.character.contains('៏');
    if (isAbove) return height * 0.06;
    
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isVowel = widget.character.contains('◌') ||
        widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3);
    final hasValidBackend = _backendResult != null && _backendResult!.success;
    final displayPassed = hasValidBackend 
        ? (isVowel ? _backendResult!.passed : (_backendResult!.passed && (_passed ?? false)))
        : (_passed ?? false);

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showHint ? Icons.lightbulb_rounded : Icons.edit_rounded,
                color: _showHint
                    ? AppColors.tertiary
                    : widget.accentColor,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                _showHint ? 'Gợi ý viết ${widget.label}' : 'Viết ${widget.label}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: _showHint
                      ? AppColors.tertiaryDark
                      : widget.accentColorDark,
                ),
              ),
            ],
          ),
        ),

        // ── Canvas area ──
        Expanded(
          child: _showHint ? _buildHintPage() : _buildCanvas(),
        ),

        SizedBox(height: 4.h),

        // ── Toolbar ──
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Row(
            children: [
              // Xóa
              Expanded(
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 16.sp, color: AppColors.textHint),
                        SizedBox(width: 4.w),
                        Text(
                          'Xóa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Kiểm tra
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _strokes.isNotEmpty
                      ? (_passed != null ? _clear : _check)
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      gradient: _passed == null
                          ? LinearGradient(colors: [
                              widget.accentColor,
                              widget.accentColorDark,
                            ])
                          : displayPassed
                              ? const LinearGradient(colors: [
                                  AppColors.tertiary,
                                  AppColors.tertiaryDark,
                                ])
                              : const LinearGradient(colors: [
                                  AppColors.coral,
                                  AppColors.coralDark,
                                ]),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: (_passed == null
                                  ? widget.accentColor
                                  : displayPassed
                                      ? AppColors.tertiary
                                      : AppColors.coral)
                              .withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_checking)
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          Icon(
                            _passed == null
                                ? Icons.check_circle_outline_rounded
                                : displayPassed
                                    ? Icons.celebration_rounded
                                    : Icons.refresh_rounded,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        SizedBox(width: 4.w),
                        Text(
                          _checking
                              ? 'Đang chấm...'
                              : _passed == null
                                  ? 'Kiểm tra'
                                  : displayPassed
                                      ? 'Tuyệt vời! 🎉'
                                      : 'Thử lại',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Gợi ý
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showHint = !_showHint),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: _showHint
                          ? AppColors.tertiarySurface
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: _showHint
                            ? AppColors.tertiary.withValues(alpha: 0.3)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16.sp,
                          color: _showHint
                              ? AppColors.tertiaryDark
                              : AppColors.textHint,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Gợi ý',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _showHint
                                ? AppColors.tertiaryDark
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintPage() {
    final strokeData = StrokeGuideData.getStrokes(widget.character);
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: 0.3),
                width: 2.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _GuideLinePainterWidget(),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Transform.translate(
                        offset: Offset(0, _getGuideShiftY(height)),
                        child: Text(
                          widget.character,
                          style: GoogleFonts.battambang(
                            fontSize: _guideFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiary.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showStrokeGuide)
                    CustomPaint(
                      size: Size.infinite,
                      painter: _StrokeGuidePainterWidget(strokeData),
                    ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final bool isVowel = widget.character.contains('◌') ||
              widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3);
          final hasValidBackend = _backendResult != null && _backendResult!.success;
          final displayPassed = hasValidBackend 
              ? ((isVowel || _isCompound) ? _backendResult!.passed : (_backendResult!.passed && (_passed ?? false)))
              : (_passed ?? false);
          return Container(
            key: _canvasKey,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _passed == null
                    ? const Color(0xFFD7CCC8)
                    : displayPassed
                        ? AppColors.tertiary
                        : AppColors.coral,
                width: 2.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Stack(
                children: [
                  // Grid
                  CustomPaint(
                    size: Size.infinite,
                    painter: _GuideLinePainterWidget(),
                  ),
                  // Guide letter (very light)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Transform.translate(
                        offset: Offset(0, _getGuideShiftY(height)),
                        child: Text(
                          widget.character,
                          style: GoogleFonts.battambang(
                            fontSize: _guideFontSize,
                            fontWeight: FontWeight.w300,
                            color: widget.accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
              // Drawing surface
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => setState(() {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  _current = [d.localPosition];
                  _currentTimestamped = [
                    StrokePoint(
                      x: d.localPosition.dx,
                      y: d.localPosition.dy,
                      t: now,
                    ),
                  ];
                  _passed = null;
                  _result = null;
                  _recResult = null;
                  _backendResult = null;
                }),
                onPanUpdate: (d) => setState(() {
                  _current.add(d.localPosition);
                  _currentTimestamped.add(
                    StrokePoint(
                      x: d.localPosition.dx,
                      y: d.localPosition.dy,
                      t: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                }),
                onPanEnd: (_) => setState(() {
                  if (_current.isNotEmpty) {
                    _strokes.add(List.from(_current));
                    _strokeTimestamps.add(List.from(_currentTimestamped));
                    _current = [];
                    _currentTimestamped = [];
                  }
                }),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _StrokePainterWidget(_strokes, _current),
                  ),
                ),
              ),
              // Floating Result Banner inside the Stack
              if (_result != null && _passed != null)
                Positioned(
                  left: 12.w,
                  right: 12.w,
                  bottom: 12.h,
                  child: Builder(
                    builder: (context) {
                       final bool isVowel = widget.character.contains('◌') ||
                           widget.character.runes.any((r) => r >= 0x17B6 && r <= 0x17D3);
                       final hasValidBackend = _backendResult != null && _backendResult!.success;
                       final displayPassed = hasValidBackend 
                           ? ((isVowel || _isCompound) ? _backendResult!.passed : (_backendResult!.passed && _passed!))
                           : _passed!;
                      final displayScore = hasValidBackend ? (displayPassed ? _backendResult!.similarityScore.toDouble() : 30.0) : _result!.score;
                      final displayStars = hasValidBackend ? (displayPassed ? _backendResult!.stars : 0) : _result!.stars;
                      final displayFeedback = hasValidBackend ? (displayPassed ? _backendResult!.feedback : (_passed! ? _backendResult!.feedback : _result!.feedback)) : _result!.feedback;

                      return AnimatedBuilder(
                        animation: _bounceCtrl,
                        builder: (context, _) => Transform.scale(
                          scale: displayPassed
                              ? 1.0 + 0.05 * math.sin(_bounceCtrl.value * math.pi)
                              : 1.0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: displayPassed
                                  ? AppColors.tertiarySurface
                                  : AppColors.coralSurface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: displayPassed
                                    ? AppColors.tertiary.withValues(alpha: 0.35)
                                    : AppColors.coral.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      displayPassed ? '🎉' : '😅',
                                      style: TextStyle(fontSize: 18.sp),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        displayPassed
                                            ? 'Tuyệt vời! $displayScore%'
                                            : 'Chưa đạt! $displayScore%',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                          color: displayPassed
                                              ? AppColors.tertiaryDark
                                              : AppColors.coralDark,
                                        ),
                                      ),
                                    ),
                                    if (displayPassed) ...[
                                      SizedBox(width: 4.w),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          3,
                                          (i) => Icon(
                                            i < displayStars
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 18.w,
                                            color: i < displayStars
                                                ? AppColors.secondary
                                                : AppColors.surfaceContainerHighest,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Divider(
                                  color: (displayPassed ? AppColors.tertiary : AppColors.coral).withValues(alpha: 0.15),
                                  height: 1.h,
                                ),
                                SizedBox(height: 6.h),
                                if (hasValidBackend) ...[
                                  // Detailed Tier 2 Geometric Analysis Results
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _backendResult!.passed
                                            ? Icons.check_circle_rounded
                                            : Icons.info_rounded,
                                        size: 14.w,
                                        color: _backendResult!.passed
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          displayFeedback,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_backendResult!.errors.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Gợi ý sửa nét:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.coralDark,
                                      ),
                                    ),
                                    ..._backendResult!.errors.map((error) => Padding(
                                      padding: EdgeInsets.only(left: 4.w, top: 2.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              error,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ] else if (_recResult != null) ...[
                                  // Fallback to local Tier 1 feedback while waiting
                                  ..._recResult!.feedback.split('\n').map((line) {
                                    final isCorrect = line.startsWith('✓');
                                    final isIncorrect = line.startsWith('✗');
                                    final isWarning = line.startsWith('△');
                                    final hasPrefix = isCorrect || isIncorrect || isWarning;
                                    final displayLine = hasPrefix ? line.substring(2) : line;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 2.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            isCorrect
                                                ? Icons.check_circle_rounded
                                                : isIncorrect
                                                    ? Icons.cancel_rounded
                                                    : Icons.info_rounded,
                                            size: 14.w,
                                            color: isCorrect
                                                ? Colors.green[700]
                                                : isIncorrect
                                                    ? Colors.red[700]
                                                    : Colors.orange[700],
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              displayLine,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (!_passed! && _recResult!.tips.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Gợi ý sửa:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.coralDark,
                                      ),
                                    ),
                                    ..._recResult!.tips.map((tip) => Padding(
                                      padding: EdgeInsets.only(left: 4.w, top: 2.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.coral,
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ] else ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    _result!.feedback,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: displayPassed
                                          ? AppColors.tertiaryDark
                                          : AppColors.coralDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
            ],
          ),
        ),
      );
    }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS (scoped to this widget file)
// ═══════════════════════════════════════════════════════════════

class _GuideLinePainterWidget extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;
    const cols = 6;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).ceil();
    for (int i = 1; i < cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int j = 1; j < rows; j++) {
      final y = j * cellW;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StrokePainterWidget extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _StrokePainterWidget(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final donePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s[0].dx, s[0].dy);
      for (int i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, donePaint);
    }

    if (current.length >= 2) {
      final activePaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (int i = 1; i < current.length; i++) {
        path.lineTo(current[i].dx, current[i].dy);
      }
      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainterWidget old) => true;
}

class _StrokeGuidePainterWidget extends CustomPainter {
  final List<List<double>> strokes;
  _StrokeGuidePainterWidget(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final s in strokes) {
      final num = s[0].toInt();
      final px = s[1] * size.width;
      final py = s[2] * size.height;
      final angleDeg = s[3];
      final angleRad = angleDeg * math.pi / 180;

      final r = 18.0;
      final startAngle = angleRad - 0.8;
      final sweepAngle = 1.6;

      final rect = Rect.fromCircle(center: Offset(px, py), radius: r);
      canvas.drawArc(rect, startAngle, sweepAngle, false, arrowPaint);

      final endAngle = startAngle + sweepAngle;
      final tipX = px + r * math.cos(endAngle);
      final tipY = py + r * math.sin(endAngle);
      final headLen = 8.0;
      final h1 = Offset(
        tipX - headLen * math.cos(endAngle - 0.6),
        tipY - headLen * math.sin(endAngle - 0.6),
      );
      final h2 = Offset(
        tipX - headLen * math.cos(endAngle + 0.8),
        tipY - headLen * math.sin(endAngle + 0.8),
      );
      canvas.drawLine(
          Offset(tipX, tipY), h1, arrowPaint..strokeWidth = 2.0);
      canvas.drawLine(
          Offset(tipX, tipY), h2, arrowPaint..strokeWidth = 2.0);

      final labelDist = r + 14;
      final labelAngle = angleRad;
      final lx = px + labelDist * math.cos(labelAngle - math.pi);
      final ly = py + labelDist * math.sin(labelAngle - math.pi);

      final bgPaint = Paint()..color = const Color(0xFFD32F2F);
      canvas.drawCircle(Offset(lx, ly), 10, bgPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$num',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeGuidePainterWidget old) => true;
}
