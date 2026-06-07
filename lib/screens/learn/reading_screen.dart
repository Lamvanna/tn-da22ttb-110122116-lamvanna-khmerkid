import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../models/khmer_reading.dart';

/// Màn hình Tập đọc Khmer - Premium 100% Traditional Book-page Layout
class ReadingScreen extends StatefulWidget {
  final int initialIndex;
  const ReadingScreen({super.key, this.initialIndex = 0});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  late int _currentLesson;
  ScoreService? _score;

  // Track currently playing line and word boundaries
  int? _playingLineIdx;
  int? _playingWordIdx;
  int? _wordStart;
  int? _wordEnd;
  bool _isPlayingAll = false;

  final Set<int> _clickedLines = {};
  bool _isCompleting = false;

  late AnimationController _listAnimCtrl;

  final List<KhmerReading> _lessons = KhmerReadingData.lessons;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.initialIndex;
    _loadScore();
    _initTts();
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  Future<void> _initSTT() async {
    // Disabled due to speech recognition maintenance
  }

  Future<void> _initTts() async {
    try {
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
      await _tts.setSpeechRate(0.32); // Slow and clear for learning
      await _tts.setVolume(1.0);

      _tts.setProgressHandler((String text, int start, int end, String word) {
        if (mounted && _playingLineIdx != null) {
          setState(() {
            _wordStart = start;
            _wordEnd = end;
          });
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _wordStart = null;
            _wordEnd = null;
            _playingLineIdx = null;
            _playingWordIdx = null;
          });
        }
      });

      _tts.setErrorHandler((_) {
        if (mounted) {
          setState(() {
            _wordStart = null;
            _wordEnd = null;
            _playingLineIdx = null;
            _playingWordIdx = null;
          });
        }
      });

