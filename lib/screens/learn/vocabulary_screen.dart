import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vocabulary.dart';
import '../../widgets/app_header.dart';

/// Màn hình học từ vựng Khmer theo chủ đề — RESPONSIVE
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          SizedBox(height: 12.h),
          _buildCategoryTabs(cats),
          SizedBox(height: 12.h),
          _buildCategoryInfo(cat),
          SizedBox(height: 12.h),
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
      height: 44.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final c = cats[index];
          final selected = _selectedCat == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: selected ? c.color : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected ? c.color : AppColors.surfaceContainerHighest,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.color.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.emoji, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Text(
                    c.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textSecondary,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: cat.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(cat.emoji, style: TextStyle(fontSize: 36.sp)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: cat.color,
                    ),
                  ),
                  Text(
                    '$learned/${cat.words.length} từ đã học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40.w, height: 40.w,
              child: CircularProgressIndicator(
                value: cat.words.isEmpty ? 0 : learned / cat.words.length,
                strokeWidth: 4.w,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cat.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList(VocabCategory cat) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
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
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isPlaying ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: isPlaying
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(word.emoji, style: TextStyle(fontSize: 28.sp)),
              ),
            ),
            SizedBox(width: 14.w),
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
                          fontSize: 22.sp,
                          color: AppColors.violet,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (isPlaying)
                        Icon(Icons.volume_up_rounded, color: color, size: 18.sp),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '"${word.romanized}" — ${word.meaning}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (word.pronunciation.isNotEmpty)
                    Text(
                      'Phát âm: ${word.pronunciation}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            // Number
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
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
