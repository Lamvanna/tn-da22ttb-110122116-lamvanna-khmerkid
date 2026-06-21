import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../models/khmer_diacritical.dart';
import '../../widgets/khmer_write_widget.dart';
import '../../widgets/khmer_speak_widget.dart';
import '../../repositories/progress_repository.dart';


/// Màn hình học dấu Khmer cao cấp (đồng bộ 100% SpellingScreen)
/// Tích hợp TTS (Nghe), Bảng vẽ (Tập viết)
class DiacriticalScreen extends StatefulWidget {
  final int initialIndex;
  const DiacriticalScreen({super.key, this.initialIndex = 0});

  @override
  State<DiacriticalScreen> createState() => _DiacriticalScreenState();
}

class _DiacriticalScreenState extends State<DiacriticalScreen>
    with SingleTickerProviderStateMixin {
  ScoreService? _score;
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerDiacritical> _lessons = KhmerDiacriticalData.diacriticals;
  final Map<int, Set<int>> _completedSteps = {};
  int _activeSheet = 0;
  bool _isAlreadyDone = false;

  @override
  void initState() {
    _loadScore();
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerDiacritical get _lesson => _lessons[_idx];

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
    setState(() {
      _idx = i;
      _activeSheet = 0;
    });
    _animCtrl.forward();
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));

    if (_completedSteps[_idx]!.length == 3) _onLessonCompleted();
  }

  void _onLessonCompleted() {
    setState(() {
      _lesson.isLearned = true;
      _lesson.starRating = 3;
    });

    final lessonId = 'diacritical_$_idx';
    ProgressRepository.instance.isLessonCompleted(lessonId).then((done) {
      if (mounted) {
        setState(() {
          _isAlreadyDone = done;
        });
      }
    });

    ScoreService.getInstance().then((scoreService) {
      return scoreService.completeDiacriticalLesson(
        _idx,
        14,
        xp: 110,
        lessonId: lessonId,
        diacriticalText: _lesson.character,
        transliteration: _lesson.romanized,
      );
    }).then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint('Error saving diacritical progress: $e');
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
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
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: SingleChildScrollView(
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
                  context.translate('learn.completed_diacritic', args: {'character': _lesson.name}),
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
                if (!_isAlreadyDone)
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
                          '+14 Sao',
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
                          '+110 XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isAlreadyDone)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.grey[300]!, width: 1.5.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.grey[600], size: 20.w),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            'Đã hoàn thành (Không cộng thêm Sao)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                            ),
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
                        if (_activeSheet != 0) Positioned.fill(child: _buildInlineSheet()),
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
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerDark.withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            top: -20.h,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -30.w,
            bottom: -10.h,
            child: Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
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
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 20),
                            ),
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.w),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              context.translate('learn.diacritic_count', args: {'done': _idx + 1, 'total': _lessons.length}),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 13.sp)),
                            SizedBox(width: 4.w),
                            Text(
                              '${_lessons.where((l) => l.isLearned).length * 20}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 13.sp)),
                            SizedBox(width: 4.w),
                            Text(
                              '${_score?.streak ?? 0}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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

  _DiacriticalFormula _getFormula(KhmerDiacritical item) {
    final signStr = '◌${item.character}';
    switch (item.character) {
      case '់':
        return _DiacriticalFormula(
          base: 'ក',
          sign: signStr,
          result: 'កក់',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Bantoc',
          resultLabel: 'Từ gội',
        );
      case 'ំ':
        return _DiacriticalFormula(
          base: 'ក',
          sign: signStr,
          result: 'កំ',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Nikahit',
          resultLabel: 'Từ nắm',
        );
      case 'ះ':
        return _DiacriticalFormula(
          base: 'ស',
          sign: signStr,
          result: 'សះ',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Reahmuk',
          resultLabel: 'Từ lành',
        );
      case 'ៈ':
        return _DiacriticalFormula(
          base: 'ន',
          sign: signStr,
          result: 'នៈ',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Yukolpintu',
          resultLabel: 'Từ ấy',
        );
      case '៉':
        return _DiacriticalFormula(
          base: 'ម',
          sign: signStr,
          result: 'ម៉ា',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Musekadoan',
          resultLabel: 'Từ mẹ',
        );
      case '៊':
        return _DiacriticalFormula(
          base: 'ស',
          sign: signStr,
          result: 'ស៊ី',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Treysap',
          resultLabel: 'Từ ăn',
        );
      case '្':
        return _DiacriticalFormula(
          base: 'ស',
          sign: signStr,
          result: 'ស្រា',
          baseLabel: 'Phụ âm',
          signLabel: 'Dấu Cheung',
          resultLabel: 'Từ rượu',
        );
      case 'ៗ':
        return _DiacriticalFormula(
          base: 'ធំ',
          sign: signStr,
          result: 'ធំៗ',
          baseLabel: 'Từ đơn',
          signLabel: 'Dấu Lekto',
          resultLabel: 'Lặp từ',
        );
      case '។':
        return _DiacriticalFormula(
          base: 'ខ្ញុំទៅ',
          sign: signStr,
          result: 'ខ្ញុំទៅ។',
          baseLabel: 'Vế câu',
          signLabel: 'Dấu Khan',
          resultLabel: 'Cuối câu',
        );
      case '៎':
        return _DiacriticalFormula(
          base: 'អត់',
          sign: signStr,
          result: 'អត់៎',
          baseLabel: 'Từ cảm thán',
          signLabel: 'Dấu Kakabat',
          resultLabel: 'Nhấn mạnh',
        );
      case '៌':
        return _DiacriticalFormula(
          base: 'ធម',
          sign: signStr,
          result: 'ធម៌',
          baseLabel: 'Phần gốc',
          signLabel: 'Dấu Robat',
          resultLabel: 'Từ Pháp',
        );
      case '័':
        return _DiacriticalFormula(
          base: 'ខ',
          sign: signStr,
          result: 'ខ័ន',
          baseLabel: 'Phụ âm',
          signLabel: 'Samyok Sannya',
          resultLabel: 'Từ chặn',
        );
      default:
        return _DiacriticalFormula(
          base: 'ក',
          sign: signStr,
          result: item.example.isNotEmpty ? item.example : '...',
        );
    }
  }

  Widget _buildSpellingCard() {
    final formula = _getFormula(_lesson);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 90.h, 8.w, 24.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormulaBox(formula.base, const Color(0xFFFF6D00), formula.baseLabel),
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Text(
                    '+',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB0BEC5),
                    ),
                  ),
                ),
                _buildFormulaBox(formula.sign, const Color(0xFF1CB0F6), formula.signLabel),
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Text(
                    '=',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB0BEC5),
                    ),
                  ),
                ),
                _buildFormulaBox(formula.result, const Color(0xFF58CC02), formula.resultLabel == 'Ví dụ' ? context.translate('learn.example') : formula.resultLabel),
              ],
            ),
          ),
          SizedBox(height: 70.h),
          Container(
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.08),
                  blurRadius: 10.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lesson.romanized.isNotEmpty && _lesson.romanized != '...')
                        Text(
                          '"${_lesson.romanized}"',
                          style: GoogleFonts.battambang(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.volume_up_rounded, size: 16.w, color: const Color(0xFFFF6D00)),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              _lesson.description.isNotEmpty
                                  ? context.translate('learn.description_label') + ': ' + _lesson.description
                                  : 'Bài học dấu Khmer',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.format_shapes_rounded, color: const Color(0xFFFF6D00), size: 26.sp),
                ),
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
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14.r,
                offset: Offset(0, 7.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              char,
              style: GoogleFonts.battambang(
                fontSize: 38.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════ INLINE SHEET ═══════════════════
  Widget _buildInlineSheet() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                if (_activeSheet == 1)
                  Expanded(
                    child: _InlineListenContent(
                      lesson: _lesson,
                      formula: _getFormula(_lesson),
                      onComplete: () => _markStepComplete(0),
                    ),
                  ),
                if (_activeSheet == 2)
                  Expanded(
                    child: KhmerSpeakWidget(
                      targetWord: _lesson.example.isNotEmpty ? _lesson.example : _lesson.character,
                      romanized: _lesson.romanized,
                      meaning: _lesson.description,
                      accentColor: const Color(0xFF1E88E5),
                      accentColorDark: const Color(0xFF1565C0),
                      surfaceColor: const Color(0xFFEEF4FC),
                      onComplete: () => _markStepComplete(1),
                    ),
                  ),
                if (_activeSheet == 3)
                  Expanded(
                    child: KhmerWriteWidget(
                      character: _lesson.example.isNotEmpty ? _lesson.example : _lesson.character,
                      label: 'dấu',
                      isCompound: true,
                      showStrokeGuide: true, // hiển thị hướng nét nếu có guide data
                      enableOcr: false,
                      onComplete: () => _markStepComplete(2),
                      accentColor: AppColors.primary,
                      accentColorDark: AppColors.primaryDark,
                      surfaceColor: AppColors.primarySurface,
                    ),
                  ),
              ],
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: GestureDetector(
                onTap: () => setState(() => _activeSheet = 0),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close_rounded, size: 20.sp, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1),
            child: _actionCard(
              imagePath: 'image/Nghe.png',
              label: 'Nghe',
              sub: 'Học phát âm',
              bgColor: const Color(0xFFE8F5E9),
              accentColor: const Color(0xFF43A047),
              stepIdx: 0,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2),
            child: _actionCard(
              imagePath: 'image/Mic.png',
              label: context.translate('common.speak'),
              sub: context.translate('learn.practice_pronunciation'),
              bgColor: const Color(0xFFE3F2FD),
              accentColor: const Color(0xFF1E88E5),
              stepIdx: 1,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3),
            child: _actionCard(
              imagePath: 'image/Viết.png',
              label: context.translate('common.write'),
              sub: context.translate('learn.practice_writing'),
              bgColor: const Color(0xFFEDE7F6),
              accentColor: const Color(0xFF5E35B1),
              stepIdx: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String imagePath,
    required String label,
    required String sub,
    required Color bgColor,
    required Color accentColor,
    required int stepIdx,
  }) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: done ? accentColor.withValues(alpha: 0.6) : accentColor.withValues(alpha: 0.18),
          width: done ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(imagePath, width: 64.w, height: 64.w, fit: BoxFit.contain),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (done) ...[
                SizedBox(width: 4.w),
                Icon(Icons.check_circle_rounded, size: 14.w, color: accentColor),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    final hasPrev = _idx > 0;
    final hasNext = _idx < _lessons.length - 1;
    final canNext = _canGo(_idx + 1);
    final labels = ['Nghe', context.translate('common.speak'), context.translate('common.write')];
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

class _DiacriticalFormula {
  final String base;
  final String sign;
  final String result;
  final String baseLabel;
  final String signLabel;
  final String resultLabel;

  const _DiacriticalFormula({
    required this.base,
    required this.sign,
    required this.result,
    this.baseLabel = 'Từ gốc',
    this.signLabel = 'Dấu',
    this.resultLabel = 'Ví dụ',
  });
}

// ═══════════════════════════════════════════════════════════════
// INLINE NGHE (TTS)
// ═══════════════════════════════════════════════════════════════
class _InlineListenContent extends StatefulWidget {
  final KhmerDiacritical lesson;
  final _DiacriticalFormula formula;
  final VoidCallback onComplete;
  const _InlineListenContent({
    required this.lesson,
    required this.formula,
    required this.onComplete,
  });

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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(
      _khmerSupported
          ? 'km'
          : langList.any((l) => l.contains('vi'))
              ? 'vi-VN'
              : 'en-US',
    );
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
      }
    });
    if (mounted) setState(() => _ttsReady = true);
  }

  @override
  void dispose() {
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _playCount++;
    });
    _pulseCtrl.repeat(reverse: true);
    final text = _khmerSupported ? widget.formula.result : widget.lesson.exampleMeaning;
    final result = await _tts.speak(text);
    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _pulseCtrl.stop();
        }
      });
    }
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headphones_rounded, color: AppColors.tertiary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Nghe phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiaryDark,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.2),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.tertiarySurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _smallCharBox(widget.formula.base, const Color(0xFFFF6D00)),
                        SizedBox(width: 6.w),
                        Icon(Icons.add, color: AppColors.textHint, size: 14.sp),
                        SizedBox(width: 6.w),
                        _smallCharBox(widget.formula.sign, const Color(0xFF1E88E5)),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 14.sp),
                        SizedBox(width: 8.w),
                        _smallCharBox(widget.formula.result, const Color(0xFF43A047)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder:
                          (context, child) => Container(
                            width: 140.w,
                            height: 140.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.tertiary.withValues(
                                  alpha: _isPlaying ? 0.5 : 0.25,
                                ),
                                width: 1.5.w,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 120.w,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.tertiarySurface,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90.w,
                                    height: 90.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors:
                                            _isPlaying
                                                ? [AppColors.tertiary, AppColors.tertiaryDark]
                                                : [AppColors.tertiaryLight, AppColors.tertiary],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.tertiary.withValues(
                                            alpha:
                                                0.3 +
                                                (_isPlaying ? 0.25 * _pulseCtrl.value : 0),
                                          ),
                                          blurRadius:
                                              (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r,
                                          offset: Offset(0, 4.h),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40.w,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(11, (i) {
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
                    }),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isPlaying
                        ? context.translate('learn.pronouncing')
                        : _playCount > 0
                        ? context.translate('learn.listened_count_label', args: {'count': _playCount})
                        : 'Nhấn nút để nghe phát âm mẫu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _isPlaying ? AppColors.tertiary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallCharBox(String ch, Color c) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Center(
        child: Text(
          ch,
          style: GoogleFonts.battambang(fontSize: 18.sp, fontWeight: FontWeight.w700, color: c),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE VIẾT (CANVAS)
// ═══════════════════════════════════════════════════════════════
class _InlineWriteContent extends StatefulWidget {
  final KhmerDiacritical lesson;
  final VoidCallback onComplete;
  const _InlineWriteContent({required this.lesson, required this.onComplete});

  @override
  State<_InlineWriteContent> createState() => _InlineWriteContentState();
}

class _InlineWriteContentState extends State<_InlineWriteContent> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed;
  bool _showHint = false;

  void _clear() {
    setState(() {
      _strokes.clear();
      _current.clear();
      _passed = null;
    });
  }

  void _check() {
    if (_strokes.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _passed = true);
    widget.onComplete();
  }

  Widget _buildHintPage() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.lesson.example.isNotEmpty ? widget.lesson.example : widget.lesson.character,
            style: GoogleFonts.battambang(
              fontSize: 90.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF57F17),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Hướng dẫn viết nét',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Hãy viết theo đúng nét vẽ Khmer từ trái sang phải, từ trên xuống dưới để viết chữ thật chuẩn xác nhé!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5D4037),
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => setState(() => _showHint = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57F17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(
              context.translate('common.i_understand'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: RepaintBoundary(
          child: Stack(
            children: [
              CustomPaint(size: Size.infinite, painter: _GridPainter()),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Text(
                    widget.lesson.example.isNotEmpty ? widget.lesson.example : widget.lesson.character,
                    style: GoogleFonts.battambang(
                      fontSize: 190.sp,
                      fontWeight: FontWeight.w300,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onPanStart:
                    (d) => setState(() {
                      _current = [d.localPosition];
                      _passed = null;
                    }),
                onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
                onPanEnd:
                    (_) => setState(() {
                      _strokes.add(List.from(_current));
                      _current = [];
                    }),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _StrokePainter(_strokes, _current),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showHint ? Icons.lightbulb_rounded : Icons.edit_rounded,
                color: _showHint ? AppColors.tertiary : AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                _showHint ? context.translate('learn.writing_hint') : 'Viết chữ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: _showHint ? AppColors.tertiaryDark : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _showHint ? _buildHintPage() : _buildCanvas()),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, size: 16.sp, color: AppColors.textHint),
                        SizedBox(width: 4.w),
                        Text(
                          context.translate('common.clear'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _passed != null ? () => setState(() => _passed = null) : _check,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      gradient:
                          _passed == null
                              ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              )
                              : _passed!
                              ? const LinearGradient(
                                colors: [AppColors.tertiary, AppColors.tertiaryDark],
                              )
                              : const LinearGradient(
                                colors: [AppColors.coral, AppColors.coralDark],
                              ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_passed == null
                                      ? AppColors.primary
                                      : _passed!
                                      ? AppColors.tertiary
                                      : AppColors.coral)
                                  .withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _passed == null
                              ? Icons.check_circle_outline_rounded
                              : _passed!
                              ? Icons.celebration_rounded
                              : Icons.refresh_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _passed == null
                              ? 'Kiểm tra'
                              : _passed!
                              ? context.translate('learn.beautiful_emoji')
                              : context.translate('common.retry'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showHint = !_showHint),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: _showHint ? AppColors.tertiarySurface : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color:
                            _showHint
                                ? AppColors.tertiary.withValues(alpha: 0.3)
                                : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16.sp,
                          color: _showHint ? AppColors.tertiaryDark : AppColors.textHint,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          context.translate('learn.hint'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _showHint ? AppColors.tertiaryDark : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE0D5C5).withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    const cols = 8;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).ceil();

    for (int i = 0; i <= cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int j = 0; j <= rows; j++) {
      final y = j * cellW;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
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
    final done = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s[0].dx, s[0].dy);
      for (int i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, done);
    }
    if (current.length >= 2) {
      final active = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 5.w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (int i = 1; i < current.length; i++) {
        path.lineTo(current[i].dx, current[i].dy);
      }
      canvas.drawPath(path, active);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
