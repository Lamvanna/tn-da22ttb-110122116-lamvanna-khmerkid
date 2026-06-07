import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/tts_service.dart';

/// ════════════════════════════════════════════════════════════════════
/// KhmerListenWidget — Widget NGHE tái sử dụng
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Chữ Khmer lớn ở giữa với glow effect
///   • Nút play gradient với pulse animation khi phát
///   • Wave bars animation (11 bars, center-outward pattern)
///   • Speed selector (🐢 Chậm / 🔊 Vừa / 🐇 Nhanh)
///   • Play count tracker
///   • Auto-complete sau lần nghe đầu tiên
/// ════════════════════════════════════════════════════════════════════

class KhmerListenWidget extends StatefulWidget {
  final String character;
  final String romanized;
  final String pronunciation;
  /// Khi có giá trị: phát đúng chuỗi này bằng giọng tiếng Việt (vd "srăk a"),
  /// BỎ QUA việc đọc ký tự Khmer. Dùng cho nguyên âm cần đọc tên "srăk + âm".
  final String? speakTextOverride;
  final VoidCallback? onComplete;
  final bool showSpeedControl;
  final Color accentColor;
  final Color accentColorDark;
  final Color surfaceColor;

  const KhmerListenWidget({
    super.key,
    required this.character,
    this.romanized = '',
    this.pronunciation = '',
    this.speakTextOverride,
    this.onComplete,
    this.showSpeedControl = true,
    this.accentColor = const Color(0xFF2F9656),
    this.accentColorDark = const Color(0xFF258048),
    this.surfaceColor = const Color(0xFFE6F5EC),
  });

  @override
  State<KhmerListenWidget> createState() => _KhmerListenWidgetState();
}

class _KhmerListenWidgetState extends State<KhmerListenWidget>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService.instance;
  late AnimationController _pulseCtrl;
  bool _isPlaying = false;
  int _playCount = 0;
  bool _ttsReady = false;
  TtsSpeed _speed = TtsSpeed.normal;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    _tts.onStart = () {
      if (mounted) setState(() => _isPlaying = true);
      _pulseCtrl.repeat(reverse: true);
    };
    _tts.onComplete = () {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
        _pulseCtrl.value = 0;
      }
    };
    _tts.onError = (_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
        _pulseCtrl.value = 0;
      }
    };

    await _tts.init();
    if (mounted) setState(() => _ttsReady = _tts.isInitialized);
  }

  @override
  void dispose() {
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() => _playCount++);

    await _tts.setSpeed(_speed);

    final override = widget.speakTextOverride;
    if (override != null && override.trim().isNotEmpty) {
      // Đọc đúng chuỗi tên (vd "srăk a") bằng giọng Việt, không đọc ký tự Khmer
      await _tts.speakVietnamese(override);
    } else {
      await _tts.speakKhmerLetter(
        character: widget.character,
        pronunciation: widget.pronunciation,
        romanized: widget.romanized,
      );
    }

    if (_playCount >= 1) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.only(top: 12.h, bottom: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headphones_rounded,
                  color: widget.accentColor, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Nghe phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: widget.accentColorDark,
                ),
              ),
            ],
          ),
        ),

        // ── Main content ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 12.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Character circle
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          blurRadius: 20.r,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.character,
                        style: GoogleFonts.battambang(
                          fontSize: 54.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Pronunciation badge
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
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
                            widget.pronunciation.isNotEmpty && widget.pronunciation != widget.romanized
                                ? 'Phát âm: "${widget.romanized}" [${widget.pronunciation}]'
                                : 'Phát âm: "${widget.romanized}"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColorDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Play button with triple rings
                  GestureDetector(
                    onTap: _ttsReady ? _play : null,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Column(
                        children: [
                          _buildPlayButton(),
                          SizedBox(height: 10.h),
                          _buildWaveBars(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Status text
                  Text(
                    _isPlaying
                        ? 'Đang phát âm...'
                        : _playCount > 0
                            ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
                            : 'Nhấn nút để nghe phát âm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          _isPlaying ? widget.accentColor : AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Speed selector
                  if (widget.showSpeedControl) _buildSpeedSelector(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.accentColor
              .withValues(alpha: _isPlaying ? 0.5 : 0.25),
          width: 1.5.w,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Center(
        child: Container(
          width: 102.w,
          height: 102.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.surfaceColor,
          ),
          child: Center(
            child: Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPlaying
                      ? [widget.accentColor, widget.accentColorDark]
                      : [
                          widget.accentColor.withValues(alpha: 0.8),
                          widget.accentColor,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(
                      alpha:
                          0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0),
                    ),
                    blurRadius:
                        (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(11, (i) {
        final center = 5;
        final dist = (i - center).abs();
        final base = dist <= 1 ? 20.h : dist <= 3 ? 10.h : 5.h;
        final h = _isPlaying
            ? base * (0.5 + 0.5 * _pulseCtrl.value)
            : base * 0.4;
        return Container(
          width: dist <= 1 ? 4.w : 3.w,
          height: h,
          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
          decoration: BoxDecoration(
            color: widget.accentColor
                .withValues(alpha: _isPlaying ? 0.8 : 0.3),
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      }),
    );
  }

  Widget _buildSpeedSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tốc độ:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(width: 8.w),
          _speedChip('🐢 Chậm', TtsSpeed.slow),
          SizedBox(width: 6.w),
          _speedChip('🔊 Vừa', TtsSpeed.normal),
          SizedBox(width: 6.w),
          _speedChip('🐇 Nhanh', TtsSpeed.fast),
        ],
      ),
    );
  }

  Widget _speedChip(String label, TtsSpeed val) {
    final active = _speed == val;
    return GestureDetector(
      onTap: () {
        setState(() => _speed = val);
        _tts.setSpeed(val);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: active ? widget.accentColor : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
