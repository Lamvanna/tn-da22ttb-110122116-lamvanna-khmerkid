import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';
import '../../models/khmer_number.dart';

/// Đố vui — Câu đố tổng hợp về chữ và số Khmer
/// Dạng trắc nghiệm 4 đáp án, mỗi lượt 10 câu
class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  final _rng = Random();
  int _score = 0;
  int _qIdx = 0;
  int _correct = 0;
  final int _total = 10;
  late List<_QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
  }

  List<_QuizQuestion> _generateQuestions() {
    final questions = <_QuizQuestion>[];
    final letters = KhmerLetterData.consonants;
    final numbers = KhmerNumberData.numbers;

    // Tạo câu hỏi về chữ cái
    for (int i = 0; i < 6; i++) {
      final correct = letters[_rng.nextInt(letters.length)];
      final wrongSet = letters
          .where((l) => l.character != correct.character)
          .toList()
        ..shuffle(_rng);
      final options = [correct.romanized, ...wrongSet.take(3).map((l) => l.romanized)];
      options.shuffle(_rng);

      questions.add(_QuizQuestion(
        question: 'Chữ "${correct.character}" đọc là gì?',
        options: options,
        correctAnswer: correct.romanized,
        category: 'Chữ cái',
        emoji: '🔤',
      ));
    }

    // Tạo câu hỏi về số
    for (int i = 0; i < 2; i++) {
      final correct = numbers[_rng.nextInt(numbers.length)];
      final wrongSet = numbers
          .where((n) => n.character != correct.character)
          .toList()
        ..shuffle(_rng);
      final options = [correct.value, ...wrongSet.take(3).map((n) => n.value)];
      options.shuffle(_rng);

      questions.add(_QuizQuestion(
        question: 'Số "${correct.character}" có giá trị bằng bao nhiêu?',
        options: options,
        correctAnswer: correct.value,
        category: 'Số',
        emoji: '🔢',
      ));
    }

    // Câu hỏi ngược (từ phiên âm → chữ)
    for (int i = 0; i < 2; i++) {
      final correct = letters[_rng.nextInt(letters.length)];
      final wrongSet = letters
          .where((l) => l.character != correct.character)
          .toList()
        ..shuffle(_rng);
      final options = [
        correct.character,
        ...wrongSet.take(3).map((l) => l.character)
      ];
      options.shuffle(_rng);

      questions.add(_QuizQuestion(
        question: 'Phiên âm "${correct.romanized}" là chữ nào?',
        options: options,
        correctAnswer: correct.character,
        category: 'Nhận diện',
        emoji: '👀',
      ));
    }

    questions.shuffle(_rng);
    return questions.take(_total).toList();
  }

  int? _selectedIdx;
  bool _answered = false;

  void _onSelect(int idx) {
    if (_answered) return;
    final q = _questions[_qIdx];
    final isCorrect = q.options[idx] == q.correctAnswer;

    setState(() {
      _selectedIdx = idx;
      _answered = true;
      if (isCorrect) {
        _score += 10;
        _correct++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_qIdx >= _total - 1) {
        _showResult();
      } else {
        setState(() {
          _qIdx++;
          _selectedIdx = null;
          _answered = false;
        });
      }
    });
  }

  void _showResult() {
    final pct = (_correct / _total * 100).toInt();
    String emoji, msg;
    if (pct >= 90) {
      emoji = '🏆';
      msg = 'Xuất sắc! Bạn thật giỏi!';
    } else if (pct >= 70) {
      emoji = '🎉';
      msg = 'Rất tốt! Cố gắng thêm nhé!';
    } else if (pct >= 50) {
      emoji = '👍';
      msg = 'Khá tốt! Luyện tập thêm nhé!';
    } else {
      emoji = '📚';
      msg = 'Cần ôn tập thêm!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF37474F))),
              const SizedBox(height: 12),
              // Thống kê
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCol('$_correct/$_total', 'Đúng'),
                    Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                    _statCol('$pct%', 'Tỉ lệ'),
                    Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                    _statCol('$_score', 'Điểm'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFF7E57C2))),
                      child: Text('Thoát',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7E57C2))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _score = 0;
                          _qIdx = 0;
                          _correct = 0;
                          _selectedIdx = null;
                          _answered = false;
                          _questions = _generateQuestions();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCA28),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('Chơi lại',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5D4037))),
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

  Widget _statCol(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF37474F))),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9E9E))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_qIdx];
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress
                  _buildProgress(),
                  const SizedBox(height: 20),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCA28).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${q.emoji} ${q.category}',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF57F17))),
                  ),
                  const SizedBox(height: 16),

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
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(q.question,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF37474F))),
                  ),
                  const SizedBox(height: 20),

                  // 4 đáp án
                  ...List.generate(q.options.length, (i) {
                    final isCorrect = q.options[i] == q.correctAnswer;
                    final isSelected = _selectedIdx == i;
                    final showGreen = _answered && isCorrect;
                    final showRed = _answered && isSelected && !isCorrect;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: _answered ? null : () => _onSelect(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: showGreen
                                ? const Color(0xFFE8F5E9)
                                : showRed
                                    ? const Color(0xFFFFEBEE)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: showGreen
                                  ? const Color(0xFF4CAF50)
                                  : showRed
                                      ? const Color(0xFFEF5350)
                                      : const Color(0xFFE0E0E0),
                              width: showGreen || showRed ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Ký hiệu A B C D
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: showGreen
                                      ? const Color(0xFF4CAF50)
                                      : showRed
                                          ? const Color(0xFFEF5350)
                                          : const Color(0xFFFFCA28)
                                              .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: showGreen || showRed
                                      ? Icon(
                                          showGreen
                                              ? Icons.check_rounded
                                              : Icons.close_rounded,
                                          color: Colors.white,
                                          size: 18)
                                      : Text(
                                          String.fromCharCode(65 + i),
                                          style: GoogleFonts.nunito(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFF57F17)),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(q.options[i],
                                    style: q.options[i].length <= 2
                                        ? GoogleFonts.kantumruyPro(
                                            fontSize: 24,
                                            color: const Color(0xFF3E2C6E))
                                        : GoogleFonts.nunito(
                                            fontSize: 18,
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFFFCA28), Color(0xFFF57F17)]),
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text('Đố vui Khmer',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('⭐ $_score',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Câu ${_qIdx + 1}/$_total',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF757575))),
            Text('Đúng: $_correct',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_qIdx + 1) / _total,
            minHeight: 8,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFCA28)),
          ),
        ),
      ],
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String category;
  final String emoji;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.emoji,
  });
}
