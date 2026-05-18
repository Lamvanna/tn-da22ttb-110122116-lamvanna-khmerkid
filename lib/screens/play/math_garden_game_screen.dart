import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Trò chơi: 🍎 Khu vườn Toán học Khmer (Khmer Math & Number Garden)
/// Bé học đếm và làm phép tính toán đố bằng chữ số cổ Khmer (០-៩).
class MathGardenGameScreen extends StatefulWidget {
  const MathGardenGameScreen({super.key});

  @override
  State<MathGardenGameScreen> createState() => _MathGardenGameScreenState();
}

class _MathGardenGameScreenState extends State<MathGardenGameScreen>
    with SingleTickerProviderStateMixin {
  late List<_MathLevel> _levels;
  int _currentLevelIdx = 0;
  int _score = 0;
  String? _selectedChoice;
  bool _isRoundCompleted = false;
  bool? _isCorrectAnswer;
  ScoreService? _scoreService;

  late AnimationController _gardenController;
  late Animation<double> _gardenAnimation;

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initLevels();
    _initAnimations();
  }

  void _initAnimations() {
    _gardenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _gardenAnimation = Tween<double>(begin: -5.h, end: 5.h).animate(
      CurvedAnimation(parent: _gardenController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  void _initLevels() {
    _levels = [
      _MathLevel(
        question: 'Bé hãy đếm số quả táo đỏ chín trên cây nhé! 🍎',
        khmerProblem: '🍎 🍎 🍎 🍎 🍎',
        choices: ['៣', '៤', '៥'],
        correctAnswer: '៥', // 5
        romanized: 'prăm',
        arabicMeaning: '5',
        visualEmojis: ['🍎', '🍎', '🍎', '🍎', '🍎'],
        gardenName: 'Vườn Táo Đỏ',
        bgGradient: [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
      ),
      _MathLevel(
        question: 'Bé hãy tính phép cộng sau bằng chữ số Khmer: ១ + ២ = ?',
        khmerProblem: '១ + ២ = ?', // 1 + 2 = 3
        choices: ['២', '៣', '៤'],
        correctAnswer: '៣', // 3
        romanized: 'bei',
        arabicMeaning: '3',
        visualEmojis: ['🦋', '➕', '🐝', '🐝'],
        gardenName: 'Đồi Bươm Bướm',
        bgGradient: [const Color(0xFF43A047), const Color(0xFF81C784)],
      ),
      _MathLevel(
        question: 'Có bao nhiêu bông hoa hướng dương đang nở rực rỡ? 🌻',
        khmerProblem: '🌻 🌻 🌻 🌻 🌻 🌻 🌻',
        choices: ['៦', '៧', '៨'],
        correctAnswer: '៧', // 7
        romanized: 'prăm-pi',
        arabicMeaning: '7',
        visualEmojis: ['🌻', '🌻', '🌻', '🌻', '🌻', '🌻', '🌻'],
        gardenName: 'Đồng Hướng Dương',
        bgGradient: [const Color(0xFFE65100), const Color(0xFFFFB74D)],
      ),
      _MathLevel(
        question: 'Bé tính giúp chú voi con: ៥ - ២ = ?',
        khmerProblem: '៥ - ២ = ?', // 5 - 2 = 3
        choices: ['៣', '៤', '៥'],
        correctAnswer: '៣', // 3
        romanized: 'bei',
        arabicMeaning: '3',
        visualEmojis: ['🍌', '🍌', '🍌', '🍌', '🍌', '➖', '🍌', '🍌'],
        gardenName: 'Rừng Chuối Chín',
        bgGradient: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
      ),
      _MathLevel(
        question: 'Bé hãy đếm xem có bao nhiêu cây nấm nhỏ trong cỏ? 🍄',
        khmerProblem: '🍄 🍄 🍄 🍄 🍄 🍄 🍄 🍄 🍄',
        choices: ['៧', '៨', '៩'],
        correctAnswer: '៩', // 9
        romanized: 'prăm-buon',
        arabicMeaning: '9',
        visualEmojis: ['🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄'],
        gardenName: 'Góc Nấm Mưa',
        bgGradient: [const Color(0xFF00796B), const Color(0xFF4DB6AC)],
      ),
    ];
  }

  @override
  void dispose() {
    _gardenController.dispose();
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
            'Chưa đúng rồi! Bé hãy đếm kỹ lại và thử lại nhé! 🍎💫',
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
      // Cho phép chọn lại sau 2 giây
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
    _scoreService?.completeGame('math_garden', 15);

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
                '🍎 KẾT QUẢ CHÍNH XÁC! 🍎',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '🌳🍎✨',
                style: TextStyle(fontSize: 48.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Bé đã tính ra kết quả đúng:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFF81C784), width: 2.w),
                    ),
                    child: Text(
                      _levels[_currentLevelIdx].correctAnswer,
                      style: GoogleFonts.battambang(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cách đọc: ${_levels[_currentLevelIdx].romanized}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Giá trị: Số ${_levels[_currentLevelIdx].arabicMeaning}',
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
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      child: Text(
                        'Thoát',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
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
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _currentLevelIdx < _levels.length - 1
                            ? 'Vòng tiếp theo'
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
                '🏆 THẦN ĐỒNG TOÁN HỌC! 🏆',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '🌳🍎🦋🌻🍄🐝',
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chúc mừng Bé đã vượt qua các thử thách đếm số và tính toán bằng chữ số Khmer siêu đỉnh!',
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
                    backgroundColor: const Color(0xFF2E7D32),
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
      backgroundColor: const Color(0xFFFFF8E1), // Vàng nắng dịu nhẹ của khu vườn
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

                    // 🌳 KHU VỰC KHU VƯỜN ĐẦY MÀU SẮC (Floating Animation)
                    AnimatedBuilder(
                      animation: _gardenAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _gardenAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildGardenCard(currentLevel),
                    ),

                    SizedBox(height: 24.h),

                    // 📝 CÂU HỎI TRỰC QUAN
                    _buildVisualMathProblem(currentLevel),

                    SizedBox(height: 28.h),

                    // 🪧 NÚT LỰA CHỌN PHONG CÁCH BẢNG GỖ (Choices)
                    _buildChoicesGrid(currentLevel),

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

  Widget _buildHeader(_MathLevel level) {
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
                      'Khu vườn Toán học Khmer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${level.gardenName} — Vòng ${_currentLevelIdx + 1}/${_levels.length}',
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

  Widget _buildGardenCard(_MathLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFFFECB3), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: Color(0xFFFFF9C4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: level.bgGradient.first,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Thử thách đố vui:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            level.question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMathProblem(_MathLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          // Graphic illustrations
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: level.visualEmojis.map((emoji) {
                return Text(
                  emoji,
                  style: TextStyle(fontSize: 32.sp),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            level.khmerProblem,
            style: GoogleFonts.battambang(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoicesGrid(_MathLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
          child: Text(
            'Chọn kết quả đúng dưới đây:',
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
            Color borderColor = const Color(0xFFFFD54F); // Wooden gold border
            Color textColor = AppColors.textPrimary;

            if (_isRoundCompleted && isSelected) {
              if (isCorrect) {
                btnColor = const Color(0xFFC8E6C9);
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
                  padding: EdgeInsets.symmetric(vertical: 16.h),
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
                        fontSize: 30.sp,
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

class _MathLevel {
  final String question;
  final String khmerProblem;
  final List<String> choices;
  final String correctAnswer;
  final String romanized;
  final String arabicMeaning;
  final List<String> visualEmojis;
  final String gardenName;
  final List<Color> bgGradient;

  _MathLevel({
    required this.question,
    required this.khmerProblem,
    required this.choices,
    required this.correctAnswer,
    required this.romanized,
    required this.arabicMeaning,
    required this.visualEmojis,
    required this.gardenName,
    required this.bgGradient,
  });
}
