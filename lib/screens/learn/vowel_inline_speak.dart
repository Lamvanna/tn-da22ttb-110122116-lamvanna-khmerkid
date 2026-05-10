import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';

class VowelInlineSpeakContent extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelInlineSpeakContent({super.key, required this.vowel, required this.onComplete});
  @override
  State<VowelInlineSpeakContent> createState() => _S();
}

class _S extends State<VowelInlineSpeakContent> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;
  bool _sttReady = false, _isListening = false, _hasResult = false, _isCorrect = false;
  String _recognized = '', _statusMsg = '', _selectedLocaleId = 'vi-VN';
  int _accuracy = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _initTts(); _initSTT();
  }

  Future<void> _initTts() async {
    final langs = await _tts.getLanguages;
    final list = (langs as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKm = list.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKm ? 'km' : list.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.4); await _tts.setVolume(1.0);
  }

  Future<void> _initSTT() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) { if (mounted) setState(() => _statusMsg = 'Cần cấp quyền mic!'); return; }
    try {
      _sttReady = await _speech.initialize(
        onError: (e) { if (mounted && _isListening) { _pulseCtrl.stop(); setState(() { _isListening = false; if (_recognized.isEmpty) _statusMsg = 'Không nghe được. Nói to hơn!'; else _evaluate(); }); } },
        onStatus: (s) { if (s == 'done' && mounted && _isListening) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } },
      );
      if (_sttReady) { final locs = await _speech.locales(); for (final l in locs) { if (l.localeId.toLowerCase().startsWith('vi')) { _selectedLocaleId = l.localeId; break; } } }
    } catch (_) { _sttReady = false; }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _speech.stop(); _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; });
    _pulseCtrl.repeat(reverse: true);
    try {
      await _speech.listen(
        onResult: (r) { if (mounted) { setState(() => _recognized = r.recognizedWords); if (r.finalResult) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } } },
        listenFor: const Duration(seconds: 10), pauseFor: const Duration(seconds: 4), localeId: _selectedLocaleId,
      );
    } catch (_) { _pulseCtrl.stop(); if (mounted) setState(() { _isListening = false; _statusMsg = 'Lỗi. Thử lại!'; }); }
  }

  Future<void> _stopListening() async { _pulseCtrl.stop(); await _speech.stop(); if (mounted) { setState(() => _isListening = false); _evaluate(); } }

  void _evaluate() {
    if (_hasResult) return;
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) { setState(() => _statusMsg = 'Không nhận diện được. Nói to hơn!'); return; }
    String n(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final sn = n(spoken);
    final targets = [widget.vowel.romanized, widget.vowel.pronunciation, widget.vowel.character].where((t) => t.isNotEmpty).map(n).toList();
    bool exact = targets.any((t) => sn.contains(t) || t.contains(sn));
    if (exact) { _accuracy = 100; _isCorrect = true; } else {
      double best = 0;
      for (final t in targets) { final s = _sim(sn, t); if (s > best) best = s; }
      _accuracy = (best * 100).round().clamp(0, 99);
      _isCorrect = _accuracy >= 30;
    }
    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();
  }

  double _sim(String a, String b) { if (a.isEmpty || b.isEmpty) return 0; final mx = a.length > b.length ? a.length : b.length; int m = a.length, nn = b.length;
    final d = List.generate(m + 1, (_) => List.filled(nn + 1, 0));
    for (int i = 0; i <= m; i++) d[i][0] = i; for (int j = 0; j <= nn; j++) d[0][j] = j;
    for (int i = 1; i <= m; i++) for (int j = 1; j <= nn; j++) { final c = a[i-1] == b[j-1] ? 0 : 1; d[i][j] = [d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+c].reduce((a,b) => a<b?a:b); }
    return 1.0 - (d[m][nn] / mx); }

  Future<void> _playExample() async { final t = widget.vowel.pronunciation.isNotEmpty ? widget.vowel.pronunciation : widget.vowel.romanized; await _tts.speak(t); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mic_rounded, color: AppColors.coral, size: 20.w), SizedBox(width: 8.w),
          Text('Nói phát âm', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.coralDark)),
        ])),
      Expanded(child: Align(alignment: const Alignment(0, -0.35),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 120.w, height: 120.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.coralSurface,
                boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.12), blurRadius: 24.r, spreadRadius: 4)]),
              child: Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(
                fontSize: 64.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.1)))),
            SizedBox(height: 10.h),
            GestureDetector(onTap: _playExample,
              child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(color: AppColors.coralSurface, borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up_rounded, size: 14.sp, color: AppColors.coral), SizedBox(width: 6.w),
                  Text('Phát âm: "${widget.vowel.romanized}"', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.coralDark)),
                ]))),
            SizedBox(height: 18.h),
            GestureDetector(
              onLongPressStart: _sttReady && !_isListening ? (_) => _startListening() : null,
              onLongPressEnd: _isListening ? (_) => _stopListening() : null,
              child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Column(children: [
                Container(width: 140.w, height: 140.w,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppColors.coral.withValues(alpha: _isListening ? 0.5 : 0.25), width: 1.5.w, strokeAlign: BorderSide.strokeAlignOutside)),
                  child: Center(child: Container(width: 120.w, height: 120.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.coralSurface),
                    child: Center(child: Container(width: 90.w, height: 90.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: _isListening ? [AppColors.coral, AppColors.coralDark] : [AppColors.coralLight, AppColors.coral]),
                        boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.3 + (_isListening ? 0.25 * _pulseCtrl.value : 0)),
                          blurRadius: (16 + (_isListening ? 12 * _pulseCtrl.value : 0)).r, offset: Offset(0, 4.h))]),
                      child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40.w)))))),
                SizedBox(height: 12.h),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(11, (i) {
                  final c = 5; final dd = (i - c).abs();
                  final base = dd <= 1 ? 20.h : dd <= 3 ? 10.h : 5.h;
                  final h = _isListening ? base * (0.5 + 0.5 * _pulseCtrl.value) : base * 0.4;
                  return Container(width: dd <= 1 ? 4.w : 3.w, height: h, margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: _isListening ? 0.8 : 0.3), borderRadius: BorderRadius.circular(2.r)));
                })),
              ]))),
            SizedBox(height: 8.h),
            if (_hasResult)
              Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(color: _isCorrect ? AppColors.tertiarySurface : AppColors.coralSurface, borderRadius: BorderRadius.circular(14.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isCorrect ? '🎉' : '😅', style: TextStyle(fontSize: 16.sp)), SizedBox(width: 6.w),
                  Text('$_accuracy%', style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _isCorrect ? AppColors.tertiaryDark : AppColors.coralDark)),
                  SizedBox(width: 6.w),
                  Text(_isCorrect ? 'Chính xác!' : 'Thử lại!', style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _isCorrect ? AppColors.tertiaryDark : AppColors.coralDark)),
                ]))
            else
              Text(_isListening ? 'Đang thu âm... Bỏ tay để kết thúc' : _statusMsg.isNotEmpty ? _statusMsg : !_sttReady ? 'Đang khởi tạo...' : 'Nhấn giữ mic và đọc "${widget.vowel.romanized}"',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _isListening ? AppColors.coral : AppColors.textHint)),
            SizedBox(height: 14.h),
          ])))),
    ]);
  }
}
