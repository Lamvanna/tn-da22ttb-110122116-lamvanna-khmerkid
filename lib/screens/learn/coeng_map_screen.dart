import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/khmer_coeng.dart';
import '../../constants/app_colors.dart';
import 'coeng_screen.dart';

/// Bản đồ phụ âm có chân — Timeline cards nhóm theo cụm phụ âm kép
class CoengMapScreen extends StatefulWidget {
  const CoengMapScreen({super.key});
  @override
  State<CoengMapScreen> createState() => _CoengMapScreenState();
}

class _CoengMapScreenState extends State<CoengMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _staggerCtrl;

  final List<KhmerCoeng> _lessons = KhmerCoengData.lessons;

  List<_ClusterGroup> get _groups {
    final map = <String, List<_IndexedLesson>>{};
    for (int i = 0; i < _lessons.length; i++) {
      final key = '${_lessons[i].upperConsonant}្${_lessons[i].lowerConsonant}';
      map.putIfAbsent(key, () => []);
      map[key]!.add(_IndexedLesson(index: i, lesson: _lessons[i]));
    }
    int groupNum = 0;
    return map.entries.map((e) {
      groupNum++;
      final items = e.value;
      final done = items.where((il) => il.lesson.isLearned).length;
      final total = items.length;
      return _ClusterGroup(
        number: groupNum,
        cluster: e.key,
        items: items,
        doneCount: done,
        totalCount: total,
      );
    }).toList();
  }

  int get _totalDone => _lessons.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _staggerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _staggerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(10.w, 18.h, 16.w, 100.h),
            child: Column(
              children: List.generate(groups.length, (i) {
                final delay = (i * 0.12).clamp(0.0, 1.0);
                final end = (delay + 0.4).clamp(0.0, 1.0);
                final anim = CurvedAnimation(
                  parent: _staggerCtrl,
                  curve: Interval(delay, end, curve: Curves.easeOutCubic));
                return AnimatedBuilder(
                  animation: anim,
                  builder: (_, child) => Opacity(
                    opacity: anim.value,
                    child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child)),
                  child: _GroupCard(
                    group: groups[i],
                    isLast: i == groups.length - 1,
                    pulseCtrl: _pulseCtrl,
                    onOpenLesson: _openLesson));
              }),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final progress = _lessons.isNotEmpty ? _totalDone / _lessons.length : 0.0;
    final pct = (progress * 100).toInt();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFFE65100), Color(0xFFFF6D00), Color(0xFFFFB300)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: const Color(0xFFE65100).withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(children: [
        Positioned(right: -40.w, top: -30.h,
          child: Container(width: 120.w, height: 120.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25.w, bottom: -20.h,
          child: Container(width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
        Positioned(right: 0, bottom: -2.h,
          child: Image.asset('assets/images/elephant_mascot.png',
            width: 100.w, height: 100.w, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 2.h, 105.w, 4.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 36.w, height: 36.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w))),
                  SizedBox(width: 12.w),
                  Flexible(child: Text('Phụ âm chân ្',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              SizedBox(height: 0.h),
              Padding(padding: EdgeInsets.only(left: 48.w),
                child: Text('$_totalDone/${_lessons.length} đã hoàn thành',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)))),
              SizedBox(height: 4.h),
              Padding(padding: EdgeInsets.only(left: 48.w),
                child: Row(children: [
                  Expanded(child: Container(height: 6.h,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4.r)),
                    child: Stack(children: [
                      FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: [BoxShadow(color: const Color(0xFF43A047).withValues(alpha: 0.5), blurRadius: 6)])))]))),
                  SizedBox(width: 8.w),
                  Text('$pct%', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
            ]))),
      ]),
    );
  }

  void _openLesson(int idx) {
    HapticFeedback.lightImpact();
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => CoengScreen(initialIndex: idx)),
    ).then((_) { if (mounted) setState(() {}); });
  }
}

// ════════════════════════════════════════════════════════════════
//  MODELS
// ════════════════════════════════════════════════════════════════
class _IndexedLesson {
  final int index;
  final KhmerCoeng lesson;
  const _IndexedLesson({required this.index, required this.lesson});
}

class _ClusterGroup {
  final int number;
  final String cluster;
  final List<_IndexedLesson> items;
  final int doneCount;
  final int totalCount;

