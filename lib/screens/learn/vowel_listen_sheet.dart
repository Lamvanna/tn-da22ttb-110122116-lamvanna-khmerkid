import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';

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
    HapticFeedback.lightImpact();
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Gradient Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: const BoxDecoration(
            gradient: AppColors.listenGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Lắng nghe và ghi nhớ cách đọc', style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
          ]),
        ),

        // ── Content ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(children: [
            // Character
            Text(widget.vowel.character, style: GoogleFonts.kantumruyPro(
              fontSize: 80, fontWeight: FontWeight.w700,
              color: AppColors.primary, height: 1.1)),
            const SizedBox(height: 8),
            // Pronunciation badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20)),
              child: Text('Phát âm: "${widget.vowel.romanized}"', style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(height: 28),

            // ── Wave Bars + Play Button ──
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Left bars
                ...List.generate(7, (i) {
                  final h = _isPlaying
                    ? 14.0 + 22 * ((i % 4 + 1) / 4) * (0.3 + 0.7 * _waveCtrl.value)
                    : 8.0 + (i % 3) * 5.0;
                  return Container(width: 4, height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25),
                      borderRadius: BorderRadius.circular(2)));
                }),
                const SizedBox(width: 16),
                // Play button with pressed state
                GestureDetector(
                  onTapDown: (_) => setState(() => _playBtnPressed = true),
                  onTapUp: (_) => setState(() => _playBtnPressed = false),
                  onTapCancel: () => setState(() => _playBtnPressed = false),
                  onTap: _ttsReady ? _play : null,
                  child: AnimatedScale(
                    scale: _playBtnPressed ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.listenGradient,
                        boxShadow: [BoxShadow(
                          color: AppColors.tertiary.withValues(alpha: 0.4),
                          blurRadius: 20, offset: const Offset(0, 8))]),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 36)),
                  ),
                ),
                const SizedBox(width: 16),
                // Right bars (mirrored)
                ...List.generate(7, (i) {
                  final h = _isPlaying
                    ? 14.0 + 22 * (((6 - i) % 4 + 1) / 4) * (0.3 + 0.7 * _waveCtrl.value)
                    : 8.0 + ((6 - i) % 3) * 5.0;
                  return Container(width: 4, height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25),
                      borderRadius: BorderRadius.circular(2)));
                }),
              ]),
            ),
            const SizedBox(height: 12),
            // Status text
            Text(
              _isPlaying ? 'Đang phát âm...'
                : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
                : 'Nhấn nút để nghe phát âm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // ── Speed chips ──
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Tốc độ:', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              const SizedBox(width: 10),
              _speedChip('🐢 Chậm', 0),
              const SizedBox(width: 8),
              _speedChip('🔊 Vừa', 1),
              const SizedBox(width: 8),
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
        HapticFeedback.selectionClick();
        setState(() => _speed = val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: active ? [BoxShadow(
            color: AppColors.tertiary.withValues(alpha: 0.3),
            blurRadius: 8, offset: const Offset(0, 3))] : null),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
