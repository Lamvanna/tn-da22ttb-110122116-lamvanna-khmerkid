import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';

/// Sheet tập viết nguyên âm — RESPONSIVE + Plus Jakarta Sans
class VowelWriteSheet extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelWriteSheet({super.key, required this.vowel, required this.onComplete});
  @override
  State<VowelWriteSheet> createState() => _State();
}

class _State extends State<VowelWriteSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String? _feedback;
  bool? _passed;

  void _check() {
    if (_strokes.length < 2) { setState(() { _passed = false; _feedback = 'Cần ít nhất 2 nét vẽ! (hiện có ${_strokes.length} nét)'; }); return; }
    int pts = 0;
    for (final s in _strokes) pts += s.length;
    if (pts < 20) { setState(() { _passed = false; _feedback = 'Nét viết quá ngắn! Hãy viết rõ ràng hơn.'; }); return; }
    double minX = double.infinity, maxX = 0, minY = double.infinity, maxY = 0;
    for (final s in _strokes) { for (final p in s) { if (p.dx < minX) minX = p.dx; if (p.dx > maxX) maxX = p.dx; if (p.dy < minY) minY = p.dy; if (p.dy > maxY) maxY = p.dy; } }
    if ((maxX - minX) < 30 || (maxY - minY) < 30) { setState(() { _passed = false; _feedback = 'Chữ quá nhỏ! Hãy viết lớn hơn.'; }); return; }
    setState(() { _passed = true; _feedback = null; });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.sheetWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
      child: Column(children: [
        // ── Drag Handle ──
        Container(width: 48.w, height: 5.h, margin: EdgeInsets.only(top: 12.h),
          decoration: BoxDecoration(color: AppColors.sheetWarmBorder, borderRadius: BorderRadius.circular(3.r))),
        SizedBox(height: 8.h),
        if (_passed != true) ...[
          Text('✍️ Tập viết chữ ${widget.vowel.character}',
            style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.sheetBrown)),
          SizedBox(height: 2.h),
          Text('Quan sát mẫu rồi viết theo',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.sheetBrownLight)),
          SizedBox(height: 8.h),
          // Model Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFECB3), Color(0xFFFFE082)]),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFFFCC02), width: 2.5),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), blurRadius: 12.r, offset: Offset(0, 4.h)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4.r, offset: Offset(0, 2.h))]),
            child: Stack(children: [
              Positioned(left: 0, top: 0, child: Container(padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(8.r)),
                child: Text('✏️', style: TextStyle(fontSize: 16.sp)))),
              Positioned(right: 0, top: 0, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(color: AppColors.sheetBrownLight, borderRadius: BorderRadius.circular(10.r)),
                child: Text('Mẫu', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)))),
              Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 90.sp, fontWeight: FontWeight.w700, color: AppColors.sheetBrown, height: 1.15)))),
            ]),
          ),
          SizedBox(height: 6.h),
          // Feedback
          if (_feedback != null && _passed == false)
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: const Color(0xFFEF9A9A))),
                child: Row(children: [
                  Text('😅', style: TextStyle(fontSize: 18.sp)), SizedBox(width: 8.w),
                  Expanded(child: Text(_feedback!, style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.errorDark))),
                ]))),
          // Canvas
          Expanded(child: Container(
            margin: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _passed == null ? AppColors.sheetWarmBorder : _passed! ? AppColors.successGreen : AppColors.errorRed, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(14.r),
              child: Stack(children: [
                CustomPaint(size: Size.infinite, painter: _GridPainter()),
                Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 180.sp, fontWeight: FontWeight.w300, color: AppColors.sheetWarmBorder.withValues(alpha: 0.45)))),
                GestureDetector(
                  onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; _feedback = null; }),
                  onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
                  onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
                  child: CustomPaint(size: Size.infinite, painter: _StrokePainter(_strokes, _current))),
              ])),
          )),
          SizedBox(height: 8.h),
          // Toolbar
          Padding(padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
            child: Container(padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: AppColors.sheetWarmBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6.r, offset: Offset(0, 2.h))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _toolBtn(icon: Icons.check_circle_outline_rounded, label: 'Kiểm tra',
                  color: _strokes.isNotEmpty ? AppColors.successGreen : AppColors.textHint,
                  onTap: _strokes.isNotEmpty ? _check : null),
                _toolBtn(icon: Icons.auto_fix_high_rounded, label: 'Cục tẩy',
                  color: _strokes.isNotEmpty ? AppColors.secondary : AppColors.textHint,
                  onTap: _strokes.isNotEmpty ? () => setState(() { _strokes.removeLast(); _passed = null; _feedback = null; }) : null),
                _toolBtn(icon: Icons.refresh_rounded, label: 'Làm lại', color: AppColors.errorRed,
                  onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; })),
              ]))),
        ],
        // ── Success ──
        if (_passed == true)
          Expanded(child: Center(child: Padding(padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28.r),
                boxShadow: [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.12), blurRadius: 20.r, offset: Offset(0, 6.h)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8.r, offset: Offset(0, 2.h))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 100.w, height: 100.w,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.successLighter, AppColors.successGreen]),
                    boxShadow: [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.3), blurRadius: 16.r, offset: Offset(0, 6.h))]),
                  child: Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 52.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)))),
                SizedBox(height: 16.h),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Padding(padding: EdgeInsets.symmetric(horizontal: 4.w), child: Icon(Icons.star_rounded, size: 36.sp, color: AppColors.secondary)))),
                SizedBox(height: 12.h),
                Text('Viết tuyệt vời!', style: GoogleFonts.plusJakartaSans(fontSize: 26.sp, fontWeight: FontWeight.w800, color: const Color(0xFF2E7D32))),
                SizedBox(height: 4.h),
                Text('Bé viết rất đẹp! 🎉', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500, color: AppColors.sheetBrownLight)),
                SizedBox(height: 14.h),
                Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16.r)),
                  child: Text('+10 XP ⭐', style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.secondary))),
                SizedBox(height: 20.h),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; }),
                    child: Container(padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.secondary)),
                      child: Center(child: Text('Viết lại', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.secondary)))))),
                  SizedBox(width: 12.w),
                  Expanded(child: GestureDetector(
                    onTap: () {
                      final m = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      m.showSnackBar(SnackBar(
                        content: Text('🎉 Viết tuyệt vời! +10 XP', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                        backgroundColor: AppColors.successGreen, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(16.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), duration: const Duration(seconds: 2)));
                    },
                    child: Container(padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.successLight, AppColors.successGreen]),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.3), blurRadius: 8.r, offset: Offset(0, 3.h))]),
                      child: Center(child: Text('Hoàn thành ✅', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)))))),
                ]),
              ]))))),
      ]),
    );
  }

  Widget _toolBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48.w, height: 48.w,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14.r)),
        child: Icon(icon, color: color, size: 22.sp)),
      SizedBox(height: 4.h),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
    ]));
  }
}

class _GridPainter extends CustomPainter {
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
    final p = Paint()..color = AppColors.sheetBrown..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes) { if (s.length < 2) continue; final path = Path()..moveTo(s[0].dx, s[0].dy); for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy); canvas.drawPath(path, p); }
    if (current.length >= 2) { final ap = Paint()..color = AppColors.sheetBrownLight..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke; final path = Path()..moveTo(current[0].dx, current[0].dy); for (int i = 1; i < current.length; i++) path.lineTo(current[i].dx, current[i].dy); canvas.drawPath(path, ap); }
  }
  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
