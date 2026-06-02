import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/scoring_service.dart';
import '../services/audio_preprocessing_service.dart';

/// ════════════════════════════════════════════════════════════════════
/// KhmerSpeakWidget — Widget NÓI tái sử dụng
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Nút micro với pulse animation + triple rings
///   • Transcript realtime khi đang nghe
///   • Thanh tiến trình (12 giây countdown)
///   • Điểm số 0-100% (string_similarity)
///   • Highlight chữ đúng/sai
///   • Badge kết quả: >= 70% pass
///   • Nút nghe mẫu trước khi nói
/// ════════════════════════════════════════════════════════════════════

class KhmerSpeakWidget extends StatefulWidget {
  final String character;
  final String romanized;
  final String pronunciation;
  /// Các cách đọc hợp lệ bổ sung (vd số: ["muôi","một","1"]; nguyên âm: ["a","aa"]).
  /// Được gộp vào tập so khớp khi chấm điểm.
  final List<String> acceptedAnswers;
  final VoidCallback? onComplete;
  final int passThreshold;
  final Color accentColor;
  final Color accentColorDark;
  final Color surfaceColor;

  const KhmerSpeakWidget({
    super.key,
    required this.character,
    this.romanized = '',
    this.pronunciation = '',
    this.acceptedAnswers = const [],
    this.onComplete,
    this.passThreshold = 70,
    this.accentColor = const Color(0xFFD0584D),
    this.accentColorDark = const Color(0xFFB6473D),
    this.surfaceColor = const Color(0xFFFCEBE9),
  });

  @override
  State<KhmerSpeakWidget> createState() => _KhmerSpeakWidgetState();
}

