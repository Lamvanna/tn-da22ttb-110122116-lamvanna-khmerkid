import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';
import 'letter_detail_screen.dart';

/// Bản đồ chữ cái Khmer — Clean Duolingo style
class LetterMapView extends StatefulWidget {
  final VoidCallback onBack;
  const LetterMapView({super.key, required this.onBack});

  @override
  State<LetterMapView> createState() => _LetterMapViewState();
}

class _LetterMapViewState extends State<LetterMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerLetter> _letters = KhmerLetterData.consonants;

  static const double _nodeSpacingY = 95.0;
  static const double _topPadding = 24.0;
  static const double _nodeSize = 58.0;

  int get _currentIdx {
    final idx = _letters.indexWhere((l) => !l.isLearned);
    return idx == -1 ? _letters.length - 1 : idx;
  }

  int get _doneCount => _letters.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final target = (_letters.length - 1 - _currentIdx) * _nodeSpacingY - 200;
    if (_scrollCtrl.hasClients && target > 0) {
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

  // Zigzag positions — stays well within screen
  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18; // Giữ trong màn hình
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  // Rotating colors per group of 5
  static const _colors = [
    Color(0xFF58CC02), // xanh lá
    Color(0xFF1CB0F6), // xanh dương
    Color(0xFFFF9600), // cam
    Color(0xFFCE82FF), // tím
    Color(0xFFFF4B4B), // đỏ
  ];

  Color _nodeColor(int idx) => _colors[(idx ~/ 5) % _colors.length];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _letters.length * _nodeSpacingY + 120;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
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
                        count: _letters.length,
                        width: w,
                        getX: _nodeX,
                        getY: _nodeY,
                        doneCount: _doneCount,
                      ),
                      child: Stack(
                        children: _buildAllNodes(w),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final progress = _doneCount / _letters.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF37474F), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF58CC02), Color(0xFF46A302)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_doneCount / ${_letters.length}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ALL NODES ───
  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];

    for (int i = 0; i < _letters.length; i++) {
      final ri = _letters.length - 1 - i; // reversed index
      final letter = _letters[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = letter.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = _nodeColor(ri);

      widgets.add(
        Positioned(
          left: x - _nodeSize / 2,
          top: y - _nodeSize / 2,
          child: GestureDetector(
            onTap: locked ? null : () => _openLetter(ri),
            child: SizedBox(
              width: _nodeSize,
              height: _nodeSize + (done ? 18 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle
                  curr
                      ? AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: child,
                          ),
                          child: _circle(letter, color, done, curr, locked),
                        )
                      : _circle(letter, color, done, curr, locked),
                  // Stars
                  if (done && letter.starRating > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          min(letter.starRating, 3),
                          (_) => const Icon(Icons.star_rounded,
                            color: Color(0xFFFFD700), size: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _circle(KhmerLetter letter, Color color, bool done, bool curr, bool locked) {
    if (locked) {
      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE8E8E8),
          border: Border.all(
            color: const Color(0xFFD0D0D0),
            width: 3,
          ),
        ),
        child: const Icon(Icons.lock_rounded,
          color: Color(0xFFBDBDBD), size: 22),
      );
    }

    return Container(
      width: _nodeSize,
      height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.25)!,
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.5)!,
          width: 3,
        ),
        boxShadow: [
          // Bottom shadow (3D effect)
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.5)!.withValues(alpha: 0.6),
            blurRadius: 0,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          // Glow
          if (curr)
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
        ],
      ),
      child: Center(
        child: Text(
          letter.character,
          style: GoogleFonts.kantumruyPro(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLetter(int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(initialIndex: idx),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

// ═══════════════════════════════════════════════
// MAP PAINTER — path + subtle decorations
// ═══════════════════════════════════════════════

class _MapPainter extends CustomPainter {
  final int count;
  final double width;
  final double Function(int, double) getX;
  final double Function(int) getY;
  final int doneCount;

  _MapPainter({
    required this.count,
    required this.width,
    required this.getX,
    required this.getY,
    required this.doneCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    // Build full path
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

    // Undone path — light gray
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots along undone path
    final metrics = path.computeMetrics();
    final dotPaint = Paint()
      ..color = const Color(0xFFD0D0D0);
    for (final m in metrics) {
      for (double d = 0; d < m.length; d += 14) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 2.5, dotPaint);
      }
    }

    // Done portion — green thick
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
      canvas.drawPath(dp, Paint()
        ..color = const Color(0xFF3D8B00).withValues(alpha: 0.5)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);

      // Main
      canvas.drawPath(dp, Paint()
        ..color = const Color(0xFF58CC02)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);

      // Highlight
      canvas.drawPath(dp, Paint()
        ..color = const Color(0xFF89E219).withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
