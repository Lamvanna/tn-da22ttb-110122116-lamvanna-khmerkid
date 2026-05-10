import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_letter.dart';
import '../../data/stroke_guide_data.dart';

/// Màn hình chi tiết học chữ cái Khmer
/// Tích hợp TTS (nghe), STT (nói), stroke validation (viết)
class LetterDetailScreen extends StatefulWidget {
  final int initialIndex;

  const LetterDetailScreen({super.key, this.initialIndex = 0});

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerLetter> _letters = KhmerLetterData.consonants;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  // 0 = none, 1 = listen, 2 = speak, 3 = write
  int _activeSheet = 0;

  @override
  void initState() {
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
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerLetter get _letter => _letters[_idx];

  bool _isLocked(int idx) {
    if (idx < 0 || idx >= _letters.length) return true;
    if (_letters[idx].isLearned) return false;
    final firstUnlearned = _letters.indexWhere((l) => !l.isLearned);
    return idx != firstUnlearned;
  }

  void _goTo(int i) {
    if (i < 0 || i >= _letters.length || _isLocked(i)) return;
    _animCtrl.reset();
    setState(() { _idx = i; _activeSheet = 0; });
    _animCtrl.forward();
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));

    if (_completedSteps[_idx]!.length == 3) {
      _onLetterCompleted();
    }
  }

  void _onLetterCompleted() {
    _letters[_idx].isLearned = true;
    _letters[_idx].starRating = 3;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _letters.length - 1;
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
                'Bạn đã hoàn thành chữ "${_letter.character}"',
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
                      'Học chữ tiếp theo →',
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
  int get _completedCount => _completedSteps[_idx]?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
                    // Letter card always exists (determines height),
                    // inline sheet overlays on top when active
                    Stack(
                      children: [
                        _buildLetterCard(),
                        if (_activeSheet != 0)
                          Positioned.fill(child: _buildInlineSheet()),
                      ],
                    ),
                    SizedBox(height: 8.h),
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
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
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
          // Content
          SafeArea(
            bottom: false,
            child: Transform.translate(
              offset: Offset(0, -5.h),
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 0, 0, 2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20.w,
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
                                  'Chữ cái ${_letters.sublist(0, _idx + 1).where((l) => !l.isTest).length}/${_letters.where((l) => !l.isTest).length}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 54.w, top: 8.h),
                            child: Row(
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
                                        '${_letters.where((l) => l.isLearned && !l.isTest).length * 15}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6.w),
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
                                        '7 ngày',
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
                          ),
                        ],
                      ),
                    ),
                    // Mascot - responsive
                    Transform.translate(
                      offset: Offset(-5.w, -5.h),
                      child: SizedBox(
                        width: 130.w,
                        height: 75.h,
                        child: OverflowBox(
                          maxHeight: 200.w,
                          maxWidth: 200.w,
                          child: Image.asset(
                            'assets/images/elephant_mascot.png',
                            width: 200.w,
                            height: 200.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStep(IconData icon, String label, int stepIdx) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: done
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: done
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.w, color: done ? Colors.white : Colors.white60),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: done ? Colors.white : Colors.white60,
            ),
          ),
          if (done) ...[
            SizedBox(width: 4.w),
            Icon(
              Icons.check_circle_rounded,
              size: 14.w,
              color: AppColors.tertiaryLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 16.w,
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      color: Colors.white24,
    );
  }

  // ═══════════════════ CARD CHỮ + MINH HỌA ═══════════════════
  Widget _buildLetterCard() {
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
          // ── Top: big character ──
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 70.h, 20.w, 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Subscript form top-right
                Positioned(
                  top: -56.h,
                  right: -8.w,
                  child: Text(
                    '${_letter.character}្${_letter.character}',
                    style: GoogleFonts.battambang(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.7),
                    ),
                  ),
                ),
                // Big character center
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(40.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF1E88E5,
                          ).withValues(alpha: 0.06),
                        ),
                        child: Text(
                          _letter.character,
                          style: GoogleFonts.battambang(
                            fontSize: 130.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1E88E5),
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: 80.w,
                        height: 3.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E88E5).withValues(alpha: 0.1),
                              const Color(0xFF1E88E5),
                              const Color(0xFF1E88E5).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          // ── Bottom: info row ──
          Container(
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
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
                      Row(
                        children: [
                          Text(
                            _getKhmerWord(),
                            style: GoogleFonts.battambang(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 16.w,
                            color: const Color(0xFF1E88E5),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _letter.meaning.isNotEmpty
                                ? _letter.meaning
                                : _letter.pronunciation,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Transform.translate(
                    offset: Offset(-10.w, 0),
                    child: OverflowBox(
                      maxWidth: 110.w,
                      maxHeight: 110.w,
                      child: _buildIllustration(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ INLINE SHEET OVERLAY ═══════════════════
  Widget _buildInlineSheet() {
    // Dynamic colors per sheet type
    final List<Color> gradColors = _activeSheet == 1
      ? [AppColors.tertiary, AppColors.tertiaryDark]
      : _activeSheet == 2
        ? [AppColors.coral, AppColors.coralDark]
        : [AppColors.primary, AppColors.primaryDark];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // Content
            Column(
              children: [
                if (_activeSheet == 1)
                  Expanded(
                    child: _InlineListenContent(
                      letter: _letter,
                      onComplete: () => _markStepComplete(0),
                    ),
                  ),
                if (_activeSheet == 2)
                  Expanded(
                    child: _InlineSpeakContent(
                      letter: _letter,
                      onComplete: () => _markStepComplete(1),
                    ),
                  ),
                if (_activeSheet == 3)
                  Expanded(
                    child: _InlineWriteContent(
                      letter: _letter,
                      onComplete: () => _markStepComplete(2),
                    ),
                  ),
              ],
            ),
            // Close button
            Positioned(
              top: 10.h, right: 10.w,
              child: GestureDetector(
                onTap: () => setState(() => _activeSheet = 0),
                child: Container(
                  width: 30.w, height: 30.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16.sp, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ NGHE + NÓI + VIẾT ═══════════════════
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showListenSheet,
            child: _actionCard(
              imagePath: 'image/Nghe.png',
              label: 'Nghe',
              sub: 'Nghe phát âm',
              bgColor: const Color(0xFFE8F5E9),
              accentColor: const Color(0xFF43A047),
              stepIdx: 0,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: _showSpeakSheet,
            child: _actionCard(
              imagePath: 'image/Mic.png',
              label: 'Nói',
              sub: 'Luyện phát âm',
              bgColor: const Color(0xFFFFF3E0),
              accentColor: const Color(0xFFF57C00),
              stepIdx: 1,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: _showWriteSheet,
            child: _actionCard(
              imagePath: 'image/Viết.png',
              label: 'Viết',
              sub: 'Tập viết chữ',
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
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: done ? accentColor.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.18),
          width: done ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(imagePath, width: 70.w, height: 70.w, fit: BoxFit.contain),
          SizedBox(height: 10.h),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp, fontWeight: FontWeight.w800, color: accentColor)),
          SizedBox(height: 3.h),
          Text(sub, style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp, fontWeight: FontWeight.w600,
            color: accentColor.withValues(alpha: 0.65))),

        ],
      ),
    );
  }

  // ═══════════════════ NAVIGATION + STEPPER ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _idx > 0 && !_isLocked(_idx - 1);
    final canNext = _idx < _letters.length - 1 && !_isLocked(_idx + 1);
    final labels = ['Nghe', 'Nói', 'Viết'];
    final stepColors = [const Color(0xFF3D5AFE), const Color(0xFFFF9100), const Color(0xFF7C4DFF)];
    return Row(
      children: [
        GestureDetector(
          onTap: canPrev ? () => _goTo(_idx - 1) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.12)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6.r, offset: Offset(0, 2.h))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left_rounded, color: canPrev ? const Color(0xFF1E88E5) : AppColors.textHint, size: 18.w),
              Text('Trước', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: canPrev ? const Color(0xFF1E88E5) : AppColors.textHint)),
            ]),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          if (i.isOdd) {
            final prevDone = _isStepComplete(i ~/ 2);
            return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (_) => Container(
              width: 4.w, height: 2.5.h, margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              decoration: BoxDecoration(color: prevDone ? stepColors[i ~/ 2].withValues(alpha: 0.5) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(1.r)),
            )));
          }
          final stepI = i ~/ 2;
          final done = _isStepComplete(stepI);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 28.w, height: 28.w, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: done ? [stepColors[stepI], stepColors[stepI].withValues(alpha: 0.7)] : [const Color(0xFFE8E8E8), const Color(0xFFD8D8D8)]),
              boxShadow: done ? [BoxShadow(color: stepColors[stepI].withValues(alpha: 0.35), blurRadius: 6.r, offset: Offset(0, 2.h))] : null,
            ), child: Center(child: done
              ? Icon(Icons.check_rounded, size: 14.w, color: Colors.white)
              : Text('${stepI + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)))),
            SizedBox(height: 2.h),
            Text(labels[stepI], style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: done ? stepColors[stepI] : AppColors.textHint)),
          ]);
        }))),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: canNext ? () => _goTo(_idx + 1) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: canNext ? const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]) : null,
              color: canNext ? null : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: canNext ? [BoxShadow(color: const Color(0xFF1E88E5).withValues(alpha: 0.35), blurRadius: 10.r, offset: Offset(0, 3.h))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(canNext ? 'Tiếp theo' : 'Khóa', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: canNext ? Colors.white : AppColors.textHint)),
              SizedBox(width: 4.w),
              Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded, color: canNext ? Colors.white : AppColors.textHint, size: 18.w),
            ]),
          ),
        ),
      ],
    );
  }


  // ═══════════════════ SHEETS ═══════════════════
  void _showListenSheet() {
    setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1);
  }

  void _showSpeakSheet() {
    setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2);
  }

  void _showWriteSheet() {
    setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3);
  }

  Widget _buildIllustration() {
    final img = _getImage();
    if (img != null) {
      return Image.asset(img, width: 110.w, height: 110.w, fit: BoxFit.contain);
    }
    return Text(_getEmoji(), style: TextStyle(fontSize: 90.sp));
  }

  String _getKhmerWord() {
    switch (_letter.character) {
      case 'ក': return 'កុក';
      case 'ខ': return 'ខ្លា';
      case 'គ': return 'គោ';
      case 'ឃ': return 'ឃ្មុំ';
      case 'ង': return 'ង៉ាន';
      case 'ច': return 'ចាន';
      case 'ឆ': return 'ឆ្មា';
      case 'ជ': return 'ជ្រូក';
      case 'ឈ': return 'ឈូស';
      case 'ញ': return 'ញៀម';
      default: return _letter.character;
    }
  }

  String? _getImage() {
    switch (_letter.meaning) {
      case 'con cò': return 'image/Con cò.png';
      case 'con hổ': return 'image/con hổ.png';
      default: return null;
    }
  }

  String _getEmoji() {
    switch (_letter.meaning) {
      case 'con cò':
        return '🦩';
      case 'con khỉ':
        return '🐒';
      case 'con gà':
        return '🐓';
      case 'con bò':
        return '🐄';
      case 'con ngỗng':
        return '🦢';
      case 'con chó':
        return '🐕';
      case 'con mèo':
        return '🐱';
      case 'con cá':
        return '🐟';
      case 'con hươu':
        return '🦌';
      case 'con thỏ':
        return '🐰';
      case 'con voi':
        return '🐘';
      case 'con rùa':
        return '🐢';
      case 'con ong':
        return '🐝';
      case 'con cua':
        return '🦀';
      case 'con rắn':
        return '🐍';
      case 'con hổ':
        return '🐅';
      case 'con ngựa':
        return '🐴';
      case 'con vịt':
        return '🦆';
      case 'con bướm':
        return '🦋';
      case 'con cọp':
        return '🐯';
      case 'con ếch':
        return '🐸';
      case 'con ốc':
        return '🐌';
      case 'con công':
        return '🦚';
      case 'con sóc':
        return '🐿️';
      case 'con kiến':
        return '🐜';
      case 'con dê':
        return '🐐';
      case 'con sư tử':
        return '🦁';
      case 'con heo':
        return '🐷';
      case 'con chim':
        return '🐦';
      case 'con tôm':
        return '🦐';
      case 'con chuột':
        return '🐭';
      case 'con gấu':
        return '🐻';
      case 'con khỉ đột':
        return '🦍';
      default:
        return '📝';
    }
  }
}

