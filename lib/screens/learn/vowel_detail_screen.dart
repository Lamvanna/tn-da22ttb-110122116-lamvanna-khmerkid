import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import '../../services/auth_service.dart';
import '../../widgets/khmer_listen_widget.dart';
import '../../widgets/khmer_speak_widget.dart';
import '../../widgets/khmer_write_widget.dart';
import '../../services/score_service.dart';
import '../../services/lesson_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../repositories/progress_repository.dart';

/// Chi tiết 1 nguyên âm — 2 bước inline: Nghe, Viết (giống phụ âm)
class VowelDetailScreen extends StatefulWidget {
  final int initialIndex;
  const VowelDetailScreen({super.key, this.initialIndex = 0});
  @override
  State<VowelDetailScreen> createState() => _VowelDetailScreenState();
}

class _VowelDetailScreenState extends State<VowelDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  List<KhmerVowel> _vowels = KhmerVowelData.vowels;
  bool _isLoading = false;
  ScoreService? _score;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  // 0 = none, 1 = listen, 2 = speak, 3 = write
  int _activeSheet = 0;
  bool _isAlreadyDone = false;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
    _loadScoreAndLessons();
  }

  Future<void> _loadScoreAndLessons() async {
    try {
      final score = await ScoreService.getInstance();
      if (mounted) {
        setState(() {
          _score = score;
        });
      }

      // 1. Tạo bản sao từ danh sách tĩnh chất lượng cao để bảo toàn các nguyên âm phụ thuộc, ví dụ và nghĩa tiếng Việt gốc
      final List<KhmerVowel> fullList = KhmerVowelData.vowels.map((item) {
        return KhmerVowel(
          id: item.id,
          character: item.character,
          dependent: item.dependent,
          romanized: item.romanized,
          pronunciation: item.pronunciation,
          example: item.example,
          exampleMeaning: item.exampleMeaning,
          starRating: item.starRating,
          isLearned: item.isLearned,
        );
      }).toList();

      // 2. Nạp trực tiếp từ ProgressRepository cache RAM trực tuyến
      try {
        final vowelProgress = await ProgressRepository.instance.getProgressMap('vowel');
        for (int i = 0; i < fullList.length; i++) {
          if (vowelProgress.containsKey(i)) {
            fullList[i].isLearned = true;
            fullList[i].starRating = vowelProgress[i]!;
          } else {
            fullList[i].isLearned = false;
            fullList[i].starRating = 0;
          }
        }
        if (mounted) {
          setState(() {
            _vowels = fullList;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error loading vowel progress from repository: $e');
      }

      // 3. Tải danh sách dynamic lessons từ database để lấy ID của từng nguyên âm trong nền
      final lessonService = await LessonService.getInstance();
      final lessonsData = await lessonService.fetchLessonsByType('vowel');
      
      final lessonIdMap = <String, String>{};
      for (final l in lessonsData) {
        final text = l['khmerText']?.toString() ?? '';
        final id = l['_id']?.toString() ?? l['id']?.toString() ?? '';
        if (text.isNotEmpty && id.isNotEmpty) {
          lessonIdMap[text] = id;
        }
      }

      // Ánh xạ ID từ DB vào danh sách tĩnh
      for (final v in fullList) {
        if (lessonIdMap.containsKey(v.character)) {
          v.id = lessonIdMap[v.character];
        }
      }

      if (mounted) {
        setState(() {
          _vowels = fullList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic vowel lessons: $e');
      if (mounted) {
        setState(() {
          _vowels = KhmerVowelData.vowels;
          _isLoading = false;
        });
      }
    }
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));

    if (_completedSteps[_idx]!.length == 3) _onCompleted();
  }

  void _onCompleted() {
    _vowels[_idx].isLearned = true;
    _vowels[_idx].starRating = 3;

    final lessonId = _v.id ?? 'vowel_$_idx';
    ProgressRepository.instance.isLessonCompleted(lessonId).then((done) {
      if (mounted) {
        setState(() {
          _isAlreadyDone = done;
        });
      }
    });

    ScoreService.getInstance().then((scoreService) {
      return scoreService.completeVowelLesson(
        _idx,
        8,
        xp: 55,
        lessonId: _v.id ?? 'vowel_$_idx',
        vowelText: _v.displayCharacter,
        transliteration: _v.romanized,
      );
    }).then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint('⚠️ Error completing vowel lesson: $e');
    });

    // Show completion dialog after a 1.2-second delay to allow the confetti animation to play first
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _vowels.length - 1;
    showDialog(
      context: context, barrierDismissible: false,
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
                  context.translate('learn.completed_vowel', args: {'character': _v.displayCharacter}),
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
                          '+8 Sao',
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
                          '+55 XP',
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
                            context.translate('learn.next_vowel_btn'),
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
                      context.translate('learn.back_to_list'),
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

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  KhmerVowel get _v => _vowels.isNotEmpty ? _vowels[_idx] : KhmerVowelData.vowels[_idx];
  bool _isStepComplete(int step) {
    if (_vowels.isEmpty) return false;
    return _completedSteps[_idx]?.contains(step) ?? false;
  }

  bool _canGo(int i) {
    if (_vowels.isEmpty || i < 0 || i >= _vowels.length) return false;
    if (i <= _idx) return true; // Can always go back
    final currentLessonCompleted = _vowels[_idx].isLearned || (_completedSteps[_idx]?.length == 3);
    if (i == _idx + 1) return currentLessonCompleted;
    return false;
  }
  void _goTo(int i) {
    if (!_canGo(i)) return;
    _animCtrl.reset();
    setState(() { _idx = i; _activeSheet = 0; });
    _animCtrl.forward();
  }

  void _showListenSheet() => setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1);
  void _showSpeakSheet() => setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2);
  void _showWriteSheet() => setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.learnBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.learnBackground,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: _activeSheet == 3
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 470.h),
                  child: Stack(children: [
                    _buildMainCard(),
                    if (_activeSheet != 0) Positioned.fill(child: _buildInlineSheet()),
                  ]),
                ),
                SizedBox(height: 8.h),
                _buildActionRow(),
                SizedBox(height: 16.h),
                _buildNavButtons(),
              ]),
            ),
          ),
        ),
      ]),
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
          bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: AppColors.headerDark.withValues(alpha: 0.35),
          blurRadius: 24.r, offset: Offset(0, 8.h))],
      ),
      child: Stack(children: [
        Positioned(right: -20.w, top: -20.h,
          child: Container(width: 100.w, height: 100.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -30.w, bottom: -10.h,
          child: Container(width: 70.w, height: 70.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
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
                        Row(children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle),
                              child: Icon(Icons.arrow_back_rounded, size: 20.w)),
                            color: Colors.white, padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.w)),
                          SizedBox(width: 6.w),
                          Expanded(child: Text(context.translate('learn.vowel_count', args: {'done': _idx + 1, 'total': _vowels.length}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                        ]),
                        Padding(
                          padding: EdgeInsets.only(left: 54.w, top: 8.h),
                          child: Row(children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12.r)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('⭐', style: TextStyle(fontSize: 13.sp)),
                                SizedBox(width: 4.w),
                                Text('${_score?.totalStars ?? 0}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                              ]),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12.r)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('🔥', style: TextStyle(fontSize: 13.sp)),
                                SizedBox(width: 4.w),
                                Text('${_score?.streak ?? 0} ngày',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Mascot
                  Transform.translate(
                    offset: Offset(-5.w, -5.h),
                    child: SizedBox(
                      width: 130.w, height: 75.h,
                      child: OverflowBox(
                        maxHeight: 200.w, maxWidth: 200.w,
                        child: Image.asset('assets/images/elephant_mascot.png',
                          width: 200.w, height: 200.w, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _playExample() async {
    // Đọc TÊN nguyên âm kiểu Khmer ("srăk a") bằng giọng Việt, khớp với bước Nghe.
    await TtsService.instance.speakVietnamese(_v.listenText);
  }

  // ═══════════════════ MAIN CARD ═══════════════════
  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 470.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20.r, offset: Offset(0, 6.h))],
      ),
      child: Column(
        children: [
          // ── Top: big character ──
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 0),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(40.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.06)),
                  child: Text(_v.displayCharacter, style: GoogleFonts.battambang(
                    fontSize: 130.sp, fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E88E5), height: 1.1)),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: 80.w, height: 3.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFF1E88E5).withValues(alpha: 0.1),
                      const Color(0xFF1E88E5),
                      const Color(0xFF1E88E5).withValues(alpha: 0.1)]),
                    borderRadius: BorderRadius.circular(2.r))),
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
              boxShadow: [BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                blurRadius: 10.r, offset: Offset(0, 3.h))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _v.example.isNotEmpty ? _v.example : _v.dependent,
                        style: GoogleFonts.battambang(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1565C0)),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.volume_up_rounded,
                            size: 16.w, color: const Color(0xFF1E88E5)),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              _v.exampleMeaning.isNotEmpty
                                  ? '${_v.exampleMeaning} • "${_v.pronunciation}"'
                                  : context.translate('learn.pronunciation_label') + ' "' + _v.pronunciation + '"',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Nút nghe nhanh
                GestureDetector(
                  onTap: _playExample,
                  child: Container(
                    width: 56.w, height: 56.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                        blurRadius: 10.r, offset: Offset(0, 3.h))],
                    ),
                    child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 28.w),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: double.infinity, color: Colors.white,
        child: Stack(children: [
          Column(children: [
            if (_activeSheet == 1)
              Expanded(
                child: KhmerListenWidget(
                  character: _v.character,
                  romanized: _v.romanized,
                  pronunciation: _v.pronunciation,
                  // Nghe đọc TÊN nguyên âm kiểu Khmer: "srăk a", "srăk e"...
                  // (đọc bằng giọng Việt, không đọc ký tự Khmer ra "a")
                  speakTextOverride: _v.listenText,
                  accentColor: AppColors.tertiary,
                  accentColorDark: AppColors.tertiaryDark,
                  surfaceColor: AppColors.tertiarySurface,
                  onComplete: () => _markStepComplete(0),
                ),
              ),
            if (_activeSheet == 2)
              Expanded(
                child: KhmerSpeakWidget(
                  targetWord: _v.displayCharacter,
                  romanized: _v.romanized,
                  meaning: _v.pronunciation,
                  accentColor: const Color(0xFF1E88E5),
                  accentColorDark: const Color(0xFF1565C0),
                  surfaceColor: const Color(0xFFEEF4FC),
                  onComplete: () => _markStepComplete(1),
                ),
              ),
            if (_activeSheet == 3)
              Expanded(
                child: KhmerWriteWidget(
                  // Strip ◌ (U+25CC dotted circle) — DB stores vowel marks without it
                  character: _v.displayCharacter.replaceAll('\u25CC', ''),
                  accentColor: AppColors.primary,
                  accentColorDark: AppColors.primaryDark,
                  surfaceColor: AppColors.primarySurface,
                  showStrokeGuide: true, // Hiển thị mũi tên hướng nét cho nguyên âm
                  enableOcr: false,
                  minPointsRequired: 80, // Nguyên âm nét ngắn — giảm yêu cầu xuống 80 điểm cho đồng bộ
                  minStrokesRequired: 1, // Tối thiểu 1 nét cho nguyên âm
                  passThreshold: 60.0, // Ngưỡng đạt 60%
                  outsideThreshold: 45.0, // Nét ra ngoài tối đa 45%
                  toleranceRadius: 25.0, // Bán kính tolerance 25px ôm trọn nét vẽ
                  onComplete: () => _markStepComplete(2),
                ),
              ),
          ]),
          Positioned(top: 8.h, right: 8.w,
            child: GestureDetector(
              onTap: () => setState(() => _activeSheet = 0),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8.r, offset: Offset(0, 2.h))]),
                child: Icon(Icons.close_rounded, size: 20.sp, color: AppColors.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════ ACTION ROW ═══════════════════
  Widget _buildActionRow() {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: _showListenSheet,
        child: _actionCard(
          imagePath: 'image/Nghe.png', label: context.translate('common.listen'), sub: context.translate('learn.listen_pronunciation'),
          bgColor: const Color(0xFFE8F5E9), accentColor: const Color(0xFF43A047), stepIdx: 0),
      )),
      SizedBox(width: 8.w),
      Expanded(child: GestureDetector(
        onTap: _showSpeakSheet,
        child: _actionCard(
          imagePath: 'image/Mic.png', label: context.translate('common.speak'), sub: context.translate('learn.practice_pronunciation'),
          bgColor: const Color(0xFFE3F2FD), accentColor: const Color(0xFF1E88E5), stepIdx: 1),
      )),
      SizedBox(width: 8.w),
      Expanded(child: GestureDetector(
        onTap: _showWriteSheet,
        child: _actionCard(
          imagePath: 'image/Viết.png', label: context.translate('common.write'), sub: context.translate('learn.practice_writing_letter'),
          bgColor: const Color(0xFFEDE7F6), accentColor: const Color(0xFF5E35B1), stepIdx: 2),
      )),
    ]);
  }

  Widget _actionCard({
    required String imagePath, required String label,
    required String sub, required Color bgColor,
    required Color accentColor, required int stepIdx,
  }) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: done ? accentColor.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.18),
          width: done ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 16.r, offset: Offset(0, 6.h)),
          BoxShadow(color: accentColor.withValues(alpha: 0.06), blurRadius: 4.r, offset: Offset(0, 2.h)),
        ]),
      child: Column(children: [
        Image.asset(imagePath, width: 70.w, height: 70.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 18.sp, fontWeight: FontWeight.w800, color: accentColor)),
        SizedBox(height: 3.h),
        Text(sub, style: GoogleFonts.plusJakartaSans(
          fontSize: 11.sp, fontWeight: FontWeight.w600,
          color: accentColor.withValues(alpha: 0.65))),
      ]),
    );
  }

  // ═══════════════════ NAVIGATION + STEPPER ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _canGo(_idx - 1);
    final canNext = _canGo(_idx + 1);
    final labels = [context.translate('common.listen'), context.translate('common.speak'), context.translate('common.write')];
    final stepColors = [const Color(0xFF43A047), const Color(0xFF1E88E5), const Color(0xFF5E35B1)];
    return Row(children: [
      GestureDetector(
        onTap: canPrev ? () => _goTo(_idx - 1) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.12)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6.r, offset: Offset(0, 2.h))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chevron_left_rounded, color: canPrev ? const Color(0xFF1E88E5) : AppColors.textHint, size: 18.w),
            Text(context.translate('common.back'), style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: canPrev ? const Color(0xFF1E88E5) : AppColors.textHint)),
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
          } else if (_idx < _vowels.length - 1) {
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
            boxShadow: canNext ? [BoxShadow(color: const Color(0xFF1E88E5).withValues(alpha: 0.35), blurRadius: 10.r, offset: Offset(0, 3.h))] : null),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(canNext ? context.translate('common.next') : context.translate('common.locked'), style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: canNext ? Colors.white : AppColors.textHint)),
            SizedBox(width: 4.w),
            Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded, color: canNext ? Colors.white : AppColors.textHint, size: 18.w),
          ]),
        ),
      ),
    ]);
  }
}
