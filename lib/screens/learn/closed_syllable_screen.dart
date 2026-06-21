import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../models/khmer_closed_syllable.dart';
import '../../repositories/progress_repository.dart';
import '../../widgets/khmer_write_widget.dart';
import '../../widgets/khmer_speak_widget.dart';

/// Màn hình học vần đóng Khmer (phụ âm đầu + phụ âm cuối + dấu ់)
class ClosedSyllableScreen extends StatefulWidget {
  final int initialIndex;
  const ClosedSyllableScreen({super.key, this.initialIndex = 0});

  @override
  State<ClosedSyllableScreen> createState() => _ClosedSyllableScreenState();
}

class _ClosedSyllableScreenState extends State<ClosedSyllableScreen>
    with SingleTickerProviderStateMixin {
  ScoreService? _score;
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerClosedSyllable> _lessons = KhmerClosedSyllableData.lessons;

  final Map<int, Set<int>> _completedSteps = {};
  int _activeSheet = 0;

  @override
  void initState() {
    _loadScore();
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/elephant_mascot.png'), context);
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  KhmerClosedSyllable get _lesson => _lessons[_idx];

  bool _canGo(int i) {
    if (_lessons.isEmpty || i < 0 || i >= _lessons.length) return false;
    if (i <= _idx) return true; // Can always go back
    final currentLessonCompleted = _lesson.isLearned || (_completedSteps[_idx]?.length == 3);
    if (i == _idx + 1) return currentLessonCompleted;
    return false;
  }

  void _goTo(int i) {
    if (!_canGo(i)) return;
    _animCtrl.reset();
    setState(() { _idx = i; _activeSheet = 0; });
    _animCtrl.forward();
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));

    if (_completedSteps[_idx]!.length == 3) _onLessonCompleted();
  }

  void _onLessonCompleted() async {
    _lesson.isLearned = true;
    _lesson.starRating = 3;

    try {
      final scoreService = await ScoreService.getInstance();
      await scoreService.completeWholeLessonReward();

      // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
      await ProgressRepository.instance.completeLesson(
        lessonId: 'closed_syllable_$_idx',
        lessonType: 'closed_syllable',
        lessonOrder: _idx,
        stars: 3,
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ Error saving closed_syllable progress: $e');
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _lessons.length - 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 56.sp)),
              SizedBox(height: 16.h),
              Text(
                context.translate('common.congratulations'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.tertiary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                context.translate('learn.completed_closed_syllable', args: {'character': _lesson.combined}),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: Offset(0, 4.h),
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Icon(
                        Icons.star_rounded,
                        size: 40.w,
                        color: const Color(0xFFFFD600),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Transform.translate(
                    offset: Offset(0, -6.h),
                    child: Icon(
                      Icons.star_rounded,
                      size: 56.w,
                      color: const Color(0xFFFFD600),
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                          blurRadius: 12.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Transform.translate(
                    offset: Offset(0, 4.h),
                    child: Transform.rotate(
                      angle: 0.15,
                      child: Icon(
                        Icons.star_rounded,
                        size: 40.w,
                        color: const Color(0xFFFFD600),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFFFF176), width: 1.5.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBC02D).withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 20.w),
                    SizedBox(width: 4.w),
                    Text(
                      '+5 Sao',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF57F17),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12.w),
                      width: 1.w,
                      height: 16.h,
                      color: const Color(0xFFF57F17).withValues(alpha: 0.3),
                    ),
                    Icon(Icons.bolt_rounded, color: const Color(0xFFFF9100), size: 20.w),
                    SizedBox(width: 4.w),
                    Text(
                      '+60 XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              if (hasNext) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tertiary, AppColors.tertiaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.35),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goTo(_idx + 1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.translate('learn.next_lesson_btn'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    side: BorderSide(color: AppColors.violet.withValues(alpha: 0.5), width: 1.5.w),
                  ),
                  child: Text(
                    context.translate('learn.back_to_map'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.violet,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStepComplete(int step) => _completedSteps[_idx]?.contains(step) ?? false;

    Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: _activeSheet == 3
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        RepaintBoundary(child: _buildSpellingCard()),
                        if (_activeSheet != 0)
                          Positioned.fill(child: _buildInlineSheet()),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _buildActionRow(),
                    SizedBox(height: 16.h),
                    _buildNavButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
    Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.learnHeaderGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: AppColors.headerDark.withValues(alpha: 0.35),
          blurRadius: 24.r, offset: Offset(0, 8.h))]),
      child: Stack(
        children: [
          Positioned(right: -20.w, top: -20.h,
            child: Container(width: 100.w, height: 100.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(left: -30.w, bottom: -10.h,
            child: Container(width: 70.w, height: 70.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, -12.h),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_rounded, size: 20)),
                            color: Colors.white, padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.w)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(context.translate('learn.closed_syllable_count', args: {'done': _idx + 1, 'total': _lessons.length}),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 13.sp)),
                            SizedBox(width: 4.w),
                            Text('${_lessons.where((l) => l.isLearned).length * 20}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 13.sp)),
                            SizedBox(width: 4.w),
                            Text('${_score?.streak ?? 0}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06), blurRadius: 20.r, offset: Offset(0, 6.h))]),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 90.h, 16.w, 24.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormulaBox(_lesson.initialConsonant, const Color(0xFF1CB0F6), context.translate('learn.spelling_initial_consonant')),
                Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: Text('+', style: GoogleFonts.plusJakartaSans(
                    fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5)))),
                _buildFormulaBox(_lesson.finalConsonant, const Color(0xFFFF4B4B), context.translate('learn.spelling_final_consonant')),
                Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: Text('=', style: GoogleFonts.plusJakartaSans(
                    fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5)))),
                _buildFormulaBox(_lesson.combined, const Color(0xFF58CC02), context.translate('learn.spelling_result')),
              ],
            ),
          ),
          SizedBox(height: 70.h),
          Container(
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                blurRadius: 10.r, offset: Offset(0, 3.h))]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lesson.romanized.isNotEmpty && _lesson.romanized != '...')
                        Text('"${_lesson.romanized}"',
                          style: GoogleFonts.battambang(
                            fontSize: 24.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
                      SizedBox(height: 6.h),
                      Row(children: [
                        Icon(Icons.volume_up_rounded, size: 16.w, color: const Color(0xFF1E88E5)),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            _lesson.meaning.isNotEmpty ? '${context.translate('learn.meaning_prefix')}${_lesson.meaning}' : context.translate('learn.closed_syllable_practice_desc'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                      ]),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 56.w, height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8.r, offset: Offset(0, 2.h))]),
                  child: Icon(Icons.school_rounded, color: const Color(0xFF1E88E5), size: 26.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaBox(String char, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 80.w, height: 80.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16.r, offset: Offset(0, 8.h))]),
          child: Center(
            child: Text(char,
              style: GoogleFonts.battambang(
                fontSize: 48.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1))),
        ),
        SizedBox(height: 10.h),
        Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }

  // ═══════════════════ INLINE SHEET OVERLAY ═══════════════════
  Widget _buildInlineSheet() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Column(children: [
              if (_activeSheet == 1)
                Expanded(child: _InlineListenContent(lesson: _lesson, onComplete: () => _markStepComplete(0))),
              if (_activeSheet == 2)
                Expanded(
                  child: KhmerSpeakWidget(
                    targetWord: _lesson.combined,
                    romanized: _lesson.romanized,
                    meaning: _lesson.meaning,
                    accentColor: const Color(0xFF1E88E5),
                    accentColorDark: const Color(0xFF1565C0),
                    surfaceColor: const Color(0xFFEEF4FC),
                    onComplete: () => _markStepComplete(1),
                  ),
                ),
              if (_activeSheet == 3)
                Expanded(
                  child: KhmerWriteWidget(
                    character: _lesson.combined,
                    label: context.translate('learn.closed_syllable'),
                    isCompound: true,
                    showStrokeGuide: true, // hiển thị hướng nét nếu có guide data
                    enableOcr: false,
                    onComplete: () => _markStepComplete(2),
                    accentColor: const Color(0xFF5E35B1),
                    accentColorDark: const Color(0xFF4527A0),
                    surfaceColor: const Color(0xFFEDE7F6),
                  ),
                ),
            ]),
            Positioned(
              top: 8.h, right: 8.w,
              child: GestureDetector(
                onTap: () => setState(() => _activeSheet = 0),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.r, offset: Offset(0, 2.h))]),
                  child: Icon(Icons.close_rounded, size: 20.sp, color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ ACTION ROW ═══════════════════
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1),
          child: _actionCard(imagePath: 'image/Nghe.png', label: context.translate('common.listen'), sub: context.translate('learning_path.spelling'),
            bgColor: const Color(0xFFE8F5E9), accentColor: const Color(0xFF43A047), stepIdx: 0))),
        SizedBox(width: 8.w),
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2),
          child: _actionCard(imagePath: 'image/Mic.png', label: context.translate('common.speak'), sub: context.translate('learn.practice_pronunciation'),
            bgColor: const Color(0xFFE3F2FD), accentColor: const Color(0xFF1E88E5), stepIdx: 1))),
        SizedBox(width: 8.w),
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3),
          child: _actionCard(imagePath: 'image/Viết.png', label: context.translate('common.write'), sub: context.translate('learn.practice_writing_compound'),
            bgColor: const Color(0xFFEDE7F6), accentColor: const Color(0xFF5E35B1), stepIdx: 2))),
      ],
    );
  }

  Widget _actionCard({
    required String imagePath, required String label, required String sub,
    required Color bgColor, required Color accentColor, required int stepIdx,
  }) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: done ? accentColor.withValues(alpha: 0.6) : accentColor.withValues(alpha: 0.18),
          width: done ? 2.5 : 1.5),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 16.r, offset: Offset(0, 6.h))]),
      child: Column(children: [
        Image.asset(imagePath, width: 64.w, height: 64.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          if (done) ...[SizedBox(width: 4.w), Icon(Icons.check_circle_rounded, size: 14.w, color: accentColor)],
        ]),
        SizedBox(height: 2.h),
        Text(sub, textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]),
    );
  }

  // ═══════════════════ NAV BUTTONS ═══════════════════
  Widget _buildNavButtons() {
    final hasPrev = _idx > 0;
    final hasNext = _idx < _lessons.length - 1;
    final canNext = _canGo(_idx + 1);
    final labels = [context.translate('common.listen'), context.translate('common.speak'), context.translate('common.write')];
    final stepColors = [const Color(0xFF43A047), const Color(0xFF1E88E5), const Color(0xFF5E35B1)];
    return Row(
      children: [
        GestureDetector(
          onTap: hasPrev ? () => _goTo(_idx - 1) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.12)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6.r, offset: Offset(0, 2.h))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: hasPrev ? const Color(0xFF1E88E5) : AppColors.textHint, size: 18.w),
              Text(context.translate('common.back'), style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: hasPrev ? const Color(0xFF1E88E5) : AppColors.textHint)),
            ]),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                if (i.isOdd) {
                  final stepI = i ~/ 2;
                  final prevDone = _isStepComplete(stepI);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (_) => Container(
                      width: 4.w,
                      height: 2.5.h,
                      margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                      decoration: BoxDecoration(
                        color: prevDone
                            ? stepColors[stepI].withValues(alpha: 0.5)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    )),
                  );
                }
                final stepI = i ~/ 2;
                final done = _isStepComplete(stepI);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: done
                              ? [stepColors[stepI], stepColors[stepI].withValues(alpha: 0.7)]
                              : [const Color(0xFFE8E8E8), const Color(0xFFD8D8D8)],
                        ),
                        boxShadow: done
                            ? [BoxShadow(color: stepColors[stepI].withValues(alpha: 0.35), blurRadius: 6.r, offset: Offset(0, 2.h))]
                            : null,
                      ),
                      child: Center(
                        child: done
                            ? Icon(Icons.check_rounded, size: 14.w, color: Colors.white)
                            : Text(
                                '${stepI + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      labels[stepI],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: done ? stepColors[stepI] : AppColors.textHint,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: () {
            if (canNext) {
              _goTo(_idx + 1);
            } else if (hasNext) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.translate('learn.complete_activities_warning')),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: canNext ? const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]) : null,
              color: canNext ? null : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: canNext ? [BoxShadow(color: const Color(0xFF1E88E5).withValues(alpha: 0.35), blurRadius: 10.r, offset: Offset(0, 3.h))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(canNext ? context.translate('common.next') : context.translate('common.locked'), style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: canNext ? Colors.white : AppColors.textHint)),
              SizedBox(width: 4.w),
              Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded, color: canNext ? Colors.white : AppColors.textHint, size: 18.w),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE NGHE (TTS)
