import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_number.dart';
import '../../services/score_service.dart';
import '../../services/lesson_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/khmer_listen_widget.dart';
import '../../widgets/khmer_speak_widget.dart';
import '../../widgets/khmer_write_widget.dart';

/// Màn hình chi tiết số Khmer — Tích hợp 2 bước học inline (Nghe, Viết) tương tự nguyên âm
class NumberDetailScreen extends StatefulWidget {
  final int initialIndex;
  const NumberDetailScreen({super.key, this.initialIndex = 0});

  @override
  State<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends State<NumberDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  List<KhmerNumber> _numbers = KhmerNumberData.numbers;
  bool _isLoading = false;
  ScoreService? _score;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  // 0 = none, 1 = listen, 2 = speak, 3 = write
  int _activeSheet = 0;

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

      // 1. Tạo bản sao từ danh sách tĩnh chất lượng cao để bảo toàn ký tự gốc, phiên âm, từ vựng và cách đọc tiếng Việt
      final List<KhmerNumber> fullList = KhmerNumberData.numbers.map((item) {
        return KhmerNumber(
          id: item.id,
          character: item.character,
          value: item.value,
          khmerWord: item.khmerWord,
          romanized: item.romanized,
          pronunciation: item.pronunciation,
          starRating: item.starRating,
          isLearned: item.isLearned,
        );
      }).toList();