// ═══════════════════════════════════════════════════════════════

class _InlineListenContent extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _InlineListenContent({required this.letter, required this.onComplete});

  @override
  State<_InlineListenContent> createState() => _InlineListenContentState();
}

class _InlineListenContentState extends State<_InlineListenContent>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _speed = 1;
  int _playCount = 0;
  bool _ttsReady = false;
  bool _khmerSupported = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));
    if (_khmerSupported) {
      await _tts.setLanguage('km');
    } else {
      final viSupported = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(viSupported ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(_speedRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); }
    });
    _tts.setErrorHandler((msg) {
      if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); }
    });
    if (mounted) setState(() => _ttsReady = true);
  }

  double get _speedRate {
    switch (_speed) { case 0: return 0.2; case 2: return 0.7; default: return 0.4; }
  }

  @override
  void dispose() { _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() { _isPlaying = true; _playCount++; });
    _pulseCtrl.repeat(reverse: true);
    await _tts.setSpeechRate(_speedRate);
    final text = _khmerSupported ? widget.letter.character
      : widget.letter.pronunciation.isNotEmpty ? widget.letter.pronunciation : widget.letter.romanized;
    final result = await _tts.speak(text);
    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); }
      });
    }
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headphones_rounded, color: AppColors.tertiary, size: 20.w),
              SizedBox(width: 8.w),
              Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.tertiaryDark,
              )),
            ],
          ),
        ),

        // ── Main content (fills remaining space) ──
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Character with circle glow
                  Container(
                    width: 120.w, height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tertiarySurface,
                      boxShadow: [BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.12),
                        blurRadius: 24.r, spreadRadius: 4,
                      )],
                    ),
                    child: Center(
                      child: Text(widget.letter.character, style: GoogleFonts.battambang(
                        fontSize: 64.sp, fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark, height: 1.1,
                      )),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Pronunciation badge
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.tertiarySurface,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.volume_up_rounded, size: 14.sp, color: AppColors.tertiary),
                        SizedBox(width: 6.w),
                        Text('Phát âm: "${widget.letter.romanized}"', style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.tertiaryDark,
                        )),
                      ]),
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Play button with rings
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Column(
                        children: [
                          // Triple ring play
                          Container(
                            width: 140.w, height: 140.w,
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
                                width: 120.w, height: 120.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.tertiarySurface,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90.w, height: 90.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        colors: _isPlaying
                                          ? [AppColors.tertiary, AppColors.tertiaryDark]
                                          : [AppColors.tertiaryLight, AppColors.tertiary],
                                      ),
                                      boxShadow: [BoxShadow(
                                        color: AppColors.tertiary.withValues(
                                          alpha: 0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0)),
                                        blurRadius: (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r,
                                        offset: Offset(0, 4.h),
                                      )],
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white, size: 40.w,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Wave bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(11, (i) {
                              final center = 5;
                              final dist = (i - center).abs();
                              final base = dist <= 1 ? 20.h : dist <= 3 ? 10.h : 5.h;
                              final h = _isPlaying
                                ? base * (0.5 + 0.5 * _pulseCtrl.value)
                                : base * 0.4;
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isPlaying ? 'Đang phát âm...'
                      : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
                      : 'Nhấn nút để nghe phát âm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp, fontWeight: FontWeight.w600,
                      color: _isPlaying ? AppColors.tertiary : AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, int val) {
    final active = _speed == val;
    return GestureDetector(
      onTap: () => setState(() => _speed = val),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp, fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppColors.textHint,
        )),
      ),
    );
  }
}