// ═══════════════════════════════════════════════════════════════
class _InlineListenContent extends StatefulWidget {
  final KhmerClosedSyllable lesson;
  final VoidCallback onComplete;
  const _InlineListenContent({required this.lesson, required this.onComplete});
  @override
  State<_InlineListenContent> createState() => _InlineListenContentState();
}

class _InlineListenContentState extends State<_InlineListenContent>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _playCount = 0;
  bool _ttsReady = false;
  bool _khmerSupported = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(_khmerSupported ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    _tts.setErrorHandler((_) { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    if (mounted) setState(() => _ttsReady = true);
  }

  @override
  void dispose() { _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() { _isPlaying = true; _playCount++; });
    _pulseCtrl.repeat(reverse: true);
    final text = _khmerSupported
        ? '${widget.lesson.initialConsonant} ${widget.lesson.finalConsonant} ${widget.lesson.combined}'
        : widget.lesson.meaning;
    final result = await _tts.speak(text);
    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); }
      });
    }
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.headphones_rounded, color: AppColors.tertiary, size: 20.w),
          SizedBox(width: 8.w),
          Text(context.translate('learn.listen_closed_syllable'),
            style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.tertiaryDark)),
        ])),
      Expanded(
        child: Align(
          alignment: const Alignment(0, -0.2),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.tertiarySurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.15))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _smallCharBox(widget.lesson.initialConsonant, const Color(0xFF1E88E5)),
                  SizedBox(width: 8.w),
                  Icon(Icons.add, color: AppColors.textHint, size: 16.sp),
                  SizedBox(width: 8.w),
                  _smallCharBox(widget.lesson.finalConsonant, const Color(0xFFE53935)),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 16.sp),
                  SizedBox(width: 8.w),
                  _smallCharBox(widget.lesson.combined, const Color(0xFF43A047)),
                ])),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: _ttsReady ? _play : null,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) => Container(
                    width: 140.w, height: 140.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.5 : 0.25),
                        width: 1.5.w, strokeAlign: BorderSide.strokeAlignOutside)),
                    child: Center(
                      child: Container(
                        width: 120.w, height: 120.w,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiarySurface),
                        child: Center(
                          child: Container(
                            width: 90.w, height: 90.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: _isPlaying
                                    ? [AppColors.tertiary, AppColors.tertiaryDark]
                                    : [AppColors.tertiaryLight, AppColors.tertiary]),
                              boxShadow: [BoxShadow(
                                color: AppColors.tertiary.withValues(alpha: 0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0)),
                                blurRadius: (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r,
                                offset: Offset(0, 4.h))]),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white, size: 40.w)))))))),
              SizedBox(height: 14.h),
              // Wave sound animation bars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  11,
                  (i) {
                    final center = 5;
                    final dist = (i - center).abs();
                    final baseH = dist <= 1 ? 20.h : dist <= 3 ? 10.h : 5.h;
                    final h = _isPlaying ? baseH * (0.5 + 0.5 * _pulseCtrl.value) : baseH * 0.4;
                    return Container(
                      width: dist <= 1 ? 4.w : 3.w,
                      height: h,
                      margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _isPlaying ? context.translate('learn.pronouncing_closed_syllable')
                    : _playCount > 0 ? context.translate('learn.listened_closed_syllable_count_label', args: {'count': _playCount})
                    : context.translate('learn.press_to_listen'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w600,
                  color: _isPlaying ? AppColors.tertiary : AppColors.textHint)),
            ])),
        )),
    ]);
  }

  Widget _smallCharBox(String ch, Color c) {
    return Container(
      width: 52.w, height: 52.w,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1.5)),
      child: Center(child: Text(ch,
        style: GoogleFonts.battambang(fontSize: 18.sp, fontWeight: FontWeight.w700, color: c))),
    );
  }
}


