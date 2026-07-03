import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';
import '../../services/score_service.dart';
import '../../services/admin_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/khmer_speak_widget.dart';
import '../../widgets/khmer_write_widget.dart';

/// Màn hình Kiểm tra — Bài kiểm tra tổng hợp
/// Cố định 20 câu hỏi bao gồm trắc nghiệm, luyện nói phát âm và tập viết nét chữ
class TestScreen extends StatefulWidget {
  final String? testRange;
  const TestScreen({super.key, this.testRange});

  @override
  State<TestScreen> createState() => _TestScreenState();
}
class _TestScreenState extends State<TestScreen> {
  bool _started = false;
  bool _loading = false;
  static const int _difficulty = 2; // Fixed to 2 (Thử thách) to give maximum stars/XP rewards on completion

  List<_TestQ> _questions = [];
  int _qIdx = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;

  List<KhmerLetter> _getRangeLetters(String rangeStr) {
    final letters = KhmerLetterData.consonants.where((l) => !l.isTest).toList();
    if (rangeStr == '1-40') {
      return letters;
    }
    
    try {
      final parts = rangeStr.split('-');
      if (parts.length == 2) {
        final start = int.parse(parts[0]) - 1;
        final end = int.parse(parts[1]) - 1;
        final startClamped = start.clamp(0, letters.length - 1);
        final endClamped = end.clamp(startClamped, letters.length - 1);
        return letters.sublist(startClamped, endClamped + 1);
      }
    } catch (_) {}
    
    return letters;
  }

