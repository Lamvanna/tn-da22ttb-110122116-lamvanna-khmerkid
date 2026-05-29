import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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

  // Speech-to-Text dynamic listening
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _sttReady = false;
  bool _isListeningSTT = false;
  final Map<int, List<int>> _sttHighlights = {}; // Track [start, end] matched range per line
  String _selectedLocaleId = 'km';
  String _lastRecognizedText = '';
  bool _sttResultShown = false;

  // Playback state
  bool _isPlayingBack = false;

  // Karaoke guide for recording
  int _guideLineIdx = 0;
  int _guideWordIdx = -1;
  Timer? _guideTimer;

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
    _initSTT();
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
    try {
      final status = await Permission.microphone.status;
      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quyền Micro bị từ chối vĩnh viễn. Bé hãy mở cài đặt để cấp quyền!'),
              action: SnackBarAction(
                label: 'Cài đặt',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) return;
      
      _sttReady = await _speech.initialize(
        onError: (e) {
          debugPrint("[STT] Error: $e");
          if (mounted && _isListeningSTT) {
            setState(() => _isListeningSTT = false);
          }
        },
        onStatus: (s) {
          debugPrint("[STT] Status: $s");
          if (s == 'done' && mounted && _isListeningSTT) {
            _finishRecording();
          }
        },
      );
      
      if (_sttReady) {
        try {
          final locs = await _speech.locales();
          bool foundKhmer = false;
          for (final l in locs) {
            if (l.localeId.toLowerCase().startsWith('km')) {
              _selectedLocaleId = l.localeId;
              foundKhmer = true;
              break;
            }
          }
          if (!foundKhmer) {
            final systemLoc = await _speech.systemLocale();
            if (systemLoc != null) {
              _selectedLocaleId = systemLoc.localeId;
            }
          }
        } catch (localeErr) {
          debugPrint('STT Locales query error: $localeErr');
          _selectedLocaleId = 'km-KH';
        }
        debugPrint("[STT] Selected locale: $_selectedLocaleId");
      }
    } catch (e) {
      debugPrint("STT initialization failed: $e");
    }
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
    _stopSTT();
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
    _stopSTT();
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

  Future<void> _startSTT() async {
    if (!_sttReady) {
      await _initSTT();
      if (!_sttReady) {
        debugPrint('[STT] Not ready, cannot start');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể khởi động nhận diện giọng nói')),
          );
        }
        return;
      }
    }
    
    _stopTts();
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isListeningSTT = true;
      _isPlayingBack = false;
      _sttHighlights.clear();
      _lastRecognizedText = '';
      _sttResultShown = false;
      _clickedLines.clear();
    });
    
    // Start speech recognition
    try {
      await _speech.stop();
      await _speech.listen(
        onResult: (r) {
          if (mounted) {
            _processSpeechResult(r.recognizedWords);
            if (r.finalResult) {
              _finishRecording();
            }
          }
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 15),
        localeId: _selectedLocaleId,
      );
      // Start karaoke guide after STT starts
      _startGuide();
    } catch (e) {
      debugPrint('[STT] Listen error: $e');
      if (mounted) setState(() => _isListeningSTT = false);
    }
  }

  Future<void> _finishRecording() async {
    _stopGuide();
    if (mounted) {
      setState(() => _isListeningSTT = false);
      if (!_sttResultShown) {
        _sttResultShown = true;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showSTTResultDialog();
        });
      }
    }
  }

  Future<void> _stopSTT() async {
    _stopGuide();
    await _speech.stop();
    if (mounted) setState(() => _isListeningSTT = false);
  }

  void _startGuide() {
    _guideTimer?.cancel();
    final lesson = _lessons[_currentLesson];
    if (lesson.lines.isEmpty) return;
    
    setState(() {
      _guideLineIdx = 0;
      _guideWordIdx = 0;
    });
    
    // Advance word every 1.5 seconds
    _guideTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted || !_isListeningSTT) {
        timer.cancel();
        return;
      }
      
      final lines = lesson.lines;
      final currentWords = lines[_guideLineIdx].khmer
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      
      setState(() {
        _guideWordIdx++;
        if (_guideWordIdx >= currentWords.length) {
          // Move to next line
          _guideLineIdx++;
          _guideWordIdx = 0;
          
          if (_guideLineIdx >= lines.length) {
            // Finished all lines - loop back
            _guideLineIdx = 0;
            _guideWordIdx = 0;
          }
        }
      });
    });
  }

  void _stopGuide() {
    _guideTimer?.cancel();
    _guideTimer = null;
    if (mounted) {
      setState(() {
        _guideLineIdx = 0;
        _guideWordIdx = -1;
      });
    }
  }

  void _processSpeechResult(String spokenText) {
    if (spokenText.isEmpty) return;
    _lastRecognizedText = spokenText;
    
    String clean(String s) => s.replaceAll(RegExp(r'[\s\u200b]'), '');
    final cleanSpoken = clean(spokenText);
    final lesson = _lessons[_currentLesson];
    
    setState(() {
      
      for (int i = 0; i < lesson.lines.length; i++) {
        final line = lesson.lines[i];
        final cleanLine = clean(line.khmer);
        
        if (cleanSpoken.contains(cleanLine)) {
          _clickedLines.add(i);
          _sttHighlights[i] = [0, line.khmer.length];
        } else {
          final match = _findLongestMatch(line.khmer, spokenText);
          if (match != null && match[2] >= 2) {
            _sttHighlights[i] = [match[0], match[1]];
            if (match[2] >= line.khmer.length * 0.7) {
              _clickedLines.add(i);
            }
          }
        }
      }
    });
    
    _checkProgress();
  }

  List<int>? _findLongestMatch(String lineText, String spokenText) {
    int bestStart = 0;
    int bestEnd = 0;
    int maxLen = 0;
    
    for (int start = 0; start < lineText.length; start++) {
      for (int end = start + 2; end <= lineText.length; end++) {
        final sub = lineText.substring(start, end);
        if (spokenText.contains(sub)) {
          final len = end - start;
          if (len > maxLen) {
            maxLen = len;
            bestStart = start;
            bestEnd = end;
          }
        }
      }
    }
    
    if (maxLen > 0) {
      return [bestStart, bestEnd, maxLen];
    }
    return null;
  }

  void _showSTTResultDialog() {
    final lesson = _lessons[_currentLesson];
    final totalLines = lesson.lines.length;
    final matchedLines = _clickedLines.length;
    final accuracy = totalLines > 0 ? (matchedLines / totalLines * 100).round() : 0;
    final passed = accuracy >= 70;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 12,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Kết quả thu âm 🎙️',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 18.h),

                // Beautiful Custom Circular Progress Gauge
                Container(
                  width: 105.w,
                  height: 105.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (passed ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                            .withValues(alpha: 0.12),
                        blurRadius: 16.r,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: accuracy / 100.0,
                      trackColor: const Color(0xFFF1F5F9),
                      progressColors: passed
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFF43F5E), const Color(0xFFE11D48)],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$accuracy%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              color: passed ? const Color(0xFF047857) : const Color(0xFFBE123C),
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Hoàn thành',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Highly Styled Encouragement Capsule Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: passed
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: passed ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        passed ? '🏆' : '💪',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        passed ? 'Tuyệt vời quá bé ơi!' : 'Cố gắng thêm nhé!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: passed
                              ? const Color(0xFF047857)
                              : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Bé đọc đúng $matchedLines / $totalLines dòng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 20.h),

                // Speaking Bubble - Modern Child-Friendly design
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: _lastRecognizedText.isNotEmpty
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _lastRecognizedText.isNotEmpty
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFEE2E2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8.r,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: _lastRecognizedText.isNotEmpty
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFEF4444),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Giọng của bé được nhận diện:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _lastRecognizedText.isNotEmpty
                            ? _lastRecognizedText
                            : 'Bé ơi, hình như máy chưa nghe rõ giọng bé nè! Thử bấm "Thu lại" rồi đọc to hơn, rõ hơn một chút nha! 💕',
                        style: _lastRecognizedText.isNotEmpty
                            ? GoogleFonts.battambang(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                                height: 1.4,
                              )
                            : GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                                height: 1.4,
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Playback Button (using TTS for recognized words)
                if (_lastRecognizedText.isNotEmpty)
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return GestureDetector(
                        onTap: () async {
                          if (_isPlayingBack) {
                            await _tts.stop();
                            setState(() => _isPlayingBack = false);
                            setDialogState(() {});
                          } else {
                            setState(() => _isPlayingBack = true);
                            setDialogState(() {});
                            await _tts.speak(_lastRecognizedText);
                            _tts.setCompletionHandler(() {
                              if (mounted) {
                                setState(() => _isPlayingBack = false);
                                setDialogState(() {});
                              }
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isPlayingBack
                                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                  : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: (_isPlayingBack
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF6366F1))
                                    .withValues(alpha: 0.3),
                                blurRadius: 8.r,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlayingBack ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _isPlayingBack ? 'Dừng phát' : '🔊 Nghe lại giọng vừa đọc',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                SizedBox(height: 22.h),

                // Interactive Per-line results
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chi tiết từng câu (Chạm để nghe mẫu):',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                ...List.generate(lesson.lines.length, (i) {
                  final line = lesson.lines[i];
                  final matched = _clickedLines.contains(i);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _speakLine(i);
                        },
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: matched
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.015),
                                blurRadius: 6.r,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left Status Circle Badge
                              Container(
                                width: 34.w,
                                height: 34.w,
                                decoration: BoxDecoration(
                                  color: matched
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  matched ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: matched ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // Text, transliteration & meaning details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.khmer,
                                      style: GoogleFonts.battambang(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: matched ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                        height: 1.3,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    SizedBox(height: 4.h),
                                    Text(
                                      line.romanized,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      line.meaning,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),

                              // Speaker icon action trigger
                              Container(
                                width: 28.w,
                                height: 28.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: const Color(0xFF64748B),
                                  size: 15.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20.h),

                // Actions buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                        child: Text(
                          'Đóng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE91E63).withValues(alpha: 0.25),
                              blurRadius: 10.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                            _startSTT();
                          },
                          icon: Icon(Icons.mic_rounded, size: 18.sp, color: Colors.white),
                          label: Text(
                            'Thu lại',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (passed) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 10.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        if (_currentLesson < _lessons.length - 1) {
                          _onLessonCompleted();
                        }
                      },
                      icon: Icon(Icons.arrow_forward_rounded, size: 18.sp, color: Colors.white),
                      label: Text(
                        'Mở bài tiếp theo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _speakWord(int lineIdx, int wordIdx, String word) async {
    if (!_ttsReady) return;
    
    _isPlayingAll = false;
    _stopSTT();
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
            
        // 3. STT spoken recognized range check
        final sttRange = _sttHighlights[lineIdx];
        final isSttPlaying = _isListeningSTT && 
            sttRange != null &&
            _isWordInTtsRange(text, word, wordIdx, sttRange[0], sttRange[1]);
        
        // 4. Karaoke guide: current word to read
        final isGuideActive = _isListeningSTT && _guideWordIdx >= 0;
        final isGuideCurrent = isGuideActive && _guideLineIdx == lineIdx && _guideWordIdx == wordIdx;
        final isGuidePassed = isGuideActive && (
            lineIdx < _guideLineIdx || 
            (lineIdx == _guideLineIdx && wordIdx < _guideWordIdx)
        );
            
        Color textColor = const Color(0xFF1E293B);
        Color bgColor = Colors.transparent;
        
        if (isSttPlaying) {
          textColor = const Color(0xFF4CAF50); // Green for STT matched
          bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.1);
        } else if (isWordPlaying || isTtsPlaying) {
          textColor = const Color(0xFF2979FF); // Blue for active speaking
          bgColor = const Color(0xFF2979FF).withValues(alpha: 0.1);
        } else if (isGuideCurrent) {
          textColor = const Color(0xFFFF6D00); // Orange for "read this now"
          bgColor = const Color(0xFFFF6D00).withValues(alpha: 0.15);
        } else if (isGuidePassed) {
          textColor = const Color(0xFF90A4AE); // Grey for already passed
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
    _stopSTT();
    setState(() {
      _currentLesson = idx;
      _clickedLines.clear();
      _sttHighlights.clear();
      _isCompleting = false;
    });
    _listAnimCtrl.reset();
    _listAnimCtrl.forward();
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _guideTimer?.cancel();
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
                          GestureDetector(
                            onTap: _isListeningSTT ? _stopSTT : _startSTT,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: _isListeningSTT 
                                    ? const Color(0xFFEF5350).withValues(alpha: 0.1)
                                    : const Color(0xFFE91E63).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: _isListeningSTT
                                      ? const Color(0xFFEF5350).withValues(alpha: 0.3)
                                      : const Color(0xFFE91E63).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isListeningSTT ? Icons.stop_rounded : Icons.mic_rounded,
                                    color: _isListeningSTT ? const Color(0xFFEF5350) : const Color(0xFFE91E63),
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _isListeningSTT ? 'Đang thu' : 'Thu âm',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _isListeningSTT ? const Color(0xFFEF5350) : const Color(0xFFE91E63),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColors != progressColors;
  }
}
