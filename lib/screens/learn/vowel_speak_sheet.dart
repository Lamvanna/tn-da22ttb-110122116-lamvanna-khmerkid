import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import '../../services/scoring_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

/// Sheet luyện nói nguyên âm
/// Dùng cùng logic + ngưỡng đánh giá với KhmerSpeakWidget (consonant):
///   • SpeechService (thay stt.SpeechToText cũ)
///   • scoreBestAlternate — chấm tất cả alternates, chọn bản khớp nhất
///   • passThreshold = 70%  (không đánh dấu đúng khi chưa đạt)
///   • Hiển thị: văn bản nghe được / âm mục tiêu / % độ chính xác
class VowelSpeakSheet extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelSpeakSheet({
    super.key,
    required this.vowel,
    required this.onComplete,
  });

  @override
  State<VowelSpeakSheet> createState() => _VowelSpeakSheetState();
}

class _VowelSpeakSheetState extends State<VowelSpeakSheet>
    with TickerProviderStateMixin {
  final SpeechService _speech = SpeechService.instance;
  final TtsService _tts = TtsService.instance;
  final ScoringService _scoring = ScoringService.instance;

  late AnimationController _pulseCtrl;
  late AnimationController _timerCtrl;

  bool _sttReady = false;
  bool _isListening = false;
  bool _isStartingListening = false;
  bool _isPlayingExample = false;

  String _recognized = '';
  List<String> _alternates = const [];
  String _matchedText = '';

  bool _hasResult = false;
  PronunciationResult? _result;
  double _rawConfidence = 0.0;
  String _statusMsg = '';

  // Audio visualisation
  double _audioLevel = 0.0;
  final List<double> _audioLevelHistory = List.filled(20, 0.0);
  int _audioLevelIndex = 0;

  /// Pass threshold khớp yêu cầu: 70%
  static const int _passThreshold = 70;

  // ─── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _timerCtrl = AnimationController(
        vsync: this, duration: SpeechService.defaultListenFor);
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
        if (isFinal) _onListeningDone();
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
        if (!ok) _statusMsg = 'Đang khởi tạo nhận diện giọng nói...';
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
    _speech.onResult = null;
    _speech.onError = null;
    _speech.onStatus = null;
    _speech.onAudioLevel = null;
    _speech.cancel();
    _tts.stop();
    _pulseCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  // ─── Listening ────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_isStartingListening) return;
    _isStartingListening = true;
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 400));
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
          _statusMsg = 'Không thể khởi động mic. Thử lại!';
        });
      } else {
        setState(() => _statusMsg = '');
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
    if (_isStartingListening) return;
    if (!_sttReady) {
      final ok = await _speech.init();
      if (mounted) setState(() => _sttReady = ok);
      return;
    }
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  // ─── Scoring ──────────────────────────────────────────────────

  /// Chấm điểm giống KhmerSpeakWidget: dùng scoreBestAlternate,
  /// ngưỡng 70%, KHÔNG đánh dấu passed khi thực sự sai.
  void _evaluate() {
    if (_hasResult) return;
    if (_recognized.trim().isEmpty) {
      setState(() => _statusMsg = 'Không nhận diện được. Nói to hơn!');
      return;
    }

    final double calibConf =
        ScoringService.calibrateConfidence(_rawConfidence);

    // Dùng scoreBestAlternate để chọn bản alternates khớp nhất
    final candidates = <String>[
      if (_recognized.trim().isNotEmpty) _recognized.trim(),
      ..._alternates,
    ];

    final PronunciationScoreResult scoreResult;
    final best = _scoring.scoreBestAlternate(
      targetCharacter: widget.vowel.character,
      alternates: candidates,
      confidence: _rawConfidence,
      romanized: widget.vowel.pronunciationClean,
      pronunciation: widget.vowel.pronunciationClean,
      acceptedAnswers: [
        widget.vowel.pronunciationClean,
        widget.vowel.romanized,
        widget.vowel.pronunciation,
      ],
      passThreshold: _passThreshold,
    );

    scoreResult = best.result;
    _matchedText = best.matchedText;

    // Loại bỏ trường hợp confidence quá thấp VÀ score thấp
    final bool reallyUnclear =
        calibConf < 0.35 && scoreResult.rawScore < 50.0;
    if (reallyUnclear) {
      setState(() {
        _statusMsg = 'Chúng tôi nghe chưa rõ. Vui lòng đọc lại.';
        _hasResult = true;
        _result = null;
      });
      return;
    }

    final highlights = _scoring.buildHighlights(
      _matchedText, 
      widget.vowel.character, 
      scoreResult.passed,
      romanized: widget.vowel.pronunciationClean,
      pronunciation: widget.vowel.pronunciationClean,
      acceptedAnswers: [
        widget.vowel.pronunciationClean,
        widget.vowel.romanized,
        widget.vowel.pronunciation,
      ],
    );

    final pronunciationRes = PronunciationResult(
      accuracy: scoreResult.weightedScore.round(),
      passed: scoreResult.passed,
      stars: _accuracyToStars(scoreResult.weightedScore.round()),
      matchedTarget: widget.vowel.character,
      highlights: highlights,
    );

    setState(() {
      _result = pronunciationRes;
      _hasResult = true;
    });

    // Chỉ gọi onComplete khi ĐẠT ngưỡng — không bao giờ đánh dấu sai là đúng
    if (scoreResult.passed) {
      widget.onComplete();
    }
  }

  int _accuracyToStars(int accuracy) {
    if (accuracy >= 90) return 3;
    if (accuracy >= 80) return 2;
    if (accuracy >= _passThreshold) return 1;
    return 0;
  }

  Future<void> _playExample() async {
    if (_isPlayingExample) return;
    setState(() => _isPlayingExample = true);
    await _tts.speakVietnamese(widget.vowel.listenText);
    if (mounted) setState(() => _isPlayingExample = false);
  }

  void _retry() {
    setState(() {
      _hasResult = false;
      _result = null;
      _rawConfidence = 0.0;
      _recognized = '';
      _alternates = const [];
      _matchedText = '';
      _statusMsg = '';
    });
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.sheetWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.sheetWarmBorder,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),

            // Title
            Center(
              child: Text(
                'Tập nói phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sheetBrown,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Character display
            Center(
              child: Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.headerEnd, AppColors.headerAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.headerAccent.withValues(alpha: 0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.vowel.character,
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

            // Romanized badge
            Center(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.sheetWarmBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Text(
                  '"${widget.vowel.pronunciationClean}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sheetBrown,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Listen example button
            Center(
              child: GestureDetector(
                onTap: !_isPlayingExample && !_isListening
                    ? _playExample
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 18.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.violetSurface,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlayingExample
                            ? Icons.volume_up_rounded
                            : Icons.headphones_rounded,
                        color: AppColors.violet,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _isPlayingExample
                            ? 'Đang phát...'
                            : 'Nghe mẫu trước',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Timer countdown (when listening)
            if (_isListening)
              AnimatedBuilder(
                animation: _timerCtrl,
                builder: (context, _) => Column(
                  children: [
                    SizedBox(
                      width: 200.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: _timerCtrl.value,
                          minHeight: 4.h,
                          backgroundColor: AppColors.secondary
                              .withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.secondary),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${(SpeechService.defaultListenFor.inSeconds * (1 - _timerCtrl.value)).round()}s',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),

            // Microphone button with waveform bars
            Center(
              child: GestureDetector(
                onTap: _hasResult ? _retry : _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) => _buildMicButton(),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Realtime transcript
            if (_isListening && _recognized.isNotEmpty)
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.sheetWarmBorder.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '"$_recognized"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sheetBrown,
                    ),
                  ),
                ),
              ),

            // Status message
            if (!_hasResult)
              Center(
                child: Text(
                  _isListening
                      ? 'Đang nghe... Chạm để dừng'
                      : _statusMsg.isNotEmpty
                          ? _statusMsg
                          : !_sttReady
                              ? 'Đang khởi tạo...'
                              : 'Chạm mic và đọc "${widget.vowel.pronunciationClean}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _isListening
                        ? AppColors.errorRed
                        : AppColors.sheetBrownLight,
                  ),
                ),
              ),

            // Result card
            if (_hasResult) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // ─── Mic button ───────────────────────────────────────────────

  Widget _buildMicButton() {
    final levelScale =
        _isListening ? (1.0 + _audioLevel * 0.15) : 1.0;
    Color micColor;
    IconData micIcon;
    if (_hasResult) {
      micColor = (_result?.passed ?? false)
          ? AppColors.successGreen
          : AppColors.errorRed;
      micIcon = Icons.refresh_rounded;
    } else if (_isListening) {
      micColor = AppColors.errorRed;
      micIcon = Icons.stop_rounded;
    } else {
      micColor = _sttReady ? AppColors.successLight : AppColors.textHint;
      micIcon = Icons.mic_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 100.w * levelScale,
      height: 100.w * levelScale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [micColor, Color.lerp(micColor, Colors.black, 0.2) ?? Colors.black],
        ),
        boxShadow: [
          BoxShadow(
            color: micColor.withValues(
              alpha: 0.35 +
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
      child: Icon(micIcon, color: Colors.white, size: 34.sp),
    );
  }

  // ─── Result Card ──────────────────────────────────────────────

  Widget _buildResultCard() {
    final r = _result;

    // Confidence gate failed — nghe không rõ
    if (r == null) {
      return Container(
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.secondary, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Chúng tôi nghe chưa rõ. Vui lòng đọc lại.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sheetBrown,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildDetailRow(
                'Hệ thống nghe', _recognized.isNotEmpty ? '"$_recognized"' : '(không rõ)'),
            SizedBox(height: 12.h),
            _retryButton(),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: r.passed
              ? AppColors.successGreen.withValues(alpha: 0.35)
              : AppColors.errorRed.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (r.passed ? AppColors.successGreen : AppColors.errorRed)
                .withValues(alpha: 0.10),
            blurRadius: 14.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: pass/fail + stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(r.passed ? '🎉' : '😅',
                      style: TextStyle(fontSize: 22.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    r.passed ? 'Tuyệt vời!' : 'Chưa đạt',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: r.passed
                          ? AppColors.successGreen
                          : AppColors.errorDark,
                    ),
                  ),
                ],
              ),
              // Stars
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < r.stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20.w,
                    color: i < r.stars
                        ? AppColors.secondary
                        : AppColors.sheetWarmBorder,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: Colors.black12, height: 1),
          SizedBox(height: 10.h),

          // Recognized text
          _buildDetailRow(
            'Hệ thống nghe',
            _recognized.isNotEmpty ? '"$_recognized"' : '(không rõ)',
          ),
          SizedBox(height: 6.h),

          // Expected text
          _buildDetailRow(
            'Âm mục tiêu',
            '"${widget.vowel.pronunciationClean}"',
            valueColor: AppColors.sheetBrown,
          ),
          SizedBox(height: 6.h),

          // Accuracy percentage
          _buildDetailRow(
            'Độ chính xác',
            '${r.accuracy}%',
            valueColor: r.passed
                ? AppColors.successGreen
                : AppColors.errorDark,
            bold: true,
          ),

          // Pass threshold note
          SizedBox(height: 4.h),
          Text(
            r.passed
                ? '✓ Đạt ngưỡng $_passThreshold% — hoàn thành!'
                : '✗ Cần đạt ≥ $_passThreshold% để qua — hãy thử lại!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: r.passed
                  ? AppColors.successGreen
                  : AppColors.errorRed,
            ),
          ),

          SizedBox(height: 14.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _retry,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Center(
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (r.passed) ...[
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.successLight,
                            AppColors.successGreen
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Center(
                        child: Text(
                          'Hoàn thành ✅',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: bold ? 15.sp : 13.sp,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? AppColors.sheetBrown,
            ),
          ),
        ),
      ],
    );
  }

  Widget _retryButton() {
    return GestureDetector(
      onTap: _retry,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Center(
          child: Text(
            'Thử lại',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
