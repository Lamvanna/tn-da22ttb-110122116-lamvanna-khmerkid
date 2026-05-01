import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Màn hình Tập đọc - Reading Practice Screen
/// Bài đọc Khmer từ cơ bản đến nâng cao, tích hợp TTS
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  int _currentLesson = 0;
  int? _highlightIdx;

  static final List<_ReadingLesson> _lessons = [
    _ReadingLesson(
      title: 'Bài 1: Phụ âm cơ bản',
      subtitle: 'Đọc phụ âm ក - ង',
      emoji: '📖',
      color: const Color(0xFF4CAF50),
      lines: [
        _ReadLine(khmer: 'ក ខ គ ឃ ង', romanized: 'Ka Kha Ko Kho Ngo', meaning: 'Nhóm phụ âm đầu tiên'),
        _ReadLine(khmer: 'កា ខា គា ឃា ងា', romanized: 'Kaa Khaa Koo Khoo Ngoo', meaning: 'Kết hợp nguyên âm "aa"'),
        _ReadLine(khmer: 'កី ខី គី ឃី ងី', romanized: 'Key Khey Key Khey Ngey', meaning: 'Kết hợp nguyên âm "ey"'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 2: Từ đơn giản',
      subtitle: 'Đọc từ 1-2 âm tiết',
      emoji: '📗',
      color: const Color(0xFF2196F3),
      lines: [
        _ReadLine(khmer: 'កា', romanized: 'Kaa', meaning: 'Con quạ'),
        _ReadLine(khmer: 'គោ', romanized: 'Ko', meaning: 'Con bò'),
        _ReadLine(khmer: 'ឆ្មា', romanized: 'Chma', meaning: 'Con mèo'),
        _ReadLine(khmer: 'ឆ្កែ', romanized: 'Chkae', meaning: 'Con chó'),
        _ReadLine(khmer: 'ត្រី', romanized: 'Trey', meaning: 'Con cá'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 3: Câu ngắn',
      subtitle: 'Đọc câu đơn giản',
      emoji: '📘',
      color: const Color(0xFFE91E63),
      lines: [
        _ReadLine(khmer: 'ម៉ែ ស្រឡាញ់ ខ្ញុំ', romanized: 'Mae srolanh knhom', meaning: 'Mẹ yêu con'),
        _ReadLine(khmer: 'ខ្ញុំ ទៅ សាលា', romanized: 'Knhom tov sala', meaning: 'Con đi học'),
        _ReadLine(khmer: 'ប៉ា ធ្វើ ការ', romanized: 'Pa thveu ka', meaning: 'Bố đi làm'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 4: Số đếm',
      subtitle: 'Đọc số từ 1-10',
      emoji: '📙',
      color: const Color(0xFFFF9800),
      lines: [
        _ReadLine(khmer: '១ ២ ៣ ៤ ៥', romanized: 'Muoy Pi Bey Buon Pram', meaning: '1 2 3 4 5'),
        _ReadLine(khmer: '៦ ៧ ៨ ៩ ១០', romanized: 'Prammuoy Prampil Prambey Prambuon Dop', meaning: '6 7 8 9 10'),
      ],
    ),
    _ReadingLesson(
      title: 'Bài 5: Đoạn văn',
      subtitle: 'Đọc đoạn văn ngắn',
      emoji: '📕',
      color: const Color(0xFF7E57C2),
      lines: [
        _ReadLine(khmer: 'ខ្ញុំ ឈ្មោះ សុខា។', romanized: 'Knhom chhmuoh Sokha.', meaning: 'Tôi tên là Sokha.'),
        _ReadLine(khmer: 'ខ្ញុំ រៀន នៅ សាលា។', romanized: 'Knhom rien nov sala.', meaning: 'Tôi học ở trường.'),
        _ReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ គ្រូ។', romanized: 'Knhom srolanh kru.', meaning: 'Tôi yêu cô giáo.'),
        _ReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ ម៉ែ ប៉ា។', romanized: 'Knhom srolanh mae pa.', meaning: 'Tôi yêu mẹ bố.'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.35);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _highlightIdx = null); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _highlightIdx = null); });
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speakLine(int idx) async {
    if (!_ttsReady) return;
    final line = _lessons[_currentLesson].lines[idx];
    setState(() => _highlightIdx = idx);
    await _tts.speak(line.khmer);
  }

  Future<void> _speakAll() async {
    if (!_ttsReady) return;
    final lines = _lessons[_currentLesson].lines;
    for (int i = 0; i < lines.length; i++) {
      if (!mounted) return;
      setState(() => _highlightIdx = i);
      await _tts.speak(lines[i].khmer);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    if (mounted) setState(() => _highlightIdx = null);
  }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_currentLesson];
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(children: [
        _buildHeader(context),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildLessonSelector(),
            const SizedBox(height: 14),
            _buildLessonInfo(lesson),
            const SizedBox(height: 14),
            _buildReadingCard(lesson),
            const SizedBox(height: 14),
            _buildControlButtons(),
            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded), color: AppColors.textWhite, iconSize: 28),
          Expanded(child: Text('📖 Tập đọc', style: AppTextStyles.screenTitle, textAlign: TextAlign.center)),
          const SizedBox(width: 48),
        ]),
      )),
    );
  }

  Widget _buildLessonSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          final selected = _currentLesson == index;
          return GestureDetector(
            onTap: () => setState(() { _currentLesson = index; _highlightIdx = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? l.color : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? l.color : const Color(0xFFE0E0E0)),
                boxShadow: selected ? [BoxShadow(color: l.color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(l.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('Bài ${index + 1}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF616161))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonInfo(_ReadingLesson lesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lesson.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lesson.color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Text(lesson.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lesson.title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: lesson.color)),
          Text(lesson.subtitle, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF757575))),
        ])),
      ]),
    );
  }

  Widget _buildReadingCard(_ReadingLesson lesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        ...List.generate(lesson.lines.length, (i) {
          final line = lesson.lines[i];
          final isHighlight = _highlightIdx == i;
          return GestureDetector(
            onTap: () => _speakLine(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isHighlight ? lesson.color.withValues(alpha: 0.08) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: isHighlight ? Border.all(color: lesson.color.withValues(alpha: 0.5), width: 1.5) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(line.khmer,
                      style: GoogleFonts.kantumruyPro(fontSize: 24, color: const Color(0xFF3E2C6E),
                          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400))),
                  Icon(isHighlight ? Icons.volume_up_rounded : Icons.play_circle_outline_rounded,
                      color: isHighlight ? lesson.color : const Color(0xFFBDBDBD), size: 22),
                ]),
                const SizedBox(height: 4),
                Text(line.romanized, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isHighlight ? lesson.color : const Color(0xFF9E9E9E))),
                Text(line.meaning, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500,
                    color: const Color(0xFFBDBDBD))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildControlButtons() {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: _speakAll,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_lessons[_currentLesson].color, _lessons[_currentLesson].color.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _lessons[_currentLesson].color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text('Nghe toàn bài', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () { _tts.stop(); setState(() => _highlightIdx = null); },
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
        ),
      ),
    ]);
  }
}

class _ReadingLesson {
  final String title, subtitle, emoji;
  final Color color;
  final List<_ReadLine> lines;
  const _ReadingLesson({required this.title, required this.subtitle, required this.emoji, required this.color, required this.lines});
}

class _ReadLine {
  final String khmer, romanized, meaning;
  const _ReadLine({required this.khmer, required this.romanized, required this.meaning});
}
