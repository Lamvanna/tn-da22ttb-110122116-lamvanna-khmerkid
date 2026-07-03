import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import 'package:khmerkid/utils/app_haptics.dart';

/// Sheet nghe phát âm nguyên âm — RESPONSIVE
class VowelListenSheet extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelListenSheet({super.key, required this.vowel, required this.onComplete});
  @override
  State<VowelListenSheet> createState() => _State();
}

class _State extends State<VowelListenSheet> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _speed = 1;
  int _playCount = 0;
  bool _ttsReady = false;
  bool _khmerSupported = false;
  bool _playBtnPressed = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));
    if (_khmerSupported) {
      await _tts.setLanguage('km');
    } else {
      final viSupported = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(viSupported ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(_speedRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() { if (mounted) { setState(() => _isPlaying = false); _waveCtrl.stop(); } });
    _tts.setErrorHandler((msg) { if (mounted) { setState(() => _isPlaying = false); _waveCtrl.stop(); } });
    if (mounted) setState(() => _ttsReady = true);
  }

  double get _speedRate => _speed == 0 ? 0.2 : _speed == 2 ? 0.7 : 0.4;

  @override
  void dispose() { _tts.stop(); _waveCtrl.dispose(); super.dispose(); }

  Future<void> _play() async {
    if (_isPlaying) return;
    AppHaptics.lightImpact();
    setState(() { _isPlaying = true; _playCount++; });
    _waveCtrl.repeat(reverse: true);
    await _tts.setSpeechRate(_speedRate);
    final text = _khmerSupported ? widget.vowel.character
        : widget.vowel.pronunciation.isNotEmpty ? widget.vowel.pronunciation : widget.vowel.romanized;
    final result = await _tts.speak(text);
    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) { setState(() => _isPlaying = false); _waveCtrl.stop(); }
      });
    }
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Gradient Header ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 22.h),
          decoration: BoxDecoration(
            gradient: AppColors.listenGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(children: [
            // Drag handle
            Container(
              width: 48.w, height: 5.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3.r)),
            ),
            SizedBox(height: 14.h),
            Container(
              width: 48.w, height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16.r)),
              child: Icon(Icons.headphones_rounded, color: Colors.white, size: 26.sp),
            ),
            SizedBox(height: 10.h),
            Text(context.translate('learn.listen_pronunciation'), style: GoogleFonts.plusJakartaSans(
              fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 4.h),
            Text(context.translate('learn.listen_and_remember'), style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
          ]),
        ),

        // ── Content ──
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 28.h),
          child: Column(children: [
            // Character
            Text(widget.vowel.character, style: GoogleFonts.battambang(
              fontSize: 80.sp, fontWeight: FontWeight.w700,
              color: AppColors.primary, height: 1.1)),
            SizedBox(height: 8.h),
            // Pronunciation badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r)),
              child: Text('Phát âm: "${widget.vowel.romanized}"', style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            SizedBox(height: 28.h),

            // ── Wave Bars + Play Button ──
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Left bars
                ...List.generate(7, (i) {
                  final h = _isPlaying
                    ? 14.0 + 22 * ((i % 4 + 1) / 4) * (0.3 + 0.7 * _waveCtrl.value)
                    : 8.0 + (i % 3) * 5.0;
                  return Container(width: 4.w, height: h,
                    margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25),
                      borderRadius: BorderRadius.circular(2.r)));
                }),
                SizedBox(width: 16.w),
                // Play button
                GestureDetector(
                  onTapDown: (_) => setState(() => _playBtnPressed = true),
                  onTapUp: (_) => setState(() => _playBtnPressed = false),
                  onTapCancel: () => setState(() => _playBtnPressed = false),
                  onTap: _ttsReady ? _play : null,
                  child: AnimatedScale(
                    scale: _playBtnPressed ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 72.w, height: 72.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.listenGradient,
                        boxShadow: [BoxShadow(
                          color: AppColors.tertiary.withValues(alpha: 0.4),
                          blurRadius: 20.r, offset: Offset(0, 8.h))]),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 36.sp)),
                  ),
                ),
                SizedBox(width: 16.w),
                // Right bars
                ...List.generate(7, (i) {
                  final h = _isPlaying
                    ? 14.0 + 22 * (((6 - i) % 4 + 1) / 4) * (0.3 + 0.7 * _waveCtrl.value)
                    : 8.0 + ((6 - i) % 3) * 5.0;
                  return Container(width: 4.w, height: h,
                    margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25),
                      borderRadius: BorderRadius.circular(2.r)));
                }),
              ]),
            ),
            SizedBox(height: 12.h),
            // Status text
            Text(
              _isPlaying ? context.translate('learn.pronouncing')
                : _playCount > 0 ? context.translate('learn.listened_count_label', args: {'count': _playCount})
                : context.translate('learn.press_to_listen'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            SizedBox(height: 24.h),

            // ── Speed chips ──
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(context.translate('learn.speed_label'), style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              SizedBox(width: 10.w),
              _speedChip('🐢 ' + context.translate('settings.speed_slow'), 0),
              SizedBox(width: 8.w),
              _speedChip('🔊 ' + context.translate('settings.speed_normal'), 1),
              SizedBox(width: 8.w),
              _speedChip('🐇 Nhanh', 2),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _speedChip(String label, int val) {
    final active = _speed == val;
    return GestureDetector(
      onTap: () {
        AppHaptics.selectionClick();
        setState(() => _speed = val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20.r),
          border: active ? null : Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: active ? [BoxShadow(
            color: AppColors.tertiary.withValues(alpha: 0.3),
            blurRadius: 8.r, offset: Offset(0, 3.h))] : null),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp, fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
