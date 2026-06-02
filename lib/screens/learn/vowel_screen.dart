import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import 'vowel_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../services/storage_service.dart';
import '../../repositories/progress_repository.dart';


/// Bản đồ nguyên âm Khmer — Premium learning path (giống phụ âm)
class VowelScreen extends StatefulWidget {
  final VoidCallback onBack;
  const VowelScreen({super.key, required this.onBack});

  @override
  State<VowelScreen> createState() => _VowelScreenState();
}

class _VowelScreenState extends State<VowelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;

  final List<KhmerVowel> _vowels = KhmerVowelData.vowels;

  // Responsive constants — giống phụ âm
  double get _nodeSpacingY => 140.h;
  double get _topPadding => 80.h;
  double get _nodeSize => 78.w;

  int get _currentIdx {
    final idx = _vowels.indexWhere((v) => !v.isLearned);
    return idx == -1 ? _vowels.length - 1 : idx;
  }

  int get _doneCount => _vowels.where((v) => v.isLearned).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    _loadScore();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  Future<void> _loadScore() async {
    // 1. Tải nhanh từ bộ nhớ tạm local (Isar ProgressRepository) trước để giao diện hiện lên NGAY LẬP TỨC
    try {
      final localVowelProgress = await ProgressRepository.instance.getProgressMap('vowel');
      for (int i = 0; i < _vowels.length; i++) {
        if (localVowelProgress.containsKey(i)) {
          _vowels[i].isLearned = true;
          _vowels[i].starRating = localVowelProgress[i]!;
        } else {
          // Không mở khóa sẵn bài nào (mặc định học từ bài đầu tiên)
          _vowels[i].isLearned = false;
          _vowels[i].starRating = 0;
        }
      }
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      }
    } catch (e) {
      debugPrint('⚠️ Error loading local cached vowel progress: $e');
    }

    // 2. Chạy bất đồng bộ tải từ MongoDB Atlas trong nền
    try {
      // Tải lại tiến trình học tập mới nhất từ database MongoDB Atlas
      await AuthService().fetchProfile();

      // Tải danh sách dynamic lessons từ database để lấy Object ID thực tế
      try {
        final lessonService = await LessonService.getInstance();
        final dbLessons = await lessonService.fetchLessonsByType('vowel');
        final lessonIdMap = <String, String>{};
        for (final l in dbLessons) {
          final text = l['khmerText']?.toString() ?? '';
          final id = l['_id']?.toString() ?? l['id']?.toString() ?? '';
          if (text.isNotEmpty && id.isNotEmpty) {
            lessonIdMap[text] = id;
          }
        }
        for (final l in _vowels) {
          if (lessonIdMap.containsKey(l.character)) {
            l.id = lessonIdMap[l.character];
          }
        }
      } catch (ex) {
        debugPrint('⚠️ Error fetching dynamic vowel IDs: $ex');
      }

      final List<dynamic> completedLessons = List<dynamic>.from(
        AuthService().userProfile?['learningProgress']?['completedLessons'] ?? [],
      );
      
      final completedVowels = completedLessons
          .where((l) {
            if (l is Map) {
              return l['type'] == 'vowel';
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

      for (int i = 0; i < _vowels.length; i++) {
        final character = _vowels[i].character;
        final id = _vowels[i].id;

        bool isDone = completedVowels.contains(character);
        if (!isDone && id != null && completedLessonIds.contains(id)) {
          isDone = true;
        }

        if (isDone) {
          _vowels[i].isLearned = true;
          if (_vowels[i].starRating == 0) {
            _vowels[i].starRating = 3;
          }
          // Đồng bộ ngược lại bộ nhớ tạm
          await storage.saveVowelProgress(i, _vowels[i].starRating);
        } else {
          // Giữ nguyên tiến trình local đã nạp từ bộ nhớ tạm, KHÔNG tự ý ghi đè về false
        }
      }
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      }
    } catch (e) {
      debugPrint('⚠️ Error loading online vowel progress: $e');
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

  // Zigzag positions
  double _nodeX(int displayIdx, double w) {
    final centerX = w / 2;
    final amplitude = w * 0.18;
    return centerX + sin(displayIdx * 0.6) * amplitude;
  }

  double _nodeY(int displayIdx) => _topPadding + displayIdx * _nodeSpacingY;

  // 5 màu xoay vòng
  Color _nodeColor(int idx) {
    const colors = [
      Color(0xFF2979FF),
      Color(0xFF00E676),
      Color(0xFFFFD600),
      Color(0xFFAA00FF),
      Color(0xFFFF1744),
    ];
    return colors[(idx ~/ 3) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mapH = _vowels.length * _nodeSpacingY + 120.h;

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
                width: w,
                height: mapH,
                child: CustomPaint(
                  painter: _VowelMapPainter(
                    count: _vowels.length,
                    width: w,
                    getX: _nodeX,
                    getY: _nodeY,
                    doneCount: _doneCount,
                    undonePath: 10.w,
                    shadowStroke: 12.w,
                    mainStroke: 8.w,
                    highlightStroke: 3.w,
                  ),
                  child: Stack(children: _buildAllNodes(w)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final progress = _vowels.isEmpty ? 0.0 : _doneCount / _vowels.length;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -40.w, top: -30.h,
          child: Container(width: 120.w, height: 120.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25.w, bottom: -20.h,
          child: Container(width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Mascot elephant
        Positioned(
          right: 0, bottom: -2.h,
          child: Image.asset('image/Voi nguyên âm.png',
            width: 100.w, height: 100.w, fit: BoxFit.contain)),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 105.w, 5.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: Back + Title
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
                    Flexible(child: Text('Học nguyên âm Khmer',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                  ],
                ),
                SizedBox(height: 0.h),
                Padding(
                  padding: EdgeInsets.only(left: 48.w),
                  child: Text('$_doneCount/${_vowels.length} đã hoàn thành',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85))),
                ),
                SizedBox(height: 4.h),
                // Progress bar
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
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                              borderRadius: BorderRadius.circular(4.r),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF43A047).withValues(alpha: 0.5),
                                blurRadius: 6)])))]),
                    )),
                    SizedBox(width: 8.w),
                    Text('$pct%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─── ALL NODES ───
  List<Widget> _buildAllNodes(double w) {
    final widgets = <Widget>[];

    for (int i = 0; i < _vowels.length; i++) {
      final ri = _vowels.length - 1 - i;
      final vowel = _vowels[ri];
      final x = _nodeX(i, w);
      final y = _nodeY(i);
      final done = vowel.isLearned;
      final curr = ri == _currentIdx;
      final locked = !done && !curr;
      final color = _nodeColor(ri);
      final baiNum = ri + 1;

      // Label position: alternate left/right
      final isNodeOnRight = x > w / 2;
      final labelOnLeft = isNodeOnRight;

      // ── Label card ──
      final labelW = 95.w;
      final labelX = labelOnLeft
          ? x - _nodeSize / 2 - labelW - 10.w
          : x + _nodeSize / 2 + 10.w;
      final labelY = y - 45.h;

      widgets.add(
        Positioned(
          left: labelX, top: labelY,
          child: Container(
            width: labelW,
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
            decoration: BoxDecoration(
              color: locked ? Colors.white.withValues(alpha: 0.45) : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: locked ? null : Border.all(
                color: color.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: locked ? Colors.black.withValues(alpha: 0.03) : color.withValues(alpha: 0.10),
                  blurRadius: 14, offset: const Offset(0, 5)),
                if (!locked) BoxShadow(
                  color: color.withValues(alpha: 0.06), blurRadius: 4, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: locked ? const Color(0xFFE8EEF5) : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r)),
                  child: Text('Bài $baiNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp, fontWeight: FontWeight.w800,
                      color: locked ? const Color(0xFFB0BEC5) : color)),
                ),
                SizedBox(height: 4.h),
                Text(vowel.character.replaceFirst('អ', ''),
                  style: GoogleFonts.battambang(
                    fontSize: 36.sp, fontWeight: FontWeight.w700, height: 1.2,
                    color: locked ? const Color(0xFFB0BEC5) : const Color(0xFF1A202C))),
                Text(vowel.romanized.isNotEmpty
                    ? vowel.romanized[0].toUpperCase() + vowel.romanized.substring(1) : '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w500,
                    color: locked ? const Color(0xFFCFD8DC) : const Color(0xFF718096))),
                SizedBox(height: 4.h),
                Row(mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (si) => Icon(
                    Icons.star_rounded, size: 16.w,
                    color: (done && si < vowel.starRating)
                        ? const Color(0xFFFFB300)
                        : locked
                            ? const Color(0xFFE0E0E0).withValues(alpha: 0.4)
                            : const Color(0xFFE0E0E0)))),
              ],
            ),
          ),
        ),
      );

      // ── Arrow pointer ──
      final arrowX = labelOnLeft ? labelX + labelW - 2.w : labelX - 8.w;
      widgets.add(
        Positioned(
          left: arrowX, top: y - 6.h,
          child: CustomPaint(
            size: Size(14.w, 16.h),
            painter: _ArrowPainter(
              pointsRight: labelOnLeft,
              color: locked ? Colors.white.withValues(alpha: 0.45) : Colors.white)),
        ),
      );

      // ── Node circle ──
      widgets.add(
        Positioned(
          left: x - _nodeSize / 2, top: y - _nodeSize / 2,
          child: GestureDetector(
            onTap: locked ? null : () => _openVowel(ri),
            child: SizedBox(
              width: _nodeSize, height: _nodeSize,
              child: curr
                  ? AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value, child: child),
                      child: _circle(vowel, color, done, curr, locked))
                  : _circle(vowel, color, done, curr, locked),
            ),
          ),
        ),
      );

      // ── Lesson number badge ──
      if (!locked) {
        widgets.add(
          Positioned(
            left: x + _nodeSize / 2 - 16.w,
            top: y - _nodeSize / 2 - 4.h,
            child: Container(
              width: 22.w, height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]),
              child: Center(child: Text('$baiNum',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _circle(KhmerVowel vowel, Color color, bool done, bool curr, bool locked) {
    if (locked) {
      return Container(
        width: _nodeSize, height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 3.w)),
        child: Icon(Icons.lock_rounded, color: AppColors.textHint, size: 22.w),
      );
    }

    return Container(
      width: _nodeSize, height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.20)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
          stops: const [0.0, 0.45, 1.0]),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.4)!, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
            blurRadius: 0, offset: Offset(0, 4.h)),
          if (curr) BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 18, spreadRadius: 2),
        ]),
      child: Center(
        child: Text(vowel.character.replaceFirst('អ', ''),
          style: GoogleFonts.battambang(
            fontSize: 40.sp, fontWeight: FontWeight.w700,
            color: Colors.white, height: 1.0,
            shadows: [Shadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 2, offset: const Offset(0, 1))]))),
    );
  }

  void _openVowel(int idx) {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => VowelDetailScreen(initialIndex: idx)),
    ).then((_) {
      if (mounted) {
        _loadScore();
      }
    });
  }
}

