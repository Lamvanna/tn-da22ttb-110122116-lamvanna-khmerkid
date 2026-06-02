import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import '../../services/scoring_service.dart';

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
    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _statusMsg = 'Quyền Mic bị chặn. Bé hãy bấm vào đây để mở Cài đặt!');
      return;
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) { if (mounted) setState(() => _statusMsg = 'Cần cấp quyền mic!'); return; }
    try {
      _sttReady = await _speech.initialize(
        onError: (e) {
          debugPrint('[STT Error] $e');
          if (mounted && _isListening) { _pulseCtrl.stop(); setState(() { _isListening = false; if (_recognized.isEmpty) _statusMsg = 'Không nghe được. Nói to hơn!'; else _evaluate(); }); }
        },
        onStatus: (s) { if (s == 'done' && mounted && _isListening) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } },
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
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; });
    _pulseCtrl.repeat(reverse: true);
    try {
      await _speech.stop();
      await _speech.listen(
        onResult: (r) { if (mounted) { setState(() => _recognized = r.recognizedWords); if (r.finalResult) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } } },
        listenFor: const Duration(seconds: 10), pauseFor: const Duration(seconds: 4), localeId: _selectedLocaleId,
      );
    } catch (_) { _pulseCtrl.stop(); if (mounted) setState(() { _isListening = false; _statusMsg = 'Lỗi. Thử lại!'; }); }
  }

  Future<void> _stopListening() async { _pulseCtrl.stop(); await _speech.stop(); if (mounted) { setState(() => _isListening = false); _evaluate(); } }

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
    final spoken = _recognized.trim();
    if (spoken.isEmpty) { setState(() => _statusMsg = 'Không nhận diện được. Nói to hơn!'); return; }
    final res = ScoringService.instance.scorePronunciation(
      spoken: spoken,
      character: widget.vowel.character,
      romanized: widget.vowel.romanized,
      pronunciation: widget.vowel.pronunciation,
      passThreshold: 30, // Nương tay với trẻ nhỏ
    );
    _accuracy = res.accuracy;
    _isCorrect = res.passed;
    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();
  }

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
              child: Center(child: Text(widget.vowel.displayCharacter, style: GoogleFonts.battambang(
                fontSize: 64.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.1)))),
            SizedBox(height: 10.h),
            GestureDetector(onTap: _playExample,
              child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(color: AppColors.coralSurface, borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up_rounded, size: 14.sp, color: AppColors.coral), SizedBox(width: 6.w),
                  Text('Phát âm: "${widget.vowel.pronunciation}"', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.coralDark)),
                ]))),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: _toggleListening,
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
              Text(_isListening ? 'Đang thu âm... Chạm để dừng' : _statusMsg.isNotEmpty ? _statusMsg : !_sttReady ? 'Đang khởi tạo...' : 'Chạm mic và đọc "${widget.vowel.pronunciation}"',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _isListening ? AppColors.coral : AppColors.textHint)),
            SizedBox(height: 14.h),
          ])))),
    ]);
  }
}