class _ListenSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _ListenSheet({required this.letter, required this.onComplete});

  @override
  State<_ListenSheet> createState() => _ListenSheetState();
}

class _ListenSheetState extends State<_ListenSheet>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _speed = 1;
  int _playCount = 0;
  bool _ttsReady = false;
  bool _khmerSupported = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List)
        .map((l) => l.toString().toLowerCase())
        .toList();
    _khmerSupported = langList.any(
      (l) => l.contains('km') || l.contains('khmer'),
    );

    if (_khmerSupported) {
      await _tts.setLanguage('km');
    } else {
      final viSupported = langList.any((l) => l.contains('vi'));
      if (viSupported) {
        await _tts.setLanguage('vi-VN');
      } else {
        await _tts.setLanguage('en-US');
      }
    }

    await _tts.setSpeechRate(_speedRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
        _waveCtrl.stop();
      }
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _waveCtrl.stop();
      }
    });

    if (mounted) setState(() => _ttsReady = true);
  }

  double get _speedRate {
    switch (_speed) {
      case 0:
        return 0.2;
      case 2:
        return 0.7;
      default:
        return 0.4;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _playCount++;
    });
    _waveCtrl.repeat(reverse: true);

    await _tts.setSpeechRate(_speedRate);

    final textToSpeak = _khmerSupported
        ? widget.letter.character
        : widget.letter.pronunciation.isNotEmpty
        ? widget.letter.pronunciation
        : widget.letter.romanized;

    final result = await _tts.speak(textToSpeak);

    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _waveCtrl.stop();
        }
      });
    }

    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          SizedBox(height: 12.h),
          Container(
            width: 40.w, height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Title ──
          Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(
            fontSize: 22.sp, fontWeight: FontWeight.w800,
            color: const Color(0xFF1565C0),
          )),
          SizedBox(height: 4.h),
          Text('Lắng nghe và ghi nhớ cách đọc', style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp, fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          )),
          SizedBox(height: 20.h),

          // ── Character Card ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB).withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  blurRadius: 20.r, offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(widget.letter.character, style: GoogleFonts.battambang(
                  fontSize: 80.sp, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1565C0), height: 1.1,
                )),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8.r, offset: Offset(0, 2.h),
                    )],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.record_voice_over_rounded, size: 16.sp,
                        color: const Color(0xFF1E88E5)),
                      SizedBox(width: 6.w),
                      Text('"${widget.letter.romanized}"', style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1565C0),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // ── Play Button with Rings ──
          GestureDetector(
            onTap: _ttsReady ? _play : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                if (_isPlaying) Container(
                  width: 100.w, height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF43A047).withValues(alpha: 0.15), width: 3,
                    ),
                  ),
                ),
                // Middle ring
                if (_isPlaying) Container(
                  width: 84.w, height: 84.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF43A047).withValues(alpha: 0.25), width: 2,
                    ),
                  ),
                ),
                // Button
                Container(
                  width: 68.w, height: 68.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: _isPlaying
                        ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                        : [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
                    ),
                    boxShadow: [BoxShadow(
                      color: (_isPlaying
                        ? const Color(0xFF43A047) : const Color(0xFF1E88E5))
                        .withValues(alpha: 0.4),
                      blurRadius: 16.r, offset: Offset(0, 6.h),
                    )],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 36.w,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _isPlaying ? 'Đang phát âm...'
              : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
              : 'Nhấn nút để nghe phát âm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.w600,
              color: _isPlaying ? const Color(0xFF43A047) : AppColors.textHint,
            ),
          ),
          SizedBox(height: 20.h),

          // ── Speed Selector ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30.w),
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tốc độ:', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp, fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                )),
                SizedBox(width: 8.w),
                _speedChip('🐢 Chậm', 0),
                SizedBox(width: 6.w),
                _speedChip('🔊 Vừa', 1),
                SizedBox(width: 6.w),
                _speedChip('🐇 Nhanh', 2),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _speedChip(String label, int val) {
    final active = _speed == val;
    return GestureDetector(
      onTap: () => setState(() => _speed = val),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20.r),
          border: active
              ? null
              : Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// INLINE SPEAK CONTENT
// ═══════════════════════════════════════════════════════════════

class _InlineSpeakContent extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _InlineSpeakContent({required this.letter, required this.onComplete});
  @override
  State<_InlineSpeakContent> createState() => _InlineSpeakContentState();
}