  const _ClusterGroup({required this.number, required this.cluster, required this.items, required this.doneCount, required this.totalCount});

  double get progress => totalCount > 0 ? doneCount / totalCount : 0.0;
  bool get isCompleted => doneCount >= totalCount;
  bool get hasStarted => doneCount > 0;
  int get starCount { if (isCompleted) return 3; if (progress >= 0.5) return 2; if (hasStarted) return 1; return 0; }
}

// ════════════════════════════════════════════════════════════════
//  GROUP CARD
// ════════════════════════════════════════════════════════════════
class _GroupCard extends StatelessWidget {
  final _ClusterGroup group;
  final bool isLast;
  final AnimationController pulseCtrl;
  final void Function(int) onOpenLesson;

  const _GroupCard({required this.group, required this.isLast, required this.pulseCtrl, required this.onOpenLesson});

  Color get _groupColor {
    const colors = [Color(0xFFFF6D00), Color(0xFFE65100), Color(0xFFF4511E), Color(0xFFFF8F00), Color(0xFFEF6C00)];
    return colors[(group.number - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupColor;
    final pct = (group.progress * 100).toInt();
    final isCurrent = group.hasStarted && !group.isCompleted;
    final isLocked = !group.hasStarted && group.number > 1;

    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 52.w, child: Column(children: [
        SizedBox(height: 14.h),
        _buildNumberCircle(color, isCurrent, isLocked),
        SizedBox(height: 6.h),
        _buildStars(color, isLocked),
        if (!isLast) Expanded(child: CustomPaint(
          painter: _DottedLinePainter(color: isLocked ? const Color(0xFFD0D5E0) : color.withValues(alpha: 0.3)))),
      ])),
      Expanded(child: GestureDetector(
        onTap: isLocked ? null : () {
          final firstUndone = group.items.firstWhere((il) => !il.lesson.isLearned, orElse: () => group.items.first);
          onOpenLesson(firstUndone.index);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 18.h), padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isLocked ? Colors.white.withValues(alpha: 0.7) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isLocked ? const Color(0xFFE0E5F0) : isCurrent ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.15),
              width: isCurrent ? 2.0 : 1.5),
            boxShadow: [
              BoxShadow(color: isLocked ? Colors.black.withValues(alpha: 0.03) : color.withValues(alpha: 0.10), blurRadius: 16.r, offset: Offset(0, 6.h)),
              if (isCurrent) BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 20.r, spreadRadius: 1),
            ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: isLocked ? const Color(0xFFE8EDF5) : color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
                child: Text('Bài ${group.number}', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isLocked ? const Color(0xFFB0B8C8) : color))),
              SizedBox(width: 10.w),
              Expanded(child: Text('Cụm ${group.cluster}',
                style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: isLocked ? const Color(0xFFB0B8C8) : AppColors.textPrimary))),
              if (group.isCompleted)
                Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8.r)),
                  child: Text('Hoàn thành', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))))
              else if (!isLocked) Text('$pct%', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w800, color: color)),
            ]),
            SizedBox(height: 4.h),
            Text('Ghép ${group.cluster} với các nguyên âm',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w500, color: isLocked ? const Color(0xFFC0C8D8) : AppColors.textSecondary)),
            SizedBox(height: 12.h),
            _buildCharCircles(color, isLocked),
            SizedBox(height: 12.h),
            Row(children: [
              Expanded(child: Container(height: 7.h,
                decoration: BoxDecoration(color: isLocked ? const Color(0xFFE8EDF5) : color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4.r)),
                child: Stack(children: [FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: group.progress.clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]), borderRadius: BorderRadius.circular(4.r))))]))),
              SizedBox(width: 10.w),
              Text('${group.doneCount}/${group.totalCount} chữ', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w700, color: isLocked ? const Color(0xFFC0C8D8) : AppColors.textSecondary)),
              SizedBox(width: 8.w),
              Container(width: 34.w, height: 34.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isLocked ? const Color(0xFFE8EDF5) : color,
                  boxShadow: isLocked ? [] : [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8.r, offset: Offset(0, 3.h))]),
                child: Icon(isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded, color: isLocked ? const Color(0xFFB0B8C8) : Colors.white, size: isLocked ? 16.sp : 22.sp)),
            ]),
          ]),
        ),
      )),
    ]));
  }

  Widget _buildNumberCircle(Color color, bool isCurrent, bool isLocked) {
    if (isLocked) return Container(width: 42.w, height: 42.w,
      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE0E5F0), border: Border.all(color: const Color(0xFFD0D5E0), width: 3.w)),
      child: Center(child: Text('${group.number}', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0B8C8)))));
    final circle = Container(width: 42.w, height: 42.w,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.2)!, color]),
        border: Border.all(color: Color.lerp(color, Colors.white, 0.4)!, width: 3.w),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10.r, offset: Offset(0, 3.h)),
          if (isCurrent) BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16.r, spreadRadius: 2)]),
      child: Center(child: group.isCompleted
          ? Icon(Icons.check_rounded, color: Colors.white, size: 22.sp)
          : Text('${group.number}', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white))));
    if (isCurrent) return AnimatedBuilder(animation: pulseCtrl,
      builder: (_, child) => Transform.scale(scale: 1.0 + pulseCtrl.value * 0.06, child: child), child: circle);
    return circle;
  }

  Widget _buildStars(Color color, bool isLocked) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(Icons.star_rounded, size: 14.w,
        color: isLocked ? const Color(0xFFE0E5F0) : (i < group.starCount ? const Color(0xFFFFB300) : const Color(0xFFE0E0E0)))));
  }

  Widget _buildCharCircles(Color color, bool isLocked) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
      child: Padding(padding: EdgeInsets.only(top: 6.h, bottom: 2.h),
        child: Row(children: List.generate(group.items.length, (i) {
          final il = group.items[i]; final done = il.lesson.isLearned;
          return Padding(padding: EdgeInsets.only(right: 8.w),
            child: _CharCircle(character: il.lesson.combined, isDone: done, isLocked: isLocked, color: color,
              onTap: isLocked ? null : () => onOpenLesson(il.index)));
        }))));
  }
}

