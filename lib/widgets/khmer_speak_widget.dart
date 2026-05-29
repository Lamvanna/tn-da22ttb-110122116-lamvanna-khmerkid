import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/scoring_service.dart';

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
  String _recognized = '';
  String _statusMsg = '';
  bool _hasResult = false;
  PronunciationResult? _result;

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

    _speech.onResult = (text, isFinal) {
      if (mounted) {
        setState(() => _recognized = text);
        if (isFinal) {
          _onListeningDone();
        }
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
    if (mounted) setState(() => _sttReady = ok);
  }

  void _onListeningDone() {
    _pulseCtrl.stop();
    _timerCtrl.stop();
    if (mounted) setState(() => _isListening = false);
    _evaluate();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _pulseCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    await _tts.stop();
    // Safe delay to let mobile audio hardware reset before opening the mic
    await Future.delayed(const Duration(milliseconds: 350));
    setState(() {
      _recognized = '';
      _statusMsg = '';
      _hasResult = false;
      _result = null;
      _isListening = true;
    });
    _pulseCtrl.repeat(reverse: true);
    _timerCtrl.forward(from: 0);

    final ok = await _speech.startListening();
    if (!ok && mounted) {
      _pulseCtrl.stop();
      _timerCtrl.stop();
      setState(() {
        _isListening = false;
        _statusMsg = 'Lỗi nhận diện. Thử lại!';
      });
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
      if (mounted) setState(() => _sttReady = ok);
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

    final result = _scoring.scorePronunciation(
      spoken: _recognized,
      character: widget.character,
      romanized: widget.romanized,
      pronunciation: widget.pronunciation,
      passThreshold: widget.passThreshold,
    );

    setState(() {
      _result = result;
      _hasResult = true;
    });

    if (result.passed) {
      widget.onComplete?.call();
    }
  }

  Future<void> _playExample() async {
    await _tts.speakKhmerLetter(
      character: widget.character,
      pronunciation: widget.pronunciation,
      romanized: widget.romanized,
    );
  }

  void _retry() {
    setState(() {
      _hasResult = false;
      _result = null;
      _recognized = '';
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
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
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

                  // Mic button
                  GestureDetector(
                    onTap: _hasResult ? _retry : _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => _buildMicButton(),
                    ),
                  ),
                  SizedBox(height: 4.h),

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
                  if (_hasResult && _result != null) _buildResult(),

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
    return Column(
      children: [
        // Triple ring mic
        Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.accentColor
                  .withValues(alpha: _isListening ? 0.5 : 0.25),
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
                                  ? 0.25 * _pulseCtrl.value
                                  : 0),
                        ),
                        blurRadius: (16 +
                                (_isListening
                                    ? 12 * _pulseCtrl.value
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
        // Wave bars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(11, (i) {
            final center = 5;
            final dist = (i - center).abs();
            final base = dist <= 1 ? 16.h : dist <= 3 ? 8.h : 4.h;
            final h = _isListening
                ? base * (0.5 + 0.5 * _pulseCtrl.value)
                : base * 0.4;
            return Container(
              width: dist <= 1 ? 4.w : 3.w,
              height: h,
              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              decoration: BoxDecoration(
                color: widget.accentColor
                    .withValues(alpha: _isListening ? 0.8 : 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r.emoji, style: TextStyle(fontSize: 20.sp)),
              SizedBox(width: 8.w),
              Text(
                '${r.accuracy}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: r.passed
                      ? AppColors.tertiaryDark
                      : AppColors.coralDark,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                r.feedback,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: r.passed
                      ? AppColors.tertiaryDark
                      : AppColors.coralDark,
                ),
              ),
            ],
          ),
          if (_recognized.isNotEmpty) ...[
            SizedBox(height: 6.h),
            // Highlighted transcript
            Wrap(
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
          ],
          if (r.passed) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    );
  }
}