// ═══════════════════════════════════════════════
// ARROW PAINTER — label → node pointer
// ═══════════════════════════════════════════════

class _ArrowPainter extends CustomPainter {
  final bool pointsRight;
  final Color color;
  _ArrowPainter({required this.pointsRight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════
// MAP PAINTER — path + subtle decorations
// ═══════════════════════════════════════════════

class _VowelMapPainter extends CustomPainter {
  final int count;
  final double width;
  final double Function(int, double) getX;
  final double Function(int) getY;
  final int doneCount;
  final double undonePath;
  final double shadowStroke;
  final double mainStroke;
  final double highlightStroke;

  _VowelMapPainter({
    required this.count,
    required this.width,
    required this.getX,
    required this.getY,
    required this.doneCount,
    required this.undonePath,
    required this.shadowStroke,
    required this.mainStroke,
    required this.highlightStroke,
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
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFD6E4F0)
      ..strokeWidth = undonePath
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Done portion — gradient path
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
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.4)
        ..strokeWidth = shadowStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);

      // Main
      canvas.drawPath(dp, Paint()
        ..color = const Color(0xFF2979FF)
        ..strokeWidth = mainStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);

      // Highlight
      canvas.drawPath(dp, Paint()
        ..color = const Color(0xFF82B1FF).withValues(alpha: 0.6)
        ..strokeWidth = highlightStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
