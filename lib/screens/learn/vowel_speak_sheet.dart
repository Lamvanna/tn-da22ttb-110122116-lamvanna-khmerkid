import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../models/khmer_vowel.dart';

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
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) { if (mounted) setState(() => _statusMsg = 'Cần cấp quyền microphone!'); return; }
    try {
      _sttReady = await _speech.initialize(
        onError: (err) { if (mounted && _isListening) { _pulseCtrl.stop(); setState(() { _isListening = false; if (_recognized.isEmpty) { _statusMsg = 'Không nghe được. Hãy nói to hơn!'; } else { _evaluate(); } }); } },
        onStatus: (status) { if (status == 'done' && mounted && _isListening) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } },
      );
      if (_sttReady) {
        final locales = await _speech.locales();
        for (final l in locales) { if (l.localeId.toLowerCase().startsWith('vi')) { _selectedLocaleId = l.localeId; break; } }
        if (_selectedLocaleId == 'vi-VN') { for (final l in locales) { if (l.localeId.toLowerCase().startsWith('km')) { _selectedLocaleId = l.localeId; break; } } }
      }
    } catch (e) { _sttReady = false; }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _speech.stop(); _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; _isPlayingExample = false; });
    _pulseCtrl.repeat(reverse: true);
    try {
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
        decoration: const BoxDecoration(color: Color(0xFFFFF8E1), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(24, 12, 24, 24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFD7CCC8), borderRadius: BorderRadius.circular(2)))),
          Center(child: Text('Tập nói phát âm', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5D4037)))),
          const SizedBox(height: 14),
          if (!_hasResult) ...[
            // Character circle
            Center(child: Container(width: 110, height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)]),
                boxShadow: [BoxShadow(color: const Color(0xFF42A5F5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
              child: Center(child: Text(widget.vowel.character, style: GoogleFonts.kantumruyPro(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1))))),
            const SizedBox(height: 8),
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0D5C5)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
              child: Text(widget.vowel.romanized, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF5D4037))))),
            const SizedBox(height: 14),
            // Stars placeholder
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.star_outline_rounded, size: 30, color: Color(0xFFE0D5C5))))),
            const SizedBox(height: 14),
            // Listen example
            Center(child: GestureDetector(
              onTap: !_isPlayingExample && !_isListening ? _playExample : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isPlayingExample ? Icons.volume_up_rounded : Icons.headphones_rounded, color: const Color(0xFF7E57C2), size: 18),
                  const SizedBox(width: 6),
                  Text(_isPlayingExample ? 'Đang phát...' : 'Nghe mẫu trước', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF7E57C2))),
                ])))),
            const SizedBox(height: 18),
            // Mic with wave bars
            Center(child: GestureDetector(
              onTap: _sttReady && !_isListening ? _startListening : null,
              child: AnimatedBuilder(animation: _pulseCtrl, builder: (context, child) => SizedBox(width: 200, height: 100,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  ...List.generate(4, (i) {
                    final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                    return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: _isListening ? Color.lerp(const Color(0xFFEF5350), const Color(0xFFFFC107), i / 3.0)! : const Color(0xFFD7CCC8), borderRadius: BorderRadius.circular(4)));
                  }).reversed.toList(),
                  const SizedBox(width: 6),
                  Container(
                    width: _isListening ? 80 + 8 * _pulseCtrl.value : 76,
                    height: _isListening ? 80 + 8 * _pulseCtrl.value : 76,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: _isListening ? [const Color(0xFFEF5350), const Color(0xFFC62828)]
                          : !_sttReady ? [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]
                          : [const Color(0xFF66BB6A), const Color(0xFF388E3C)]),
                      boxShadow: [if (_sttReady) BoxShadow(color: (_isListening ? const Color(0xFFEF5350) : const Color(0xFF4CAF50)).withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))]),
                    child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36)),
                  const SizedBox(width: 6),
                  ...List.generate(4, (i) {
                    final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                    return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: _isListening ? Color.lerp(const Color(0xFFEF5350), const Color(0xFF42A5F5), i / 3.0)! : const Color(0xFFD7CCC8), borderRadius: BorderRadius.circular(4)));
                  }),
                ]))))),
            const SizedBox(height: 8),
            Center(child: Text(
              !_sttReady ? 'Đang khởi tạo...' : _isListening ? (_recognized.isNotEmpty ? '"$_recognized"' : 'Đang nghe...') : _statusMsg.isNotEmpty ? _statusMsg : 'Bé nhấn để nói',
              textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: _isListening ? const Color(0xFFEF5350) : const Color(0xFF8D6E63)))),
            if (_statusMsg.contains('Không') && !_isListening) ...[
              const SizedBox(height: 10),
              Center(child: GestureDetector(onTap: () => setState(() => _statusMsg = ''),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFA726), borderRadius: BorderRadius.circular(20)),
                  child: Text('Thử lại', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))))),
            ],
          ],
          // Result
          if (_hasResult) ...[
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(children: [
                Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: _isCorrect ? [const Color(0xFF81C784), const Color(0xFF43A047)] : [const Color(0xFFEF9A9A), const Color(0xFFEF5350)])),
                  child: Center(child: Text(widget.vowel.character, style: GoogleFonts.kantumruyPro(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)))),
                const SizedBox(height: 12),
                Text(_isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: _isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
                const SizedBox(height: 4),
                Text(_isCorrect ? 'Phát âm rất tốt!' : 'Hãy thử lại nhé!', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF8D6E63))),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(i < _score ~/ 2 ? Icons.star_rounded : Icons.star_outline_rounded, size: 40, color: i < _score ~/ 2 ? const Color(0xFFFFC107) : const Color(0xFFE0D5C5)))),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
                  child: RichText(text: TextSpan(style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF757575)), children: [
                    const TextSpan(text: 'Nghe được: '),
                    TextSpan(text: '"$_recognized"', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5D4037))),
                  ]))),
                if (_isCorrect) ...[
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14)),
                    child: Text('+10 XP ⭐', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFFFA726)))),
                ],
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() { _hasResult = false; _recognized = ''; _statusMsg = ''; _score = 0; }),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFA726))),
                      child: Center(child: Text('Thử lại', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFFFA726))))))),
                  if (_isCorrect) ...[
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Text('Hoàn thành ✅', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)))))),
                  ],
                ]),
              ])),
          ],
        ]),
      ),
    );
  }
}
