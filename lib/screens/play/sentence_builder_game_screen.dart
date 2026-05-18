import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Trò chơi: 🏝️ Đảo quốc Ngữ pháp (Khmer Sentence Builder Island)
/// Bé sắp xếp các khối từ vựng thành câu tiếng Khmer hoàn chỉnh có nghĩa.
class SentenceBuilderGameScreen extends StatefulWidget {
  const SentenceBuilderGameScreen({super.key});

  @override
  State<SentenceBuilderGameScreen> createState() => _SentenceBuilderGameScreenState();
}

class _SentenceBuilderGameScreenState extends State<SentenceBuilderGameScreen>
    with SingleTickerProviderStateMixin {
  late List<_SentenceLevel> _levels;
  int _currentLevelIdx = 0;
  int _score = 0;
  List<String> _shuffledWords = [];
  List<String> _selectedWords = [];
  bool _isRoundCompleted = false;
  ScoreService? _scoreService;

  late AnimationController _islandController;
  late Animation<double> _islandAnimation;

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initLevels();
    _loadLevel(_currentLevelIdx);
    _initAnimations();
  }

  void _initAnimations() {
    _islandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _islandAnimation = Tween<double>(begin: -4.h, end: 4.h).animate(
      CurvedAnimation(parent: _islandController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  void _initLevels() {
    _levels = [
      _SentenceLevel(
        vietnameseTranslation: 'Tôi đi học',
        correctWords: ['ខ្ញុំ', 'ទៅ', 'សាលារៀន'],
        wordMeanings: {
          'ខ្ញុំ': 'Tôi',
          'ទៅ': 'đi',
          'សាលារៀន': 'trường học',
        },
        islandName: 'Đảo Ngọc Trai',
        emoji: '🏝️',
      ),
      _SentenceLevel(
        vietnameseTranslation: 'Mẹ mua trái cây',
        correctWords: ['ម៉ាក់', 'ទិញ', 'ផ្លែឈើ'],
        wordMeanings: {
          'ម៉ាក់': 'Mẹ',
          'ទិញ': 'mua',
          'ផ្លែឈើ': 'trái cây',
        },
        islandName: 'Đảo Cọ Vàng',
        emoji: '🌴',
      ),
      _SentenceLevel(
        vietnameseTranslation: 'Em bé uống sữa',
        correctWords: ['កូនក្មេង', 'ផឹក', 'ទឹកដោះគោ'],
        wordMeanings: {
          'កូនក្មេង': 'Em bé',
          'ផឹក': 'uống',
          'ទឹកដោះគោ': 'sữa',
        },
        islandName: 'Đảo Hải Âu',
        emoji: '🌊',
      ),
      _SentenceLevel(
        vietnameseTranslation: 'Tôi thích ăn cơm',
        correctWords: ['ខ្ញុំ', 'ចូលចិត្ត', 'ញ៉ាំ', 'បាយ'],
        wordMeanings: {
          'ខ្ញុំ': 'Tôi',
          'ចូលចិត្ត': 'thích',
          'ញ៉ាំ': 'ăn',
          'បាយ': 'cơm',
        },
        islandName: 'Đảo San Hô',
        emoji: '🐚',
      ),
      _SentenceLevel(
        vietnameseTranslation: 'Chú voi ăn chuối',
        correctWords: ['ដំរី', 'ស៊ី', 'ចេក'],
        wordMeanings: {
          'ដំរី': 'Chú voi',
          'ស៊ី': 'ăn (động vật)',
          'ចេក': 'chuối',
        },
        islandName: 'Đảo Đá Cổ',
        emoji: '🗿',
      ),
    ];
  }

  void _loadLevel(int index) {
    final level = _levels[index];
    final words = List<String>.from(level.correctWords);
    // Trộn từ cho đến khi nó khác với thứ tự đúng để có tính thử thách
    final rng = Random();
    do {
      words.shuffle(rng);
    } while (_isListEqual(words, level.correctWords) && words.length > 1);

    setState(() {
      _shuffledWords = words;
      _selectedWords.clear();
      _isRoundCompleted = false;
    });
  }

  bool _isListEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _islandController.dispose();
    super.dispose();
  }

  void _onWordTap(String word) {
    if (_isRoundCompleted) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else {
        _selectedWords.add(word);
      }
    });
  }

  void _clearSelection() {
    if (_isRoundCompleted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedWords.clear();
    });
  }

  void _checkAnswer() {
    if (_isRoundCompleted) return;

    final currentLevel = _levels[_currentLevelIdx];
    if (_selectedWords.length < currentLevel.correctWords.length) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bé ơi, hãy xếp đủ các khối đá từ vựng nhé! 🧐',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
      return;
    }

    if (_isListEqual(_selectedWords, currentLevel.correctWords)) {
      // Bé trả lời ĐÚNG!
      _onRoundSuccess();
    } else {
      // Bé trả lời SAI -> Rung báo hiệu lỗi
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Năng lượng đá cổ lung lay! Xếp chưa đúng rồi, bé hãy thử lại nhé! 🌀',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRoundCompleted = true;
      _score += 15;
    });

    // Cộng điểm vào ScoreService
    _scoreService?.completeGame('sentence_island', 15);

    // Dialog chúc mừng hoành tráng
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🗿 MẬT THƯ ĐÃ GIẢI MÃ! 🗿',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0288D1),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                _levels[_currentLevelIdx].emoji,
                style: TextStyle(fontSize: 72.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Chúc mừng thuyền trưởng nhí đã giải mã thành công câu:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '"${_levels[_currentLevelIdx].vietnameseTranslation}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _levels[_currentLevelIdx].correctWords.join(' '),
                  style: GoogleFonts.battambang(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0288D1),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Thưởng: +15 Điểm 🌟',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0A030),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: const BorderSide(color: Color(0xFF0288D1)),
                      ),
                      child: Text(
                        'Thoát',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _nextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _currentLevelIdx < _levels.length - 1
                            ? 'Đảo tiếp theo'
                            : 'Hoàn thành!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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

  void _nextLevel() {
    if (_currentLevelIdx < _levels.length - 1) {
      setState(() {
        _currentLevelIdx++;
      });
      _loadLevel(_currentLevelIdx);
    } else {
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 THUYỀN TRƯỞNG VĨ ĐẠI! 🏆',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '🏝️🌊🐚⛵🗿⚓',
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Bé đã phiêu lưu qua cả 5 hòn đảo cổ, giải mã toàn bộ mật thư ngữ pháp Khmer xuất sắc!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Tổng điểm đạt được: +$_score Điểm 🌟',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0A030),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Trở về thế giới trò chơi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = _levels[_currentLevelIdx];

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Xanh nước biển cực dịu nhẹ
      body: Column(
        children: [
          _buildHeader(currentLevel),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),

                    // 🏝️ BẢN ĐỒ ĐẢO QUỐC (Floating Animation)
                    AnimatedBuilder(
                      animation: _islandAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _islandAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildIslandCard(currentLevel),
                    ),

                    SizedBox(height: 24.h),

                    // 📜 KHU VỰC THẢ CHỮ (Sentence Slots)
                    _buildSentenceSlots(currentLevel),

                    SizedBox(height: 24.h),

                    // 🗿 KHỐI ĐÁ TỪ VỰNG GỢI Ý (Word Blocks)
                    _buildWordBlocks(currentLevel),

                    SizedBox(height: 32.h),

                    // 🚀 NÚT ĐIỀU KHIỂN (Clear & Check)
                    _buildControlRow(),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_SentenceLevel level) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF26C6DA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 16.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đảo quốc Ngữ pháp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${level.islandName} — Vòng ${_currentLevelIdx + 1}/${_levels.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('image/sao.png', width: 16.w, height: 16.h),
                    SizedBox(width: 4.w),
                    Text(
                      '$_score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIslandCard(_SentenceLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFB3E5FC), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76.w,
            height: 76.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.lightBlue.withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: Colors.lightBlue.withOpacity(0.4),
                width: 2.w,
              ),
            ),
            child: Center(
              child: Text(
                level.emoji,
                style: TextStyle(fontSize: 42.sp),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mật thư tiếng Việt:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '"${level.vietnameseTranslation}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0288D1),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Xếp các khối đá chữ Khmer tương ứng thành câu hoàn chỉnh đúng cấu trúc.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceSlots(_SentenceLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white, width: 2.w),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10.w,
        runSpacing: 10.h,
        children: List.generate(level.correctWords.length, (idx) {
          final isSlotFilled = _selectedWords.length > idx;
          final word = isSlotFilled ? _selectedWords[idx] : '';

          return Container(
            constraints: BoxConstraints(minWidth: 80.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSlotFilled ? const Color(0xFF0288D1) : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSlotFilled ? const Color(0xFF01579B) : const Color(0xFFB0BEC5),
                style: isSlotFilled ? BorderStyle.solid : BorderStyle.solid,
                width: 2.w,
              ),
              boxShadow: isSlotFilled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withOpacity(0.2),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              isSlotFilled ? word : '?',
              textAlign: TextAlign.center,
              style: GoogleFonts.battambang(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isSlotFilled ? Colors.white : AppColors.textHint,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWordBlocks(_SentenceLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 10.h),
          child: Text(
            'Khối từ vựng gợi ý (Bấm để chọn/hủy):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.w,
          runSpacing: 12.h,
          children: _shuffledWords.map((word) {
            final isSelected = _selectedWords.contains(word);
            final meaning = level.wordMeanings[word] ?? '';

            return GestureDetector(
              onTap: () => _onWordTap(word),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB0BEC5) : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF78909C) : const Color(0xFFCFD8DC),
                    width: 2.w,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word,
                      style: GoogleFonts.battambang(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (meaning.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          meaning,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        // Nút Reset
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFB0BEC5), width: 2.w),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: _clearSelection,
              child: Text(
                'Xóa hết 🔄',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        // Nút Kiểm tra
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: _checkAnswer,
              child: Text(
                'Kiểm tra mật thư 🗿',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentenceLevel {
  final String vietnameseTranslation;
  final List<String> correctWords;
  final Map<String, String> wordMeanings;
  final String islandName;
  final String emoji;

  _SentenceLevel({
    required this.vietnameseTranslation,
    required this.correctWords,
    required this.wordMeanings,
    required this.islandName,
    required this.emoji,
  });
}
