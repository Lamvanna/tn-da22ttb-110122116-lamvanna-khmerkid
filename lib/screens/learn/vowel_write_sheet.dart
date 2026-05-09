import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_vowel.dart';

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
      decoration: const BoxDecoration(color: Color(0xFFFFF8E1), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: const Color(0xFFD7CCC8), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        if (_passed != true) ...[
          Text('✍️ Tập viết chữ ${widget.vowel.character}', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF5D4037))),
          const SizedBox(height: 2),
          Text('Quan sát mẫu rồi viết theo', style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF8D6E63))),
          const SizedBox(height: 8),
          // Model Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFECB3), Color(0xFFFFE082)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCC02), width: 2.5),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)), const BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2))]),
            child: Stack(children: [
              Positioned(left: 0, top: 0, child: Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(8)),
                child: const Text('✏️', style: TextStyle(fontSize: 16)))),
              Positioned(right: 0, top: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF8D6E63), borderRadius: BorderRadius.circular(10)),
                child: Text('Mẫu', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
              Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 90, fontWeight: FontWeight.w700, color: const Color(0xFF3E2723), height: 1.15)))),
            ]),
          ),
          const SizedBox(height: 6),
          // Feedback
          if (_feedback != null && _passed == false)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEF9A9A))),
                child: Row(children: [
                  const Text('😅', style: TextStyle(fontSize: 18)), const SizedBox(width: 8),
                  Expanded(child: Text(_feedback!, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFC62828)))),
                ]))),
          // Canvas
          Expanded(child: Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _passed == null ? const Color(0xFFD7CCC8) : _passed! ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(14),
              child: Stack(children: [
                CustomPaint(size: Size.infinite, painter: _GridPainter()),
                Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 180, fontWeight: FontWeight.w300, color: const Color(0xFFE0D5C5).withValues(alpha: 0.45)))),
                GestureDetector(
                  onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; _feedback = null; }),
                  onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
                  onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
                  child: CustomPaint(size: Size.infinite, painter: _StrokePainter(_strokes, _current))),
              ])),
          )),
          const SizedBox(height: 8),
          // Toolbar
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0D5C5)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _toolBtn(icon: Icons.check_circle_outline_rounded, label: 'Kiểm tra',
                  color: _strokes.isNotEmpty ? const Color(0xFF43A047) : const Color(0xFFBDBDBD),
                  onTap: _strokes.isNotEmpty ? _check : null),
                _toolBtn(icon: Icons.auto_fix_high_rounded, label: 'Cục tẩy',
                  color: _strokes.isNotEmpty ? const Color(0xFFFFA726) : const Color(0xFFBDBDBD),
                  onTap: _strokes.isNotEmpty ? () => setState(() { _strokes.removeLast(); _passed = null; _feedback = null; }) : null),
                _toolBtn(icon: Icons.refresh_rounded, label: 'Làm lại', color: const Color(0xFFEF5350),
                  onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; })),
              ]))),
        ],
        // Success
        if (_passed == true)
          Expanded(child: Center(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF81C784), Color(0xFF43A047)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 52, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.star_rounded, size: 36, color: Color(0xFFFFC107))))),
                const SizedBox(height: 12),
                Text('Viết tuyệt vời!', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF2E7D32))),
                const SizedBox(height: 4),
                Text('Bé viết rất đẹp! 🎉', style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF8D6E63))),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16)),
                  child: Text('+10 XP ⭐', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFFA726)))),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; }),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726))),
                      child: Center(child: Text('Viết lại', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFFFA726))))))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () {
                      final m = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      m.showSnackBar(SnackBar(
                        content: Text('🎉 Viết tuyệt vời! +10 XP', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
                        backgroundColor: const Color(0xFF4CAF50), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), duration: const Duration(seconds: 2)));
                    },
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                      child: Center(child: Text('Hoàn thành ✅', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)))))),
                ]),
              ]))))),
      ]),
    );
  }

  Widget _toolBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
    final p = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes) { if (s.length < 2) continue; final path = Path()..moveTo(s[0].dx, s[0].dy); for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy); canvas.drawPath(path, p); }
    if (current.length >= 2) { final ap = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke; final path = Path()..moveTo(current[0].dx, current[0].dy); for (int i = 1; i < current.length; i++) path.lineTo(current[i].dx, current[i].dy); canvas.drawPath(path, ap); }
  }
  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
