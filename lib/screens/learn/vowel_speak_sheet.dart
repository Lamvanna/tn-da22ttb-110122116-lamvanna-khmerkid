import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';

/// Sheet luyện nói nguyên âm — RESPONSIVE + Plus Jakarta Sans
class VowelSpeakSheet extends StatefulWidget {
  final KhmerVowel vowel;
  final VoidCallback onComplete;
  const VowelSpeakSheet({super.key, required this.vowel, required this.onComplete});
  @override
  State<VowelSpeakSheet> createState() => _State();
}

class _State extends State<VowelSpeakSheet> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;
  bool _sttReady = false;
  bool _isListening = false;
  bool _isPlayingExample = false;
  String _recognized = '';
  String _statusMsg = '';
  bool _hasResult = false;
  bool _isCorrect = false;
  int _score = 0;
  String _selectedLocaleId = 'vi-VN';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _initTts();
    _initSTT();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    if (hasKhmer) { await _tts.setLanguage('km'); } else {
      final hasVi = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(hasVi ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _isPlayingExample = false); });
  }

  Future<void> _playExample() async {
    if (_isPlayingExample) return;
    setState(() => _isPlayingExample = true);
    final text = widget.vowel.pronunciation.isNotEmpty ? widget.vowel.pronunciation : widget.vowel.romanized;
    await _tts.speak(text);
  }

  Future<void> _initSTT() async {
    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _statusMsg = 'Quyền Mic bị chặn. Bé hãy bấm vào đây để mở Cài đặt!');
      return;
    }
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) { if (mounted) setState(() => _statusMsg = 'Cần cấp quyền microphone!'); return; }
    try {
      _sttReady = await _speech.initialize(
        onError: (err) { 
          debugPrint('[STT Error] $err');
          if (mounted && _isListening) { _pulseCtrl.stop(); setState(() { _isListening = false; if (_recognized.isEmpty) { _statusMsg = 'Không nghe được. Hãy nói to hơn!'; } else { _evaluate(); } }); } 
        },
        onStatus: (status) { if (status == 'done' && mounted && _isListening) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } },
      );
      if (_sttReady) {
        try {
          final systemLocale = await _speech.systemLocale();
          if (systemLocale != null) {
            _selectedLocaleId = systemLocale.localeId;
          }
          final locales = await _speech.locales();
          bool foundKhmer = false;
          for (final l in locales) {
            if (l.localeId.toLowerCase().startsWith('km')) {
              _selectedLocaleId = l.localeId;
              foundKhmer = true;
              break;
            }
          }
          if (!foundKhmer) {
            for (final l in locales) {
              if (l.localeId.toLowerCase().startsWith('vi')) {
                _selectedLocaleId = l.localeId;
                break;
              }
            }
          }
        } catch (localeErr) {
          debugPrint('STT Locales error: $localeErr');
          _selectedLocaleId = 'km-KH';
        }
      }
    } catch (e) {
      debugPrint('STT Init error: $e');
      _sttReady = false; 
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _speech.stop(); _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; _isPlayingExample = false; });
    _pulseCtrl.repeat(reverse: true);
    try {
      await _speech.stop();
      await _speech.listen(
        onResult: (result) {
          if (mounted) { setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); }
          }
        },
        listenFor: const Duration(seconds: 10), pauseFor: const Duration(seconds: 4), localeId: _selectedLocaleId,
      );
    } catch (e) { _pulseCtrl.stop(); if (mounted) setState(() { _isListening = false; _statusMsg = 'Lỗi nhận diện. Thử lại!'; }); }
  }

  Future<void> _stopListening() async {
    _pulseCtrl.stop();
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _evaluate();
    }
  }

  Future<void> _toggleListening() async {
    if (!_sttReady) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang khởi tạo lại bộ ghi âm giọng nói...')),
        );
      }
      await _initSTT();
      if (!_sttReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị chưa sẵn sàng cho Google Speech. Vui lòng thử lại!')),
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
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) { setState(() => _statusMsg = 'Không nhận diện được. Hãy nói to hơn!'); return; }
    String normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final spokenNorm = normalize(spoken);
    final targets = [widget.vowel.romanized, widget.vowel.pronunciation, widget.vowel.character].where((t) => t.isNotEmpty).map(normalize).toList();
    bool exact = targets.any((t) => spokenNorm.contains(t) || t.contains(spokenNorm));
    if (exact) { _score = 5; _isCorrect = true; } else {
      bool firstCharMatch = targets.any((t) => t.isNotEmpty && spokenNorm.isNotEmpty && t[0] == spokenNorm[0]);
      double best = 0;
      for (final t in targets) { final s = _sim(spokenNorm, t); if (s > best) best = s; }
      if (firstCharMatch) best = (best + 0.15).clamp(0.0, 1.0);
      if (best > 0.5) { _score = 4; _isCorrect = true; }
      else if (best > 0.3) { _score = 3; _isCorrect = true; }
      else if (best > 0.15) { _score = 2; _isCorrect = false; }
      else { _score = 1; _isCorrect = false; }
    }
    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();
  }

  double _sim(String a, String b) { if (a.isEmpty || b.isEmpty) return 0; final mx = a.length > b.length ? a.length : b.length; return 1.0 - (_lev(a, b) / mx); }
  int _lev(String s, String t) {
    final m = s.length, n = t.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) d[i][0] = i;
    for (int j = 0; j <= n; j++) d[0][j] = j;
    for (int i = 1; i <= m; i++) { for (int j = 1; j <= n; j++) { final c = s[i-1] == t[j-1] ? 0 : 1; d[i][j] = [d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+c].reduce((a, b) => a < b ? a : b); } }
    return d[m][n];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(color: AppColors.sheetWarm, borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
        child: ListView(controller: ctrl, padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h), children: [
          // Drag handle
          Center(child: Container(width: 48.w, height: 5.h, margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(color: AppColors.sheetWarmBorder, borderRadius: BorderRadius.circular(3.r)))),
          Center(child: Text('Tập nói phát âm', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.sheetBrown))),
          SizedBox(height: 14.h),
          if (!_hasResult) ...[
            // Character circle
            Center(child: Container(width: 110.w, height: 110.w,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.headerEnd, AppColors.headerAccent]),
                boxShadow: [BoxShadow(color: AppColors.headerAccent.withValues(alpha: 0.3), blurRadius: 16.r, offset: Offset(0, 6.h))]),
              child: Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 56.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1))))),
            SizedBox(height: 8.h),
            Center(child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: AppColors.sheetWarmBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4.r, offset: Offset(0, 2.h))]),
              child: Text(widget.vowel.romanized, style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.sheetBrown)))),
            SizedBox(height: 14.h),
            // Stars placeholder
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Padding(padding: EdgeInsets.symmetric(horizontal: 3.w), child: Icon(Icons.star_outline_rounded, size: 30.sp, color: AppColors.sheetWarmBorder)))),
            SizedBox(height: 14.h),
            // Listen example
            Center(child: GestureDetector(
              onTap: !_isPlayingExample && !_isListening ? _playExample : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(color: AppColors.violetSurface, borderRadius: BorderRadius.circular(20.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isPlayingExample ? Icons.volume_up_rounded : Icons.headphones_rounded, color: AppColors.violet, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(_isPlayingExample ? 'Đang phát...' : 'Nghe mẫu trước', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.violet)),
                ])))),
            SizedBox(height: 18.h),
            // Mic with wave bars
            Center(child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(animation: _pulseCtrl, builder: (context, child) => SizedBox(width: 200.w, height: 100.h,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  ...List.generate(4, (i) {
                    final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                    return Container(width: 4.w, height: h, margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(color: _isListening ? Color.lerp(AppColors.errorRed, AppColors.secondary, i / 3.0)! : AppColors.sheetWarmBorder, borderRadius: BorderRadius.circular(4.r)));
                  }).reversed.toList(),
                  SizedBox(width: 6.w),
                  Container(
                    width: _isListening ? 80.w + 8 * _pulseCtrl.value : 76.w,
                    height: _isListening ? 80.w + 8 * _pulseCtrl.value : 76.w,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: _isListening ? [AppColors.errorRed, AppColors.errorDark]
                          : !_sttReady ? [AppColors.textHint, AppColors.textSecondary]
                          : [AppColors.successLight, const Color(0xFF388E3C)]),
                      boxShadow: [if (_sttReady) BoxShadow(color: (_isListening ? AppColors.errorRed : AppColors.successGreen).withValues(alpha: 0.4), blurRadius: 18.r, offset: Offset(0, 6.h))]),
                    child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36.sp)),
                  SizedBox(width: 6.w),
                  ...List.generate(4, (i) {
                    final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                    return Container(width: 4.w, height: h, margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(color: _isListening ? Color.lerp(AppColors.errorRed, AppColors.headerAccent, i / 3.0)! : AppColors.sheetWarmBorder, borderRadius: BorderRadius.circular(4.r)));
                  }),
                ]))))),
            SizedBox(height: 8.h),
            Center(child: Text(
              !_sttReady ? 'Đang khởi tạo...' : _isListening ? (_recognized.isNotEmpty ? '"$_recognized"\n(Chạm để dừng)' : 'Đang nghe...\n(Chạm để dừng)') : _statusMsg.isNotEmpty ? _statusMsg : 'Bé chạm để nói',
              textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _isListening ? AppColors.errorRed : AppColors.sheetBrownLight))),
            if (_statusMsg.contains('Không') && !_isListening) ...[
              SizedBox(height: 10.h),
              Center(child: GestureDetector(onTap: () => setState(() => _statusMsg = ''),
                child: Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20.r)),
                  child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white))))),
            ],
          ],
          // Result
          if (_hasResult) ...[
            Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12.r, offset: Offset(0, 4.h))]),
              child: Column(children: [
                Container(width: 70.w, height: 70.w,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: _isCorrect ? [AppColors.successLighter, AppColors.successGreen] : [const Color(0xFFEF9A9A), AppColors.errorRed])),
                  child: Center(child: Text(widget.vowel.character, style: GoogleFonts.battambang(fontSize: 36.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)))),
                SizedBox(height: 12.h),
                Text(_isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác', style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: _isCorrect ? const Color(0xFF2E7D32) : AppColors.errorDark)),
                SizedBox(height: 4.h),
                Text(_isCorrect ? 'Phát âm rất tốt!' : 'Hãy thử lại nhé!', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.sheetBrownLight)),
                SizedBox(height: 14.h),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(i < _score ~/ 2 ? Icons.star_rounded : Icons.star_outline_rounded, size: 40.sp, color: i < _score ~/ 2 ? AppColors.secondary : AppColors.sheetWarmBorder))),
                SizedBox(height: 14.h),
                Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14.r)),
                  child: RichText(text: TextSpan(style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, color: AppColors.textSecondary), children: [
                    const TextSpan(text: 'Nghe được: '),
                    TextSpan(text: '"$_recognized"', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.sheetBrown)),
                  ]))),
                if (_isCorrect) ...[
                  SizedBox(height: 10.h),
                  Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14.r)),
                    child: Text('+10 XP ⭐', style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.secondary))),
                ],
                SizedBox(height: 18.h),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { _hasResult = false; _recognized = ''; _statusMsg = ''; _score = 0; }),
                    child: Container(padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.secondary)),
                      child: Center(child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.secondary)))))),
                  if (_isCorrect) ...[
                    SizedBox(width: 10.w),
                    Expanded(child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.successLight, AppColors.successGreen]), borderRadius: BorderRadius.circular(16.r)),
                        child: Center(child: Text('Hoàn thành ✅', style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)))))),
                  ],
                ]),
              ])),
          ],
        ]),
      ),
    );
  }
}
