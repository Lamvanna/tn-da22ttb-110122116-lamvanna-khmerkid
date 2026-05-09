import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/khmer_vocabulary.dart';
import '../../widgets/app_header.dart';

/// Màn hình học từ vựng Khmer theo chủ đề
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  int _selectedCat = 0;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  String? _playingWord;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List)
        .map((l) => l.toString().toLowerCase())
        .toList();
    final hasKhmer = langList.any(
      (l) => l.contains('km') || l.contains('khmer'),
    );
    await _tts.setLanguage(
      hasKhmer
          ? 'km'
          : langList.any((l) => l.contains('vi'))
          ? 'vi-VN'
          : 'en-US',
    );
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _playingWord = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _playingWord = null);
    });
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady || _playingWord != null) return;
    setState(() => _playingWord = text);
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = KhmerVocabularyData.categories;
    final cat = cats[_selectedCat];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildCategoryTabs(cats),
          const SizedBox(height: 12),
          _buildCategoryInfo(cat),
          const SizedBox(height: 12),
          Expanded(child: _buildWordList(cat)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: '📚 Từ vựng Khmer',
      onBack: () => Navigator.pop(context),
      gradientColors: const [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
    );
  }

  Widget _buildCategoryTabs(List<VocabCategory> cats) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final c = cats[index];
          final selected = _selectedCat == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? c.color : const Color(0xFFE0E0E0),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    c.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryInfo(VocabCategory cat) {
    final learned = cat.words.where((w) => w.isLearned).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cat.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cat.color,
                    ),
                  ),
                  Text(
                    '$learned/${cat.words.length} từ đã học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: cat.words.isEmpty ? 0 : learned / cat.words.length,
              strokeWidth: 4,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(cat.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList(VocabCategory cat) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: cat.words.length,
      itemBuilder: (context, index) =>
          _buildWordCard(cat.words[index], cat.color, index),
    );
  }

  Widget _buildWordCard(KhmerWord word, Color color, int index) {
    final isPlaying = _playingWord == word.khmer;
    return GestureDetector(
      onTap: () => _speak(word.khmer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPlaying ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPlaying
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(word.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        word.khmer,
                        style: GoogleFonts.battambang(
                          fontSize: 22,
                          color: const Color(0xFF3E2C6E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPlaying)
                        Icon(Icons.volume_up_rounded, color: color, size: 18),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"${word.romanized}" — ${word.meaning}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  if (word.pronunciation.isNotEmpty)
                    Text(
                      'Phát âm: ${word.pronunciation}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                ],
              ),
            ),
            // Number
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