class _KhmerSpeakWidgetState extends State<KhmerSpeakWidget>
    with TickerProviderStateMixin {
  final SpeechService _speech = SpeechService.instance;
  final TtsService _tts = TtsService.instance;
  final ScoringService _scoring = ScoringService.instance;

  late AnimationController _pulseCtrl;
  late AnimationController _timerCtrl;

  bool _sttReady = false;
  bool _isListening = false;
  bool _isStartingListening = false;
  String _recognized = '';
  List<String> _alternates = const [];
  String _matchedText = '';
  String _statusMsg = '';
  bool _hasResult = false;
  PronunciationResult? _result;
  double _rawConfidence = 0.0;
  PronunciationScoreResult? _scoreResult;
  bool _khmerUnsupported = false;

  // Audio visualization
  double _audioLevel = 0.0;
  final List<double> _audioLevelHistory = List.filled(20, 0.0); // 20 bars
  int _audioLevelIndex = 0;
  AudioAnalysisResult? _audioAnalysis;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _timerCtrl = AnimationController(
      vsync: this,
      duration: SpeechService.defaultListenFor,
    );
    _initServices();
  }

  Future<void> _initServices() async {
    await _tts.init();

    _speech.onResult = (text, confidence, isFinal, alternates) {
      if (mounted) {
        setState(() {
          _recognized = text;
          _alternates = alternates;
          _rawConfidence = confidence;
        });
        if (isFinal) {
          _onListeningDone();
        }
      }
    };

    _speech.onAudioLevel = (level) {
      if (mounted && _isListening) {
        setState(() {
          _audioLevel = level;
          _audioLevelHistory[_audioLevelIndex] = level;
          _audioLevelIndex = (_audioLevelIndex + 1) % _audioLevelHistory.length;
        });
      }
    };

    _speech.onAudioQualityAnalysis = (analysis) {
      if (mounted) {
        setState(() {
          _audioAnalysis = analysis;
        });
      }
    };
    _speech.onError = (err) {
      if (mounted && _isListening) {
        _pulseCtrl.stop();
        _timerCtrl.stop();
        setState(() {
          _isListening = false;
          if (_recognized.isEmpty) {
            _statusMsg = 'Không nghe được. Nói to hơn!';
          }
        });
        if (_recognized.isNotEmpty) _evaluate();
      }
    };
    _speech.onStatus = (status) {
      if (status == 'done' && mounted && _isListening) {
        _onListeningDone();
      }
    };

    final ok = await _speech.init();
    if (mounted) {
      setState(() {
        _sttReady = ok;
        _khmerUnsupported = ok && !_speech.isKhmerAvailable;
        if (_khmerUnsupported) {
          _statusMsg = 'Thiết bị chưa tải gói offline Khmer (Đang sử dụng nhận dạng qua mạng).';
        }
      });
    }
  }

  void _onListeningDone() {
    _pulseCtrl.stop();
    _timerCtrl.stop();
    if (mounted) setState(() => _isListening = false);
    _evaluate();
  }

  @override
  void dispose() {
    // Cleanup callbacks để tránh memory leak
    _speech.onResult = null;
    _speech.onError = null;
    _speech.onStatus = null;
    _speech.onAudioLevel = null;
    _speech.onAudioQualityAnalysis = null;

    // Stop services
    _speech.cancel();
    _tts.stop();

    // Dispose controllers
    _pulseCtrl.dispose();
    _timerCtrl.dispose();

    super.dispose();
  }

  Future<void> _startListening() async {
    // Debounce: tránh spam click
    if (_isStartingListening) {
      debugPrint('[KhmerSpeakWidget] Already starting, ignoring...');
      return;
    }

    _isStartingListening = true;

    try {
      await _tts.stop();
      // Tăng delay lên 500ms để đảm bảo TTS đã dừng hoàn toàn
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _recognized = '';
        _alternates = const [];
        _matchedText = '';
        _statusMsg = 'Đang khởi động mic...';
        _hasResult = false;
        _result = null;
        _isListening = true;
        _audioLevel = 0.0;
        _audioLevelHistory.fillRange(0, _audioLevelHistory.length, 0.0);
        _audioLevelIndex = 0;
        _audioAnalysis = null;
      });
      _pulseCtrl.repeat(reverse: true);
      _timerCtrl.forward(from: 0);

      final ok = await _speech.startListening();

      if (!mounted) return;

      if (!ok) {
        _pulseCtrl.stop();
        _timerCtrl.stop();
        setState(() {
          _isListening = false;
          _statusMsg = 'Không thể khởi động mic. Vui lòng thử lại!';
        });
      } else {
        // Thành công, xóa status message
        setState(() {
          _statusMsg = '';
        });
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> _stopListening() async {
    _pulseCtrl.stop();
    _timerCtrl.stop();
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _evaluate();
    }
  }

  Future<void> _toggleListening() async {
    // Debounce: tránh spam click
    if (_isStartingListening) {
      debugPrint('[KhmerSpeakWidget] Toggle ignored: already starting');
      return;
    }

    if (!_sttReady) {
      final permStatus = await _speech.checkPermission();
      if (permStatus == SpeechPermissionStatus.permanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Quyền Micro bị từ chối vĩnh viễn. Mở cài đặt để cấp quyền!'),
              action: SnackBarAction(
                label: 'Cài đặt',
                onPressed: () => _speech.openSettings(),
              ),
            ),
          );
        }
        return;
      }
      // Try reinitializing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang khởi tạo lại...')),
        );
      }
      final ok = await _speech.init();
      if (mounted) {
        setState(() {
          _sttReady = ok;
          _khmerUnsupported = ok && !_speech.isKhmerAvailable;
          if (_khmerUnsupported) {
            _statusMsg = 'Thiết bị chưa tải gói offline Khmer (Đang sử dụng nhận dạng qua mạng).';
          } else {
            _statusMsg = '';
          }
        });
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Thiết bị chưa sẵn sàng. Vui lòng thử lại!')),
        );
      }
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  void _evaluate() {
    if (_hasResult) return;
    if (_recognized.trim().isEmpty) {
      setState(() => _statusMsg = 'Không nhận diện được. Nói to hơn!');
      return;
    }

    final double calibConfidence = ScoringService.calibrateConfidence(_rawConfidence);

    // Chấm điểm trên TẤT CẢ bản chép engine đề xuất và chọn bản khớp nhất.
    // Engine thường trả bản đầu sai (tiếng Khmer/giọng trẻ), nhưng một alternate
    // khác lại đúng — đây là lý do "nói vậy mà nhận ra khác".
    final candidates = <String>[
      if (_recognized.trim().isNotEmpty) _recognized.trim(),
      ..._alternates,
    ];
    final best = _scoring.scoreBestAlternate(
      targetCharacter: widget.character,
      alternates: candidates,
      confidence: _rawConfidence,
      romanized: widget.romanized,
      pronunciation: widget.pronunciation,
      acceptedAnswers: widget.acceptedAnswers,
      passThreshold: widget.passThreshold,
    );
    final scoreResult = best.result;
    _matchedText = best.matchedText;

    // Chỉ báo "nghe chưa rõ" khi VỪA không khớp (điểm thấp) VỪA confidence rất thấp.
    // Nếu văn bản khớp tốt thì luôn chấm, dù máy báo confidence thấp.
    final bool reallyUnclear =
        calibConfidence < 0.35 && scoreResult.rawScore < 50.0;
    if (reallyUnclear) {
      setState(() {
        _statusMsg = 'Chúng tôi nghe chưa rõ. Vui lòng đọc lại.';
        _result = null;
        _scoreResult = null;
        _hasResult = true;
      });
      _logSessionResult(null);
      return;
    }

    final highlights = _scoring.buildHighlights(
      _matchedText, 
      widget.character, 
      scoreResult.passed,
      romanized: widget.romanized,
      pronunciation: widget.pronunciation,
      acceptedAnswers: widget.acceptedAnswers,
    );

    // 4. Đồng bộ adapter PronunciationResult cho tính tương thích ngược của UI
    final pronunciationRes = PronunciationResult(
      accuracy: scoreResult.weightedScore.round(),
      passed: scoreResult.passed,
      stars: _accuracyToStars(scoreResult.weightedScore.round()),
      matchedTarget: widget.character,
      highlights: highlights,
    );

    setState(() {
      _scoreResult = scoreResult;
      _result = pronunciationRes;
      _hasResult = true;
    });

    _logSessionResult(scoreResult);

    if (scoreResult.passed) {
      widget.onComplete?.call();
    }
  }

  void _logSessionResult(PronunciationScoreResult? scoreResult) {
    try {
      final osName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);
      final deviceInfo = '$osName ${Platform.operatingSystemVersion}';

      final logMap = {
        'sessionId': 'speak_${widget.character}_${DateTime.now().millisecondsSinceEpoch}',
        'character': widget.character,
        'recognizedText': _recognized,
        'confidence': double.parse(_rawConfidence.toStringAsFixed(2)),
        'localeUsed': _speech.activeLocale,
        'localeSupported': _speech.isKhmerAvailable,
        'rawScore': scoreResult != null ? scoreResult.rawScore.round() : 0,
        'weightedScore': scoreResult != null ? scoreResult.weightedScore.round() : 0,
        'passed': scoreResult != null ? scoreResult.passed : false,
        'device': deviceInfo,
        'os': Platform.operatingSystem,
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('[KhmerSpeakWidget] 📊 Session Log:\n${jsonEncode(logMap)}');
    } catch (e) {
      debugPrint('[KhmerSpeakWidget] Log session error: $e');
    }
  }

  Future<void> _playExample() async {
    await _tts.speakKhmerLetter(
      character: widget.character,
      pronunciation: widget.pronunciation,
      romanized: widget.romanized,
    );
  }

  /// Văn bản hiển thị ở dòng "Hệ thống nghe": ưu tiên bản chép đã được chọn để
  /// khớp (matchedText). Nếu bản đó khác bản đoán đầu, hiển thị thêm bản đầu để
  /// minh bạch ("nghe X, hiểu là Y").
  String _displayHeard() {
    final matched = _matchedText.trim();
    final first = _recognized.trim();
    if (matched.isEmpty && first.isEmpty) return '(không rõ)';
    if (matched.isNotEmpty && matched != first && first.isNotEmpty) {
      return '$matched  (nghe: "$first")';
    }
    return matched.isNotEmpty ? matched : first;
  }

  void _retry() {
    setState(() {
      _hasResult = false;
      _result = null;
      _scoreResult = null;
      _rawConfidence = 0.0;
      _recognized = '';
      _alternates = const [];
      _matchedText = '';
      _statusMsg = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: widget.accentColor, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Nói phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: widget.accentColorDark,
                ),
              ),
            ],
          ),
        ),

        // ── Content ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Character circle
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          blurRadius: 24.r,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.character,
                        style: GoogleFonts.battambang(
                          fontSize: 44.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Pronunciation badge + play example
                  GestureDetector(
                    onTap: _playExample,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.surfaceColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded,
                              size: 14.sp, color: widget.accentColor),
                          SizedBox(width: 6.w),
                          Text(
                            'Nghe mẫu: "${widget.romanized}"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColorDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Timer progress
                  if (_isListening) ...[
                    AnimatedBuilder(
                      animation: _timerCtrl,
                      builder: (_, __) => Column(
                        children: [
                          SizedBox(
                            width: 200.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: _timerCtrl.value,
                                minHeight: 4.h,
                                backgroundColor: widget.accentColor
                                    .withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(
                                    widget.accentColor),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${(SpeechService.defaultListenFor.inSeconds * (1 - _timerCtrl.value)).round()}s',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Audio quality indicator
                  if (_isListening && _audioAnalysis != null)
                    _buildAudioQualityIndicator(),

                  // Mic button
                  GestureDetector(
                    onTap: _hasResult ? _retry : _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => _buildMicButton(),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Audio waveform visualization
                  if (_isListening) _buildWaveform(),
                  if (_isListening) SizedBox(height: 4.h),

                  // Transcript realtime
                  if (_isListening && _recognized.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.surfaceColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '"$_recognized"',
                        style: GoogleFonts.battambang(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.accentColorDark,
                        ),
                      ),
                    ),

                  // Result
                  if (_hasResult) _buildResult(),

                  // Status message
                  if (!_hasResult)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        _isListening
                            ? 'Đang thu âm... Chạm để dừng'
                            : _statusMsg.isNotEmpty
                                ? _statusMsg
                                : !_sttReady
                                    ? 'Đang khởi tạo...'
                                    : 'Chạm mic và đọc "${widget.romanized}"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _isListening
                              ? widget.accentColor
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    // Tính kích thước động dựa trên audio level
    final levelScale = _isListening ? (1.0 + _audioLevel * 0.15) : 1.0;

    return Column(
      children: [
        // Triple ring mic với animation dựa trên audio level
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 110.w * levelScale,
          height: 110.w * levelScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.accentColor
                  .withValues(alpha: _isListening ? (0.3 + _audioLevel * 0.4) : 0.25),
              width: 1.5.w,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Center(
            child: Container(
              width: 95.w,
              height: 95.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.surfaceColor,
              ),
              child: Center(
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _hasResult
                          ? [
                              _result!.passed
                                  ? AppColors.tertiary
                                  : AppColors.coral,
                              _result!.passed
                                  ? AppColors.tertiaryDark
                                  : AppColors.coralDark,
                            ]
                          : _isListening
                              ? [widget.accentColor, widget.accentColorDark]
                              : [
                                  widget.accentColor
                                      .withValues(alpha: 0.8),
                                  widget.accentColor,
                                ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(
                          alpha: 0.3 +
                              (_isListening
                                  ? 0.25 * _pulseCtrl.value + _audioLevel * 0.2
                                  : 0),
                        ),
                        blurRadius: (16 +
                                (_isListening
                                    ? 12 * _pulseCtrl.value + _audioLevel * 8
                                    : 0))
                            .r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    _hasResult
                        ? Icons.refresh_rounded
                        : _isListening
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                    color: Colors.white,
                    size: 30.w,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        // Wave bars với animation dựa trên audio level history
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(11, (i) {
            final center = 5;
            final dist = (i - center).abs();
            final base = dist <= 1 ? 16.h : dist <= 3 ? 8.h : 4.h;

            // Lấy audio level từ history cho mỗi bar
            final historyIndex = (_audioLevelIndex + i) % _audioLevelHistory.length;
            final levelForBar = _audioLevelHistory[historyIndex];

            final h = _isListening
                ? base * (0.5 + 0.5 * levelForBar)
                : base * 0.4;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: dist <= 1 ? 4.w : 3.w,
              height: h,
              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              decoration: BoxDecoration(
                color: widget.accentColor
                    .withValues(alpha: _isListening ? (0.5 + levelForBar * 0.5) : 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 60.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) {
          final level = _audioLevelHistory[i];
          final height = (level * 40.h).clamp(2.h, 40.h);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3.w,
            height: height,
            decoration: BoxDecoration(
              color: level > 0.6
                  ? AppColors.tertiary
                  : level > 0.3
                      ? widget.accentColor
                      : widget.accentColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2.r),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAudioQualityIndicator() {
    if (_audioAnalysis == null) return const SizedBox.shrink();

    final analysis = _audioAnalysis!;
    Color indicatorColor;
    IconData indicatorIcon;
    String indicatorText;

    switch (analysis.quality) {
      case AudioQuality.excellent:
        indicatorColor = AppColors.tertiary;
        indicatorIcon = Icons.check_circle_rounded;
        indicatorText = 'Xuất sắc';
        break;
      case AudioQuality.good:
        indicatorColor = AppColors.tertiary;
        indicatorIcon = Icons.check_circle_outline_rounded;
        indicatorText = 'Tốt';
        break;
      case AudioQuality.fair:
        indicatorColor = AppColors.secondary;
        indicatorIcon = Icons.info_outline_rounded;
        indicatorText = 'Khá';
        break;
      case AudioQuality.poor:
        indicatorColor = AppColors.coral;
        indicatorIcon = Icons.warning_amber_rounded;
        indicatorText = 'Kém';
        break;
      case AudioQuality.veryPoor:
        indicatorColor = AppColors.errorRed;
        indicatorIcon = Icons.error_outline_rounded;
        indicatorText = 'Rất kém';
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 16.w),
          SizedBox(width: 4.w),
          Text(
            'Chất lượng: $indicatorText',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  int _accuracyToStars(int accuracy) {
    if (accuracy >= 90) return 3;
    if (accuracy >= 80) return 2;
    if (accuracy >= 70) return 1;
    return 0;
  }

  Widget _buildDetailRow(
    String label, 
    String value, {
    bool isKhmerTarget = false,
    bool isKhmerRecognized = false,
    Color? textColor,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: isKhmerTarget || isKhmerRecognized
                ? GoogleFonts.battambang(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? AppColors.primaryDark,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: fontWeight,
                    color: textColor ?? AppColors.textPrimary,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final double calibConfidence = ScoringService.calibrateConfidence(_rawConfidence);
    final r = _result;

    if (r == null) {
      // Confidence gate failed
      return Container(
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.coralSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.coral.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning header
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 24.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Chúng tôi nghe chưa rõ. Vui lòng đọc lại.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coralDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            const Divider(color: Colors.black12, height: 1),
            SizedBox(height: 8.h),
            
            // Detail grid
            _buildDetailRow('Bạn đọc', widget.character, isKhmerTarget: true),
            SizedBox(height: 6.h),
            _buildDetailRow('Hệ thống nghe', _displayHeard(), isKhmerRecognized: true),
            SizedBox(height: 6.h),
            _buildDetailRow('Độ tin cậy', '${(calibConfidence * 100).toStringAsFixed(0)}% (${_rawConfidence.toStringAsFixed(2)} raw)'),
          ],
        ),
      );
    }

    // Normal score display
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: r.passed
            ? AppColors.tertiarySurface
            : AppColors.coralSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: r.passed
              ? AppColors.tertiary.withValues(alpha: 0.3)
              : AppColors.coral.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emoji & Success/Fail Feedback Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(r.emoji, style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    r.feedback,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: r.passed
                          ? AppColors.tertiaryDark
                          : AppColors.coralDark,
                    ),
                  ),
                ],
              ),
              // Stars display
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < r.stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18.w,
                    color: i < r.stars
                        ? AppColors.secondary
                        : AppColors.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          const Divider(color: Colors.black12, height: 1),
          SizedBox(height: 8.h),

          // Detail rows
          _buildDetailRow('Bạn đọc', widget.character, isKhmerTarget: true),
          SizedBox(height: 6.h),
          _buildDetailRow('Hệ thống nghe', _recognized, isKhmerRecognized: true),
          SizedBox(height: 6.h),
          
          // Highlights row
          if (_recognized.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90.w,
                  child: Text(
                    'Đánh giá từ:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 4.w,
                    children: r.highlights.map((h) {
                      return Text(
                        h.text,
                        style: GoogleFonts.battambang(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: h.isCorrect
                              ? AppColors.tertiaryDark
                              : AppColors.errorRed,
                          decoration: h.isCorrect
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],

          _buildDetailRow('Độ tin cậy', '${(calibConfidence * 100).toStringAsFixed(0)}% (${_rawConfidence.toStringAsFixed(2)} raw)'),
          SizedBox(height: 6.h),
          if (_scoreResult != null) ...[
            _buildDetailRow('Phương thức', _scoreResult!.matchMethod),
            SizedBox(height: 6.h),
          ],
          _buildDetailRow(
            'Điểm số', 
            '${r.accuracy}%', 
            textColor: r.passed ? AppColors.tertiaryDark : AppColors.coralDark,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}
