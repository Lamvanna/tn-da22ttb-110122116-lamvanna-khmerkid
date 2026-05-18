import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Trò chơi: 🕵️‍♂️ Nhà khảo cổ nhí (Khmer Sub-consonant Detective)
/// Bé khai quật và tìm chân chữ (Châng) tiếng Khmer bị khuyết trong các cổ vật đá.
class SubConsonantGameScreen extends StatefulWidget {
  const SubConsonantGameScreen({super.key});

  @override
  State<SubConsonantGameScreen> createState() => _SubConsonantGameScreenState();
}

class _SubConsonantGameScreenState extends State<SubConsonantGameScreen>
    with SingleTickerProviderStateMixin {
  late List<_DetectiveLevel> _levels;
  int _currentLevelIdx = 0;
  int _score = 0;
  String? _selectedChoice;
  bool _isRoundCompleted = false;
  bool? _isCorrectAnswer;
  ScoreService? _scoreService;

  late AnimationController _tabletController;
  late Animation<double> _tabletAnimation;

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initLevels();
    _initAnimations();
  }

  void _initAnimations() {
    _tabletController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _tabletAnimation = Tween<double>(begin: -4.h, end: 4.h).animate(
      CurvedAnimation(parent: _tabletController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  void _initLevels() {
    _levels = [
      _DetectiveLevel(
        vietnameseTranslation: 'CON CHÓ',
        emoji: '🐕',
        correctWord: 'ឆ្កែ', // chhkæ
        displayProblem: 'ឆ ្ក ែ', // broken down to show where it goes
        missingPartVietnamese: 'Chân chữ Ka (្ក)',
        choices: ['្ក', '្ខ', '្ម'],
        correctAnswer: '្ក',
        pronunciation: 'chhkæ',
        siteName: 'Đền Cổ Angkor',
        bgGradient: [const Color(0xFF8D6E63), const Color(0xFFD7CCC8)],
      ),
      _DetectiveLevel(
        vietnameseTranslation: 'CON MÈO',
        emoji: '🐈',
        correctWord: 'ឆ្មា', // chhma
        displayProblem: 'ឆ ្ម ា',
        missingPartVietnamese: 'Chân chữ Mo (្ម)',
        choices: ['្យ', '្ល', '្ម'],
        correctAnswer: '្ម',
        pronunciation: 'chhma',
        siteName: 'Mỏ Đá Khảo Cổ',
        bgGradient: [const Color(0xFF6D4C41), const Color(0xFFBCAAA4)],
      ),
      _DetectiveLevel(
        vietnameseTranslation: 'BÔNG HOA',
        emoji: '🌸',
        correctWord: 'ផ្កា', // phka
        displayProblem: 'ផ ្ក ា',
        missingPartVietnamese: 'Chân chữ Ka (្ក)',
        choices: ['្ក', '្ន', '្ស'],
        correctAnswer: '្ក',
        pronunciation: 'phka',
        siteName: 'Hầm Mộ Cát',
        bgGradient: [const Color(0xFF4E342E), const Color(0xFF8D6E63)],
      ),
      _DetectiveLevel(
        vietnameseTranslation: 'CON HỔ',
        emoji: '🐯',
        correctWord: 'ខ្លា', // khla
        displayProblem: 'ខ ្ល ា',
        missingPartVietnamese: 'Chân chữ Lo (្ល)',
        choices: ['្វ', '្ល', '្យ'],
        correctAnswer: '្ល',
        pronunciation: 'khla',
        siteName: 'Đông Bia Cổ',
        bgGradient: [const Color(0xFF5D4037), const Color(0xFFA1887F)],
      ),
      _DetectiveLevel(
        vietnameseTranslation: 'RUỘNG LÚA',
        emoji: '🌾',
        correctWord: 'ស្រែ', // sre
        displayProblem: 'ស ្រ ែ',
        missingPartVietnamese: 'Chân chữ Ro (្រ)',
        choices: ['្រ', '្ន', '្ម'],
        correctAnswer: '្រ',
        pronunciation: 'sre',
        siteName: 'Thung Lũng Gió',
        bgGradient: [const Color(0xFF795548), const Color(0xFFD7CCC8)],
      ),
    ];
  }

  @override
  void dispose() {
    _tabletController.dispose();
    super.dispose();
  }

  void _onChoiceSelected(String choice) {
    if (_isRoundCompleted) return;

    final currentLevel = _levels[_currentLevelIdx];
    setState(() {
      _selectedChoice = choice;
      _isRoundCompleted = true;
      _isCorrectAnswer = (choice == currentLevel.correctAnswer);
    });

    if (_isCorrectAnswer!) {
      _onRoundSuccess();
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chưa chính xác rồi! Cổ vật chưa ăn khớp, hãy thử lại nhé! 🕵️‍♂️💫',
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
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isCorrectAnswer!) {
          setState(() {
            _selectedChoice = null;
            _isRoundCompleted = false;
            _isCorrectAnswer = null;
          });
        }
      });
    }
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    setState(() {
      _score += 15;
    });

    // Cộng điểm vào ScoreService
    _scoreService?.completeGame('subconsonant_detective', 15);

    // Hiển thị dialog chúc mừng cực sinh động
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
                '🕵️‍♂️ KHAI QUẬT THÀNH CÔNG! 🕵️‍♂️',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF795548),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                _levels[_currentLevelIdx].emoji,
                style: TextStyle(fontSize: 54.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Bé đã tìm đúng Chân chữ ẩn giấu để hoàn thành từ:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFBCAAA4), width: 2.w),
                    ),
                    child: Text(
                      _levels[_currentLevelIdx].correctWord,
                      style: GoogleFonts.battambang(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _levels[_currentLevelIdx].vietnameseTranslation,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Đọc: ${_levels[_currentLevelIdx].pronunciation}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
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
                        side: const BorderSide(color: Color(0xFF795548)),
                      ),
                      child: Text(
                        'Thoát',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF795548),
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
                        backgroundColor: const Color(0xFF795548),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _currentLevelIdx < _levels.length - 1
                            ? 'Bia đá tiếp theo'
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
        _selectedChoice = null;
        _isRoundCompleted = false;
        _isCorrectAnswer = null;
      });
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
                '🏆 NHÀ KHẢO CỔ VĨ ĐẠI! 🏆',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '🕵️‍♂️🗿🏛️📜🏺👑',
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Bé đã khai quật toàn bộ 5 cổ vật đá cổ quý giá và thành thạo cách viết chân chữ tiếng Khmer cực kỳ xuất sắc!',
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
                    backgroundColor: const Color(0xFF795548),
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
      backgroundColor: const Color(0xFFEFEBE9), // Màu giấy cuộn cổ/cát cổ dịu nhẹ
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

                    // 🗿 BIA ĐÁ CỔ DỊCH MẬT THƯ (Floating Animation)
                    AnimatedBuilder(
                      animation: _tabletAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _tabletAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildAncientTabletCard(currentLevel),
                    ),

                    SizedBox(height: 24.h),

                    // 🏛️ KHU VỰC CỔ VẬT CHỨA TỪ KHUYẾT CHÂN CHỮ
                    _buildExcavationZone(currentLevel),

                    SizedBox(height: 28.h),

                    // 📜 CÁC MẢNH CHÂN CHỮ ĐỂ GHÉP (Choices)
                    _buildChangChoices(currentLevel),

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

  Widget _buildHeader(_DetectiveLevel level) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: level.bgGradient,
        ),
        borderRadius: const BorderRadius.only(
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
                      'Nhà khảo cổ nhí',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${level.siteName} — Vòng ${_currentLevelIdx + 1}/${_levels.length}',
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

  Widget _buildAncientTabletCard(_DetectiveLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFD7CCC8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.saved_search_rounded,
                  color: level.bgGradient.first,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Manh mối khảo cổ học:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                level.emoji,
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dịch nghĩa: ${level.vietnameseTranslation}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Bé hãy tìm: ${level.missingPartVietnamese}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcavationZone(_DetectiveLevel level) {
    // Dựng giao diện hiển thị từ bị khuyết chân chữ một cách nghệ thuật
    final List<String> parts = level.displayProblem.split(' ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Cổ vật đá bị khuyết:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: 14.h),
          // Hiển thị từ với các ô chữ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: parts.map((part) {
              final isMissingSlot = (part == '្ក' || part == '្ម' || part == '្ល' || part == '្រ');
              final isFilled = _isRoundCompleted && (_selectedChoice == level.correctAnswer);

              if (isMissingSlot) {
                // Ô chứa chân chữ bị khuyết nằm bên dưới
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isFilled ? const Color(0xFF4CAF50) : const Color(0xFFB0BEC5),
                      width: 2.w,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isFilled ? level.correctAnswer : '?',
                      style: GoogleFonts.battambang(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isFilled ? const Color(0xFF2E7D32) : AppColors.textHint,
                      ),
                    ),
                  ),
                );
              }

              // Các phụ âm thường
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                child: Text(
                  part,
                  style: GoogleFonts.battambang(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChangChoices(_DetectiveLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
          child: Text(
            'Chọn mảnh chân chữ để khai quật:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: level.choices.map((choice) {
            final isSelected = (_selectedChoice == choice);
            final isCorrect = (choice == level.correctAnswer);

            Color btnColor = Colors.white;
            Color borderColor = const Color(0xFFD7CCC8);
            Color textColor = AppColors.textPrimary;

            if (_isRoundCompleted && isSelected) {
              if (isCorrect) {
                btnColor = const Color(0xFFE8F5E9);
                borderColor = const Color(0xFF4CAF50);
                textColor = const Color(0xFF1B5E20);
              } else {
                btnColor = const Color(0xFFFFCDD2);
                borderColor = const Color(0xFFEF5350);
                textColor = const Color(0xFFB71C1C);
              }
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => _onChoiceSelected(choice),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 3.w : 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      choice,
                      style: GoogleFonts.battambang(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DetectiveLevel {
  final String vietnameseTranslation;
  final String emoji;
  final String correctWord;
  final String displayProblem;
  final String missingPartVietnamese;
  final List<String> choices;
  final String correctAnswer;
  final String pronunciation;
  final String siteName;
  final List<Color> bgGradient;

  _DetectiveLevel({
    required this.vietnameseTranslation,
    required this.emoji,
    required this.correctWord,
    required this.displayProblem,
    required this.missingPartVietnamese,
    required this.choices,
    required this.correctAnswer,
    required this.pronunciation,
    required this.siteName,
    required this.bgGradient,
  });
}
