import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../models/khmer_spelling.dart';
import '../../widgets/khmer_speak_widget.dart';
import '../../widgets/khmer_write_widget.dart';

/// Màn hình học đánh vần Khmer cao cấp (ghép phụ âm + nguyên âm thành từ)
/// Thiết kế cao cấp đồng bộ 100% với màn hình chi tiết phụ âm (LetterDetailScreen)
/// Tích hợp TTS (nghe ghép âm), STT (luyện nói thực tế), Bảng vẽ (tập viết chữ ghép)
class SpellingScreen extends StatefulWidget {
  final int initialIndex;
  const SpellingScreen({super.key, this.initialIndex = 0});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen>
    with SingleTickerProviderStateMixin {
  ScoreService? _score;
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerSpelling> _lessons = KhmerSpellingData.lessons;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  // 0 = none, 1 = listen, 2 = speak, 3 = write
  int _activeSheet = 0;

  @override
  void initState() {
    _loadScore();
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache mascot image to avoid jank on first build
    precacheImage(const AssetImage('assets/images/elephant_mascot.png'), context);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerSpelling get _lesson => _lessons[_idx];

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

    if (_completedSteps[_idx]!.length == 3) {
      _onLessonCompleted();
    }
  }

  Future<void> _onLessonCompleted() async {
    setState(() {
      _lesson.isLearned = true;
      _lesson.starRating = 3;
    });

    try {
      final scoreService = await ScoreService.getInstance();
      await scoreService.completeSpellingLesson(
        _idx,
        3,
        lessonId: null,
        spellingText: _lesson.combined,
        transliteration: _lesson.romanized,
      );
    } catch (e) {
      debugPrint('Error saving spelling progress: $e');
    }

    Future.delayed(const Duration(milliseconds: 300), () {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 12.h),
              Text(
                'Chúc mừng!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Bạn đã hoàn thành bài ghép vần "${_lesson.combined}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 28.w,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '+30 XP ⭐',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: 20.h),
              if (hasNext) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goTo(_idx + 1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Bài tiếp theo →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
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
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    side: BorderSide(color: AppColors.violet),
                  ),
                  child: Text(
                    'Quay về bản đồ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
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

  bool _isStepComplete(int step) =>
      _completedSteps[_idx]?.contains(step) ?? false;

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
              physics: const BouncingScrollPhysics(),
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

  // ═══════════════════ HEADER ĐỒNG BỘ CAO CẤP ═══════════════════
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
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                            ),
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 44.w,
                              minHeight: 44.w,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'Đánh vần ${_idx + 1}/${_lessons.length}',
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⭐',
                              style: TextStyle(fontSize: 13.sp),
                            ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔥',
                              style: TextStyle(fontSize: 13.sp),
                            ),
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

  Widget _buildSpellingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
        ),
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
          SizedBox(height: 24.h),

          // ── Top: Spelling Formula Row ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormulaBox(_lesson.consonant, const Color(0xFF1CB0F6), 'Phụ âm'),
                Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5))),
                ),
                _buildFormulaBox(_lesson.vowelSign, const Color(0xFFFF4B4B), 'Nguyên âm'),
                Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5))),
                ),
                _buildFormulaBox(_lesson.combined, const Color(0xFF58CC02), 'Kết quả'),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ── Center: Large Combined Character Showcase ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF58CC02).withValues(alpha: 0.08),
                  const Color(0xFF58CC02).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF58CC02).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _lesson.combined,
                style: GoogleFonts.battambang(
                  fontSize: 120.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF58CC02),
                  height: 1.0,
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // ── Bottom: Details & Meaning Container ──
          Container(
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FC),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
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
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      if (_lesson.romanized.isNotEmpty && _lesson.romanized != '...')
                        SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 16.w,
                            color: const Color(0xFF1E88E5),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              _lesson.meaning.isNotEmpty ? 'Nghĩa: ${_lesson.meaning}' : 'Bài luyện ghép âm',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
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
                // Decorative icon
                Container(
                  width: 48.w,
                  height: 48.w,
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
                  child: Icon(
                    Icons.school_rounded,
                    color: const Color(0xFF1E88E5),
                    size: 24.sp,
                  ),
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
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 16.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              char,
              style: GoogleFonts.battambang(
                fontSize: 48.sp,
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

  // ═══════════════════ INLINE SHEET OVERLAY ═══════════════════
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
                    child: _InlineSpellingListenContent(
                      lesson: _lesson,
                      onComplete: () => _markStepComplete(0),
                    ),
                  ),
                if (_activeSheet == 2)
                  Expanded(
                    child: KhmerSpeakWidget(
                      character: _lesson.combined,
                      romanized: _lesson.romanized,
                      pronunciation: _lesson.romanized,
                      // Chấp nhận âm ghép (romanized) + chữ ghép Khmer. Bỏ
                      // phụ âm gốc vì chỉ là 1 nửa của vần — không phải đáp
                      // án hợp lệ, dễ báo đúng khi user đọc thiếu.
                      acceptedAnswers: [
                        _lesson.romanized,
                        _lesson.combined,
                      ],
                      accentColor: AppColors.coral,
                      accentColorDark: AppColors.coralDark,
                      surfaceColor: AppColors.coralSurface,
                      passThreshold: 70, // Ngưỡng đạt 70% — đúng yêu cầu chuẩn
                      onComplete: () => _markStepComplete(1),
                    ),
                  ),
                if (_activeSheet == 3)
                  Expanded(
                    // Dùng KhmerWriteWidget giống Phụ Âm — chấm điểm thực bằng
                    // độ trùng nét viết với chữ mẫu (HandwritingTracingService),
                    // không còn đếm "có vẽ là đậu" như stub cũ.
                    child: KhmerWriteWidget(
                      character: _lesson.combined,
                      accentColor: AppColors.primary,
                      accentColorDark: AppColors.primaryDark,
                      surfaceColor: AppColors.primarySurface,
                      showStrokeGuide: false, // chữ ghép không có dữ liệu hướng nét
                      enableOcr: false,
                      onComplete: () => _markStepComplete(2),
                    ),
                  ),
              ],
            ),
            // Close floating button
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

  // ═══════════════════ BỘ BA NÚT CHỨC NĂNG NGHE NÓI VIẾT ═══════════════════
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = 1),
            child: _actionCard(
              imagePath: 'image/Nghe.png',
              label: 'Nghe',
              sub: 'Học đánh vần',
              bgColor: const Color(0xFFE8F5E9),
              accentColor: const Color(0xFF43A047),
              stepIdx: 0,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = 2),
            child: _actionCard(
              imagePath: 'image/Mic.png',
              label: 'Nói',
              sub: 'Luyện nói vần',
              bgColor: const Color(0xFFFFF3E0),
              accentColor: const Color(0xFFF57C00),
              stepIdx: 1,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSheet = 3),
            child: _actionCard(
              imagePath: 'image/Viết.png',
              label: 'Viết',
              sub: 'Tập viết chữ ghép',
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
    final widgets = <Widget>[];

    if (hasPrev) {
      widgets.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _goTo(_idx - 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('Bài trước', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.sp)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              side: BorderSide(color: AppColors.surfaceContainerHighest),
            ),
          ),
        ),
      );
    }
    
    if (hasPrev && hasNext) {
      widgets.add(SizedBox(width: 12.w));
    }
    
    if (hasNext) {
      final canNext = _canGo(_idx + 1);
      widgets.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (canNext) {
                _goTo(_idx + 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng hoàn thành tất cả hoạt động (Nghe, Nói, Viết) trước khi học bài tiếp theo.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: Text(canNext ? 'Bài tiếp' : 'Khóa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.sp)),
            label: Icon(canNext ? Icons.arrow_forward_rounded : Icons.lock_rounded, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: canNext ? AppColors.primary : AppColors.surfaceContainerLow,
              foregroundColor: canNext ? Colors.white : AppColors.textHint,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: canNext ? 2 : 0,
            ),
          ),
        ),
      );
    }

    return Row(children: widgets);
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE NGHE CHI TIẾT ĐÁNH VẦN (TTS)
// ═══════════════════════════════════════════════════════════════
class _InlineSpellingListenContent extends StatefulWidget {
  final KhmerSpelling lesson;
  final VoidCallback onComplete;
  const _InlineSpellingListenContent({required this.lesson, required this.onComplete});

