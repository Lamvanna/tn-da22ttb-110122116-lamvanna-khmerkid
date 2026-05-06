import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';
import '../../models/khmer_number.dart';
import '../../services/score_service.dart';

/// Màn hình Kiểm tra — Bài kiểm tra tổng hợp
/// 3 lựa chọn: Nhanh (5 câu), Standard (10 câu), Thử thách (20 câu)
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _started = false;
  int _difficulty = 1; // 0=easy, 1=normal, 2=hard

  int get _totalQ {
    switch (_difficulty) {
      case 0: return 5;
      case 2: return 20;
      default: return 10;
    }
  }

  final _rng = Random();
  List<_TestQ> _questions = [];
  int _qIdx = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;

  void _start() {
    _questions = _genQuestions(_totalQ);
    setState(() {
      _started = true;
      _qIdx = 0;
      _correct = 0;
      _selected = null;
      _answered = false;
    });
  }

  List<_TestQ> _genQuestions(int count) {
    final qs = <_TestQ>[];
    final letters = KhmerLetterData.consonants;
    final numbers = KhmerNumberData.numbers;

    // 70% chữ cái, 30% số
    final letterCount = (count * 0.7).ceil();
    final numberCount = count - letterCount;

    for (int i = 0; i < letterCount; i++) {
      final type = _rng.nextBool();
      if (type) {
        // Chữ Khmer → phiên âm
        final c = letters[_rng.nextInt(letters.length)];
        final wrong = letters.where((l) => l.character != c.character).toList()..shuffle(_rng);
        final opts = [c.romanized, ...wrong.take(3).map((l) => l.romanized)];
        opts.shuffle(_rng);
        qs.add(_TestQ(
          q: 'Chữ "${c.character}" đọc là?',
          options: opts,
          answer: c.romanized,
        ));
      } else {
        // Phiên âm → chữ Khmer
        final c = letters[_rng.nextInt(letters.length)];
        final wrong = letters.where((l) => l.character != c.character).toList()..shuffle(_rng);
        final opts = [c.character, ...wrong.take(3).map((l) => l.character)];
        opts.shuffle(_rng);
        qs.add(_TestQ(
          q: '"${c.romanized}" là chữ nào?',
          options: opts,
          answer: c.character,
        ));
      }
    }

    for (int i = 0; i < numberCount; i++) {
      final n = numbers[_rng.nextInt(numbers.length)];
      final wrong = numbers.where((x) => x.character != n.character).toList()..shuffle(_rng);
      final opts = [n.value, ...wrong.take(3).map((x) => x.value)];
      opts.shuffle(_rng);
      qs.add(_TestQ(
        q: 'Số "${n.character}" bằng bao nhiêu?',
        options: opts,
        answer: n.value,
      ));
    }

    qs.shuffle(_rng);
    return qs;
  }

  void _answer(int idx) {
    if (_answered) return;
    final q = _questions[_qIdx];
    final ok = q.options[idx] == q.answer;
    setState(() {
      _selected = idx;
      _answered = true;
      if (ok) _correct++;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_qIdx >= _questions.length - 1) {
        _showResult();
      } else {
        setState(() {
          _qIdx++;
          _selected = null;
          _answered = false;
        });
      }
    });
  }

  void _showResult() async {
    final pct = (_correct / _questions.length * 100).toInt();
    int stars = pct >= 90 ? 3 : pct >= 70 ? 2 : pct >= 50 ? 1 : 0;

    // Lưu kết quả kiểm tra
    try {
      final score = await ScoreService.getInstance();
      await score.completeTest(
        correct: _correct,
        total: _questions.length,
        difficulty: _difficulty,
      );
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stars >= 2 ? '🎉' : '📝', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('Kết quả bài kiểm tra',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: const Color(0xFF37474F))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFD54F),
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Text('$_correct/${_questions.length} câu đúng ($pct%)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: const Color(0xFF616161))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _started = false);
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFF5B9CF5))),
                      child: Text('Về lại',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700,
                              color: const Color(0xFF5B9CF5))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _start();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B9CF5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('Làm lại',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: _started ? _buildTest() : _buildMenu(),
    );
  }

  // ═══════ MENU CHỌN ĐỘ KHÓ ═══════
  Widget _buildMenu() {
    return Column(
      children: [
        _buildMenuHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text('Chọn độ khó',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF37474F))),
                const SizedBox(height: 20),

                _buildDiffCard(
                  title: 'Dễ',
                  sub: '5 câu hỏi • Thời gian thoải mái',
                  emoji: '😊',
                  color: const Color(0xFF66BB6A),
                  level: 0,
                ),
                const SizedBox(height: 12),
                _buildDiffCard(
                  title: 'Trung bình',
                  sub: '10 câu hỏi • Chữ + Số',
                  emoji: '💪',
                  color: const Color(0xFFFFA726),
                  level: 1,
                ),
                const SizedBox(height: 12),
                _buildDiffCard(
                  title: 'Thử thách',
                  sub: '20 câu hỏi • Tổng hợp',
                  emoji: '🔥',
                  color: const Color(0xFFEF5350),
                  level: 2,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B9CF5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text('Bắt đầu kiểm tra',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiffCard({
    required String title,
    required String sub,
    required String emoji,
    required Color color,
    required int level,
  }) {
    final selected = _difficulty == level;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E0E0),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(sub,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF757575))),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF5B9CF5), Color(0xFF3F7FE0)]),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text('📝 Kiểm tra',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════ BÀI KIỂM TRA ═══════
  Widget _buildTest() {
    final q = _questions[_qIdx];
    return Column(
      children: [
        _buildTestHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Câu ${_qIdx + 1}/${_questions.length}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575))),
                    Text('Đúng: $_correct',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4CAF50))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_qIdx + 1) / _questions.length,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF5B9CF5)),
                  ),
                ),
                const SizedBox(height: 24),

                // Câu hỏi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(q.q,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: const Color(0xFF37474F))),
                ),
                const SizedBox(height: 20),

                // 4 đáp án
                ...List.generate(q.options.length, (i) {
                  final isCorrect = q.options[i] == q.answer;
                  final isSelected = _selected == i;
                  final ok = _answered && isCorrect;
                  final wrong = _answered && isSelected && !isCorrect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _answered ? null : () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: ok
                              ? const Color(0xFFE8F5E9)
                              : wrong
                                  ? const Color(0xFFFFEBEE)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: ok
                                ? const Color(0xFF4CAF50)
                                : wrong
                                    ? const Color(0xFFEF5350)
                                    : const Color(0xFFE0E0E0),
                            width: ok || wrong ? 2.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: ok
                                    ? const Color(0xFF4CAF50)
                                    : wrong
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFF5B9CF5).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: ok || wrong
                                    ? Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                                        color: Colors.white, size: 16)
                                    : Text(String.fromCharCode(65 + i),
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF5B9CF5))),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(q.options[i],
                                  style: q.options[i].length <= 2
                                      ? GoogleFonts.kantumruyPro(
                                          fontSize: 24,
                                          color: const Color(0xFF3E2C6E))
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF37474F))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF5B9CF5), Color(0xFF3F7FE0)]),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _started = false),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text('Kiểm tra',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestQ {
  final String q;
  final List<String> options;
  final String answer;
  _TestQ({required this.q, required this.options, required this.answer});
}
