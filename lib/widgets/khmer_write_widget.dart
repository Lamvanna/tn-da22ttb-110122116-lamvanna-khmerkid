import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/scoring_service.dart';
import '../services/ocr_service.dart';
import '../data/stroke_guide_data.dart';
import '../data/khmer_stroke_templates.dart';
import 'dart:math' as math;

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
  final VoidCallback? onComplete;
  final bool showStrokeGuide;
  final bool enableOcr;
  final Color accentColor;
  final Color accentColorDark;
  final Color surfaceColor;

  const KhmerWriteWidget({
    super.key,
    required this.character,
    this.onComplete,
    this.showStrokeGuide = true,
    this.enableOcr = false,
    this.accentColor = const Color(0xFF3D7FCC),
    this.accentColorDark = const Color(0xFF24559A),
    this.surfaceColor = const Color(0xFFEAF2FC),
  });

  @override
  State<KhmerWriteWidget> createState() => _KhmerWriteWidgetState();
}

class _KhmerWriteWidgetState extends State<KhmerWriteWidget>
    with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed;
  bool _showHint = false;
  WritingResult? _result;
  RecognitionResult? _recResult;
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
    // Asynchronously preload the high-fidelity font shape template
    KhmerStrokeTemplateData.loadDynamicFontTemplate(widget.character);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
        _strokes.clear();
        _current = [];
        _passed = null;
        _result = null;
        _recResult = null;
      });

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      // Try OCR first if enabled
      if (widget.enableOcr) {
        final canvasBox =
            _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox != null) {
          final size = canvasBox.size;
          final pngPath = await OcrService.instance.saveStrokesAsPng(
            strokes: _strokes,
            width: size.width,
            height: size.height,
          );
          if (pngPath != null) {
            final ocrResult = await OcrService.instance.recognizeFromFile(
              pngPath,
              expectedText: widget.character,
            );
            if (ocrResult.ocrAvailable && ocrResult.recognizedText.isNotEmpty) {
              final writingResult = ScoringService.instance.scoreWritingOcr(
                recognized: ocrResult.recognizedText,
                expected: widget.character,
              );
              setState(() {
                _result = writingResult;
                _passed = writingResult.passed;
              });
              if (writingResult.passed) {
                _bounceCtrl.forward(from: 0);
                widget.onComplete?.call();
              }
              setState(() => _checking = false);
              return;
            }
          }
        }
      }

      // Fallback: advanced $1 shape recognizer with grid + direction analysis
      final canvasBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final size = canvasBox?.size ?? const Size(300, 300);

      final recognition = ScoringService.instance.recognizeWriting(
        character: widget.character,
        strokes: _strokes,
        canvasSize: size,
      );

      setState(() {
        _recResult = recognition;
        _result = WritingResult(
          score: recognition.finalScore.round(),
          passed: recognition.passed,
          stars: recognition.stars,
          feedback: recognition.feedback,
        );
        _passed = recognition.passed;
      });

      if (recognition.passed) {
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

  @override
  Widget build(BuildContext context) {
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
                _showHint ? 'Gợi ý viết' : 'Viết chữ',
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
                          : _passed!
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
                                  : _passed!
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
                                : _passed!
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
                                  : _passed!
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
      child: Container(
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
                  child: Text(
                    widget.character,
                    style: GoogleFonts.battambang(
                      fontSize: 260.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary.withValues(alpha: 0.65),
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
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        key: _canvasKey,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _passed == null
                ? const Color(0xFFD7CCC8)
                : _passed!
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
                  child: Text(
                    widget.character,
                    style: GoogleFonts.battambang(
                      fontSize: 260.sp,
                      fontWeight: FontWeight.w300,
                      color: widget.accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              // Drawing surface
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => setState(() {
                  _current = [d.localPosition];
                  _passed = null;
                  _result = null;
                }),
                onPanUpdate: (d) =>
                    setState(() => _current.add(d.localPosition)),
                onPanEnd: (_) => setState(() {
                  if (_current.isNotEmpty) {
                    _strokes.add(List.from(_current));
                    _current = [];
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
                  child: AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _passed!
                          ? 1.0 + 0.05 * math.sin(_bounceCtrl.value * math.pi)
                          : 1.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: _passed!
                              ? AppColors.tertiarySurface
                              : AppColors.coralSurface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: _passed!
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
                                  _passed! ? '🎉' : '😅',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _passed!
                                        ? 'Tuyệt vời! ${_result!.score}%'
                                        : 'Chưa đạt! ${_result!.score}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: _passed!
                                          ? AppColors.tertiaryDark
                                          : AppColors.coralDark,
                                    ),
                                  ),
                                ),
                                if (_passed!) ...[
                                  SizedBox(width: 4.w),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      3,
                                      (i) => Icon(
                                        i < _result!.stars
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 18.w,
                                        color: i < _result!.stars
                                            ? AppColors.secondary
                                            : AppColors.surfaceContainerHighest,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_recResult != null) ...[
                              SizedBox(height: 6.h),
                              Divider(
                                color: (_passed! ? AppColors.tertiary : AppColors.coral).withValues(alpha: 0.15),
                                height: 1.h,
                              ),
                              SizedBox(height: 6.h),
                              // Feedback lines with visual check/cross markers
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
                              // Fallback display if OCR result
                              SizedBox(height: 4.h),
                              Text(
                                _result!.feedback,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _passed! ? AppColors.tertiaryDark : AppColors.coralDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
