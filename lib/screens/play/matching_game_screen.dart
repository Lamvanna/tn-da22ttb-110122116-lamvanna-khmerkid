import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_letter.dart';

/// Trò chơi Ghép hình — Ghép chữ Khmer đúng với nghĩa / hình ảnh
/// Mỗi lượt: hiển thị 4 cặp, người chơi bấm từng cặp khớp nhau
class MatchingGameScreen extends StatefulWidget {
  const MatchingGameScreen({super.key});

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late List<_MatchItem> _items;
  _MatchItem? _firstSelected;
  final Set<int> _matched = {};
  int _score = 0;
  int _round = 1;
  int _totalPairs = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _generateRound();
  }

  void _generateRound() {
    final learned = KhmerLetterData.consonants
        .where((l) => l.isLearned)
        .toList();
    if (learned.length < 4) {
      // Nếu chưa học đủ → dùng 4 chữ đầu tiên
      learned.clear();
      learned.addAll(KhmerLetterData.consonants.take(4));
    }
    learned.shuffle(_rng);
    final selected = learned.take(4).toList();

    final items = <_MatchItem>[];
    for (int i = 0; i < selected.length; i++) {
      // Card chữ Khmer
      items.add(_MatchItem(
        id: i,
        content: selected[i].character,
        type: _MatchType.khmer,
        pairId: i,
      ));
      // Card phiên âm
      items.add(_MatchItem(
        id: i + selected.length,
        content: selected[i].romanized,
        type: _MatchType.romanized,
        pairId: i,
      ));
    }
    items.shuffle(_rng);

    setState(() {
      _items = items;
      _matched.clear();
      _firstSelected = null;
      _totalPairs = selected.length;
    });
  }

  void _onTap(_MatchItem item) {
    if (_checking) return;
    if (_matched.contains(item.pairId)) return;
    if (_firstSelected?.id == item.id) return;

    if (_firstSelected == null) {
      setState(() => _firstSelected = item);
      return;
    }

    // Kiểm tra cặp
    if (_firstSelected!.pairId == item.pairId &&
        _firstSelected!.type != item.type) {
      // Đúng cặp!
      setState(() {
        _matched.add(item.pairId);
        _score += 10;
        _firstSelected = null;
      });

      if (_matched.length == _totalPairs) {
        // Xong round
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _showRoundComplete();
        });
      }
    } else {
      // Sai cặp → flash đỏ rồi reset
      setState(() => _checking = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _firstSelected = null;
          _checking = false;
        });
      });
    }
  }

  void _showRoundComplete() {
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
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Hoàn thành!',
                  style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32))),
              const SizedBox(height: 8),
              Text('Vòng $_round — +${_totalPairs * 10} điểm',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7E57C2))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _round++);
                        _generateRound();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text('Vòng tiếp →',
                          style: GoogleFonts.nunito(
                              fontSize: 15,
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
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isMatched = _matched.contains(item.pairId);
                  final isSelected = _firstSelected?.id == item.id;

                  return GestureDetector(
                    onTap: isMatched ? null : () => _onTap(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? const Color(0xFFE8F5E9)
                            : isSelected
                                ? const Color(0xFFE3F2FD)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMatched
                              ? const Color(0xFF4CAF50)
                              : isSelected
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFFE0E0E0),
                          width: isSelected || isMatched ? 3 : 1.5,
                        ),
                        boxShadow: [
                          if (!isMatched)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isMatched ? 0.5 : 1.0,
                              child: Text(
                                item.content,
                                style: item.type == _MatchType.khmer
                                    ? GoogleFonts.kantumruyPro(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF3E2C6E),
                                      )
                                    : GoogleFonts.nunito(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF455A64),
                                      ),
                              ),
                            ),
                          ),
                          if (isMatched)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4CAF50), size: 24),
                            ),
                          // Type badge
                          Positioned(
                            bottom: 6,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.type == _MatchType.khmer
                                    ? const Color(0xFF7E57C2).withValues(alpha: 0.1)
                                    : const Color(0xFFFFA726).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.type == _MatchType.khmer
                                    ? 'Chữ Khmer'
                                    : 'Phiên âm',
                                style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.type == _MatchType.khmer
                                        ? const Color(0xFF7E57C2)
                                        : const Color(0xFFFFA726)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)]),
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
                child: Text('Ghép hình — Vòng $_round',
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

enum _MatchType { khmer, romanized }

class _MatchItem {
  final int id;
  final String content;
  final _MatchType type;
  final int pairId;

  _MatchItem({
    required this.id,
    required this.content,
    required this.type,
    required this.pairId,
  });
}
