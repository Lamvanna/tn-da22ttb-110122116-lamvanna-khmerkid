import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import '../../services/scoring_service.dart';
import '../../data/khmer_stroke_templates.dart';
import 'dart:math' as math;

/// Sheet tập viết nguyên âm
/// Dùng cùng thuật toán chấm điểm với KhmerWriteWidget (consonant):
///   • ScoringService.recognizeWriting → HandwritingTracingService
///   • Chấm dựa trên nét thực sự của nguyên âm (bỏ qua dấu hướng dẫn)
///   • Hiển thị % độ chính xác sau khi kiểm tra
///   • Trừ điểm khi viết ngoài vùng template
///   • Fail nếu nét ngoài > nét trong vùng template
///   • Pass khi đạt ≥ 60% (ngưỡng tracing — khoan dung cho trẻ em)
class VowelWriteSheet extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelWriteSheet({
    super.key,
    required this.vowel,
    required this.onComplete,
  });

  @override
  State<VowelWriteSheet> createState() => _VowelWriteSheetState();
}

class _VowelWriteSheetState extends State<VowelWriteSheet>
    with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed;
  bool _checking = false;
  WritingResult? _result;
  RecognitionResult? _recResult;
  final GlobalKey _canvasKey = GlobalKey();
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Preload font shape template for this vowel
    KhmerStrokeTemplateData.loadDynamicFontTemplate(
        widget.vowel.displayCharacter);
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

  /// Chấm điểm dùng ScoringService.recognizeWriting — cùng engine với consonant
  Future<void> _check() async {
    if (_checking || _strokes.isEmpty) return;
    setState(() => _checking = true);

    try {
      final canvasBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final size = canvasBox?.size ?? const Size(300, 300);

      // Dùng displayCharacter (ký tự hiển thị bỏ '◌') để khớp với template
      final recognition = ScoringService.instance.recognizeWriting(
        character: widget.vowel.displayCharacter,
        strokes: _strokes,
        canvasSize: size,
        // Cấu hình riêng cho nguyên âm Khmer (khoan dung hơn, nét ngắn, dấu ghép):
        minPointsOverride: 80,
        minStrokesOverride: 1,
        passThresholdOverride: 60.0,
        outsideThresholdOverride: 45.0,
        toleranceRadiusOverride: 25.0,
      );

      final writingResult = WritingResult(
        score: recognition.finalScore.round(),
        passed: recognition.passed,
        stars: recognition.stars,
        feedback: recognition.feedback,
      );

      setState(() {
        _recResult = recognition;
        _result = writingResult;
        _passed = recognition.passed;
      });

      if (recognition.passed) {
        _bounceCtrl.forward(from: 0);
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('[VowelWriteSheet] Check error: $e');
      setState(() => _passed = false);
    } finally {
      setState(() => _checking = false);
    }
  }

  double _getGuideShiftY(double height) {
    final char = widget.vowel.displayCharacter;
    final isBelow = char.contains('ុ') ||
        char.contains('ូ') ||
        char.contains('ួ') ||
        char.contains('្');
    if (isBelow) return -height * 0.08;
    
    final isAbove = char.contains('ិ') ||
        char.contains('ី') ||
        char.contains('ឹ') ||
        char.contains('ឺ') ||
        char.contains('ំ') ||
        char.contains('៏');
    if (isAbove) return height * 0.06;
    
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: AppColors.sheetWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Container(
            width: 48.w,
            height: 5.h,
            margin: EdgeInsets.only(top: 12.h, bottom: 6.h),
            decoration: BoxDecoration(
              color: AppColors.sheetWarmBorder,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),

          // ── Header ──
          Text(
            '✍️ Tập viết ${widget.vowel.displayCharacter}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.sheetBrown,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Quan sát mẫu rồi viết theo nét mờ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.sheetBrownLight,
            ),
          ),
          SizedBox(height: 8.h),

          // ── Model Card ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding:
                EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFECB3), Color(0xFFFFE082)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFFFCC02), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.sheetBrownLight,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Mẫu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.vowel.displayCharacter,
                    style: GoogleFonts.battambang(
                      fontSize: 72.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sheetBrown,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // ── Score result banner ──
          if (_result != null && _passed != null)
            _buildScoreBanner(),

          // ── Canvas ──
          Expanded(
            child: Container(
              key: _canvasKey,
              margin: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _passed == null
                      ? AppColors.sheetWarmBorder
                      : _passed!
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Stack(
                  children: [
                    // Grid
                    CustomPaint(
                      size: Size.infinite,
                      painter: _GridPainter(),
                    ),
                    // Guide character (very light)
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, _guideShiftY),
                        child: Text(
                          widget.vowel.displayCharacter,
                          style: GoogleFonts.battambang(
                            fontSize: 220.sp,
                            fontWeight: FontWeight.w300,
                            color: AppColors.sheetWarmBorder
                                .withValues(alpha: 0.3),
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
                        _recResult = null;
                      }),
                      onPanUpdate: (d) =>
                          setState(() => _current.add(d.localPosition)),
                      onPanEnd: (_) => setState(() {
                        if (_current.isNotEmpty) {
                          _strokes.add(List.from(_current));
                          _current = [];
                        }
                      }),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _StrokePainter(_strokes, _current),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── Toolbar ──
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
            child: Row(
              children: [
                // Undo
                Expanded(
                  child: _toolBtn(
                    icon: Icons.undo_rounded,
                    label: 'Xóa nét',
                    color: _strokes.isNotEmpty
                        ? AppColors.secondary
                        : AppColors.textHint,
                    onTap: _strokes.isNotEmpty
                        ? () => setState(() {
                              _strokes.removeLast();
                              _passed = null;
                              _result = null;
                              _recResult = null;
                            })
                        : null,
                  ),
                ),
                SizedBox(width: 8.w),
                // Check
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _strokes.isNotEmpty
                        ? (_passed != null ? _clear : _check)
                        : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: _passed == null
                            ? LinearGradient(colors: [
                                AppColors.successLight,
                                AppColors.successGreen,
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
                                    ? AppColors.successGreen
                                    : _passed!
                                        ? AppColors.tertiary
                                        : AppColors.coral)
                                .withValues(alpha: 0.35),
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
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.white),
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
                          SizedBox(width: 6.w),
                          Text(
                            _checking
                                ? 'Đang chấm...'
                                : _passed == null
                                    ? 'Kiểm tra'
                                    : _passed!
                                        ? 'Tuyệt vời! 🎉'
                                        : 'Làm lại',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
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
                // Clear all
                Expanded(
                  child: _toolBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Làm lại',
                    color: AppColors.errorRed,
                    onTap: _clear,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score Banner ─────────────────────────────────────────────

  Widget _buildScoreBanner() {
    final r = _result!;
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (context, _) => Transform.scale(
        scale: _passed!
            ? 1.0 + 0.04 * math.sin(_bounceCtrl.value * math.pi)
            : 1.0,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          padding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _passed! ? AppColors.tertiarySurface : AppColors.coralSurface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _passed!
                  ? AppColors.tertiary.withValues(alpha: 0.35)
                  : AppColors.coral.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score header
              Row(
                children: [
                  Text(_passed! ? '🎉' : '😅',
                      style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _passed!
                          ? 'Tuyệt vời! ${r.score}%'
                          : 'Chưa đạt! ${r.score}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _passed!
                            ? AppColors.tertiaryDark
                            : AppColors.coralDark,
                      ),
                    ),
                  ),
                  if (_passed!)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < r.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16.w,
                          color: i < r.stars
                              ? AppColors.secondary
                              : AppColors.sheetWarmBorder,
                        ),
                      ),
                    ),
                ],
              ),

              // Feedback from recognition engine
              if (_recResult != null) ...[
                SizedBox(height: 6.h),
                Divider(
                  color: (_passed! ? AppColors.tertiary : AppColors.coral)
                      .withValues(alpha: 0.15),
                  height: 1.h,
                ),
                SizedBox(height: 6.h),
                ..._recResult!.feedback.split('\n').map((line) {
                  final isCorrect = line.startsWith('✓');
                  final isIncorrect = line.startsWith('✗');
                  final isWarning = line.startsWith('△');
                  final hasPrefix =
                      isCorrect || isIncorrect || isWarning;
                  final displayLine =
                      hasPrefix ? line.substring(2) : line;
                  if (displayLine.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
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
                          size: 13.w,
                          color: isCorrect
                              ? Colors.green[700]
                              : isIncorrect
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                        ),
                        SizedBox(width: 6.w),
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
                    'Gợi ý:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coralDark,
                    ),
                  ),
                  ..._recResult!.tips.map((tip) => Padding(
                        padding:
                            EdgeInsets.only(left: 4.w, top: 2.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.coral)),
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
              ],

              // Complete button
              if (_passed!) ...[
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () {
                    final m = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    m.showSnackBar(SnackBar(
                      content: Text(
                        '🎉 Viết tuyệt vời! +10 XP',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.successLight,
                          AppColors.successGreen
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        'Hoàn thành ✅',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tool button ──────────────────────────────────────────────

  Widget _toolBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: color.withValues(
                  alpha: onTap != null ? 0.3 : 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 3.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Painters
// ═══════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE0D5C5).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    const cols = 6;
    final cw = size.width / cols;
    final rows = (size.height / cw).ceil();
    for (int i = 1; i < cols; i++) {
      canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), p);
    }
    for (int j = 1; j < rows; j++) {
      canvas.drawLine(Offset(0, j * cw), Offset(size.width, j * cw), p);
    }
    // Center lines
    final cp = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), cp);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), cp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _StrokePainter(this.strokes, this.current);

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
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
