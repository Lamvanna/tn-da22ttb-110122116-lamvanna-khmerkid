import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_writing.dart';
import '../../widgets/app_header.dart';
import '../../widgets/feedback_dialog.dart';
import '../../services/score_service.dart';

/// Trang chi tiết tập viết — Chuyển đổi thành Dictation: Chính tả - Nghe và gõ lại
class WritingDetailScreen extends StatefulWidget {
  final int initialIndex;
  const WritingDetailScreen({super.key, this.initialIndex = 0});

  @override
  State<WritingDetailScreen> createState() => _WritingDetailScreenState();
}

class _WritingDetailScreenState extends State<WritingDetailScreen> {
  final List<KhmerWriting> _lessons = KhmerWritingData.lessons;
  final FlutterTts _tts = FlutterTts();
  late int _current;
  int _doneCount = 0;
  int _totalStars = 0;
  int _streak = 0;

  final TextEditingController _inputCtrl = TextEditingController();
  bool _isConsonantTab = true;
  bool _isKeyboardVisible = true;

  // 33 Phụ âm Khmer
  final List<String> _consonants = const [
    'ក', 'ខ', 'គ', 'ឃ', 'ង',
    'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
    'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
    'ត', 'ថ', 'ទ', 'ធ', 'ន',
    'ប', 'ផ', 'ព', 'ភ', 'ម',
    'យ', 'រ', 'ល', 'វ',
    'ស', 'ហ', 'ឡ', 'អ'
  ];

  // 35 Nguyên âm và dấu Khmer
  final List<String> _vowels = const [
    'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ',
    'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ',
    'ុំ', 'ំ', 'ះ', 'ុះ', 'េះ', 'ោះ',
    '់', '៉', '៊', '៌', '៍', '៏', '័', 'ៈ',
    'ៗ', '។', '្', '៎', '៕'
  ];