class _InlineSpeakContentState extends State<_InlineSpeakContent>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;
  bool _sttReady = false;
  bool _isListening = false;
  String _recognized = '';
  String _statusMsg = '';
  bool _hasResult = false;
  bool _isCorrect = false;
  int _accuracy = 0;
  String _selectedLocaleId = 'vi-VN';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _initTts();
    _initSTT();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    if (hasKhmer) { await _tts.setLanguage('km'); }
    else {
      final hasVi = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(hasVi ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
  }

  Future<void> _initSTT() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) setState(() => _statusMsg = 'Cần cấp quyền microphone!');
      return;
    }
    try {
      _sttReady = await _speech.initialize(
        onError: (err) {
          if (mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() { _isListening = false;
              _statusMsg = _recognized.isEmpty ? 'Không nghe được. Nói to hơn!' : '';
            });
            if (_recognized.isNotEmpty) _evaluate();
          }
        },
        onStatus: (status) {
          if (status == 'done' && mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() => _isListening = false);
            _evaluate();
          }
        },
      );
      if (_sttReady) {
        final locales = await _speech.locales();
        for (final l in locales) {
          if (l.localeId.toLowerCase().startsWith('vi')) { _selectedLocaleId = l.localeId; break; }
        }
      }
    } catch (e) { _sttReady = false; }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _speech.stop(); _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; });
    _pulseCtrl.repeat(reverse: true);
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 4),
        localeId: _selectedLocaleId,
      );
    } catch (e) {
      _pulseCtrl.stop();
      if (mounted) setState(() { _isListening = false; _statusMsg = 'Lỗi nhận diện. Thử lại!'; });
    }
  }

  void _evaluate() {
    if (_hasResult) return;
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) { setState(() => _statusMsg = 'Không nhận diện được. Nói to hơn!'); return; }
    String normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final spokenNorm = normalize(spoken);
    final targets = [widget.letter.romanized, widget.letter.pronunciation, widget.letter.character]
      .where((t) => t.isNotEmpty).map(normalize).toList();
    bool exact = targets.any((t) => spokenNorm.contains(t) || t.contains(spokenNorm));
    if (exact) {
      _accuracy = 100;
      _isCorrect = true;
    } else {
      double best = 0;
      for (final t in targets) { final s = _sim(spokenNorm, t); if (s > best) best = s; }
      _accuracy = (best * 100).round().clamp(0, 99);
      _isCorrect = _accuracy >= 30;
    }
    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();
  }

  Future<void> _stopListening() async {
    _pulseCtrl.stop();
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _evaluate();
    }
  }

  double _sim(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final mx = a.length > b.length ? a.length : b.length;
    int m = a.length, n = b.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) d[i][0] = i;
    for (int j = 0; j <= n; j++) d[0][j] = j;
    for (int i = 1; i <= m; i++) for (int j = 1; j <= n; j++) {
      final c = a[i-1] == b[j-1] ? 0 : 1;
      d[i][j] = [d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+c].reduce((a,b) => a<b?a:b);
    }
    return 1.0 - (d[m][n] / mx);
  }

  Future<void> _playExample() async {
    final text = widget.letter.pronunciation.isNotEmpty ? widget.letter.pronunciation : widget.letter.romanized;
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.mic_rounded, color: AppColors.coral, size: 20.w),
            SizedBox(width: 8.w),
            Text('Nói phát âm', style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.coralDark,
            )),
          ]),
        ),
        // Content
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Character
                  Container(
                    width: 120.w, height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.coralSurface,
                      boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.12), blurRadius: 24.r, spreadRadius: 4)],
                    ),
                    child: Center(child: Text(widget.letter.character, style: GoogleFonts.battambang(
                      fontSize: 64.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.1,
                    ))),
                  ),
                  SizedBox(height: 10.h),
                  // Pronunciation badge
                  GestureDetector(
                    onTap: _playExample,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.coralSurface,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.volume_up_rounded, size: 14.sp, color: AppColors.coral),
                        SizedBox(width: 6.w),
                        Text('Phát âm: "${widget.letter.romanized}"', style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.coralDark,
                        )),
                      ]),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  // Mic button with rings
                  GestureDetector(
                    onLongPressStart: _sttReady && !_isListening ? (_) => _startListening() : null,
                    onLongPressEnd: _isListening ? (_) => _stopListening() : null,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Column(
                        children: [
                          // Triple ring mic
                          Container(
                            width: 140.w, height: 140.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.coral.withValues(alpha: _isListening ? 0.5 : 0.25),
                                width: 1.5.w,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 120.w, height: 120.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.coralSurface,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90.w, height: 90.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        colors: _isListening
                                          ? [AppColors.coral, AppColors.coralDark]
                                          : [AppColors.coralLight, AppColors.coral],
                                      ),
                                      boxShadow: [BoxShadow(
                                        color: AppColors.coral.withValues(
                                          alpha: 0.3 + (_isListening ? 0.25 * _pulseCtrl.value : 0)),
                                        blurRadius: (16 + (_isListening ? 12 * _pulseCtrl.value : 0)).r,
                                        offset: Offset(0, 4.h),
                                      )],
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                      color: Colors.white, size: 40.w,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Wave bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(11, (i) {
                              final center = 5;
                              final dist = (i - center).abs();
                              final base = dist <= 1 ? 20.h : dist <= 3 ? 10.h : 5.h;
                              final h = _isListening
                                ? base * (0.5 + 0.5 * _pulseCtrl.value)
                                : base * 0.4;
                              return Container(
                                width: dist <= 1 ? 4.w : 3.w,
                                height: h,
                                margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(alpha: _isListening ? 0.8 : 0.3),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Status
                  if (_hasResult)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _isCorrect ? AppColors.tertiarySurface : AppColors.coralSurface,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_isCorrect ? '🎉' : '😅', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 6.w),
                        Text('$_accuracy%', style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp, fontWeight: FontWeight.w800,
                          color: _isCorrect ? AppColors.tertiaryDark : AppColors.coralDark)),
                        SizedBox(width: 6.w),
                        Text(_isCorrect ? 'Chính xác!' : 'Thử lại!',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600,
                            color: _isCorrect ? AppColors.tertiaryDark : AppColors.coralDark)),
                      ]),
                    )
                  else
                    Text(
                      _isListening ? 'Đang thu âm... Bỏ tay để kết thúc'
                        : _statusMsg.isNotEmpty ? _statusMsg
                        : !_sttReady ? 'Đang khởi tạo...'
                        : 'Nhấn giữ mic và đọc "${widget.letter.romanized}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, fontWeight: FontWeight.w600,
                        color: _isListening ? AppColors.coral : AppColors.textHint,
                      ),
                    ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE WRITE CONTENT