  void _start() async {
    setState(() {
      _loading = true;
    });

    final rangeLetters = _getRangeLetters(widget.testRange ?? '1-40');
    List<_TestQ> choiceQuestions = [];

    // 1. Tải câu hỏi từ backend
    if (widget.testRange != null && widget.testRange!.isNotEmpty) {
      try {
        final result = await AdminService().fetchTestQuestionsForUser(widget.testRange!);
        if (result['success'] == true && result['data'] != null && (result['data'] as List).isNotEmpty) {
          final list = result['data'] as List;
          choiceQuestions = list.map((item) {
            final rawAnswer = item['answer']?.toString() ?? '';
            final rawOptions = List<String>.from(item['options'] ?? []);

            // 1. Tìm Khmer character tương ứng với đáp án
            String targetChar = '';
            String targetRomanized = '';
            if (rawAnswer.length == 1) {
              targetChar = rawAnswer;
              final match = KhmerLetterData.consonants.firstWhere(
                (l) => l.character == rawAnswer,
                orElse: () => KhmerLetterData.consonants.first,
              );
              targetRomanized = match.romanized;
            } else {
              // Tìm bằng romanized
              final match = KhmerLetterData.consonants.firstWhere(
                (l) => l.romanized.toLowerCase() == rawAnswer.toLowerCase(),
                orElse: () => KhmerLetterData.consonants.first,
              );
              targetChar = match.character;
              targetRomanized = match.romanized;
            }

            // 2. Chuyển đổi các lựa chọn sang dạng chữ Khmer
            final khmerOptions = rawOptions.map((opt) {
              if (opt.length == 1) return opt;
              final match = KhmerLetterData.consonants.firstWhere(
                (l) => l.romanized.toLowerCase() == opt.toLowerCase(),
                orElse: () => KhmerLetterData.consonants.first,
              );
              return match.character;
            }).toList();

            return _TestQ(
              q: 'Nghe và chọn chữ cái đúng:',
              options: khmerOptions,
              answer: targetChar,
              type: TestQuestionType.choice,
              audioChar: targetChar,
              romanized: targetRomanized,
              audioUrl: item['audioUrl']?.toString(),
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching online test questions: $e');
      }
    }

    final rng = Random();

    // Cấu hình cố định 20 câu: 8 trắc nghiệm, 6 phát âm, 6 tập viết
    int speakCount = 6;
    int writeCount = 6;
    int choiceCount = 8;

    // 2. Tự sinh thêm câu hỏi trắc nghiệm nếu thiếu từ API
    if (choiceQuestions.length < choiceCount) {
      final needed = choiceCount - choiceQuestions.length;
      final extraChoices = <_TestQ>[];
      for (int i = 0; i < needed; i++) {
        final letter = rangeLetters[rng.nextInt(rangeLetters.length)];
        final wrong = rangeLetters.where((l) => l.character != letter.character).toList();
        if (wrong.length < 3) {
          wrong.addAll(KhmerLetterData.consonants.where((l) => !l.isTest && l.character != letter.character));
        }
        wrong.shuffle(rng);
        final opts = [letter.character, ...wrong.take(3).map((l) => l.character)];
        opts.shuffle(rng);

        extraChoices.add(_TestQ(
          q: 'Nghe và chọn chữ cái đúng:',
          options: opts,
          answer: letter.character,
          type: TestQuestionType.choice,
          audioChar: letter.character,
          romanized: letter.romanized,
        ));
      }
      choiceQuestions.addAll(extraChoices);
    }

    // Shuffle và lấy đúng số lượng cần thiết
    choiceQuestions.shuffle();
    if (choiceQuestions.length > choiceCount) {
      choiceQuestions = choiceQuestions.sublist(0, choiceCount);
    }

    // 3. Sinh các câu hỏi luyện nói phát âm
    final speakQuestions = <_TestQ>[];
    for (int i = 0; i < speakCount; i++) {
      final letter = rangeLetters[rng.nextInt(rangeLetters.length)];
      speakQuestions.add(_TestQ(
        q: 'Hãy phát âm chữ cái sau:',
        options: [],
        answer: letter.character,
        type: TestQuestionType.speak,
        romanized: letter.romanized,
        meaning: letter.meaning,
      ));
    }

    // 4. Sinh các câu hỏi tập viết chữ
    final writeQuestions = <_TestQ>[];
    for (int i = 0; i < writeCount; i++) {
      final letter = rangeLetters[rng.nextInt(rangeLetters.length)];
      writeQuestions.add(_TestQ(
        q: 'Hãy tập viết chữ cái sau:',
        options: [],
        answer: letter.character,
        type: TestQuestionType.write,
      ));
    }

    // 5. Tổng hợp lại và trộn ngẫu nhiên
    final finalQuestions = <_TestQ>[];
    finalQuestions.addAll(choiceQuestions);
    finalQuestions.addAll(speakQuestions);
    finalQuestions.addAll(writeQuestions);
    finalQuestions.shuffle();

    setState(() {
      _questions = finalQuestions;
      _started = true;
      _loading = false;
      _qIdx = 0;
      _correct = 0;
      _selected = null;
      _answered = false;
    });

    _playCurrentQuestionAudio();
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
      _nextQuestion();
    });
  }

  void _answerCorrect() {
    if (_answered) return;
    setState(() {
      _correct++;
      _answered = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_qIdx >= _questions.length - 1) {
      _showResult();
    } else {
      setState(() {
        _qIdx++;
        _selected = null;
        _answered = false;
      });
      _playCurrentQuestionAudio();
    }
  }

  void _playCurrentQuestionAudio() {
    if (_qIdx < _questions.length) {
      final q = _questions[_qIdx];
      if (q.type == TestQuestionType.choice) {
        if (q.audioUrl != null && q.audioUrl!.isNotEmpty) {
          TtsService.instance.speakKhmerLetter(
            character: '',
            audioUrl: q.audioUrl,
          );
        } else if (q.audioChar != null) {
          TtsService.instance.speakKhmerLetter(character: q.audioChar!);
        }
      }
    }
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

  // ═══════ GIỚI THIỆU BÀI KIỂM TRA ═══════
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
                const SizedBox(height: 12),
                Text('Thông tin bài kiểm tra',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF37474F))),
                const SizedBox(height: 6),
                Text(
                  'Bài kiểm tra gồm 20 câu hỏi tổng hợp giúp bé củng cố toàn diện các kỹ năng đã học.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF757575)),
                ),
                const SizedBox(height: 24),

                _buildInfoCard(
                  title: 'Nhận diện chữ cái (Trắc nghiệm)',
                  sub: '8 câu hỏi • Chọn đáp án đúng cho âm đọc và mặt chữ.',
                  emoji: '📝',
                  color: const Color(0xFF2979FF),
                ),
                const SizedBox(height: 14),
                _buildInfoCard(
                  title: 'Luyện nói phát âm',
                  sub: '6 câu hỏi • Phát âm to rõ chữ cái xuất hiện trên màn hình.',
                  emoji: '🗣️',
                  color: const Color(0xFF00E676),
                ),
                const SizedBox(height: 14),
                _buildInfoCard(
                  title: 'Tập viết nét chữ',
                  sub: '6 câu hỏi • Vẽ lại chính xác các chữ cái Khmer theo hướng dẫn.',
                  emoji: '✍️',
                  color: const Color(0xFFAA00FF),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B9CF5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                      shadowColor: const Color(0xFF5B9CF5).withValues(alpha: 0.3),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text('Bắt đầu kiểm tra',
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

  Widget _buildInfoCard({
    required String title,
    required String sub,
    required String emoji,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE3E9F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF37474F))),
                const SizedBox(height: 4),
                Text(sub,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575))),
              ],
            ),
          ),
        ],
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
    final isChoice = q.type == TestQuestionType.choice;

    return Column(
      children: [
        _buildTestHeader(),
        // Thanh tiến trình và thông tin điểm số
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            children: [
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
            ],
          ),
        ),

        // Phần hiển thị câu hỏi tùy loại
        Expanded(
          child: isChoice
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      // Câu hỏi có Loa phát âm
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(q.q,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: const Color(0xFF37474F))),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () {
                                if (q.audioUrl != null && q.audioUrl!.isNotEmpty) {
                                  TtsService.instance.speakKhmerLetter(
                                    character: '',
                                    audioUrl: q.audioUrl,
                                  );
                                } else if (q.audioChar != null) {
                                  TtsService.instance.speakKhmerLetter(character: q.audioChar!);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B9CF5).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 58,
                                  color: Color(0xFF5B9CF5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Bấm loa để nghe lại 🔊',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF757575))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 4 Đáp án trắc nghiệm
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
                                            ? GoogleFonts.battambang(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
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
                )
              : Column(
                  children: [
                    // Tiêu đề/Yêu cầu luyện nói hoặc viết
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        q.q,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF37474F)),
                      ),
                    ),
                    
                    // Widget tương tác
                    Expanded(
                      child: q.type == TestQuestionType.speak
                          ? KhmerSpeakWidget(
                              key: ValueKey('speak_${_qIdx}_${q.answer}'),
                              targetWord: q.answer,
                              romanized: q.romanized ?? '',
                              meaning: q.meaning ?? '',
                              onComplete: _answerCorrect,
                              accentColor: const Color(0xFF5B9CF5),
                              accentColorDark: const Color(0xFF3F7FE0),
                            )
                          : KhmerWriteWidget(
                              key: ValueKey('write_${_qIdx}_${q.answer}'),
                              character: q.answer,
                              label: 'chữ cái',
                              onComplete: _answerCorrect,
                              accentColor: const Color(0xFF5B9CF5),
                              accentColorDark: const Color(0xFF3F7FE0),
                            ),
                    ),

                    // Nút Bỏ qua câu này đề phòng trường hợp các bé bị kẹt
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: TextButton(
                        onPressed: _nextQuestion,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          'Bỏ qua câu này ➡️',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF757575)),
                        ),
                      ),
                    ),
                  ],
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

enum TestQuestionType { choice, speak, write }

class _TestQ {
  final String q;
  final List<String> options;
  final String answer;
  final TestQuestionType type;
  final String? romanized;
  final String? meaning;
  final String? audioChar;
  final String? audioUrl;

  _TestQ({
    required this.q,
    required this.options,
    required this.answer,
    this.type = TestQuestionType.choice,
    this.romanized,
    this.meaning,
    this.audioChar,
    this.audioUrl,
  });
}
