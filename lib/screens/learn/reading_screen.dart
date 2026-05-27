import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Màn hình Tập đọc Khmer - Premium 100% Unified Design
/// Tích hợp hiệu ứng âm thanh động, Staggered Load và giao diện hiện đại
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  int _currentLesson = 0;
  int? _highlightIdx;
  ScoreService? _score;

  late AnimationController _waveCtrl;
  late AnimationController _listAnimCtrl;

  static final List<_ReadingLesson> _lessons = [
    _ReadingLesson(
      title: 'Bài 1: Phụ âm cơ bản',
      subtitle: 'Đọc phụ âm ក - ង',
      emoji: '📖',
      color: const Color(0xFF4CAF50),
      lines: [
        _ReadLine(khmer: 'ក ខ គ ឃ ង', romanized: 'Ka Kha Ko Kho Ngo', meaning: 'Nhóm phụ âm đầu tiên'),
        _ReadLine(khmer: 'កា ខា គា ឃា ងា', romanized: 'Kaa Khaa Koo Khoo Ngoo', meaning: 'Kết hợp nguyên âm "aa"'),
        _ReadLine(khmer: 'កី ខី គី ឃី ងី', romanized: 'Key Khey Key Khey Ngey', meaning: 'Kết hợp nguyên âm "ey"'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 2: Từ đơn giản',
      subtitle: 'Đọc từ 1-2 âm tiết',
      emoji: '📗',
      color: const Color(0xFF2196F3),
      lines: [
        _ReadLine(khmer: 'កា', romanized: 'Kaa', meaning: 'Con quạ'),
        _ReadLine(khmer: 'គោ', romanized: 'Ko', meaning: 'Con bò'),
        _ReadLine(khmer: 'ឆ្មា', romanized: 'Chma', meaning: 'Con mèo'),
        _ReadLine(khmer: 'ឆ្កែ', romanized: 'Chkae', meaning: 'Con chó'),
        _ReadLine(khmer: 'ត្រី', romanized: 'Trey', meaning: 'Con cá'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 3: Câu ngắn',
      subtitle: 'Đọc câu đơn giản',
      emoji: '📘',
      color: const Color(0xFFE91E63),
      lines: [
        _ReadLine(khmer: 'ម៉ែ ស្រឡាញ់ context', romanized: 'Mae srolanh knhom', meaning: 'Mẹ yêu con'),
        _ReadLine(khmer: 'ខ្ញុំ ទៅ សាលា', romanized: 'Knhom tov sala', meaning: 'Con đi học'),
        _ReadLine(khmer: 'ប៉ា ធ្វើ ការ', romanized: 'Pa thveu ka', meaning: 'Bố đi làm'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 4: Số đếm',
      subtitle: 'Đọc số từ 1-10',
      emoji: '📙',
      color: const Color(0xFFFF9800),
      lines: [
        _ReadLine(khmer: '១ ២ ៣ ៤ ៥', romanized: 'Muoy Pi Bey Buon Pram', meaning: '1 2 3 4 5'),
        _ReadLine(khmer: '៦ ៧ ៨ ៩ ១០', romanized: 'Prammuoy Prampil Prambey Prambuon Dop', meaning: '6 7 8 9 10'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 5: Đoạn văn',
      subtitle: 'Đọc đoạn văn ngắn',
      emoji: '📕',
      color: const Color(0xFF7E57C2),
      lines: [
        _ReadLine(khmer: 'ខ្ញុំ ឈ្មោះ សុខា។', romanized: 'Knhom chhmuoh Sokha.', meaning: 'Tôi tên là Sokha.'),
        _ReadLine(khmer: 'ខ្ញុំ រៀន នៅ សាលា។', romanized: 'Knhom rien nov sala.', meaning: 'Tôi học ở trường.'),
        _ReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ គ្រូ។', romanized: 'Knhom srolanh kru.', meaning: 'Tôi yêu cô giáo.'),
        _ReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ ម៉ែ ប៉ា។', romanized: 'Knhom srolanh mae pa.', meaning: 'Tôi yêu mẹ bố.'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadScore();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(
      hasKhmer
          ? 'km'
          : langList.any((l) => l.contains('vi'))
              ? 'vi-VN'
              : 'en-US',
    );
    await _tts.setSpeechRate(0.35);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _highlightIdx = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _highlightIdx = null);
    });
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speakLine(int idx) async {
    if (!_ttsReady) return;
    final line = _lessons[_currentLesson].lines[idx];
    HapticFeedback.lightImpact();
    setState(() => _highlightIdx = idx);
    await _tts.speak(line.khmer);
  }

  Future<void> _speakAll() async {
    if (!_ttsReady) return;
    final lines = _lessons[_currentLesson].lines;
    HapticFeedback.mediumImpact();
    for (int i = 0; i < lines.length; i++) {
      if (!mounted) return;
      setState(() => _highlightIdx = i);
      await _tts.speak(lines[i].khmer);
      await Future.delayed(const Duration(milliseconds: 1800));
    }
    if (mounted) setState(() => _highlightIdx = null);
  }

  @override
  void dispose() {
    _tts.stop();
    _waveCtrl.dispose();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_currentLesson];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 100.h),
              child: Column(
                children: [
                  _buildLessonSelector(),
                  SizedBox(height: 16.h),
                  _buildLessonInfo(lesson),
                  SizedBox(height: 16.h),
                  _buildReadingCard(lesson),
                  SizedBox(height: 20.h),
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.learnHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: AppColors.headerDark.withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(children: [
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
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 36.w, height: 36.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w))),
                  SizedBox(width: 12.w),
                  Flexible(child: Text('Luyện Tập Đọc',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
            ]))),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4.h,
          right: 16.w,
          child: _buildHeaderStats(),
        ),
      ]),
    );
  }

  Widget _buildHeaderStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
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
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
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

  Widget _buildLessonSelector() {
    return SizedBox(
      height: 48.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          final selected = _currentLesson == index;
          return GestureDetector(
            onTap: () {
              if (_currentLesson == index) return;
              HapticFeedback.lightImpact();
              setState(() {
                _currentLesson = index;
                _highlightIdx = null;
              });
              _listAnimCtrl.reset();
              _listAnimCtrl.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [l.color, Color.lerp(l.color, Colors.black, 0.15)!],
                      )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected ? Colors.transparent : const Color(0xFFE8ECF2),
                  width: 1.w,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: l.color.withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(l.emoji, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'Bài ${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonInfo(_ReadingLesson lesson) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: lesson.color.withValues(alpha: 0.12), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: lesson.color.withValues(alpha: 0.05),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: lesson.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(lesson.emoji, style: TextStyle(fontSize: 32.sp)),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: lesson.color,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  lesson.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioWave(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _waveCtrl,
          builder: (context, child) {
            final waveValue = sin((_waveCtrl.value * 2 * pi) + (index * 0.5));
            final height = 4.h + (waveValue.abs() * 12.h);
            return Container(
              width: 3.w,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildReadingCard(_ReadingLesson lesson) {
    return Column(
      children: List.generate(lesson.lines.length, (i) {
        final line = lesson.lines[i];
        final isHighlight = _highlightIdx == i;
        final anim = CurvedAnimation(
          parent: _listAnimCtrl,
          curve: Interval(
            (i * 0.12).clamp(0.0, 1.0),
            ((i * 0.12) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return AnimatedBuilder(
          animation: anim,
          builder:
              (context, child) => Opacity(
                opacity: anim.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - anim.value)),
                  child: child,
                ),
              ),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _speakLine(i),
                borderRadius: BorderRadius.circular(22.r),
                child: Ink(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: isHighlight ? lesson.color.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: isHighlight ? lesson.color : const Color(0xFFE8ECF2),
                      width: isHighlight ? 2.w : 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isHighlight
                                ? lesson.color.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isHighlight ? 16.r : 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              line.khmer,
                              style: GoogleFonts.battambang(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: isHighlight ? lesson.color : const Color(0xFF2D3142),
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          if (isHighlight)
                            _buildAudioWave(lesson.color)
                          else
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF5F7FA),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: const Color(0xFF9098A9),
                                size: 20.sp,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        line.romanized,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isHighlight ? lesson.color.withValues(alpha: 0.8) : const Color(0xFF718096),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        line.meaning,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA0AEC0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControlButtons() {
    final lessonColor = _lessons[_currentLesson].color;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lessonColor, Color.lerp(lessonColor, Colors.black, 0.15)!],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: lessonColor.withValues(alpha: 0.35),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _speakAll,
                icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22.sp),
                label: Text(
                  'Nghe toàn bài',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                _tts.stop();
                setState(() => _highlightIdx = null);
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                child: Icon(Icons.stop_rounded, color: Colors.white, size: 22.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingLesson {
  final String title, subtitle, emoji;
  final Color color;
  final List<_ReadLine> lines;
  const _ReadingLesson({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.lines,
  });
}

class _ReadLine {
  final String khmer, romanized, meaning;
  const _ReadLine({
    required this.khmer,
    required this.romanized,
    required this.meaning,
  });
}
