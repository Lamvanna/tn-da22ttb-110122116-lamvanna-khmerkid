import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_number.dart';
import '../../services/score_service.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../services/storage_service.dart';
import '../../repositories/progress_repository.dart';
import 'number_detail_screen.dart';


/// Bản đồ số Khmer — Premium learning path
class NumberMapScreen extends StatefulWidget {
  final VoidCallback onBack;
  const NumberMapScreen({super.key, required this.onBack});

  @override
  State<NumberMapScreen> createState() => _NumberMapScreenState();
}

class _NumberMapScreenState extends State<NumberMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;
  ScoreService? _score;

  final List<KhmerNumber> _items = KhmerNumberData.numbers;

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
    _loadScore();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    // 1. Tải nhanh từ bộ nhớ tạm local (Isar ProgressRepository) trước để giao diện hiện lên NGAY LẬP TỨC
    try {
      final localNumberProgress = await ProgressRepository.instance.getProgressMap('number');
      for (int i = 0; i < _items.length; i++) {
        if (localNumberProgress.containsKey(i)) {
          _items[i].isLearned = true;
          _items[i].starRating = localNumberProgress[i]!;
        } else {
          // Không mở khóa sẵn bài nào (mặc định học từ bài đầu tiên)
          _items[i].isLearned = false;
          _items[i].starRating = 0;
        }
      }
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      }
    } catch (e) {
      debugPrint('⚠️ Error loading local cached number progress: $e');
    }

    // 2. Chạy bất đồng bộ tải từ MongoDB Atlas trong nền
    try {
      // Tải lại tiến trình học tập mới nhất từ database MongoDB Atlas
      await AuthService().fetchProfile();

      // Tải danh sách dynamic lessons từ database để lấy Object ID thực tế
      try {
        final lessonService = await LessonService.getInstance();
        final dbLessons = await lessonService.fetchLessonsByType('number');
        final lessonIdMap = <String, String>{};
        for (final l in dbLessons) {
          final text = l['khmerText']?.toString() ?? '';
          final id = l['_id']?.toString() ?? l['id']?.toString() ?? '';
          if (text.isNotEmpty && id.isNotEmpty) {
            lessonIdMap[text] = id;
          }
        }
        for (final l in _items) {
          if (lessonIdMap.containsKey(l.character)) {
            l.id = lessonIdMap[l.character];
          }
        }
      } catch (ex) {
        debugPrint('⚠️ Error fetching dynamic number IDs: $ex');
      }

      final List<dynamic> completedLessons = List<dynamic>.from(
        AuthService().userProfile?['learningProgress']?['completedLessons'] ?? [],
      );
      
      final completedNumbers = completedLessons
          .where((l) {
            if (l is Map) {
              return l['type'] == 'number';
            }
            return false;
          })
          .map((l) => (l as Map)['khmerText']?.toString() ?? '')
          .toSet();

      final completedLessonIds = completedLessons
          .map((l) {
            if (l is Map) {
              return l['_id']?.toString() ?? l['id']?.toString() ?? '';
            }
            return l.toString();
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      final storage = await StorageService.getInstance();

      if (mounted) {
        setState(() {
          for (int i = 0; i < _items.length; i++) {
            final character = _items[i].character;
            final id = _items[i].id;

            bool isDone = completedNumbers.contains(character);
            if (!isDone && id != null && completedLessonIds.contains(id)) {
              isDone = true;
            }

            if (isDone) {
              _items[i].isLearned = true;
              if (_items[i].starRating == 0) {
                _items[i].starRating = 3;
              }
              // Đồng bộ ngược lại bộ nhớ tạm
              storage.saveNumberProgress(i, _items[i].starRating);
            } else {
              // Giữ nguyên tiến trình local đã nạp từ bộ nhớ tạm, KHÔNG tự ý ghi đè về false
            }
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      }
    } catch (e) {
      debugPrint('⚠️ Error loading online number progress: $e');
    }
  }

  void _scrollToCurrent() {
    final target = _currentIdx * _nodeSpacingY - 200.h;
    if (_scrollCtrl.hasClients) {
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
    const colors = [
      Color(0xFF00ACC1), Color(0xFF0097A7), Color(0xFF00838F),
      Color(0xFF26C6DA), Color(0xFF4DD0E1),
    ];
    return colors[(idx ~/ 2) % colors.length];
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
                  painter: _NumberMapPainter(
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(
        children: [
          Positioned(right: -40.w, top: -30.h,
            child: Container(width: 120.w, height: 120.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(left: -25.w, bottom: -20.h,
            child: Container(width: 80.w, height: 80.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 105.w, 32.h),
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
                    Flexible(child: Text('Học số Khmer',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                  ],
                ),
              ]),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4.h,
            right: 16.w,
            child: _buildHeaderStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Stars
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⭐', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text(
                '${_score?.totalStars ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        // Streak
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔥', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text(
                '${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

      final isNodeOnRight = x > w / 2;
      final labelOnLeft = isNodeOnRight;
      final labelW = 100.w;
      final labelX = labelOnLeft ? x - _nodeSize / 2 - labelW - 10.w : x + _nodeSize / 2 + 10.w;
      final labelY = y - 45.h;

      // Label
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
              child: Text('Số ${item.value}', style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp, fontWeight: FontWeight.w800,
                color: locked ? const Color(0xFFB0BEC5) : color))),
            SizedBox(height: 4.h),
            Text(item.character, style: GoogleFonts.battambang(
              fontSize: 26.sp, fontWeight: FontWeight.w700, height: 1.2,
              color: locked ? const Color(0xFFB0BEC5) : const Color(0xFF1A202C))),
            Text(item.khmerWord, style: GoogleFonts.battambang(
              fontSize: 13.sp, fontWeight: FontWeight.w500,
              color: locked ? const Color(0xFFCFD8DC) : const Color(0xFF718096))),
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

      // Node
      widgets.add(Positioned(
        left: x - _nodeSize / 2, top: y - _nodeSize / 2,
        child: GestureDetector(
          onTap: locked ? null : () => _openNumber(ri),
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color,
              border: Border.all(color: Colors.white, width: 2.w),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]),
            child: Center(child: Text(item.value, style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white))))));
      }
    }
    return widgets;
  }

  Widget _circle(KhmerNumber item, Color color, bool done, bool curr, bool locked) {
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
        style: GoogleFonts.battambang(fontSize: 30.sp, fontWeight: FontWeight.w700,
          color: Colors.white, height: 1.2,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 2, offset: const Offset(0, 1))]))));
  }

  void _openNumber(int idx) {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => NumberDetailScreen(initialIndex: idx)),
    ).then((_) {
      if (mounted) {
        _loadScore();
      }
    });
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
    path.close(); canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _NumberMapPainter extends CustomPainter {
  final int count; final double width;
  final double Function(int, double) getX; final double Function(int) getY;
  final int doneCount;
  final double undonePath, shadowStroke, mainStroke, highlightStroke;

  _NumberMapPainter({required this.count, required this.width, required this.getX,
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
      canvas.drawPath(dp, Paint()..color = const Color(0xFF00ACC1).withValues(alpha: 0.4)
        ..strokeWidth = shadowStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()..color = const Color(0xFF00ACC1)
        ..strokeWidth = mainStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      canvas.drawPath(dp, Paint()..color = const Color(0xFF4DD0E1).withValues(alpha: 0.6)
        ..strokeWidth = highlightStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