  @override
  State<_InlineSpellingListenContent> createState() => _InlineSpellingListenContentState();
}

class _InlineSpellingListenContentState extends State<_InlineSpellingListenContent>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  final int _speed = 1;
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
    await _tts.setLanguage(_khmerSupported ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(_speedRate);
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

  double get _speedRate {
    switch (_speed) {
      case 0:
        return 0.2;
      case 2:
        return 0.65;
      default:
        return 0.4;
    }
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
    await _tts.setSpeechRate(_speedRate);

    // Ưu tiên phát file âm thanh ghi sẵn, fallback sang TTS
    final hasAudioFiles = await _playAudioFiles();

    if (!hasAudioFiles) {
      // Luôn dùng phiên âm Latin để đảm bảo phát âm chính xác
      final consonantRoman = _getConsonantRoman(widget.lesson.consonant);
      final vowelRoman = _getVowelRoman(widget.lesson.vowelSign);
      final text = '$consonantRoman. $vowelRoman. ${widget.lesson.romanized}';

      debugPrint('[TTS] Speaking romanized: "$text"');
      debugPrint('[TTS] Consonant: ${widget.lesson.consonant} → $consonantRoman');
      debugPrint('[TTS] Vowel: ${widget.lesson.vowelSign} → $vowelRoman');

      // Đặt ngôn ngữ về tiếng Anh để đọc phiên âm Latin
      await _tts.setLanguage('en-US');

      final result = await _tts.speak(text);
      if (result != 1 && mounted) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() => _isPlaying = false);
            _pulseCtrl.stop();
          }
        });
      }
    }

    if (_playCount >= 1) widget.onComplete();
  }

  // Phát file âm thanh ghi sẵn (nếu có)
  Future<bool> _playAudioFiles() async {
    try {
      // TODO: Thêm AudioPlayer package và phát file âm thanh
      // Cấu trúc file: assets/audio/consonants/ក.mp3, assets/audio/vowels/ា.mp3
      //
      // final player = AudioPlayer();
      // await player.play(AssetSource('audio/consonants/${widget.lesson.consonant}.mp3'));
      // await Future.delayed(Duration(milliseconds: 800));
      // await player.play(AssetSource('audio/vowels/${widget.lesson.vowelSign}.mp3'));
      // await Future.delayed(Duration(milliseconds: 800));
      // await player.play(AssetSource('audio/combined/${widget.lesson.combined}.mp3'));
      //
      // if (mounted) {
      //   setState(() => _isPlaying = false);
      //   _pulseCtrl.stop();
      // }
      // return true;

      return false; // Tạm thời return false để dùng TTS
    } catch (e) {
      debugPrint('[Audio] Error playing audio files: $e');
      return false;
    }
  }

  // Helper để lấy phiên âm phụ âm
  String _getConsonantRoman(String consonant) {
    const map = {
      'ក': 'ka', 'ខ': 'kha', 'គ': 'ko', 'ឃ': 'kho', 'ង': 'ngo',
      'ច': 'cha', 'ឆ': 'chho', 'ជ': 'cho', 'ឈ': 'chhô', 'ញ': 'nho',
      'ដ': 'da', 'ឋ': 'tha', 'ឌ': 'do', 'ឍ': 'tho', 'ណ': 'na',
      'ត': 'ta', 'ថ': 'tha', 'ទ': 'to', 'ធ': 'tho', 'ន': 'no',
      'ប': 'ba', 'ផ': 'pha', 'ព': 'po', 'ភ': 'pho', 'ម': 'mo',
      'យ': 'yo', 'រ': 'ro', 'ល': 'lo', 'វ': 'vo',
      'ស': 'sa', 'ហ': 'ha', 'ឡ': 'la', 'អ': 'a',
    };
    return map[consonant] ?? consonant;
  }

  // Helper để lấy phiên âm nguyên âm
  String _getVowelRoman(String vowel) {
    const map = {
      'ា': 'aa', 'ិ': 'e', 'ី': 'ei', 'ុ': 'o', 'ូ': 'oo',
      'ួ': 'uor', 'ើ': 'aeu', 'ឿ': 'oeu', 'ៀ': 'ie', 'េ': 'e',
    };
    return map[vowel] ?? vowel;
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
                'Nghe đánh vần',
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
                  // Sơ đồ ghép âm mượt mà
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
                        _smallCharBox(widget.lesson.consonant, const Color(0xFF1E88E5)),
                        SizedBox(width: 8.w),
                        Icon(Icons.add, color: AppColors.textHint, size: 16.sp),
                        SizedBox(width: 8.w),
                        _smallCharBox(widget.lesson.vowelSign, const Color(0xFFE53935)),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 16.sp),
                        SizedBox(width: 8.w),
                        _smallCharBox(widget.lesson.combined, const Color(0xFF43A047)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) => Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.5 : 0.25),
                            width: 1.5.w,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiarySurface),
                            child: Center(
                              child: Container(
                                width: 90.w,
                                height: 90.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: _isPlaying
                                        ? [AppColors.tertiary, AppColors.tertiaryDark]
                                        : [AppColors.tertiaryLight, AppColors.tertiary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.tertiary.withValues(
                                        alpha: 0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0),
                                      ),
                                      blurRadius: (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r,
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
                    _isPlaying
                        ? 'Đang phát âm ghép vần...'
                        : _playCount > 0
                            ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
                            : 'Nhấn nút để nghe đánh vần mẫu',
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
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Center(
        child: Text(
          ch,
          style: GoogleFonts.battambang(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ),
    );
  }
}

// Stub luyện viết cũ (`_InlineSpellingWriteContent`) đã được thay bằng
// `KhmerWriteWidget` — sử dụng HandwritingTracingService như Phụ Âm để
// chấm điểm thực bằng độ trùng nét, thay vì chỉ đếm tổng số điểm.
