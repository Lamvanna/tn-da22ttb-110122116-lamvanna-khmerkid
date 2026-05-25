import 'dart:async';
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

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 20;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;

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
    _timer?.cancel();
    _gardenController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 0;
      _currentLevelIdx = 0;
      _selectedChoice = null;
      _isRoundCompleted = false;
      _isCorrectAnswer = null;
      _gameOver = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _onTimeOut();
        }
      });
    });
  }

  void _onTimeOut() {
    HapticFeedback.heavyImpact();
    setState(() {
      _lives = 0;
      _gameOver = true;
    });
  }

  void _onChoiceSelected(String choice) {
    if (_isRoundCompleted || _gameOver) return;

    final currentLevel = _levels[_currentLevelIdx];
    final isCorrect = (choice == currentLevel.correctAnswer);

    setState(() {
      _selectedChoice = choice;
      _isRoundCompleted = true;
      _isCorrectAnswer = isCorrect;
    });

    if (isCorrect) {
      _timer?.cancel();
      _onRoundSuccess();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        if (_lives > 1) {
          _lives--;
        } else {
          _lives = 0;
          _gameOver = true;
          _timer?.cancel();
        }
      });

      if (!_gameOver) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chưa đúng rồi! Bé bị mất 1 mạng tim 💔. Bé hãy chọn lại nhé!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          ),
        );

        // Cho phép chọn lại sau 1.5 giây
        Future.delayed(const Duration(milliseconds: 1500), () {
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
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    setState(() {
      _score += 15;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kết quả chính xác! 🍏',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'Chuẩn bị tiến sang khu vườn tiếp theo...',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _nextLevel();
      }
    });
  }

  void _nextLevel() {
    if (_currentLevelIdx < _levels.length - 1) {
      setState(() {
        _currentLevelIdx++;
        _selectedChoice = null;
        _isRoundCompleted = false;
        _isCorrectAnswer = null;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
    _timer?.cancel();
    _score = 12;
    _scoreService?.completeGame('math_garden', 12);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: !_gameStarted
              ? _buildStartScreen()
              : _gameOver
                  ? _buildGameOverScreen()
                  : Column(
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
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFFB74D)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65100).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.local_florist_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '🍎 Khu vườn Toán học',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Đếm số trái chín và làm các phép tính đố\nthú vị cùng các bạn nhỏ bằng chữ số Khmer!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFFFB74D), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65100).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🍏', 'Đếm số quả chín hoặc giải phép toán đố'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', '20 giây cho mỗi lượt tính đố vui'),
                  SizedBox(height: 10.h),
                  _ruleRow('💖', '3 mạng tim - Chọn sai đáp án sẽ bị trừ mạng'),
                  SizedBox(height: 10.h),
                  _ruleRow('🏆', 'Vượt qua 5 khu vườn để nhận cúp Thần đồng!'),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF5D4037), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'BẮT ĐẦU CHƠI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 18.sp)),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5D4037),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('😢', style: TextStyle(fontSize: 64.sp)),
            SizedBox(height: 20.h),
            Text(
              'Hết lượt chơi rồi!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFC62828),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Khu vườn đang gặp bão cát tàn phá. Bé hãy chơi lại để giúp bảo vệ khu vườn chín ngọt nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.05),
                    blurRadius: 10.r,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _statRow('⭐ Điểm số đạt được', '$_score'),
                  SizedBox(height: 12.h),
                  _statRow('🍎 Số vườn đã khám phá', '$_currentLevelIdx / ${_levels.length}'),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFC62828), width: 2.w),
                      ),
                      child: Center(
                        child: Text(
                          'Thoát',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE65100), Color(0xFFFFB74D)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF5D4037), width: 2.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withOpacity(0.3),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Chơi lại',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF37474F),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(_MathLevel level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: level.bgGradient,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: level.bgGradient.first.withOpacity(0.3),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            children: List.generate(3, (i) => Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Icon(
                i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: i < _lives ? const Color(0xFFFF1744) : Colors.white.withOpacity(0.4),
                size: 22.w,
              ),
            )),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _timeLeft <= 8
                  ? const Color(0xFFFF1744).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: _timeLeft <= 8 ? const Color(0xFFFF8A80) : Colors.white,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  '$_timeLeft',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 8 ? const Color(0xFFFF8A80) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('image/sao.png', width: 18.w, height: 18.h),
                SizedBox(width: 5.w),
                Text(
                  '$_score',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF57C00),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFFFD54F), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.12),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE082),
              border: Border.all(color: const Color(0xFFFFB300), width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.2),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              Icons.spa_rounded,
              color: level.bgGradient.first,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THỬ THÁCH ĐỐ VUI:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE65100),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  level.question,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D4037),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMathProblem(_MathLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFFFCC80), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Graphic illustrations inside a cute wicker picnic basket
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), // Picnic blanket color
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFFFB74D), width: 2.w),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: level.visualEmojis.map((emoji) {
                return Text(
                  emoji,
                  style: TextStyle(fontSize: 34.sp),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          // Math problem blackboard style
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20), // Dark green blackboard
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFF8D6E63), width: 4.w), // Wooden frame
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: Offset(0, 4.h),
                  blurRadius: 6.r,
                ),
              ],
            ),
            child: Center(
              child: Text(
                level.khmerProblem,
                style: GoogleFonts.battambang(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFF59D), // Pastel chalk yellow
                ),
              ),
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
            'Chọn kết quả bé tính được nhé:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE65100),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: level.choices.map((choice) {
            final isSelected = (_selectedChoice == choice);
            final isCorrect = (choice == level.correctAnswer);

            Color btnColor = const Color(0xFFFFE082); // Golden wood yellow
            Color borderColor = const Color(0xFFFFB300);
            Color textColor = const Color(0xFF5D4037);

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
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 3.w : 2.5.w,
                    ),
                    boxShadow: isSelected && _isRoundCompleted
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFF57C00).withOpacity(0.3),
                              offset: Offset(0, 5.h),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      choice,
                      style: GoogleFonts.battambang(
                        fontSize: 32.sp,
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
