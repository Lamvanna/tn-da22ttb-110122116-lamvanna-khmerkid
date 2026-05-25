import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_consonant_series.dart';

/// Bản đồ phụ âm hàng o và ô — Premium learning path
class ConsonantSeriesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ConsonantSeriesScreen({super.key, required this.onBack});

  @override
  State<ConsonantSeriesScreen> createState() => _ConsonantSeriesScreenState();
}

class _ConsonantSeriesScreenState extends State<ConsonantSeriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerConsonantSeries> _items = KhmerConsonantSeriesData.consonants;

  double get _nodeSpacingY => 140.h;
  double get _topPadding => 60.h;
  double get _nodeSize => 78.w;

  int get _currentIdx {
    final idx = _items.indexWhere((v) => !v.isLearned);
    return idx == -1 ? _items.length - 1 : idx;
  }

  int get _doneCount => _items.where((v) => v.isLearned).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final target = (_items.length - 1 - _currentIdx) * _nodeSpacingY - 200.h;
    if (_scrollCtrl.hasClients && target > 0) {
      _scrollCtrl.animateTo(
        target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18;
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  Color _nodeColor(int idx) {
    final item = _items[idx];
    return item.series == 'o'
        ? const Color(0xFF43A047)  // Xanh lá cho hàng o
        : const Color(0xFF1E88E5); // Xanh dương cho hàng ô
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _items.length * _nodeSpacingY + 120.h;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              reverse: true,
              child: SizedBox(
                width: w, height: mapH,
                child: CustomPaint(
                  painter: _SeriesMapPainter(
                    count: _items.length, width: w,
                    getX: _nodeX, getY: _nodeY,
                    doneCount: _doneCount,
                    undonePath: 10.w, shadowStroke: 12.w,
                    mainStroke: 8.w, highlightStroke: 3.w),
                  child: Stack(children: _buildAllNodes(w)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final progress = _items.isEmpty ? 0.0 : _doneCount / _items.length;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFF81C784)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: SafeArea(bottom: false, child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 4.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 36.w, height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w)),
              ),
              SizedBox(width: 12.w),
              Flexible(child: Text('Phụ âm hàng o-ô',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
            ],
          ),
          SizedBox(height: 0.h),
          Padding(
            padding: EdgeInsets.only(left: 48.w),
            child: Text('$_doneCount/${_items.length} đã hoàn thành',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85)))),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 48.w),
            child: Row(children: [
              Expanded(child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4.r)),
                child: Stack(children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFF0A030)]),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFF0A030).withValues(alpha: 0.5),
                        blurRadius: 6)])))]),
              )),
              SizedBox(width: 8.w),
              Text('$pct%', style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
          SizedBox(height: 6.h),
          // Legend
          Padding(
            padding: EdgeInsets.only(left: 48.w),
            child: Row(children: [
              _legendDot(const Color(0xFF43A047), 'Hàng o'),
              SizedBox(width: 16.w),
              _legendDot(const Color(0xFF1E88E5), 'Hàng ô'),
            ]),
          ),
        ]),
      )),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12.w, height: 12.w,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      SizedBox(width: 6.w),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9))),
    ]);
  }

  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];
    for (int i = 0; i < _items.length; i++) {
      final ri = _items.length - 1 - i;
      final item = _items[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = item.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = _nodeColor(ri);
      final baiNum = ri + 1;

      final isNodeOnRight = x > w / 2;
      final labelOnLeft = isNodeOnRight;
      final labelW = 100.w;
      final labelX = labelOnLeft ? x - _nodeSize / 2 - labelW - 10.w : x + _nodeSize / 2 + 10.w;
      final labelY = y - 45.h;

      // Label card
      widgets.add(Positioned(left: labelX, top: labelY,
        child: Container(
          width: labelW,
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
          decoration: BoxDecoration(
            color: locked ? Colors.white.withValues(alpha: 0.45) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: locked ? null : Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(color: locked ? Colors.black.withValues(alpha: 0.03) : color.withValues(alpha: 0.10),
                blurRadius: 14, offset: const Offset(0, 5)),
              if (!locked) BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 4, spreadRadius: 1),
            ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: locked ? const Color(0xFFE8EEF5) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r)),
              child: Text('Bài $baiNum', style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp, fontWeight: FontWeight.w800,
                color: locked ? const Color(0xFFB0BEC5) : color))),
            SizedBox(height: 4.h),
            Text(item.character, style: GoogleFonts.battambang(
              fontSize: 26.sp, fontWeight: FontWeight.w700, height: 1.2,
              color: locked ? const Color(0xFFB0BEC5) : const Color(0xFF1A202C))),
            Row(children: [
              Text(item.romanized, style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp, fontWeight: FontWeight.w500,
                color: locked ? const Color(0xFFCFD8DC) : const Color(0xFF718096))),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: (item.series == 'o' ? const Color(0xFF43A047) : const Color(0xFF1E88E5)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r)),
                child: Text(item.series, style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp, fontWeight: FontWeight.w700,
                  color: locked ? const Color(0xFFCFD8DC) : (item.series == 'o' ? const Color(0xFF43A047) : const Color(0xFF1E88E5))))),
            ]),
            SizedBox(height: 4.h),
            Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (si) => Icon(Icons.star_rounded, size: 16.w,
                color: (done && si < item.starRating) ? const Color(0xFFFFB300)
                    : locked ? const Color(0xFFE0E0E0).withValues(alpha: 0.4) : const Color(0xFFE0E0E0)))),
          ]),
        ),
      ));

      // Arrow
      final arrowX = labelOnLeft ? labelX + labelW - 2.w : labelX - 8.w;
      widgets.add(Positioned(left: arrowX, top: y - 6.h,
        child: CustomPaint(size: Size(14.w, 16.h),
          painter: _ArrowPainter(pointsRight: labelOnLeft,
            color: locked ? Colors.white.withValues(alpha: 0.45) : Colors.white))));

      // Node circle
      widgets.add(Positioned(
        left: x - _nodeSize / 2, top: y - _nodeSize / 2,
        child: GestureDetector(
          onTap: locked ? null : () => _showDetail(ri),
          child: SizedBox(width: _nodeSize, height: _nodeSize,
            child: curr
                ? AnimatedBuilder(animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                    child: _circle(item, color, done, curr, locked))
                : _circle(item, color, done, curr, locked)))));

      // Badge
      if (!locked) {
        widgets.add(Positioned(
          left: x + _nodeSize / 2 - 16.w, top: y - _nodeSize / 2 - 4.h,
          child: Container(width: 22.w, height: 22.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color,
              border: Border.all(color: Colors.white, width: 2.w),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]),
            child: Center(child: Text('$baiNum', style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white))))));
      }
    }
    return widgets;
  }

  Widget _circle(KhmerConsonantSeries item, Color color, bool done, bool curr, bool locked) {
    if (locked) {
      return Container(width: _nodeSize, height: _nodeSize,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: const Color(0xFFE8EEF5),
          border: Border.all(color: const Color(0xFFBCC8D9), width: 3.w)),
        child: Icon(Icons.lock_rounded, color: const Color(0xFF8E9DB3), size: 22.w));
    }
    return Container(width: _nodeSize, height: _nodeSize,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.20)!, color, Color.lerp(color, Colors.black, 0.12)!],
          stops: const [0.0, 0.45, 1.0]),
        border: Border.all(color: Color.lerp(color, Colors.white, 0.4)!, width: 3.w),
        boxShadow: [
          BoxShadow(color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
            blurRadius: 0, offset: Offset(0, 4.h)),
          if (curr) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 18, spreadRadius: 2)]),
      child: Center(child: Text(item.character,
        style: GoogleFonts.battambang(fontSize: 25.sp, fontWeight: FontWeight.w700,
          color: Colors.white, height: 1.2,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 2, offset: const Offset(0, 1))]))));
  }

  void _showDetail(int idx) {
    final item = _items[idx];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r), topRight: Radius.circular(28.r))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40.w, height: 4.h,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2.r))),
          SizedBox(height: 20.h),
          Text(item.character, style: GoogleFonts.battambang(fontSize: 64.sp, fontWeight: FontWeight.w700,
            color: _nodeColor(idx))),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (item.series == 'o' ? const Color(0xFF43A047) : const Color(0xFF1E88E5)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r)),
            child: Text('Hàng ${item.series}', style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp, fontWeight: FontWeight.w700,
              color: item.series == 'o' ? const Color(0xFF43A047) : const Color(0xFF1E88E5)))),
          SizedBox(height: 12.h),
          Text('${item.romanized} — ${item.pronunciation}', style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF718096))),
          SizedBox(height: 16.h),
          if (item.example.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16.r)),
              child: Column(children: [
                Text('Ví dụ', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF9098A9))),
                SizedBox(height: 4.h),
                Text(item.example, style: GoogleFonts.battambang(
                  fontSize: 28.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2D3142))),
                Text(item.exampleMeaning, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF718096))),
              ])),
          SizedBox(height: 24.h),
        ]),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final bool pointsRight;
  final Color color;
  _ArrowPainter({required this.pointsRight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      path.moveTo(0, 0); path.lineTo(size.width, size.height / 2); path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0); path.lineTo(0, size.height / 2); path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SeriesMapPainter extends CustomPainter {
  final int count;
  final double width;
  final double Function(int, double) getX;
  final double Function(int) getY;
  final int doneCount;
  final double undonePath, shadowStroke, mainStroke, highlightStroke;

  _SeriesMapPainter({required this.count, required this.width, required this.getX,
    required this.getY, required this.doneCount, required this.undonePath,
    required this.shadowStroke, required this.mainStroke, required this.highlightStroke});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = getX(i, width); final y = getY(i);
      if (i == 0) { path.moveTo(x, y); } else {
        final px = getX(i - 1, width); final py = getY(i - 1);
        path.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFD6E4F0)
      ..strokeWidth = undonePath..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    if (doneCount > 1) {
      final dp = Path();
      final si = count - 1; final ei = count - doneCount;
      for (int i = si; i >= ei; i--) {
        final x = getX(i, width); final y = getY(i);
        if (i == si) { dp.moveTo(x, y); } else {
          final px = getX(i + 1, width); final py = getY(i + 1);
          dp.cubicTo(px, (py + y) / 2, x, (py + y) / 2, x, y);
        }
      }
      canvas.drawPath(dp, Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.4)
        ..strokeWidth = shadowStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()..color = const Color(0xFF43A047)
        ..strokeWidth = mainStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.6)
        ..strokeWidth = highlightStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