// ═══════════════════════════════════════════════════════════════

class _InlineWriteContent extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _InlineWriteContent({required this.letter, required this.onComplete});
  @override
  State<_InlineWriteContent> createState() => _InlineWriteContentState();
}

class _InlineWriteContentState extends State<_InlineWriteContent> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed;
  bool _showHint = false;

  void _clear() => setState(() { _strokes.clear(); _current = []; _passed = null; });

  void _check() {
    final total = _strokes.fold<int>(0, (s, l) => s + l.length);
    if (total < 10) {
      setState(() => _passed = false);
      return;
    }
    setState(() => _passed = true);
    widget.onComplete();
  }

  Widget _buildHintPage() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3), width: 2.w),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              CustomPaint(size: Size.infinite, painter: _GuideLinePainter()),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Text(widget.letter.character, style: GoogleFonts.battambang(
                    fontSize: 180.sp, fontWeight: FontWeight.w700,
                    color: AppColors.tertiary.withValues(alpha: 0.65),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _passed == null ? const Color(0xFFD7CCC8)
              : _passed! ? AppColors.tertiary : AppColors.coral,
            width: 2.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              // Grid
              CustomPaint(size: Size.infinite, painter: _GuideLinePainter()),
              // Guide letter (light)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Text(widget.letter.character, style: GoogleFonts.battambang(
                    fontSize: 180.sp, fontWeight: FontWeight.w300,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  )),
                ),
              ),
              // Drawing
              GestureDetector(
                onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; }),
                onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
                onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
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
        // Header
        Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_showHint ? Icons.lightbulb_rounded : Icons.edit_rounded,
              color: _showHint ? AppColors.tertiary : AppColors.primary, size: 20.w),
            SizedBox(width: 8.w),
            Text(_showHint ? 'Gợi ý viết' : 'Viết chữ', style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp, fontWeight: FontWeight.w800,
              color: _showHint ? AppColors.tertiaryDark : AppColors.primaryDark,
            )),
          ]),
        ),
        // Content area — Hint page OR Canvas
        Expanded(
          child: _showHint ? _buildHintPage() : _buildCanvas(),
        ),
        // Toolbar
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Row(
            children: [
              // Xóa
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
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.refresh_rounded, size: 16.sp, color: AppColors.textHint),
                      SizedBox(width: 4.w),
                      Text('Xóa', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textHint,
                      )),
                    ]),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Kiểm tra / Kết quả
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _passed != null ? () => setState(() => _passed = null) : _check,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      gradient: _passed == null
                        ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                        : _passed!
                          ? const LinearGradient(colors: [AppColors.tertiary, AppColors.tertiaryDark])
                          : const LinearGradient(colors: [AppColors.coral, AppColors.coralDark]),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [BoxShadow(color: (_passed == null ? AppColors.primary : _passed! ? AppColors.tertiary : AppColors.coral).withValues(alpha: 0.3), blurRadius: 8.r, offset: Offset(0, 3.h))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _passed == null ? Icons.check_circle_outline_rounded
                          : _passed! ? Icons.celebration_rounded : Icons.refresh_rounded,
                        size: 16.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        _passed == null ? 'Kiểm tra' : _passed! ? 'Đẹp lắm! 🎉' : 'Thử lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white,
                      )),
                    ]),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Gợi ý
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showHint = !_showHint),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: _showHint ? AppColors.tertiarySurface : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: _showHint ? AppColors.tertiary.withValues(alpha: 0.3) : const Color(0xFFE0E0E0)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 16.sp,
                        color: _showHint ? AppColors.tertiaryDark : AppColors.textHint),
                      SizedBox(width: 4.w),
                      Text('Gợi ý', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp, fontWeight: FontWeight.w700,
                        color: _showHint ? AppColors.tertiaryDark : AppColors.textHint,
                      )),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22.w, color: color),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPEAK SHEET — Nhận diện giọng nói THẬT bằng Speech-to-Text
