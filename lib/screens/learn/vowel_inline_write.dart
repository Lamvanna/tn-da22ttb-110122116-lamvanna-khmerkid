import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import '../../services/scoring_service.dart';

class VowelInlineWriteContent extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelInlineWriteContent({super.key, required this.vowel, required this.onComplete});
  @override
  State<VowelInlineWriteContent> createState() => _S();
}

class _S extends State<VowelInlineWriteContent> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed;
  bool _showHint = false;
  final GlobalKey _canvasKey = GlobalKey();

  void _clear() => setState(() { _strokes.clear(); _current = []; _passed = null; });

  void _check() {
    final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = canvasBox?.size ?? const Size(200, 200);

    final recognition = ScoringService.instance.recognizeWriting(
      character: widget.vowel.displayCharacter,
      strokes: _strokes,
      canvasSize: size,
    );

    setState(() {
      _passed = recognition.passed;
    });

    if (recognition.passed) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 4.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.edit_rounded, color: AppColors.primary, size: 20.w), SizedBox(width: 8.w),
          Text(_showHint ? 'Gợi ý viết chữ' : 'Tập viết chữ', style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ])),
      Expanded(child: _showHint ? _buildHintPage() : _buildCanvas()),
      // Toolbar
      Padding(padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _toolBtn(Icons.lightbulb_outline_rounded, _showHint ? 'Viết' : 'Gợi ý',
            AppColors.tertiary, () => setState(() => _showHint = !_showHint)),
          if (!_showHint) ...[
            _toolBtn(Icons.check_circle_outline_rounded, 'Kiểm tra',
              _strokes.isNotEmpty ? AppColors.tertiary : AppColors.textHint,
              _strokes.isNotEmpty ? _check : null),
            _toolBtn(Icons.auto_fix_high_rounded, 'Cục tẩy',
              _strokes.isNotEmpty ? AppColors.secondary : AppColors.textHint,
              _strokes.isNotEmpty ? () => setState(() { _strokes.removeLast(); _passed = null; }) : null),
            _toolBtn(Icons.refresh_rounded, 'Làm lại', AppColors.coral, _clear),
          ],
        ])),
    ]);
  }

  Widget _buildHintPage() {
    return Padding(padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3), width: 2.w)),
        child: ClipRRect(borderRadius: BorderRadius.circular(14.r),
          child: Stack(children: [
            CustomPaint(size: Size.infinite, painter: _GuideLinePainter()),
            Center(child: Padding(padding: EdgeInsets.only(bottom: 20.h),
              child: Text(widget.vowel.displayCharacter, style: GoogleFonts.battambang(
                fontSize: 180.sp, fontWeight: FontWeight.w700, color: AppColors.tertiary.withValues(alpha: 0.65))))),
          ]))));
  }

  Widget _buildCanvas() {
    return Padding(padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _passed == null ? const Color(0xFFD7CCC8) : _passed! ? AppColors.tertiary : AppColors.coral, width: 2.w)),
        child: ClipRRect(borderRadius: BorderRadius.circular(14.r),
          child: Stack(children: [
            CustomPaint(size: Size.infinite, painter: _GuideLinePainter()),
            Center(child: Padding(padding: EdgeInsets.only(bottom: 20.h),
              child: Text(widget.vowel.displayCharacter, style: GoogleFonts.battambang(
                fontSize: 180.sp, fontWeight: FontWeight.w300, color: const Color(0xFFD7CCC8).withValues(alpha: 0.45))))),
            GestureDetector(
              key: _canvasKey,
              onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; }),
              onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
              onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
              child: CustomPaint(size: Size.infinite, painter: _StrokePainter(_strokes, _current))),
            if (_passed != null)
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 10.h,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _passed! ? AppColors.tertiarySurface : AppColors.coralSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _passed!
                          ? AppColors.tertiary.withValues(alpha: 0.35)
                          : AppColors.coral.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Text(
                    _passed! ? 'Viết rất đẹp! 🎉' : 'Nét vẽ chưa chuẩn. Hãy thử viết lại nhé!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: _passed! ? AppColors.tertiaryDark : AppColors.coralDark,
                    ),
                  ),
                ),
              ),
          ]))));
  }

  Widget _toolBtn(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40.w, height: 40.w,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12.r)),
        child: Icon(icon, color: color, size: 18.sp)),
      SizedBox(height: 3.h),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
    ]));
  }
}

class _GuideLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFE0D5C5).withValues(alpha: 0.4)..strokeWidth = 0.8;
    const cols = 8; final cw = size.width / cols; final rows = (size.height / cw).ceil();
    for (int i = 0; i <= cols; i++) canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), p);
    for (int j = 0; j <= rows; j++) canvas.drawLine(Offset(0, j * cw), Offset(size.width, j * cw), p);
    final cp = Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), cp);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), cp);
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
    final p = Paint()..color = AppColors.primaryDark..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes) { if (s.length < 2) continue; final path = Path()..moveTo(s[0].dx, s[0].dy); for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy); canvas.drawPath(path, p); }
    if (current.length >= 2) { final ap = Paint()..color = AppColors.primary..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy); for (int i = 1; i < current.length; i++) path.lineTo(current[i].dx, current[i].dy); canvas.drawPath(path, ap); }
  }
  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
