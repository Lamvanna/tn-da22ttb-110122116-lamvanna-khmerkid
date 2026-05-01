import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';

/// Trò chơi Xếp hình — Sắp xếp chữ cái Khmer theo đúng thứ tự
/// Hiển thị 5 chữ đã shuffle, kéo thả / bấm để sắp đúng thứ tự
class SortingGameScreen extends StatefulWidget {
  const SortingGameScreen({super.key});

  @override
  State<SortingGameScreen> createState() => _SortingGameScreenState();
}

class _SortingGameScreenState extends State<SortingGameScreen> {
  final _rng = Random();
  late List<KhmerLetter> _correctOrder;
  late List<KhmerLetter> _userOrder;
  int _score = 0;
  int _round = 1;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generateRound();
  }

  void _generateRound() {
    final all = List<KhmerLetter>.from(KhmerLetterData.consonants);
    final startIdx = _rng.nextInt(max(1, all.length - 5));
    _correctOrder = all.sublist(startIdx, min(startIdx + 5, all.length));

    _userOrder = List.from(_correctOrder);
    // Shuffle cho đến khi khác thứ tự gốc
    do {
      _userOrder.shuffle(_rng);
    } while (_listsEqual(_userOrder, _correctOrder) && _correctOrder.length > 1);

    setState(() {
      _showResult = false;
      _isCorrect = false;
    });
  }

  bool _listsEqual(List<KhmerLetter> a, List<KhmerLetter> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].character != b[i].character) return false;
    }
    return true;
  }

  void _checkOrder() {
    final correct = _listsEqual(_userOrder, _correctOrder);
    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) _score += 20;
    });

    if (correct) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _round++;
          _generateRound();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: Column(
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          // Hướng dẫn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sắp xếp các chữ cái theo đúng thứ tự bảng chữ cái Khmer!',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF616161)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Thứ tự đúng (gợi ý nhỏ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Thứ tự đúng: ',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E9E9E))),
                ...List.generate(_correctOrder.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFBDBDBD))),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Danh sách kéo thả
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _userOrder.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _userOrder.removeAt(oldIndex);
                  _userOrder.insert(newIndex, item);
                  _showResult = false;
                });
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.transparent,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final letter = _userOrder[index];
                final isCorrectPos = _showResult &&
                    letter.character == _correctOrder[index].character;
                final isWrongPos = _showResult && !isCorrectPos;

                return Container(
                  key: ValueKey(letter.character),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isCorrectPos
                        ? const Color(0xFFE8F5E9)
                        : isWrongPos
                            ? const Color(0xFFFFEBEE)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCorrectPos
                          ? const Color(0xFF4CAF50)
                          : isWrongPos
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFE0E0E0),
                      width: _showResult ? 2 : 1,
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
                      // Số thứ tự
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${index + 1}',
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF42A5F5))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Chữ Khmer
                      Text(letter.character,
                          style: GoogleFonts.kantumruyPro(
                              fontSize: 32,
                              color: const Color(0xFF3E2C6E))),
                      const SizedBox(width: 12),
                      // Phiên âm
                      Text(letter.romanized,
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575))),
                      const Spacer(),
                      // Drag handle
                      Icon(Icons.drag_handle_rounded,
                          color: const Color(0xFFBDBDBD)),
                      // Result icon
                      if (_showResult) ...[
                        const SizedBox(width: 8),
                        Icon(
                          isCorrectPos
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isCorrectPos
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Nút kiểm tra
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showResult && _isCorrect ? null : _checkOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showResult && _isCorrect
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF42A5F5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  _showResult && _isCorrect
                      ? '✅ Đúng rồi! Đang tải vòng tiếp...'
                      : _showResult
                          ? '❌ Sai rồi — Thử lại!'
                          : 'Kiểm tra thứ tự',
                  style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
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
            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)]),
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
                child: Text('Xếp hình — Vòng $_round',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
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
}
