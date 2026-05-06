import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_spelling.dart';
import '../../widgets/app_header.dart';

/// Trang đánh vần — Ghép phụ âm + nguyên âm thành âm tiết
class SpellingScreen extends StatefulWidget {
  final int initialIndex;
  const SpellingScreen({super.key, this.initialIndex = 0});
  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final List<KhmerSpelling> _lessons = KhmerSpellingData.lessons;
  final FlutterTts _tts = FlutterTts();
  late int _current;
  final Set<int> _completedSteps = {}; // 0=nghe, 1=nói, 2=viết
  bool _isListening = false;
  String _sttResult = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  KhmerSpelling get _lesson => _lessons[_current];
  int get _doneCount => _lessons.where((l) => l.isLearned).length;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
    await _tts.setSpeechRate(0.35);
    await _tts.setVolume(1.0);
  }


  void _speak(String text) => _tts.speak(text);

  bool _isStepDone(int s) => _completedSteps.contains(s);
  void _markStep(int s) => setState(() => _completedSteps.add(s));


  void _next() {
    if (_current < _lessons.length - 1) {
      setState(() {
        _current++;
        _completedSteps.clear();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _completedSteps.clear();
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _lessons.isEmpty ? 0.0 : (_current + 1) / _lessons.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AppHeader(
          title: '✏️ Đánh vần',
          subtitle: '$_doneCount/${_lessons.length} bài đã học',
          onBack: () => Navigator.pop(context),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)),
            child: Text('${(_current + 1)}/${_lessons.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(children: [
            Row(children: [
              Text('Bài ${_current + 1}', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
            ]),
            const SizedBox(height: 6),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tertiary, AppColors.tertiaryLight]),
                    borderRadius: BorderRadius.circular(4)))),
            ),
          ]),
        ),
        // Content
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(children: [
            _buildSpellingCard(),
            const SizedBox(height: 16),
            _buildActionRow(),
            const SizedBox(height: 20),
            _buildStepProgress(),
            const SizedBox(height: 16),
            _buildNavButtons(),

          ]),
        )),
      ]),
    );
  }

  // ═══════════ CARD đánh vần ═══════════
  Widget _buildSpellingCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(children: [
        // Gradient accent bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])),
          child: Text('Ghép phụ âm + nguyên âm', textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        // Formula
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildCharBox(_lesson.consonant, AppColors.primary, 'Phụ âm'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                  child: Center(child: Text('+',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textHint))))),
              _buildCharBox(_lesson.vowelSign, AppColors.coral, 'Nguyên âm'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                  child: Center(child: Text('=',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textHint))))),
              _buildCharBox(
                _lesson.combined,
                AppColors.tertiary,
                'Kết quả'),
            ]),
            const SizedBox(height: 18),
            // Listen button
            GestureDetector(
              onTap: () => _speak('${_lesson.consonant} ${_lesson.vowelSign} ${_lesson.combined}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                    child: Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 16)),
                  const SizedBox(width: 8),
                  Text('Nghe đánh vần',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                ]),
              ),
            ),
            if (_lesson.meaning.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('"${_lesson.romanized}" — ${_lesson.meaning}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildCharBox(String char, Color color, String label, {bool isResult = false}) {
    final isQuestion = isResult && char == '?';
    return Column(children: [
      Container(
        width: 66, height: 66,
        decoration: BoxDecoration(
          gradient: isQuestion ? null : LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.2)!,
              color,
              Color.lerp(color, Colors.black, 0.08)!]),
          color: isQuestion ? AppColors.surfaceContainerLow : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isQuestion ? AppColors.surfaceContainerHighest : Colors.white.withValues(alpha: 0.3),
            width: 2),
          boxShadow: [if (!isQuestion) BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10, offset: const Offset(0, 4))]),
        child: Center(
          child: Text(char,
            style: GoogleFonts.kantumruyPro(
              fontSize: char == '?' ? 30 : 28,
              fontWeight: FontWeight.w700,
              color: isQuestion ? AppColors.textHint : Colors.white))),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary)),
    ]);
  }

  // ═══════════ 3 BƯỚC: NGHE – NÓI – VIẾT ═══════════
  Widget _buildActionRow() {
    return Column(children: [
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: _showListenSheet,
          child: _actionBtn(
            icon: Icons.headphones_rounded, label: 'Nghe',
            sub: 'Phát âm mẫu', color: AppColors.tertiary, step: 0))),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: _showSpeakSheet,
          child: _actionBtn(
            icon: Icons.mic_rounded, label: 'Nói',
            sub: 'Luyện phát âm', color: AppColors.secondary, step: 1))),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _showWriteSheet,
        child: _actionBtn(
          icon: Icons.draw_rounded, label: 'Viết',
          sub: 'Tập viết chữ ghép', color: AppColors.coral, step: 2)),
    ]);
  }

  Widget _actionBtn({required IconData icon, required String label,
      required String sub, required Color color, required int step}) {
    final done = _isStepDone(step);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.12)!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 12, offset: const Offset(0, 5))]),
      child: Column(children: [
        Stack(alignment: Alignment.topRight, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 24)),
          if (done) Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
            child: Icon(Icons.check_rounded, size: 12, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(sub, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.75))),
      ]),
    );
  }

  // ═══════════ STEP PROGRESS ═══════════
  Widget _buildStepProgress() {
    final steps = ['Nghe', 'Nói', 'Viết'];
    final icons = [Icons.headphones_rounded, Icons.mic_rounded, Icons.draw_rounded];
    final colors = [AppColors.tertiary, AppColors.secondary, AppColors.coral];
    final allDone = _completedSteps.length >= 3;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: allDone ? AppColors.tertiary.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone ? AppColors.tertiary.withValues(alpha: 0.25) : AppColors.surfaceContainerHighest),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Row(children: [
          Icon(allDone ? Icons.emoji_events_rounded : Icons.checklist_rounded,
            color: allDone ? AppColors.tertiary : AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(allDone ? 'Hoàn thành tất cả!' : 'Tiến trình luyện tập',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: allDone ? AppColors.tertiary : AppColors.textPrimary)),
          const Spacer(),
          Text('${_completedSteps.length}/3',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: allDone ? AppColors.tertiary : AppColors.textHint)),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(3, (i) {
          final done = _isStepDone(i);
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: done ? colors[i].withValues(alpha: 0.1) : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done ? colors[i].withValues(alpha: 0.3) : Colors.transparent)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(done ? Icons.check_circle_rounded : icons[i],
                  size: 16, color: done ? colors[i] : AppColors.textHint),
                const SizedBox(width: 6),
                Text(steps[i], style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: done ? colors[i] : AppColors.textHint)),
              ]),
            ),
          ));
        })),
      ]),
    );
  }

  // ═══════════ NAV BUTTONS ═══════════
  Widget _buildNavButtons() {
    final hasPrev = _current > 0;
    final hasNext = _current < _lessons.length - 1;
    return Row(children: [
      if (hasPrev) Expanded(child: OutlinedButton.icon(
        onPressed: _prev,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text('Bài trước', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: AppColors.surfaceContainerHighest)))),
      if (hasPrev && hasNext) const SizedBox(width: 12),
      if (hasNext) Expanded(child: ElevatedButton.icon(
        onPressed: _next,
        icon: Text('Bài tiếp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        label: const Icon(Icons.arrow_forward_rounded, size: 18),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
    ]);
  }

  // ── NGHE ──
  void _showListenSheet() {
    _speak('${_lesson.consonant} ${_lesson.vowelSign} ${_lesson.combined}');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Gradient banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tertiary, AppColors.tertiaryLight]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2))),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 28)),
              const SizedBox(height: 10),
              Text('Nghe đánh vần', style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Lắng nghe cách ghép âm', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
          // ── Content ──
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), child: Column(children: [
            // Formula row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _sheetCharBox(_lesson.consonant, AppColors.primary),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textHint))),
                _sheetCharBox(_lesson.vowelSign, AppColors.coral),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textHint))),
                _sheetCharBox(_lesson.combined, AppColors.tertiary),
              ]),
            ),
            const SizedBox(height: 12),
            Text('"${_lesson.romanized}" — ${_lesson.meaning}',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _speak('${_lesson.consonant} ${_lesson.vowelSign} ${_lesson.combined}'),
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                label: Text('Nghe lại', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () { _markStep(0); Navigator.pop(context); },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text('Xong', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow, foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _sheetCharBox(String ch, Color c) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.withValues(alpha: 0.25))),
    child: Center(child: Text(ch, style: GoogleFonts.kantumruyPro(
      fontSize: 26, fontWeight: FontWeight.w700, color: c))));

  // ── NÓI ──
  void _showSpeakSheet() async {
    await Permission.microphone.request();
    if (!mounted) return;
    setState(() { _sttResult = ''; _isListening = false; });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Gradient banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryLight]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2))),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28)),
              const SizedBox(height: 10),
              Text('Nói đánh vần', style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Luyện phát âm chữ ghép', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
          // ── Content ──
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), child: Column(children: [
            // Target character
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                Text('Hãy đọc:', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(_lesson.combined, style: GoogleFonts.kantumruyPro(
                  fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text('"${_lesson.romanized}"', style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              ]),
            ),
            const SizedBox(height: 18),
            // Mic button
            GestureDetector(
              onTap: () async {
                if (_isListening) {
                  await _speech.stop();
                  setS(() => _isListening = false);
                  return;
                }
                final avail = await _speech.initialize();
                if (!avail) return;
                setS(() => _isListening = true);
                _speech.listen(
                  onResult: (r) => setS(() => _sttResult = r.recognizedWords),
                  listenFor: const Duration(seconds: 5),
                  localeId: 'km',
                );
                Future.delayed(const Duration(seconds: 5), () {
                  if (_isListening) { _speech.stop(); setS(() => _isListening = false); }
                });
              },
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _isListening
                    ? [AppColors.coral, AppColors.coralLight]
                    : [AppColors.secondary, AppColors.secondaryLight]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: (_isListening ? AppColors.coral : AppColors.secondary).withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 6))]),
                child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, size: 34)),
            ),
            const SizedBox(height: 12),
            Text(_isListening ? 'Đang nghe...' : (_sttResult.isEmpty ? 'Nhấn mic để nói' : 'Bạn nói: "$_sttResult"'),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () { _markStep(1); Navigator.pop(ctx); },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text('Hoàn thành', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          ])),
        ]),
      )),
    );
  }

  // ── VIẾT ──
  void _showWriteSheet() {
    _strokes.clear();
    _currentStroke.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Gradient banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.coral, AppColors.coralLight]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2))),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.draw_rounded, color: Colors.white, size: 28)),
              const SizedBox(height: 10),
              Text('Tập viết: ${_lesson.combined}', style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Viết theo nét chữ mẫu', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
          // ── Canvas ──
          Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), child: Column(children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.15), width: 2)),
              child: Stack(children: [
                Center(child: Text(_lesson.combined, style: GoogleFonts.kantumruyPro(
                  fontSize: 110, color: AppColors.coral.withValues(alpha: 0.07)))),
                GestureDetector(
                  onPanStart: (d) => setS(() => _currentStroke = [d.localPosition]),
                  onPanUpdate: (d) => setS(() => _currentStroke.add(d.localPosition)),
                  onPanEnd: (_) => setS(() { _strokes.add(List.from(_currentStroke)); _currentStroke = []; }),
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _StrokePainter(_strokes, _currentStroke))),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => setS(() { _strokes.clear(); _currentStroke.clear(); }),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Xóa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.coral.withValues(alpha: 0.4))))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () { _markStep(2); Navigator.pop(ctx); },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text('Xong', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          ])),
        ]),
      )),
    );
  }


  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Hoàn thành!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Bạn đã hoàn thành tất cả bài đánh vần!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (_) =>
                const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 32))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: Text('Quay về',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Colors.white)))),
          ]),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _StrokePainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) { _draw(canvas, s, paint); }
    _draw(canvas, current, paint);
  }

  void _draw(Canvas canvas, List<Offset> pts, Paint p) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