      // 2. Tải nhanh từ bộ nhớ tạm local (SharedPreferences) trước để màn hình mở lên NGAY LẬP TỨC
      try {
        final storage = await StorageService.getInstance();
        final localNumberProgress = storage.getNumberProgress();
        for (int i = 0; i < fullList.length; i++) {
          if (localNumberProgress.containsKey(i)) {
            fullList[i].isLearned = true;
            fullList[i].starRating = localNumberProgress[i]!;
          } else {
            // Không mặc định đánh dấu đã học (isLearned = false) để tránh chưa học đã mở khóa
            fullList[i].isLearned = false;
            fullList[i].starRating = 0;
          }
        }
        if (mounted) {
          setState(() {
            _numbers = fullList;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error loading local cached number progress in detail: $e');
      }

      // 3. Tải danh sách dynamic lessons từ database để lấy ID của từng số trong nền
      final lessonService = await LessonService.getInstance();
      final lessonsData = await lessonService.fetchLessonsByType('number');
      
      final lessonIdMap = <String, String>{};
      for (final l in lessonsData) {
        final text = l['khmerText']?.toString() ?? '';
        final id = l['_id']?.toString() ?? l['id']?.toString() ?? '';
        if (text.isNotEmpty && id.isNotEmpty) {
          lessonIdMap[text] = id;
        }
      }

      // Ánh xạ ID từ DB vào danh sách tĩnh
      for (final n in fullList) {
        if (lessonIdMap.containsKey(n.character)) {
          n.id = lessonIdMap[n.character];
        }
      }

      // 4. Tải danh sách các bài học đã hoàn thành của người dùng từ MongoDB Atlas
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

      final completedIds = completedLessons
          .map((l) {
            if (l is Map) {
              return l['_id']?.toString() ?? l['id']?.toString() ?? '';
            }
            return l.toString();
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      final storage = await StorageService.getInstance();

      // 5. Đồng bộ trạng thái học tập thực tế và mở khóa mặc định các bài học ban đầu
      for (int i = 0; i < fullList.length; i++) {
        final character = fullList[i].character;
        final id = fullList[i].id;

        bool isDone = completedNumbers.contains(character);
        if (!isDone && id != null && completedIds.contains(id)) {
          isDone = true;
        }

        if (isDone) {
          fullList[i].isLearned = true;
          if (fullList[i].starRating == 0) {
            fullList[i].starRating = 3;
          }
          await storage.saveNumberProgress(i, fullList[i].starRating);
        } else {
          // Giữ nguyên tiến trình local đã nạp từ bộ nhớ tạm, KHÔNG tự ý ghi đè về false
        }
      }

      if (mounted) {
        setState(() {
          _numbers = fullList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading dynamic number lessons: $e');
      if (mounted) {
        setState(() {
          _numbers = KhmerNumberData.numbers;
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

  Future<void> _onCompleted() async {
    setState(() {
      _numbers[_idx].isLearned = true;
      _numbers[_idx].starRating = 3;
    });

    try {
      final scoreService = await ScoreService.getInstance();
      await scoreService.completeNumberLesson(
        _idx,
        3,
        lessonId: _num.id,
        numberText: _num.character,
        transliteration: _num.romanized,
      );
    } catch (e) {
      debugPrint('Error saving number progress: $e');
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _numbers.length - 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🎉', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text('Chúc mừng!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            SizedBox(height: 8.h),
            Text('Bạn đã hoàn thành số "${_num.value}" ( ${_num.character} )',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            SizedBox(height: 6.h),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (i) => Icon(Icons.star_rounded,
                        size: 28.sp, color: const Color(0xFFFFB300)))),
            SizedBox(height: 6.h),
            Text('+15 XP ⭐',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFB300))),
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
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r))),
                    child: Text('Học số tiếp theo →',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )),
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
                          borderRadius: BorderRadius.circular(14.r)),
                      side: const BorderSide(color: AppColors.primary)),
                  child: Text('Quay về danh sách',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                )),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerNumber get _num => _numbers.isNotEmpty ? _numbers[_idx] : KhmerNumberData.numbers[_idx];
  bool _isStepComplete(int step) {
    if (_numbers.isEmpty) return false;
    return _completedSteps[_idx]?.contains(step) ?? false;
  }

  bool _canGo(int i) {
    if (_numbers.isEmpty || i < 0 || i >= _numbers.length) return false;
    if (i <= _idx) return true; // Can always go back
    final currentLessonCompleted = _numbers[_idx].isLearned || (_completedSteps[_idx]?.length == 3);
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

  void _showListenSheet() =>
      setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1);
  void _showSpeakSheet() =>
      setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2);
  void _showWriteSheet() =>
      setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3);

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
                    if (_activeSheet != 0)
                      Positioned.fill(child: _buildInlineSheet()),
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

  // ═══════════════════ HEADER (đồng bộ với trang Phụ âm) ═══════════════════
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
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 0, 10.h),
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
                                child: Icon(Icons.arrow_back_rounded, size: 20.w),
                              ),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.w),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Số ${_num.value} ( ${_num.character} )',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                      '${_score?.totalStars ?? 0}',
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
                        ),
                      ],
                    ),
                  ),
                  // Mascot
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
        ],
      ),
    );
  }

  Future<void> _playExample() async {
    await TtsService.instance.speakKhmerLetter(
      character: _num.character,
      pronunciation: _num.pronunciation,
      romanized: _num.romanized,
    );
  }

  // ═══════════════════ MAIN CARD (đồng bộ với trang Phụ âm) ═══════════════════
  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 470.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
            color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20.r,
              offset: Offset(0, 6.h))
        ],
      ),
      child: Column(
        children: [
          // ── Top: big number ──
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 0),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(40.w),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.06)),
                  child: Text(_num.character,
                      style: GoogleFonts.battambang(
                          fontSize: 130.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.1)),
                ),
                SizedBox(height: 10.h),
                Container(
                    width: 80.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.1)
                        ]),
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 10.r, offset: Offset(0, 3.h))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _num.khmerWord,
                        style: GoogleFonts.battambang(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1565C0)),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.volume_up_rounded,
                            size: 16.w, color: AppColors.primary),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Số ${_num.value} • "${_num.pronunciation}"',
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
        width: double.infinity,
        color: Colors.white,
        child: Stack(children: [
          Column(children: [
            if (_activeSheet == 1)
              Expanded(
                child: KhmerListenWidget(
                  character: _num.character,
                  romanized: _num.value,
                  pronunciation: _num.pronunciation,
                  accentColor: AppColors.tertiary,
                  accentColorDark: AppColors.tertiaryDark,
                  surfaceColor: AppColors.tertiarySurface,
                  onComplete: () => _markStepComplete(0),
                ),
              ),
            if (_activeSheet == 2)
              Expanded(
                child: KhmerSpeakWidget(
                  targetWord: _num.khmerWord.isNotEmpty ? _num.khmerWord : _num.character,
                  romanized: _num.romanized,
                  meaning: 'Số ${_num.value}',
                  accentColor: const Color(0xFF1E88E5),
                  accentColorDark: const Color(0xFF1565C0),
                  surfaceColor: const Color(0xFFEEF4FC),
                  onComplete: () => _markStepComplete(1),
                ),
              ),
            if (_activeSheet == 3)
              Expanded(
                child: KhmerWriteWidget(
                  character: _num.character,
                  label: 'số',
                  accentColor: AppColors.primary,
                  accentColorDark: AppColors.primaryDark,
                  surfaceColor: AppColors.primarySurface,
                  showStrokeGuide: true, // Hiển thị mũi tên hướng nét cho số
                  enableOcr: false,
                  onComplete: () => _markStepComplete(2),
                ),
              ),
          ]),
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
                            offset: Offset(0, 2.h))
                      ]),
                  child: Icon(Icons.close_rounded,
                      size: 20.sp, color: AppColors.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════ ACTION ROW ═══════════════════
  Widget _buildActionRow() {
    return Row(children: [
      Expanded(
          child: GestureDetector(
        onTap: _showListenSheet,
        child: _actionCard(
            imagePath: 'image/Nghe.png',
            label: 'Nghe',
            sub: 'Nghe phát âm',
            bgColor: const Color(0xFFE8F5E9),
            accentColor: const Color(0xFF43A047),
            stepIdx: 0),
      )),
      SizedBox(width: 8.w),
      Expanded(
          child: GestureDetector(
        onTap: _showSpeakSheet,
        child: _actionCard(
            imagePath: 'image/Mic.png',
            label: 'Nói',
            sub: 'Luyện phát âm',
            bgColor: const Color(0xFFE3F2FD),
            accentColor: const Color(0xFF1E88E5),
            stepIdx: 1),
      )),
      SizedBox(width: 8.w),
      Expanded(
          child: GestureDetector(
        onTap: _showWriteSheet,
        child: _actionCard(
            imagePath: 'image/Viết.png',
            label: 'Viết',
            sub: 'Tập viết số',
            bgColor: const Color(0xFFEDE7F6),
            accentColor: const Color(0xFF5E35B1),
            stepIdx: 2),
      )),
    ]);
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
              color: done
                  ? accentColor.withValues(alpha: 0.5)
                  : accentColor.withValues(alpha: 0.18),
              width: done ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 16.r,
                offset: Offset(0, 6.h)),
            BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 4.r,
                offset: Offset(0, 2.h)),
          ]),
      child: Column(children: [
        Image.asset(imagePath, width: 70.w, height: 70.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: accentColor)),
        SizedBox(height: 3.h),
        Text(sub,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: accentColor.withValues(alpha: 0.65))),
      ]),
    );
  }

  // ═══════════════════ NAVIGATION + STEPPER ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _canGo(_idx - 1);
    final canNext = _canGo(_idx + 1);
    final labels = ['Nghe', 'Nói', 'Viết'];
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
            Text('Trước', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: canPrev ? const Color(0xFF1E88E5) : AppColors.textHint)),
          ]),
        ),
      ),
      SizedBox(width: 6.w),
      Expanded(
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
      SizedBox(width: 6.w),
      GestureDetector(
        onTap: () {
          if (canNext) {
            _goTo(_idx + 1);
          } else if (_idx < _numbers.length - 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng hoàn thành tất cả hoạt động (Nghe, Nói, Viết) trước khi học bài tiếp theo.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
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
            Text(canNext ? 'Tiếp theo' : 'Khóa', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: canNext ? Colors.white : AppColors.textHint)),
            SizedBox(width: 4.w),
            Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded, color: canNext ? Colors.white : AppColors.textHint, size: 18.w),
          ]),
        ),
      ),
    ]);
  }
}