      if (mounted) {
        setState(() => _ttsReady = true);
      }
    } catch (e) {
      debugPrint("TTS initialization failed: $e");
    }
  }

  Future<void> _speakLine(int idx) async {
    if (!_ttsReady) return;
    
    _isPlayingAll = false;
    await _tts.stop();
    
    final line = _lessons[_currentLesson].lines[idx];
    HapticFeedback.lightImpact();
    
    setState(() {
      _playingLineIdx = idx;
      _wordStart = 0;
      _wordEnd = 0;
      _clickedLines.add(idx);
    });
    
    await _tts.speak(line.khmer);
    _checkProgress();
  }

  Future<void> _speakAll() async {
    if (!_ttsReady) return;
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isPlayingAll = true;
    });
    
    final lines = _lessons[_currentLesson].lines;
    for (int i = 0; i < lines.length; i++) {
      if (!mounted || !_isPlayingAll) return;
      
      await _tts.stop();
      
      final completer = Completer<void>();
      
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });
      _tts.setErrorHandler((_) {
        if (!completer.isCompleted) completer.complete();
      });
      
      setState(() {
        _playingLineIdx = i;
        _wordStart = 0;
        _wordEnd = 0;
        _clickedLines.add(i);
      });
      
      await _tts.speak(lines[i].khmer);
      
      await completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          if (!completer.isCompleted) completer.complete();
        },
      );
      
      if (!_isPlayingAll) return;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (mounted && _isPlayingAll) {
      setState(() {
        _playingLineIdx = null;
        _wordStart = null;
        _wordEnd = null;
        _isPlayingAll = false;
      });
      
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _wordStart = null;
            _wordEnd = null;
            _playingLineIdx = null;
          });
        }
      });
      
      _checkProgress();
    }
  }

  void _stopTts() {
    _isPlayingAll = false;
    _tts.stop();
    setState(() {
      _playingLineIdx = null;
      _playingWordIdx = null;
      _wordStart = null;
      _wordEnd = null;
    });
  }

  Future<void> _speakWord(int lineIdx, int wordIdx, String word) async {
    if (!_ttsReady) return;
    
    _isPlayingAll = false;
    await _tts.stop();
    
    HapticFeedback.lightImpact();
    setState(() {
      _playingLineIdx = lineIdx;
      _playingWordIdx = wordIdx;
      _wordStart = null;
      _wordEnd = null;
      _clickedLines.add(lineIdx);
    });
    
    await _tts.speak(word);
    _checkProgress();
  }

  bool _isWordInTtsRange(String lineText, String word, int wordIdx, int start, int end) {
    try {
      final wordsList = lineText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (wordIdx >= wordsList.length) return false;
      
      int charStart = 0;
      for (int i = 0; i < wordIdx; i++) {
        charStart = lineText.indexOf(wordsList[i], charStart) + wordsList[i].length;
      }
      charStart = lineText.indexOf(word, charStart);
      int charEnd = charStart + word.length;
      
      return (start >= charStart && start < charEnd) || (end > charStart && end <= charEnd);
    } catch (_) {
      return false;
    }
  }

  Widget _buildKhmerText(int lineIdx, String text) {
    // Split text by whitespace, filtering out empty items
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.w,
      runSpacing: 6.h,
      children: List.generate(words.length, (wordIdx) {
        final word = words[wordIdx];
        
        // 1. Tapped word playing
        final isWordPlaying = _playingLineIdx == lineIdx && _playingWordIdx == wordIdx;
        
        // 2. Reading all whole line playing range check
        final isTtsPlaying = _playingWordIdx == null &&
            _playingLineIdx == lineIdx && 
            _wordStart != null && 
            _wordEnd != null &&
            _isWordInTtsRange(text, word, wordIdx, _wordStart!, _wordEnd!);
            
        Color textColor = const Color(0xFF1E293B);
        Color bgColor = Colors.transparent;
        
        if (isWordPlaying || isTtsPlaying) {
          textColor = const Color(0xFF2979FF); // Blue for active speaking
          bgColor = const Color(0xFF2979FF).withValues(alpha: 0.1);
        }
        
        return GestureDetector(
          onTap: () => _speakWord(lineIdx, wordIdx, word),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: GoogleFonts.battambang(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.3,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _checkProgress() {
    if (_isCompleting) return;
    final lesson = _lessons[_currentLesson];
    if (_clickedLines.length == lesson.lines.length) {
      _onLessonCompleted();
    }
  }

  void _onLessonCompleted() {
    if (_isCompleting) return;
    final lesson = _lessons[_currentLesson];
    if (lesson.isLearned) return; // Already completed

    _isCompleting = true;
    _score?.completeReadingLesson(_currentLesson, 3, lessonId: null).then((_) {
      setState(() {
        lesson.isLearned = true;
        lesson.starRating = 3;
      });
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _currentLesson < _lessons.length - 1;
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
                'Bạn đã hoàn thành bài tập đọc "${_lessons[_currentLesson].title.split(':').last.trim()}"',
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
                  (i) => Icon(Icons.star_rounded, size: 28.w, color: AppColors.secondary),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '+15 Sao ⭐',
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
                      _goTo(_currentLesson + 1);
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

  void _goTo(int idx) {
    if (idx < 0 || idx >= _lessons.length) return;
    _stopTts();
    setState(() {
      _currentLesson = idx;
      _clickedLines.clear();
      _isCompleting = false;
    });
    _listAnimCtrl.reset();
    _listAnimCtrl.forward();
  }

  @override
  void dispose() {
    _tts.stop();
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top controls inside card
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _playingLineIdx != null ? _stopTts : _speakAll,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: _playingLineIdx != null
                                    ? const Color(0xFFEF5350).withValues(alpha: 0.1)
                                    : const Color(0xFF03A9F4).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: _playingLineIdx != null
                                      ? const Color(0xFFEF5350).withValues(alpha: 0.3)
                                      : const Color(0xFF03A9F4).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _playingLineIdx != null ? Icons.stop_rounded : Icons.volume_up_rounded,
                                    color: _playingLineIdx != null ? const Color(0xFFEF5350) : const Color(0xFF03A9F4),
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _playingLineIdx != null ? 'Dừng' : 'Nghe',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _playingLineIdx != null ? const Color(0xFFEF5350) : const Color(0xFF03A9F4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'Bài ${_currentLesson + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(width: 80.w),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    // Centered Textbook Lines List
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(lesson.lines.length, (i) {
                            final line = lesson.lines[i];
                            final isSentenceDivider = i == 4;

                            return Column(
                              children: [
                                if (isSentenceDivider) SizedBox(height: 24.h),
                                  GestureDetector(
                                    onTap: () => _speakLine(i),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      color: Colors.transparent,
                                      child: _buildKhmerText(i, line.khmer),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Navigation Row at Bottom
          _buildNavButtons(),
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
                      decoration: const BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.grey[700], size: 20.w))),
                  SizedBox(width: 12.w),
                  Flexible(child: Text('Tập đọc',
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
              Text('${_score?.totalStars ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
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
              Text('${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildNavButtons() {
    final hasPrev = _currentLesson > 0;
    final hasNext = _currentLesson < _lessons.length - 1;
    final isNextUnlocked = _lessons[_currentLesson].isLearned;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Red previous button
          Opacity(
            opacity: hasPrev ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !hasPrev,
              child: ElevatedButton.icon(
                onPressed: () => _goTo(_currentLesson - 1),
                icon: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20.sp),
                label: Text(
                  'Trước',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  shadowColor: const Color(0xFFEF5350).withValues(alpha: 0.3),
                  elevation: 4,
                ),
              ),
            ),
          ),
          // Orange next button
          Opacity(
            opacity: hasNext ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !hasNext || !isNextUnlocked,
              child: ElevatedButton(
                onPressed: () => _goTo(_currentLesson + 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  shadowColor: const Color(0xFFFFA726).withValues(alpha: 0.3),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tiếp theo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      !isNextUnlocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 20.sp,
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
}

/// Custom circular gauge progress bar drawing code
class _CircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final List<Color> progressColors;

  _CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Draw progress arc with gradients
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        colors: progressColors,
        startAngle: -3.14159265 / 2,
        endAngle: 3 * 3.14159265 / 2,
        transform: const GradientRotation(-3.14159265 / 2),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -3.14159265 / 2,
        progress * 2 * 3.14159265,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) => false;
}