// ════════════════════════════════════════════════════════════════
class _CharCircle extends StatefulWidget {
  final String character; final bool isDone; final bool isLocked; final Color color; final VoidCallback? onTap;
  const _CharCircle({required this.character, required this.isDone, required this.isLocked, required this.color, this.onTap});
  @override
  State<_CharCircle> createState() => _CharCircleState();
}

class _CharCircleState extends State<_CharCircle> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;
  @override
  void initState() { super.initState(); _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120)); _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut)); }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  void _handleTap() { if (widget.onTap == null) return; HapticFeedback.lightImpact(); _tapCtrl.forward().then((_) { _tapCtrl.reverse(); widget.onTap!(); }); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap,
      child: AnimatedBuilder(animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: SizedBox(width: 48.w, height: 48.w,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(width: 48.w, height: 48.w,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r),
                color: widget.isLocked ? const Color(0xFFF0F2F8) : widget.isDone ? widget.color.withValues(alpha: 0.10) : const Color(0xFFF5F7FC),
                border: Border.all(color: widget.isLocked ? const Color(0xFFE0E5F0) : widget.isDone ? widget.color.withValues(alpha: 0.30) : const Color(0xFFD8DDE8), width: 2.w)),
              child: Center(child: widget.isLocked
                  ? Icon(Icons.lock_rounded, color: const Color(0xFFB8C0D0), size: 18.sp)
                  : Text(widget.character, style: GoogleFonts.battambang(fontSize: 14.sp, fontWeight: FontWeight.w700, height: 1.2, color: widget.isDone ? widget.color : const Color(0xFF64748B))))),
            if (widget.isDone) Positioned(top: -4.h, right: -4.w,
              child: Container(width: 18.w, height: 18.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color, border: Border.all(color: Colors.white, width: 2.w), boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 4.r)]),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 10.sp))),
            if (widget.isLocked) Positioned(top: -4.h, right: -4.w,
              child: Container(width: 18.w, height: 18.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD0D5E0), border: Border.all(color: Colors.white, width: 2.w)),
                child: Icon(Icons.lock_rounded, color: Colors.white, size: 9.sp))),
          ]))));
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final cx = size.width / 2; double y = 6;
    while (y < size.height) { canvas.drawCircle(Offset(cx, y), 1.5, paint); y += 8; }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
