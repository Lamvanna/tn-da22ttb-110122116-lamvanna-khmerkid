import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_number.dart';

class NumberInlineListenContent extends StatefulWidget {
  final KhmerNumber number;
  final VoidCallback onComplete;
  const NumberInlineListenContent({super.key, required this.number, required this.onComplete});
  @override
  State<NumberInlineListenContent> createState() => _S();
}

class _S extends State<NumberInlineListenContent> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false, _ttsReady = false, _khmerSupported = false;
  int _speed = 1, _playCount = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _initTts();
  }

  Future<void> _initTts() async {
    final langs = await _tts.getLanguages;
    final list = (langs as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = list.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(_khmerSupported ? 'km' : list.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(_speedRate);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    _tts.setErrorHandler((_) { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    if (mounted) setState(() => _ttsReady = true);
  }

  double get _speedRate => _speed == 0 ? 0.2 : _speed == 2 ? 0.7 : 0.4;

  @override
  void dispose() { _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() { _isPlaying = true; _playCount++; });
    _pulseCtrl.repeat(reverse: true);
    await _tts.setSpeechRate(_speedRate);
    final text = _khmerSupported ? widget.number.character
        : widget.number.pronunciation.isNotEmpty ? widget.number.pronunciation : widget.number.romanized;
    final r = await _tts.speak(text);
    if (r != 1 && mounted) Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); }
    });
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.headphones_rounded, color: AppColors.primary, size: 20.w),
          SizedBox(width: 8.w),
          Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ])),
      Expanded(child: Align(alignment: const Alignment(0, -0.35),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 120.w, height: 120.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primarySurface,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24.r, spreadRadius: 4)]),
              child: Center(child: Text(widget.number.character, style: GoogleFonts.battambang(
                fontSize: 64.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.1)))),
            SizedBox(height: 10.h),
            GestureDetector(onTap: _ttsReady ? _play : null,
              child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up_rounded, size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('Phát âm: "${widget.number.pronunciation}"', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                ]))),
            SizedBox(height: 18.h),
            GestureDetector(onTap: _ttsReady ? _play : null,
              child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Column(children: [
                Container(width: 140.w, height: 140.w,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: _isPlaying ? 0.5 : 0.25), width: 1.5.w, strokeAlign: BorderSide.strokeAlignOutside)),
                  child: Center(child: Container(width: 120.w, height: 120.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primarySurface),
                    child: Center(child: Container(width: 90.w, height: 90.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: _isPlaying ? [AppColors.primary, AppColors.primaryDark] : [AppColors.primaryLight, AppColors.primary]),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0)),
                          blurRadius: (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r, offset: Offset(0, 4.h))]),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 40.w)))))),
                SizedBox(height: 12.h),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(11, (i) {
                  final c = 5; final d = (i - c).abs();
                  final base = d <= 1 ? 20.h : d <= 3 ? 10.h : 5.h;
                  final h = _isPlaying ? base * (0.5 + 0.5 * _pulseCtrl.value) : base * 0.4;
                  return Container(width: d <= 1 ? 4.w : 3.w, height: h, margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: _isPlaying ? 0.8 : 0.3), borderRadius: BorderRadius.circular(2.r)));
                })),
              ]))),
            SizedBox(height: 8.h),
            Text(_isPlaying ? 'Đang phát âm...' : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại' : 'Nhấn nút để nghe phát âm',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _isPlaying ? AppColors.primary : AppColors.textHint)),
            SizedBox(height: 14.h),
          ])))),
    ]);
  }
}