  KhmerWriting get _lesson => _lessons[_current];

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _initTts();
    _loadDoneCount();
  }

  Future<void> _loadDoneCount() async {
    try {
      final scoreService = await ScoreService.getInstance();
      int count = 0;
      for (final lesson in _lessons) {
        if (lesson.isLearned) {
          count++;
        }
      }
      if (mounted) {
        setState(() {
          _doneCount = count;
          _totalStars = scoreService.totalStars;
          _streak = scoreService.streak;
        });
      }
    } catch (e) {
      debugPrint('Error loading done count: $e');
    }
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
    await _tts.setSpeechRate(0.35);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text, {bool isSlow = false}) async {
    if (isSlow) {
      await _tts.setSpeechRate(0.15);
    } else {
      await _tts.setSpeechRate(0.35);
    }
    await _tts.speak(text);
  }

  void _next() {
    if (_current < _lessons.length - 1) {
      setState(() {
        _current++;
        _inputCtrl.clear();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _showCompletionDialog();
      });
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _inputCtrl.clear();
      });
    }
  }

  void _onKeyTapped(String char) {
    if (_inputCtrl.text.length >= 200) return;
    final text = _inputCtrl.text;
    final selection = _inputCtrl.selection;
    setState(() {
      if (selection.isValid) {
        final start = selection.start;
        final end = selection.end;
        final newText = text.replaceRange(start, end, char);
        _inputCtrl.text = newText;
        _inputCtrl.selection = TextSelection.collapsed(offset: start + char.length);
      } else {
        _inputCtrl.text = text + char;
      }
    });
  }

  void _onBackspaceTapped() {
    final text = _inputCtrl.text;
    if (text.isEmpty) return;
    final selection = _inputCtrl.selection;
    setState(() {
      if (selection.isValid) {
        final start = selection.start;
        final end = selection.end;
        if (start != end) {
          _inputCtrl.text = text.replaceRange(start, end, '');
          _inputCtrl.selection = TextSelection.collapsed(offset: start);
        } else if (start > 0) {
          _inputCtrl.text = text.replaceRange(start - 1, start, '');
          _inputCtrl.selection = TextSelection.collapsed(offset: start - 1);
        }
      } else {
        _inputCtrl.text = text.substring(0, text.length - 1);
      }
    });
  }

  Future<void> _check() async {
    final targetChar = _lesson.character;
    final entered = _inputCtrl.text.trim();
    
    if (entered.isEmpty) return;
    
    // Chuẩn hóa ký tự trước khi đối chiếu
    final normTarget = targetChar.replaceAll(' ', '').replaceAll('◌', '').replaceAll('\u25cc', '').toLowerCase();
    final normEntered = entered.replaceAll(' ', '').replaceAll('◌', '').replaceAll('\u25cc', '').toLowerCase();
    
    final isPassed = normTarget == normEntered;
    int stars = isPassed ? 3 : 0;
    
    if (isPassed) {
      _speak(targetChar);
    }
    
    // Lưu kết quả bài viết
    try {
      final scoreService = await ScoreService.getInstance();
      await scoreService.completeWritingLesson(
        _current,
        stars,
        lessonId: null,
        strokes: const [],
        targetCharacter: targetChar,
        passed: isPassed,
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
    
    if (mounted) {
      if (isPassed) {
        FeedbackDialog.showSuccess(
          context,
          xpEarned: 15,
          message: context.translate('learn.dictation_success'),
        );
        setState(() {
          _lesson.isLearned = true;
          _lesson.starRating = 3;
        });
        _loadDoneCount();
      } else {
        FeedbackDialog.showFailure(
          context,
          message: context.translate('learn.incorrect_dictation_warning'),
        );
      }
    }
  }



  @override
  void dispose() {
    _tts.stop();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final progress = _lessons.isEmpty ? 0.0 : (_current + 1) / _lessons.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        children: [
          // App Header
          _buildHeader(),
          // Progress and Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [


                  // ── Audio player and Mascot Box ──
                  _buildAudioPlayerCard(),

                  const SizedBox(height: 14),

                  // ── Gõ câu bạn vừa nghe Area ──
                  _buildInputBox(),

                  const SizedBox(height: 14),

                  // ── Action Buttons (Replay, Check, Next combined in 1 row) ──
                  _buildActionRow(),
                ],
              ),
            ),
          ),
          // Custom Keyboard docked at the bottom
          if (_isKeyboardVisible) _buildKeyboard(w),
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
                              context.translate('learn.writing_count', args: {'done': _current + 1, 'total': _lessons.length}),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22.sp,
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
                              '$_totalStars',
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
                              '$_streak',
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

  // Audio Player and Mascot Card
  Widget _buildAudioPlayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Audio elements
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruction prompt
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: AppColors.violet, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('learn.listen_to_sentence'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'và gõ lại vào ô bên dưới nhé!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Big Circular Play Button and wave lines
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWaveform(),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => _speak(_lesson.character),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.violet, AppColors.violetLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildWaveform(),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nhấn để nghe',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.violet,
                  ),
                ),
              ),
            ],
          ),
          // Mascot positioned on the right
          Positioned(
            right: -10,
            top: -10,
            child: SizedBox(
              width: 90.w,
              height: 90.w,
              child: Image.asset(
                'image/Voi nguyên âm.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Slow audio button on bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _speak(_lesson.character, isSlow: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.slow_motion_video_rounded, color: AppColors.violet, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Nghe chậm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
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

  Widget _buildWaveform() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaveBar(14),
        _buildWaveBar(26),
        _buildWaveBar(18),
        _buildWaveBar(32),
        _buildWaveBar(12),
      ],
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 3.w,
      height: height.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Type your Khmer input card
  Widget _buildInputBox() {
    return GestureDetector(
      onTap: () {
        if (!_isKeyboardVisible) {
          setState(() => _isKeyboardVisible = true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEEEDF2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.violet, size: 16),
                const SizedBox(width: 6),
                Text(
                  context.translate('learn.type_sentence_heard'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              constraints: BoxConstraints(minHeight: 120.h),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _inputCtrl,
                    maxLines: null,
                    readOnly: true,
                    showCursor: true,
                    onTap: () {
                      if (!_isKeyboardVisible) {
                        setState(() => _isKeyboardVisible = true);
                      }
                    },
                    style: GoogleFonts.battambang(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: context.translate('learn.enter_khmer_sentence'),
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${_inputCtrl.text.length}/200',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // Action Buttons Row (Combined Replay, Check, Next into 1 premium row)
  Widget _buildActionRow() {
    final hasInput = _inputCtrl.text.trim().isNotEmpty;
    final canPrev = _current > 0;
    final canNext = _current < _lessons.length - 1;

    return Row(
      children: [
        // 1. Back button (Icon only to save space)
        if (canPrev)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFEEEDF2), width: 1.5),
            ),
            child: IconButton(
              onPressed: _prev,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
              constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
              padding: EdgeInsets.zero,
            ),
          ),
        if (canPrev) SizedBox(width: 8.w),

        // 2. Replay button (Icon only to save space)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFEEEDF2), width: 1.5),
          ),
          child: IconButton(
            onPressed: () => _speak(_lesson.character),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.violet),
            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(width: 8.w),

        // 3. Check button (Expanded)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: hasInput ? _check : null,
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                gradient: hasInput
                    ? const LinearGradient(colors: [AppColors.violet, AppColors.violetLight])
                    : null,
                color: hasInput ? null : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: hasInput
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: hasInput ? Colors.white : AppColors.textHint,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      context.translate('common.check'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: hasInput ? Colors.white : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Next button
        if (canNext) ...[
          SizedBox(width: 8.w),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.2),
                      blurRadius: 6.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.translate('common.next'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14.sp),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Keyboard Dock
  Widget _buildKeyboard(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        border: Border(top: BorderSide(color: const Color(0xFFE0E2E8), width: 1.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeyboardTabs(),
          _buildKeyboardKeys(screenWidth),
          _buildKeyboardBottomRow(screenWidth),
        ],
      ),
    );
  }

  Widget _buildKeyboardTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF1F2F6),
      child: Row(
        children: [
          // Consonants Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isConsonantTab = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isConsonantTab ? AppColors.violetSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConsonantTab ? AppColors.violet : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.font_download_outlined,
                        color: _isConsonantTab ? AppColors.violet : AppColors.textSecondary,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Phụ âm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isConsonantTab ? AppColors.violet : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Swap Button
          GestureDetector(
            onTap: () => setState(() => _isConsonantTab = !_isConsonantTab),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E2E8)),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: AppColors.violet, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Vowels Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isConsonantTab = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isConsonantTab ? AppColors.coralSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_isConsonantTab ? AppColors.coral : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette_outlined,
                        color: !_isConsonantTab ? AppColors.coral : AppColors.textSecondary,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Nguyên âm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !_isConsonantTab ? AppColors.coral : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Hide Keyboard Button
          GestureDetector(
            onTap: () => setState(() => _isKeyboardVisible = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E2E8)),
              ),
              child: const Icon(Icons.keyboard_hide_rounded, color: AppColors.violet, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardKeys(double screenWidth) {
    final keys = _isConsonantTab ? _consonants : _vowels;
    // Spacing: 6px between keys. 10 keys per row => 9 gaps => 54px total spacing.
    // Left/right padding: 10px each => 20px total padding.
    // Remaining width for 10 keys: screenWidth - 74px.
    final keyWidth = (screenWidth - 76) / 10;
    
    return Container(
      color: const Color(0xFFF1F2F6),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: keys.map((keyChar) {
          final isCombining = !_isConsonantTab && 
              keyChar != 'ៗ' && 
              keyChar != '។' && 
              keyChar != '៕';
          final displayLabel = isCombining ? '◌$keyChar' : keyChar;

          return GestureDetector(
            onTap: () => _onKeyTapped(keyChar),
            child: Container(
              width: keyWidth,
              height: 38.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayLabel,
                  style: GoogleFonts.battambang(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyboardBottomRow(double screenWidth) {
    final keyWidth = (screenWidth - 76) / 10;
    final delWidth = keyWidth * 1.8 + 6;
    final doneWidth = keyWidth * 1.8 + 6;
    final spaceWidth = screenWidth - delWidth - doneWidth - 32;

    return Container(
      color: const Color(0xFFF1F2F6),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete Key
          GestureDetector(
            onTap: _onBackspaceTapped,
            child: Container(
              width: delWidth,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E2E8),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backspace_outlined, size: 16.sp, color: AppColors.violet),
                  const SizedBox(width: 4),
                  Text(
                    context.translate('common.clear'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.violet,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Space Key
          GestureDetector(
            onTap: () => _onKeyTapped(' '),
            child: Container(
              width: spaceWidth,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  context.translate('learn.spacebar'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          // Done Key
          GestureDetector(
            onTap: _check,
            child: Container(
              width: doneWidth,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 16.sp, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Xong',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  void _showCompletionDialog() {
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
                  context.translate('learn.completed_all_writing'),
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
                        '+3 Sao',
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
                        '+15 XP',
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
                      Navigator.pop(context);
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
                    child: Text(
                      'Quay về',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
}
