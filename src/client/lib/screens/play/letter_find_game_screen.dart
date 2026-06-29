import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';

/// Trò chơi chữ — Nghe/đọc phiên âm, chọn đúng chữ Khmer
/// Mỗi câu hỏi: hiển thị phiên âm, chọn 1 trong 4 ký tự Khmer
class LetterFindGameScreen extends StatefulWidget {
  const LetterFindGameScreen({super.key});

  @override
  State<LetterFindGameScreen> createState() => _LetterFindGameScreenState();
}

class _LetterFindGameScreenState extends State<LetterFindGameScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  int _score = 0;
  int _questionNum = 0;
  final int _totalQuestions = 10;
  int _correctCount = 0;

  late KhmerLetter _correctLetter;
  late List<KhmerLetter> _options;
  int? _selectedIdx;
  bool _answered = false;

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final all = List<KhmerLetter>.from(KhmerLetterData.consonants);
    all.shuffle(_rng);

    _correctLetter = all.first;
    _options = [_correctLetter];

    // Thêm 3 lựa chọn sai
    final others = all.where((l) => l.character != _correctLetter.character).toList();
    others.shuffle(_rng);
    _options.addAll(others.take(3));
    _options.shuffle(_rng);

    setState(() {
      _selectedIdx = null;
      _answered = false;
      _questionNum++;
    });
  }

  void _onSelect(int idx) {
    if (_answered) return;

    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });

    final isCorrect = _options[idx].character == _correctLetter.character;
    if (isCorrect) {
      _score += 10;
      _correctCount++;
    } else {
      _shakeCtrl.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_questionNum >= _totalQuestions) {
        _showFinalResult();
      } else {
        _generateQuestion();
      }
    });
  }

  void _showFinalResult() {
    final pct = (_correctCount / _totalQuestions * 100).toInt();
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
              Text(pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '📚',
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Kết quả',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF37474F))),
              const SizedBox(height: 8),
              Text('$_correctCount/$_totalQuestions đúng ($pct%)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF616161))),
              const SizedBox(height: 4),
              Text('Tổng điểm: $_score ⭐',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFA726))),
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
                          style: GoogleFonts.plusJakartaSans(
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
                          _questionNum = 0;
                          _correctCount = 0;
                        });
                        _generateQuestion();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('Chơi lại',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
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
      backgroundColor: const Color(0xFFF0FFF0),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Thanh tiến trình
                  _buildProgressBar(),
                  const SizedBox(height: 24),

                  // Câu hỏi
                  _buildQuestion(),
                  const SizedBox(height: 24),

                  // 4 lựa chọn
                  _buildOptions(),
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
            colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
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
                child: Text('Trò chơi chữ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('⭐ $_score',
                    style: GoogleFonts.plusJakartaSans(
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

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Câu $_questionNum/$_totalQuestions',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF757575))),
            Text('Đúng: $_correctCount',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _questionNum / _totalQuestions,
            minHeight: 8,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
      child: Column(
        children: [
          Text('Tìm chữ cái Khmer có phiên âm:',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('"${_correctLetter.romanized}"',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7E57C2))),
          ),
          if (_correctLetter.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Gợi ý: ${_correctLetter.meaning}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBDBDBD))),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final option = _options[index];
        final isCorrectOption = option.character == _correctLetter.character;
        final isSelected = _selectedIdx == index;
        final showCorrect = _answered && isCorrectOption;
        final showWrong = _answered && isSelected && !isCorrectOption;

        return GestureDetector(
          onTap: _answered ? null : () => _onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: showCorrect
                  ? const Color(0xFFE8F5E9)
                  : showWrong
                      ? const Color(0xFFFFEBEE)
                      : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: showCorrect
                    ? const Color(0xFF4CAF50)
                    : showWrong
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFE0E0E0),
                width: showCorrect || showWrong ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(option.character,
                      style: GoogleFonts.battambang(
                          fontSize: 42,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3E2C6E))),
                  if (_answered) ...[
                    const SizedBox(height: 4),
                    Icon(
                      showCorrect
                          ? Icons.check_circle_rounded
                          : showWrong
                              ? Icons.cancel_rounded
                              : null,
                      color: showCorrect
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