// Flow: Bấm mic → Nói → Hệ thống tự chấm điểm
// ═══════════════════════════════════════════════════════════════

class _SpeakSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _SpeakSheet({required this.letter, required this.onComplete});

  @override
  State<_SpeakSheet> createState() => _SpeakSheetState();
}

class _SpeakSheetState extends State<_SpeakSheet>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;

  bool _sttReady = false;
  bool _isListening = false;
  bool _isPlayingExample = false;
  String _recognized = '';
  String _statusMsg = '';
  bool _hasResult = false;
  bool _isCorrect = false;
  int _score = 0;
  String _selectedLocaleId = 'vi-VN';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initTts();
    _initSTT();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List)
        .map((l) => l.toString().toLowerCase())
        .toList();
    final hasKhmer = langList.any(
      (l) => l.contains('km') || l.contains('khmer'),
    );
    if (hasKhmer) {
      await _tts.setLanguage('km');
    } else {
      final hasVi = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(hasVi ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingExample = false);
    });
  }

  Future<void> _playExample() async {
    if (_isPlayingExample) return;
    setState(() => _isPlayingExample = true);
    final text = widget.letter.pronunciation.isNotEmpty
        ? widget.letter.pronunciation
        : widget.letter.romanized;
    await _tts.speak(text);
  }

  Future<void> _initSTT() async {
    final micStatus = await Permission.microphone.request();
    debugPrint('[STT] Mic permission: $micStatus');
    if (!micStatus.isGranted) {
      if (mounted) {
        setState(() => _statusMsg = 'Cần cấp quyền microphone!');
      }
      return;
    }

    try {
      _sttReady = await _speech.initialize(
        onError: (err) {
          debugPrint('[STT] Error: ${err.errorMsg}');
          if (mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() {
              _isListening = false;
              if (_recognized.isEmpty) {
                _statusMsg = 'Không nghe được. Hãy nói to và rõ hơn!';
              } else {
                _evaluate();
              }
            });
          }
        },
        onStatus: (status) {
          debugPrint('[STT] Status: $status');
          if (status == 'done' && mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() => _isListening = false);
            _evaluate();
          }
        },
      );
      debugPrint('[STT] Initialize: $_sttReady');

      // Pre-select locale
      if (_sttReady) {
        final locales = await _speech.locales();
        for (final l in locales) {
          if (l.localeId.toLowerCase().startsWith('vi')) {
            _selectedLocaleId = l.localeId;
            break;
          }
        }
        if (_selectedLocaleId == 'vi-VN') {
          for (final l in locales) {
            if (l.localeId.toLowerCase().startsWith('km')) {
              _selectedLocaleId = l.localeId;
              break;
            }
          }
        }
        debugPrint('[STT] Selected locale: $_selectedLocaleId');
      }
    } catch (e) {
      debugPrint('[STT] Init error: $e');
      _sttReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Stop TTS if playing
    await _tts.stop();
    setState(() {
      _recognized = '';
      _statusMsg = '';
      _hasResult = false;
      _isListening = true;
      _isPlayingExample = false;
    });
    _pulseCtrl.repeat(reverse: true);

    debugPrint('[STT] Using locale: $_selectedLocaleId');

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint(
            '[STT] Result: "${result.recognizedWords}" final=${result.finalResult}',
          );
          if (mounted) {
            setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) {
              _pulseCtrl.stop();
              setState(() => _isListening = false);
              _evaluate();
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 4),
        localeId: _selectedLocaleId,
      );
    } catch (e) {
      debugPrint('[STT] Listen error: $e');
      _pulseCtrl.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMsg = 'Lỗi nhận diện giọng nói. Thử lại!';
        });
      }
    }
  }

  void _evaluate() {
    if (_hasResult) return;
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) {
      setState(() => _statusMsg = 'Không nhận diện được. Hãy nói to hơn!');
      return;
    }

    // Normalize: remove diacritics-like chars, spaces
    String normalize(String s) =>
        s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');

    final spokenNorm = normalize(spoken);
    final targets = [
      widget.letter.romanized,
      widget.letter.pronunciation,
      widget.letter.character,
    ].where((t) => t.isNotEmpty).map(normalize).toList();

    // Check exact or contains match
    bool exact = targets.any(
      (t) => spokenNorm.contains(t) || t.contains(spokenNorm),
    );
    if (exact) {
      _score = 5;
      _isCorrect = true;
    } else {
      // Check first character match (common for short syllables)
      bool firstCharMatch = targets.any(
        (t) => t.isNotEmpty && spokenNorm.isNotEmpty && t[0] == spokenNorm[0],
      );

      double best = 0;
      for (final t in targets) {
        final s = _sim(spokenNorm, t);
        if (s > best) best = s;
      }

      // More lenient: if first char matches, boost score
      if (firstCharMatch) best = (best + 0.15).clamp(0.0, 1.0);

      if (best > 0.5) {
        _score = 4;
        _isCorrect = true;
      } else if (best > 0.3) {
        _score = 3;
        _isCorrect = true;
      } else if (best > 0.15) {
        _score = 2;
        _isCorrect = false;
      } else {
        _score = 1;
        _isCorrect = false;
      }
    }

    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();

    // Show result dialog
    if (!mounted) return;
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
              Text(_isCorrect ? '🎉' : '😅', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 12.h),
              Text(
                _isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: _isCorrect ? AppColors.tertiary : AppColors.coral,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _isCorrect ? 'Phát âm rất tốt!' : 'Hãy thử lại nhé!',
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
                    i < _score ~/ 2
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 28.w,
                    color: i < _score ~/ 2
                        ? AppColors.secondary
                        : AppColors.surfaceContainerHighest,
                  ),
                ),
              ),
              if (_recognized.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  'Nghe được: "$_recognized"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (_isCorrect) ...[
                SizedBox(height: 6.h),
                Text(
                  '+10 XP ⭐',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              if (_isCorrect) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Hoàn thành ✅',
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
                    setState(() {
                      _hasResult = false;
                      _recognized = '';
                      _statusMsg = '';
                      _score = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    side: BorderSide(color: AppColors.violet),
                  ),
                  child: Text(
                    'Thử lại',
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

  double _sim(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final mx = a.length > b.length ? a.length : b.length;
    return 1.0 - (_lev(a, b) / mx);
  }

  int _lev(String s, String t) {
    final m = s.length, n = t.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      d[0][j] = j;
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final c = s[i - 1] == t[j - 1] ? 0 : 1;
        final v = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + c];
        d[i][j] = v.reduce((a, b) => a < b ? a : b);
      }
    }
    return d[m][n];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // ── Title ──
            Center(
              child: Text(
                'Tập nói phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // ── Khi chưa có kết quả: hiện character + mic ──
            if (!_hasResult) ...[
              // Character in blue circle
              Center(
                child: Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.3),
                        blurRadius: 16.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.letter.character,
                      style: GoogleFonts.battambang(
                        fontSize: 56.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFE0D5C5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.letter.romanized,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Stars placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    3,
                    (i) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Icon(
                        Icons.star_outline_rounded,
                        size: 30.w,
                        color: AppColors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Listen example pill
              Center(
                child: GestureDetector(
                  onTap: !_isPlayingExample && !_isListening
                      ? _playExample
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlayingExample
                              ? Icons.volume_up_rounded
                              : Icons.headphones_rounded,
                          color: const Color(0xFF7E57C2),
                          size: 18.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _isPlayingExample ? 'Đang phát...' : 'Nghe mẫu trước',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7E57C2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Mic button with wave bars
              Center(
                child: GestureDetector(
                  onTap: _sttReady && !_isListening ? _startListening : null,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) => SizedBox(
                      width: 200.w,
                      height: 100.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...List.generate(4, (i) {
                            final h = _isListening
                                ? 12.0.h +
                                      (20.h + i * 6.h) *
                                          (0.4 + 0.6 * _pulseCtrl.value)
                                : 8.0.h + i * 3.0.h;
                            return Container(
                              width: 4.w,
                              height: h,
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Color.lerp(
                                        AppColors.coral,
                                        AppColors.secondary,
                                        i / 3.0,
                                      )!
                                    : AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            );
                          }).reversed.toList(),
                          SizedBox(width: 6.w),
                          Container(
                            width: _isListening
                                ? 80.w + 8.w * _pulseCtrl.value
                                : 76.w,
                            height: _isListening
                                ? 80.w + 8.w * _pulseCtrl.value
                                : 76.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isListening
                                    ? [
                                        const Color(0xFFEF5350),
                                        const Color(0xFFC62828),
                                      ]
                                    : !_sttReady
                                    ? [
                                        const Color(0xFFBDBDBD),
                                        const Color(0xFF9E9E9E),
                                      ]
                                    : [
                                        const Color(0xFF66BB6A),
                                        const Color(0xFF388E3C),
                                      ],
                              ),
                              boxShadow: [
                                if (_sttReady)
                                  BoxShadow(
                                    color:
                                        (_isListening
                                                ? const Color(0xFFEF5350)
                                                : const Color(0xFF4CAF50))
                                            .withValues(alpha: 0.4),
                                      blurRadius: 18.r,
                                    offset: Offset(0, 6.h),
                                  ),
                              ],
                            ),
                            child: Icon(
                              _isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 36.w,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          ...List.generate(4, (i) {
                            final h = _isListening
                                ? 12.0.h +
                                      (20.h + i * 6.h) *
                                          (0.4 + 0.6 * _pulseCtrl.value)
                                : 8.0.h + i * 3.0.h;
                            return Container(
                              width: 4.w,
                              height: h,
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Color.lerp(
                                        AppColors.coral,
                                        AppColors.primary,
                                        i / 3.0,
                                      )!
                                    : AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  !_sttReady
                      ? 'Đang khởi tạo...'
                      : _isListening
                      ? (_recognized.isNotEmpty
                            ? '"$_recognized"'
                            : 'Đang nghe...')
                      : _statusMsg.isNotEmpty
                      ? _statusMsg
                      : 'Bé nhấn để nói',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isListening
                        ? AppColors.coral
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (_statusMsg.contains('Không') && !_isListening) ...[
                SizedBox(height: 10.h),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _statusMsg = ''),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WRITE SHEET — Tập viết chữ Khmer
// ═══════════════════════════════════════════════════════════════

class _WriteSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _WriteSheet({required this.letter, required this.onComplete});

  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String? _feedback;
  bool? _passed;

  void _check() {
    if (_strokes.length < 2) {
      setState(() {
        _passed = false;
        _feedback = 'Cần ít nhất 2 nét vẽ! (hiện có ${_strokes.length} nét)';
      });
      return;
    }
    int pts = 0;
    for (final s in _strokes) {
      pts += s.length;
    }
    if (pts < 20) {
      setState(() {
        _passed = false;
        _feedback = 'Nét viết quá ngắn! Hãy viết rõ ràng hơn.';
      });
      return;
    }
    double minX = double.infinity, maxX = 0, minY = double.infinity, maxY = 0;
    for (final s in _strokes) {
      for (final p in s) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    if ((maxX - minX) < 30 || (maxY - minY) < 30) {
      setState(() {
        _passed = false;
        _feedback = 'Chữ quá nhỏ! Hãy viết lớn hơn.';
      });
      return;
    }
    setState(() {
      _passed = true;
      _feedback = null;
    });
    widget.onComplete();

    // Show success dialog
    if (!mounted) return;
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
                'Viết tuyệt vời!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Bé viết chữ "${widget.letter.character}" rất đẹp!',
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
                '+10 XP ⭐',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Hoàn thành ✅',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _strokes.clear();
                      _current.clear();
                      _passed = null;
                      _feedback = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    side: BorderSide(color: AppColors.violet),
                  ),
                  child: Text(
                    'Viết lại',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 8.h),
          // Title (ẩn khi có kết quả)
          if (_passed != true) ...[
            Text(
              '✍️ Tập viết chữ ${widget.letter.character}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Quan sát mẫu rồi viết theo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          // ── Khi chưa viết đúng ──
          if (_passed != true) ...[
            // Model Character Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondarySurface,
                    AppColors.secondaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.secondary, width: 2.5.w),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                  BoxShadow(
                    color: const Color(0x11000000),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('✏️', style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onBackground,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Mẫu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        widget.letter.character,
                        style: GoogleFonts.battambang(
                          fontSize: 90.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            // Feedback banner (chỉ hiện khi sai)
            if (_feedback != null && _passed == false)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Row(
                    children: [
                      Text('😅', style: TextStyle(fontSize: 18.sp)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _feedback!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Canvas
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _passed == null
                        ? const Color(0xFFD7CCC8)
                        : _passed!
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFEF5350),
                    width: 2.w,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Stack(
                    children: [
                      CustomPaint(size: Size.infinite, painter: _GridPainter()),
                      Center(
                        child: Text(
                          widget.letter.character,
                          style: GoogleFonts.battambang(
                            fontSize: 180.sp,
                            fontWeight: FontWeight.w300,
                            color: const Color(
                              0xFFE0D5C5,
                            ).withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onPanStart: (d) => setState(() {
                          _current = [d.localPosition];
                          _passed = null;
                          _feedback = null;
                        }),
                        onPanUpdate: (d) =>
                            setState(() => _current.add(d.localPosition)),
                        onPanEnd: (_) => setState(() {
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
            ),
            SizedBox(height: 8.h),
            // Toolbar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE0D5C5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _toolBtn(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Kiểm tra',
                      color: _strokes.isNotEmpty
                          ? AppColors.tertiary
                          : AppColors.textHint,
                      onTap: _strokes.isNotEmpty ? _check : null,
                    ),
                    _toolBtn(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'Cục tẩy',
                      color: _strokes.isNotEmpty
                          ? AppColors.secondary
                          : AppColors.textHint,
                      onTap: _strokes.isNotEmpty
                          ? () => setState(() {
                              _strokes.removeLast();
                              _passed = null;
                              _feedback = null;
                            })
                          : null,
                    ),
                    _toolBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Làm lại',
                      color: AppColors.coral,
                      onTap: () => setState(() {
                        _strokes.clear();
                        _current.clear();
                        _passed = null;
                        _feedback = null;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 22.w),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _StrokeGuidePainter extends CustomPainter {
  final List<List<double>> strokes;
  _StrokeGuidePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final s in strokes) {
      final num = s[0].toInt();
      final px = s[1] * size.width;
      final py = s[2] * size.height;
      final angleDeg = s[3];
      final angleRad = angleDeg * math.pi / 180;

      // Draw curved arrow
      final r = 18.0;  // radius of arc
      final startAngle = angleRad - 0.8;
      final sweepAngle = 1.6;

      // Arc
      final rect = Rect.fromCircle(center: Offset(px, py), radius: r);
      canvas.drawArc(rect, startAngle, sweepAngle, false, arrowPaint);

      // Arrowhead at end of arc
      final endAngle = startAngle + sweepAngle;
      final tipX = px + r * math.cos(endAngle);
      final tipY = py + r * math.sin(endAngle);
      final headLen = 8.0;
      final h1 = Offset(
        tipX - headLen * math.cos(endAngle - 0.6),
        tipY - headLen * math.sin(endAngle - 0.6),
      );
      final h2 = Offset(
        tipX - headLen * math.cos(endAngle + 0.8),
        tipY - headLen * math.sin(endAngle + 0.8),
      );
      canvas.drawLine(Offset(tipX, tipY), h1, arrowPaint..strokeWidth = 2.0);
      canvas.drawLine(Offset(tipX, tipY), h2, arrowPaint..strokeWidth = 2.0);

      // Number label (positioned outside the arc)
      final labelDist = r + 14;
      final labelAngle = angleRad;
      final lx = px + labelDist * math.cos(labelAngle - math.pi);
      final ly = py + labelDist * math.sin(labelAngle - math.pi);

      // Circle background
      final bgPaint = Paint()..color = const Color(0xFFD32F2F);
      canvas.drawCircle(Offset(lx, ly), 10, bgPaint);

      // Number text
      final tp = TextPainter(
        text: TextSpan(
          text: '$num',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeGuidePainter old) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid squares
    final gridPaint = Paint()
      ..color = const Color(0xFFE0D5C5).withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    const cols = 8;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).ceil();
    // Vertical lines
    for (int i = 0; i <= cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Horizontal lines
    for (int j = 0; j <= rows; j++) {
      final y = j * cellW;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Center cross (thicker)
    final centerPaint = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GuideLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Full grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;
    const cols = 6;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).ceil();
    for (int i = 1; i < cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int j = 1; j < rows; j++) {
      final y = j * cellW;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawDashed(Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    final d = (p2 - p1);
    final len = d.distance;
    if (len == 0) return;
    final ux = d.dx / len, uy = d.dy / len;
    double pos = 0;
    while (pos < len) {
      final s = Offset(p1.dx + ux * pos, p1.dy + uy * pos);
      pos += dash;
      if (pos > len) pos = len;
      final e = Offset(p1.dx + ux * pos, p1.dy + uy * pos);
      canvas.drawLine(s, e, paint);
      pos += gap;
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s[0].dx, s[0].dy);
      for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy);
      canvas.drawPath(path, done);
    }
    if (current.length >= 2) {
      final active = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (int i = 1; i < current.length; i++)
        path.lineTo(current[i].dx, current[i].dy);
      canvas.drawPath(path, active);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
