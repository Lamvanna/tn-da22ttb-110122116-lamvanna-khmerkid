import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_letter.dart';
import 'letter_detail_screen.dart';

/// Bản đồ chữ cái Khmer — Premium learning path
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

  static const double _nodeSpacingY = 100.0;
  static const double _topPadding = 28.0;
  static const double _nodeSize = 62.0;

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
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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

  // Zigzag positions
  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18;
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  // 5 màu xoay vòng theo nhóm 5 chữ
  Color _nodeColor(int idx) {
    const colors = [
      Color(0xFF2979FF), // 🔵 xanh tươi
      Color(0xFF00E676), // 🟢 xanh lá neon
      Color(0xFFFFD600), // 🟡 vàng tươi
      Color(0xFFAA00FF), // 🟣 tím neon
      Color(0xFFFF1744), // 🔴 đỏ tươi
    ];
    return colors[(idx ~/ 5) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _letters.length * _nodeSpacingY + 120;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
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
                    child: Stack(children: _buildAllNodes(w)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final progress = _doneCount / _letters.length;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -25,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Mascot elephant
          Positioned(
            right: 0,
            bottom: -15,
            child: Image.asset(
              'image/Voi nguyên âm.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 105, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Back + Title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Học phụ âm Khmer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      '$_doneCount/${_letters.length} đã hoàn thành',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF66BB6A),
                                        Color(0xFF43A047),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF43A047,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pct%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
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
      final ri = _letters.length - 1 - i;
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
              height: _nodeSize + (done ? 20 : 0),
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
                          (_) => Icon(
                            Icons.star_rounded,
                            color: AppColors.secondary,
                            size: 13,
                          ),
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

  Widget _circle(
    KhmerLetter letter,
    Color color,
    bool done,
    bool curr,
    bool locked,
  ) {
    if (locked) {
      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerLow,
          border: Border.all(
            color: AppColors.surfaceContainerHighest,
            width: 3,
          ),
        ),
        child: Icon(Icons.lock_rounded, color: AppColors.textHint, size: 22),
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
            Color.lerp(color, Colors.white, 0.20)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.4)!,
          width: 3,
        ),
        boxShadow: [
          // Bottom 3D effect
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
          // Glow for current
          if (curr)
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: Text(
          letter.character,
          style: GoogleFonts.kantumruyPro(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.20),
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
      MaterialPageRoute(builder: (_) => LetterDetailScreen(initialIndex: idx)),
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

    // Undone path — subtle
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD6E4F0)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Done portion — blue gradient path
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
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: 0.4)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Main
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF2979FF)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Highlight
      canvas.drawPath(
        dp,
        Paint()
          ..color = const Color(0xFF82B1FF).withValues(alpha: 0.6)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
