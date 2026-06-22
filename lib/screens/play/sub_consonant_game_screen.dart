import 'dart:async';
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
  Map<String, dynamic>? _rewardResult;

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 35;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;

  // UX & Scaffolding variables
  bool _showIntro = false;
  bool _showCorrectAnswerZoom = false;

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
    // Đồng bộ vật phẩm hồi phục lên CSDL khi vào game
    await _scoreService?.syncRegeneratedInventory();
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
        choices: ['្ក', '្ខ', '្គ', '្ង'],
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
        choices: ['្ម', '្ន', '្ល', '្ញ'],
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
        choices: ['្ក', '្ខ', '្ច', '្ស'],
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
        choices: ['្ល', '្វ', '្យ', '្រ'],
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
        choices: ['្រ', '្ល', '្ម', '្ន'],
        correctAnswer: '្រ',
        pronunciation: 'sre',
        siteName: 'Thung Lũng Gió',
        bgGradient: [const Color(0xFF795548), const Color(0xFFD7CCC8)],
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabletController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _showIntro = true;
      _lives = 3;
      _score = 0;
      _currentLevelIdx = 0;
      _selectedChoice = null;
      _isRoundCompleted = false;
      _isCorrectAnswer = null;
      _gameOver = false;
      _rewardResult = null;
      _showCorrectAnswerZoom = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_showIntro) {
      return;
    }
    _timeLeft = (_currentLevelIdx == 0) ? 45 : 35;
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
    _scoreService?.completeGame(
      'subconsonant_detective',
      _score,
      syncToBackend: true,
      correctAnswers: _currentLevelIdx,
      totalQuestions: _levels.length,
    ).then((result) {
      if (mounted) setState(() => _rewardResult = result);
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
        _showCorrectAnswerZoom = true;
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
              'Chưa chính xác rồi! Bé bị mất 1 mạng tim 💔. Học lại chân chữ đúng nhé!',
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

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _selectedChoice = null;
              _isRoundCompleted = false;
              _isCorrectAnswer = null;
              _showCorrectAnswerZoom = false;
            });
          }
        });
      } else {
        _scoreService?.completeGame(
          'subconsonant_detective',
          _score,
          syncToBackend: true,
          correctAnswers: _currentLevelIdx,
          totalQuestions: _levels.length,
        ).then((result) {
          if (mounted) {
            setState(() {
              _rewardResult = result;
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
                    'Khai quật thành công! 🏛️',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'Chuẩn bị tiến sang bia cổ thạch tiếp theo...',
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
        backgroundColor: const Color(0xFF795548),
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

  void _showGameFinishedDialog() async {
    _timer?.cancel();
    _score = 20;
    final result = await _scoreService?.completeGame(
      'subconsonant_detective',
      20,
      syncToBackend: true,
      correctAnswers: _levels.length,
      totalQuestions: _levels.length,
    );
    if (mounted) {
      setState(() {
        _rewardResult = result;
      });
    }

    if (!mounted) return;

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
              if (_rewardResult != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.5.w),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'XẾP LOẠI: ${_rewardResult!['rating']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('image/sao.png', width: 22.w, height: 22.h),
                          SizedBox(width: 4.w),
                          Text(
                            '+${_rewardResult!['stars']} Sao',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF57F17),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          const Icon(Icons.bolt_rounded, color: Colors.orange, size: 22),
                          SizedBox(width: 4.w),
                          Text(
                            '+${_rewardResult!['xp']} XP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: !_gameStarted
              ? _buildStartScreen()
              : _gameOver
                  ? _buildGameOverScreen()
                  : _showIntro
                      ? _buildIntroScreen(currentLevel)
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
                  colors: [Color(0xFF5D4037), Color(0xFFA1887F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.gavel_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '🕵️‍♂️ Nhà khảo cổ nhí',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4E342E),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Khai quật bia đá Granite cổ đại và dùng\nbúa khảo cổ ghép đúng mảnh Chân chữ bị khuyết!',
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
                border: Border.all(color: const Color(0xFFA1887F), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🔨', 'Dùng búa khảo cổ gõ vào mảnh chân chữ đúng'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', '25 giây cho mỗi lượt khai quật bia đá cổ'),
                  SizedBox(height: 10.h),
                  _ruleRow('💖', '3 mạng tim - Chọc búa sai sẽ bị trừ mạng'),
                  SizedBox(height: 10.h),
                  _ruleRow('🏺', 'Giải mã thành công 5 cổ thạch để chiến thắng!'),
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
                    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF4E342E), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D4037).withOpacity(0.4),
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
              color: const Color(0xFF4E342E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sad Face Badge
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF9A9A), Color(0xFFE57373)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC62828).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('😢', style: TextStyle(fontSize: 60)),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Hết lượt chơi rồi!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFC62828),
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: Offset(2.w, 2.h),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Đền cổ bị sụp đổ do động đất. Bé hãy chơi lại để tiếp tục cuộc phiêu lưu khai quật nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            if (_rewardResult != null) ...[
              SizedBox(height: 20.h),
              _buildRatingBadge(_rewardResult!['rating'].toString()),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFFFF59D), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF57F17).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'image/sao.png',
                            width: 44.w,
                            height: 44.h,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '+${_rewardResult!['stars']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          Text(
                            'Sao vàng',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF57F17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'image/XP.png',
                            width: 44.w,
                            height: 44.h,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.bolt_rounded,
                              color: Colors.orange.shade800,
                              size: 44.r,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '+${_rewardResult!['xp']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFD84315),
                            ),
                          ),
                          Text(
                            'Điểm XP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPremiumStatTile(
                    label: '⭐ Điểm số đạt được',
                    value: '$_score',
                    fallbackIcon: Icons.emoji_events_rounded,
                    themeColor: const Color(0xFFF57C00),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: '🏛️ Số cổ vật khai quật',
                    value: '$_currentLevelIdx / ${_levels.length}',
                    fallbackIcon: Icons.museum_rounded,
                    themeColor: const Color(0xFF8D6E63),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFCFD8DC), width: 2.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB0BEC5),
                            offset: Offset(0, 4.h),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Thoát',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF546E7A),
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
                      height: 52.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4E342E),
                            offset: Offset(0, 4.h),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Chơi lại',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
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

  Widget _buildRatingBadge(String rating) {
    Color bgColor = const Color(0xFFFFF8E1);
    Color borderColor = const Color(0xFFFFD54F);
    Color textColor = const Color(0xFFE65100);

    if (rating.contains('🌱')) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFFA5D6A7);
      textColor = const Color(0xFF2E7D32);
    } else if (rating.contains('👍')) {
      bgColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF90CAF9);
      textColor = const Color(0xFF1565C0);
    } else if (rating.contains('🎉')) {
      bgColor = const Color(0xFFF3E5F5);
      borderColor = const Color(0xFFCE93D8);
      textColor = const Color(0xFF7B1FA2);
    } else if (rating.contains('🌟')) {
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFE082);
      textColor = const Color(0xFFE65100);
    } else if (rating.contains('👑')) {
      bgColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFFFCC80);
      textColor = const Color(0xFFD84315);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: borderColor, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'XẾP LOẠI: $rating',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPremiumStatTile({
    required String label,
    required String value,
    required IconData fallbackIcon,
    required Color themeColor,
  }) {
    String cleanLabel = label;
    String emoji = '';
    
    if (label.isNotEmpty) {
      final runes = label.runes;
      final firstChar = runes.first;
      if (firstChar > 127) {
        emoji = String.fromCharCode(firstChar);
        cleanLabel = String.fromCharCodes(runes.skip(1)).trim();
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: themeColor.withOpacity(0.12), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: emoji.isNotEmpty
                ? Text(
                    emoji,
                    style: TextStyle(fontSize: 18.sp),
                  )
                : Icon(
                    fallbackIcon,
                    color: themeColor,
                    size: 18.r,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              cleanLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_DetectiveLevel level) {
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
              color: _timeLeft <= 8 && !_showIntro
                  ? const Color(0xFFFF1744).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: _timeLeft <= 8 && !_showIntro ? const Color(0xFFFF8A80) : Colors.white,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  _showIntro ? '∞' : '$_timeLeft',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 8 && !_showIntro ? const Color(0xFFFF8A80) : Colors.white,
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
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18.w),
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

  Widget _buildAncientTabletCard(_DetectiveLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF8D6E63), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.12),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD7CCC8),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8D6E63).withOpacity(0.2),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.saved_search_rounded,
                  color: level.bgGradient.first,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Manh mối khảo cổ học:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5.w),
                ),
                child: Text(
                  level.emoji,
                  style: TextStyle(fontSize: 34.sp),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dịch nghĩa: ${level.vietnameseTranslation}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4E342E),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Bé hãy tìm: ${level.missingPartVietnamese}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8D6E63),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcavationZone(_DetectiveLevel level) {
    final List<String> parts = level.displayProblem.split(' ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Bia Đá Granite Khảo Cổ 🏛️',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF8D6E63),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 18.h),
          // Hiển thị từ với các ô chữ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: parts.map((part) {
              final isMissingSlot = (part == '្ក' || part == '្ម' || part == '្ល' || part == '្រ');
              final isFilled = _isRoundCompleted && (_selectedChoice == level.correctAnswer);

              if (isMissingSlot) {
                final isZoomed = _showCorrectAnswerZoom;
                final displayChar = (isFilled || isZoomed) ? level.correctAnswer : '?';
                
                Widget slotContent = Container(
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    color: (isFilled || isZoomed) 
                        ? const Color(0xFFFFF8E1) 
                        : const Color(0xFF4E342E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: (isFilled || isZoomed) ? const Color(0xFFFFB300) : const Color(0xFF8D6E63),
                      width: 2.5.w,
                    ),
                    boxShadow: [
                      if (isFilled || isZoomed)
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.5),
                          blurRadius: 10.r,
                          spreadRadius: 2.r,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayChar,
                      style: GoogleFonts.battambang(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: (isFilled || isZoomed) ? const Color(0xFFE65100) : const Color(0xFF8D6E63),
                      ),
                    ),
                  ),
                );

                if (isZoomed) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.4,
                        child: slotContent,
                      ),
                      Positioned(
                        bottom: -22.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE082),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: const Color(0xFFFFB300), width: 1.w),
                          ),
                          child: Text(
                            'Chân chữ đúng',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return slotContent;
              }

              // Các phụ âm thường khắc nổi
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                child: Text(
                  part,
                  style: GoogleFonts.battambang(
                    fontSize: 38.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4E342E),
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
            'Chọn mảnh cổ thạch để gõ búa khảo cổ:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4E342E),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: level.choices.map((choice) {
            final isSelected = (_selectedChoice == choice);
            final isCorrect = (choice == level.correctAnswer);

            Color btnColor = const Color(0xFFD7CCC8); // Sandy stone block
            Color borderColor = const Color(0xFF8D6E63);
            Color textColor = const Color(0xFF4E342E);

            if (_isRoundCompleted && isSelected) {
              if (isCorrect) {
                btnColor = const Color(0xFFE8F5E9); // Emerald success
                borderColor = const Color(0xFF4CAF50);
                textColor = const Color(0xFF1B5E20);
              } else {
                btnColor = const Color(0xFFFFCDD2); // Ruby error
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
                  padding: EdgeInsets.symmetric(vertical: 18.h),
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
                              color: const Color(0xFF5D4037).withOpacity(0.3),
                              offset: Offset(0, 5.h),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      choice,
                      style: GoogleFonts.battambang(
                        fontSize: 28.sp,
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

  Widget _buildIntroScreen(_DetectiveLevel level) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: const Color(0xFF8D6E63), width: 4.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: const Color(0xFF795548), size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'BÀI HỌC VỀ CHÂN CHỮ',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        color: const Color(0xFF5D4037),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              
              Text(
                'Từ mẫu hoàn chỉnh:',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 12.h),
              
              Container(
                height: 180.h,
                width: double.infinity,
                alignment: Alignment.center,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    final subConsonantYOffset = value * 45.h;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 20.h,
                          child: Text(
                            level.correctWord[0],
                            style: GoogleFonts.battambang(
                              fontSize: 54.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4E342E),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20.h + 20.h + subConsonantYOffset,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Color.lerp(Colors.transparent, const Color(0xFFFFF8E1), value),
                              border: Border.all(
                                color: Color.lerp(Colors.transparent, const Color(0xFFFFB300), value)!,
                                width: 2.w,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              level.correctAnswer,
                              style: GoogleFonts.battambang(
                                fontSize: 34.sp,
                                fontWeight: FontWeight.bold,
                                color: Color.lerp(const Color(0xFF4E342E), const Color(0xFFE65100), value)!,
                              ),
                            ),
                          ),
                        ),
                        if (value > 0.6)
                          Positioned(
                            top: 115.h,
                            child: AnimatedOpacity(
                              opacity: (value - 0.6) / 0.4,
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                '👇 Chân chữ: ${level.missingPartVietnamese}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.sp,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              
              Text(
                '${level.emoji} ${level.vietnameseTranslation} (${level.pronunciation})',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  color: const Color(0xFF4E342E),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Trong tiếng Khmer, chân chữ (Coeng) là dạng ký hiệu viết dưới phụ âm chính để tạo thành tổ hợp âm ghép khó.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5.sp,
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 32.h),
              
              _IntroStartButton(
                onPressed: () {
                  setState(() {
                    _showIntro = false;
                  });
                  _startTimer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroStartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _IntroStartButton({required this.onPressed});

  @override
  State<_IntroStartButton> createState() => _IntroStartButtonState();
}

class _IntroStartButtonState extends State<_IntroStartButton> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _secondsLeft == 0;
    return GestureDetector(
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF8D6E63)])
              : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400]),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isEnabled ? const Color(0xFF4E342E) : Colors.grey.shade500,
            width: 2.w,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withOpacity(0.3),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            isEnabled ? 'Tôi hiểu rồi — Bắt đầu! 🚀' : 'Học bài... ($_secondsLeft giây)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
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
