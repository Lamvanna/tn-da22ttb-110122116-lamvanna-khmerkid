import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:string_similarity/string_similarity.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../models/khmer_reading.dart';
import '../../services/voice_recognition_service.dart';
import '../../widgets/feedback_dialog.dart';

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
  final Map<int, List<bool>> _lessonWordCorrectness = {};
  bool _hasLessonResult = false;
  int _correctLessonWords = 0;
  int _incorrectLessonWords = 0;
  bool _isCompleting = false;

  late AnimationController _listAnimCtrl;

  final List<KhmerReading> _lessons = KhmerReadingData.lessons;

  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  bool _isRecording = false;
  bool _isProcessing = false;
  int _recordSeconds = 0;
  Timer? _recordingTimer;
  String? _filePath;

  List<(int, int)> _guidedCoordinates = [];
  int? _guidedLineIdx;
  int? _guidedWordIdx;
  int _currentGuideIndex = 0;
  Timer? _guideTimer;

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

  void _startRecording() async {
    _stopTts();

    // Set up guide coordinates for pacing highlight
    _guidedCoordinates.clear();
    final lesson = _lessons[_currentLesson];
    for (int i = 0; i < lesson.lines.length; i++) {
      final words = lesson.lines[i].khmer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      for (int j = 0; j < words.length; j++) {
        _guidedCoordinates.add((i, j));
      }
    }

    _currentGuideIndex = 0;

    setState(() {
      _isRecording = true;
      _isProcessing = false;
      _recordSeconds = 0;
      _lessonWordCorrectness.clear();
      _hasLessonResult = false;
      if (_guidedCoordinates.isNotEmpty) {
        _guidedLineIdx = _guidedCoordinates[0].$1;
        _guidedWordIdx = _guidedCoordinates[0].$2;
      } else {
        _guidedLineIdx = null;
        _guidedWordIdx = null;
      }
    });

    _voiceService.startRecording();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
      if (_recordSeconds >= 45) { // 45 seconds max for entire lesson
        _stopRecording();
      }
    });

    // Animate pacing highlight from word to word (approx 1.2s per word)
    _guideTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      _currentGuideIndex++;
      if (_currentGuideIndex < _guidedCoordinates.length) {
        setState(() {
          _guidedLineIdx = _guidedCoordinates[_currentGuideIndex].$1;
          _guidedWordIdx = _guidedCoordinates[_currentGuideIndex].$2;
        });
      } else {
        setState(() {
          _guidedLineIdx = null;
          _guidedWordIdx = null;
        });
        timer.cancel();
      }
    });
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    _guideTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _guidedLineIdx = null;
      _guidedWordIdx = null;
    });

    try {
      final path = await _voiceService.stopRecording();
      if (path == null) {
        throw Exception("Không thể lấy tệp tin âm thanh đã ghi.");
      }
      _filePath = path;

      final lesson = _lessons[_currentLesson];
      final expectedText = lesson.lines.map((l) => l.khmer).join(' ');
      final backendRes = await _voiceService.uploadAudio(_filePath!, expectedText);

      final correctnessMap = _evaluateLesson(lesson, backendRes.recognizedText);

      int correctCount = 0;
      int incorrectCount = 0;
      correctnessMap.forEach((lineIdx, list) {
        for (var isCorrect in list) {
          if (isCorrect) {
            correctCount++;
          } else {
            incorrectCount++;
          }
        }
      });

      setState(() {
        _lessonWordCorrectness.clear();
        _lessonWordCorrectness.addAll(correctnessMap);
        _hasLessonResult = true;
        _correctLessonWords = correctCount;
        _incorrectLessonWords = incorrectCount;
        _isProcessing = false;

        // Mark all lines as read to complete progress
        for (int i = 0; i < lesson.lines.length; i++) {
          _clickedLines.add(i);
        }
      });
      _checkProgress();

      if (mounted) {
        if (incorrectCount == 0) {
          FeedbackDialog.showSuccess(
            context,
            xpEarned: 15,
            message: context.translate('learn.reading_success'),
          );
        } else if (correctCount > 0) {
          FeedbackDialog.showSuccess(
            context,
            xpEarned: 5,
            message: 'Tốt lắm! Con đã đọc đúng $correctCount/${correctCount + incorrectCount} chữ! Hãy cố gắng thêm nhé! 👍',
          );
        } else {
          FeedbackDialog.showFailure(
            context,
            message: context.translate('learn.incorrect_reading_warning'),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _normalizeKhmer(String text) {
    return text
        .replaceAll('◌', '')
        .replaceAll('\u25cc', '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  Map<int, List<bool>> _evaluateLesson(KhmerReading lesson, String recognized) {
    final Map<int, List<bool>> correctnessMap = {};
    final recNorm = _normalizeKhmer(recognized);

    int charStart = 0;

    for (int i = 0; i < lesson.lines.length; i++) {
      final lineText = lesson.lines[i].khmer;
      final targetWords = lineText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final List<bool> wordCorrectness = List.filled(targetWords.length, false);

      for (int wIdx = 0; wIdx < targetWords.length; wIdx++) {
        final tw = targetWords[wIdx];
        String twNorm = _normalizeKhmer(tw);

        // Handle the Khmer repeat sign ៗ by repeating the previous word
        if (twNorm == 'ៗ' && wIdx > 0) {
          twNorm = _normalizeKhmer(targetWords[wIdx - 1]);
        }

        if (twNorm.isEmpty) {
          // If the target word becomes empty (e.g. it was just placeholder), count it as correct
          wordCorrectness[wIdx] = true;
          continue;
        }

        bool found = false;

        if (charStart < recNorm.length) {
          final remaining = recNorm.substring(charStart);
          final windowSize = twNorm.length + 15; // 15 characters lookahead
          final searchArea = remaining.substring(
              0, remaining.length < windowSize ? remaining.length : windowSize);

          int offset = searchArea.indexOf(twNorm);
          if (offset != -1) {
            found = true;
            charStart += offset + twNorm.length;
          } else {
            // Similarity lookahead match within the window area
            for (int start = 0; start <= searchArea.length - twNorm.length; start++) {
              final slice = searchArea.substring(start, start + twNorm.length);
              if (StringSimilarity.compareTwoStrings(twNorm, slice) > 0.7) {
                found = true;
                charStart += start + twNorm.length;
                break;
              }
            }
          }
        }

        wordCorrectness[wIdx] = found;
      }

      correctnessMap[i] = wordCorrectness;
    }

    return correctnessMap;
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
    final hasResult = _hasLessonResult && _lessonWordCorrectness.containsKey(lineIdx);
    
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

        // 3. Recording guidance highlight
        final isGuided = _isRecording && _guidedLineIdx == lineIdx && _guidedWordIdx == wordIdx;
            
        Color textColor = const Color(0xFF1E293B);
        Color bgColor = Colors.transparent;
        
        if (isWordPlaying || isTtsPlaying || isGuided) {
          textColor = const Color(0xFF2979FF); // Blue for active speaking/recording guide
          bgColor = const Color(0xFF2979FF).withValues(alpha: 0.1);
        } else if (hasResult) {
          final isCorrect = _lessonWordCorrectness[lineIdx]![wordIdx];
          if (isCorrect) {
            textColor = const Color(0xFF2E7D32); // Green for correct
            bgColor = const Color(0xFFE8F5E9);
          } else {
            textColor = const Color(0xFFC62828); // Red for incorrect
            bgColor = const Color(0xFFFFEBEE);
          }
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
    
    // Update state immediately
    setState(() {
      lesson.isLearned = true;
      lesson.starRating = 3;
    });

    // Run API call in background
    _score?.completeReadingLesson(_currentLesson, 3, lessonId: 'reading_$_currentLesson', xp: 15).catchError((e) {
      debugPrint('⚠️ Error completing reading lesson: $e');
    });

    // Trigger dialog after 1.2 seconds
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _currentLesson < _lessons.length - 1;
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
                  'Bạn đã hoàn thành bài tập đọc "${_lessons[_currentLesson].title.split(':').last.trim()}"',
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
                        _goTo(_currentLesson + 1);
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

  void _goTo(int idx) {
    if (idx < 0 || idx >= _lessons.length) return;
    _stopTts();
    setState(() {
      _currentLesson = idx;
      _clickedLines.clear();
      _lessonWordCorrectness.clear();
      _hasLessonResult = false;
      _isCompleting = false;
    });
    _listAnimCtrl.reset();
    _listAnimCtrl.forward();
  }

  @override
  void dispose() {
    _tts.stop();
    _listAnimCtrl.dispose();
    _recordingTimer?.cancel();
    _guideTimer?.cancel();
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
                            context.translate('learn.lesson_n', args: {'number': _currentLesson + 1}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isProcessing
                                ? null
                                : (_isRecording ? _stopRecording : _startRecording),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? const Color(0xFFEF5350).withValues(alpha: 0.1)
                                    : _isProcessing
                                        ? const Color(0xFF03A9F4).withValues(alpha: 0.1)
                                        : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: _isRecording
                                      ? const Color(0xFFEF5350).withValues(alpha: 0.3)
                                      : _isProcessing
                                          ? const Color(0xFF03A9F4).withValues(alpha: 0.3)
                                          : const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isProcessing) ...[
                                    SizedBox(
                                      width: 14.w,
                                      height: 14.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF03A9F4)),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Đang chấm...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF03A9F4),
                                      ),
                                    ),
                                  ] else if (_isRecording) ...[
                                    Icon(
                                      Icons.stop_rounded,
                                      color: const Color(0xFFEF5350),
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Dừng (0:${_recordSeconds.toString().padLeft(2, '0')})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF5350),
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.mic_none_rounded,
                                      color: const Color(0xFF4CAF50),
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Đọc',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),

                    // Show lesson level results summary if available
                    if (_hasLessonResult) ...[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: _incorrectLessonWords == 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _incorrectLessonWords == 0 ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Kết quả đọc bài: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            Text(
                              'Đúng $_correctLessonWords',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            Text(' | ', style: TextStyle(color: Colors.grey[400])),
                            Text(
                              'Sai $_incorrectLessonWords',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hasLessonResult = false;
                                  _lessonWordCorrectness.clear();
                                });
                              },
                              child: Icon(Icons.cancel_rounded, size: 16.sp, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                  Flexible(child: Text(context.translate('learn.reading_title'),
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
                  context.translate('common.back'),
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
                      context.translate('common.next'),
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

