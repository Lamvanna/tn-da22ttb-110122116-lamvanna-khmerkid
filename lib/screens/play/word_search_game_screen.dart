import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Trò chơi: 🌲 Giải cứu thú rừng (Khmer Word Search & Rescue)
/// Bé tìm các chữ cái tạo nên tên con vật để giải cứu chúng.
class WordSearchGameScreen extends StatefulWidget {
  const WordSearchGameScreen({super.key});

  @override
  State<WordSearchGameScreen> createState() => _WordSearchGameScreenState();
}

class _WordSearchGameScreenState extends State<WordSearchGameScreen>
    with SingleTickerProviderStateMixin {
  late List<_Level> _levels;
  int _currentLevelIdx = 0;
  int _score = 0;
  List<Point<int>> _selectedPoints = [];
  bool _isRoundCompleted = false;
  ScoreService? _scoreService;

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 30;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initLevels();
    _initAnimations();
  }

  void _initAnimations() {
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bubbleAnimation = Tween<double>(begin: -6.h, end: 6.h).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  void _initLevels() {
    _levels = [
      _Level(
        animalVietnamese: 'CON VOI',
        khmerWord: 'ដំរី',
        romanized: 'dâm-rei',
        emoji: '🐘',
        objective: 'Tìm phụ âm ដ, nguyên âm ំ, phụ âm រ, nguyên âm ី',
        grid: [
          ['ក', 'ខ', 'គ', 'ឃ', 'ង'],
          ['ដ', 'ំ', 'រ', 'ី', 'ច'],
          ['ឆ', 'ជ', 'ឈ', 'ញ', 'ដ'],
          ['ឋ', 'ឌ', 'ឍ', 'ណ', 'ត'],
          ['ថ', 'ទ', 'ធ', 'ន', 'ប'],
        ],
        path: [
          const Point(1, 0),
          const Point(1, 1),
          const Point(1, 2),
          const Point(1, 3),
        ],
      ),
      _Level(
        animalVietnamese: 'CON HỔ',
        khmerWord: 'ខ្លា',
        romanized: 'khla',
        emoji: '🐯',
        objective: 'Tìm phụ âm ខ, chân chữ ្ល, nguyên âm ា',
        grid: [
          ['ញ', 'ដ', 'ឋ', 'ឌ', 'ឍ'],
          ['ណ', 'ត', 'ថ', 'ទ', 'ធ'],
          ['ខ', '្ល', 'ា', 'ន', 'ប'],
          ['ផ', 'ព', 'ភ', 'ម', 'យ'],
          ['រ', 'ល', 'វ', 'ស', 'ហ'],
        ],
        path: [
          const Point(2, 0),
          const Point(2, 1),
          const Point(2, 2),
        ],
      ),
      _Level(
        animalVietnamese: 'CON KHỈ',
        khmerWord: 'ស្វា',
        romanized: 'sva',
        emoji: '🐒',
        objective: 'Tìm phụ âm ស, chân chữ ្វ, nguyên âm ា',
        grid: [
          ['ឡ', 'អ', 'ក', 'ខ', 'គ'],
          ['ឃ', 'ង', 'ច', 'ឆ', 'ជ'],
          ['ឈ', 'ស', 'ញ', 'ដ', 'ឋ'],
          ['ឌ', '្វ', 'ឍ', 'ណ', 'ត'],
          ['ថ', 'ា', 'ទ', 'ធ', 'ន'],
        ],
        path: [
          const Point(2, 1),
          const Point(3, 1),
          const Point(4, 1),
        ],
      ),
      _Level(
        animalVietnamese: 'CON CÁ',
        khmerWord: 'ត្រី',
        romanized: 'trei',
        emoji: '🐟',
        objective: 'Tìm phụ âm ត, chân chữ ្រ, nguyên âm ី',
        grid: [
          ['ត', 'ខ', 'គ', 'ឃ', 'ង'],
          ['្រ', 'ច', 'ឆ', 'ជ', 'ឈ'],
          ['ី', 'ញ', 'ដ', 'ឋ', 'ឌ'],
          ['ឍ', 'ណ', 'ត', 'ថ', 'ទ'],
          ['ធ', 'ន', 'ប', 'ផ', 'ព'],
        ],
        path: [
          const Point(0, 0),
          const Point(1, 0),
          const Point(2, 0),
        ],
      ),
      _Level(
        animalVietnamese: 'CON ONG',
        khmerWord: 'ឃ្មុំ',
        romanized: 'khmum',
        emoji: '🐝',
        objective: 'Tìm phụ âm ឃ, chân chữ ្ម, nguyên âm ុំ',
        grid: [
          ['ភ', 'ម', 'យ', 'រ', 'ល'],
          ['វ', 'ស', 'ហ', 'ឡ', 'អ'],
          ['ក', 'ខ', 'គ', 'ឃ', 'ង'],
          ['ច', 'ឆ', 'ជ', '្ម', 'ញ'],
          ['ដ', 'ឋ', 'ឌ', 'ុំ', 'ឍ'],
        ],
        path: [
          const Point(2, 3),
          const Point(3, 3),
          const Point(4, 3),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bubbleController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 0;
      _currentLevelIdx = 0;
      _selectedPoints.clear();
      _isRoundCompleted = false;
      _gameOver = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 30;
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

  void _onCellTap(int row, int col) {
    if (_isRoundCompleted || _gameOver) return;

    final currentLevel = _levels[_currentLevelIdx];
    final tappedPoint = Point(row, col);

    final nextTargetIndex = _selectedPoints.length;
    if (nextTargetIndex < currentLevel.path.length) {
      final targetPoint = currentLevel.path[nextTargetIndex];

      if (tappedPoint == targetPoint) {
        // Bé ấn đúng!
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPoints.add(tappedPoint);
        });

        // Kiểm tra xem đã hoàn thành từ chưa
        if (_selectedPoints.length == currentLevel.path.length) {
          _timer?.cancel();
          _onRoundSuccess();
        }
      } else {
        // Bé ấn sai nét -> Rung phản hồi báo sai, trừ 1 mạng
        HapticFeedback.vibrate();
        setState(() {
          _selectedPoints.clear();
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
                'Chưa đúng rồi! Bé bị mất 1 mạng tim 💔. Bé hãy tìm lại nhé!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            ),
          );
        }
      }
    }
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    setState(() {
      _isRoundCompleted = true;
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
                    'Giải cứu thành công! 🐾',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'Chuẩn bị tiến sang khu rừng tiếp theo...',
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
        _selectedPoints.clear();
        _isRoundCompleted = false;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
    _timer?.cancel();
    _score = 10;
    _scoreService?.completeGame('word_search', 10);
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
                '🏆 CHIẾN THẮNG! 🏆',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '🌳🐾🐯🐘🐟🐝',
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chúc mừng Bé đã giải cứu thành công toàn bộ thú rừng và hoàn thành thử thách xuất sắc!',
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
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: !_gameStarted
              ? _buildStartScreen()
              : _gameOver
                  ? _buildGameOverScreen()
                  : _buildGamePlay(currentLevel),
        ),
      ),
    );
  }

  Widget _buildGamePlay(_Level level) {
    return Column(
      children: [
        _buildHeader(level),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),

                  // 🐘 KHU VỰC THÚ CẦN GIẢI CỨU (Bubble Animation)
                  AnimatedBuilder(
                    animation: _bubbleAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bubbleAnimation.value),
                        child: child,
                      );
                    },
                    child: _buildRescueCard(level),
                  ),

                  SizedBox(height: 20.h),

                  // 🧩 LƯỚI Ô CHỮ KHMER 5X5
                  _buildWordGrid(level),

                  SizedBox(height: 24.h),

                  // 📝 HƯỚNG DẪN TỪNG CHỮ CÁI
                  _buildProgressRow(level),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.forest_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '🌲 Giải cứu thú rừng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Tìm các chữ cái Khmer để ghép thành tên\ncác loài thú và giải thoát chúng khỏi bong bóng!',
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
                border: Border.all(color: const Color(0xFF81C784), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🦁', 'Tìm tên con thú trong lưới ô chữ'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', '30 giây cho mỗi lượt chơi'),
                  SizedBox(height: 10.h),
                  _ruleRow('💖', '3 mạng tim - Bấm sai nét sẽ bị trừ mạng'),
                  SizedBox(height: 10.h),
                  _ruleRow('🌟', 'Giải cứu thành công để nhận điểm thưởng'),
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
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF1B5E20), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.4),
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
              color: const Color(0xFF1B5E20),
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
              'Bé đừng nản lòng nhé! Hãy thử lại để giải cứu các bạn thú rừng đáng yêu nhé.',
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
                  _statRow('🦁 Số thú giải cứu', '$_currentLevelIdx / ${_levels.length}'),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF1B5E20), width: 2.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
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

  Widget _buildHeader(_Level level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
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

  Widget _buildRescueCard(_Level level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF81C784), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.12),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bubble Animating Animal representation
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.cyan.shade100,
                      Colors.cyan.shade300,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 3.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 10.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
              ),
              Text(
                level.emoji,
                style: TextStyle(fontSize: 44.sp),
              ),
              if (!_isRoundCompleted)
                // Lock overlay to show it is trapped!
                Positioned(
                  bottom: 2.h,
                  right: 2.w,
                  child: Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BÉ HÃY GIẢI CỨU:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  level.animalVietnamese,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  level.objective,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordGrid(_Level level) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 25, // 5x5
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final r = index ~/ 5;
          final c = index % 5;
          final letter = level.grid[r][c];

          final point = Point(r, c);
          final isSelected = _selectedPoints.contains(point);
          final selectionIndex = _selectedPoints.indexOf(point);

          return GestureDetector(
            onTap: () => _onCellTap(r, c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.bounceOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4CAF50) // Bright playful green
                    : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFA5D6A7),
                  width: isSelected ? 3.w : 2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF1B5E20).withOpacity(0.4)
                        : const Color(0xFFC8E6C9),
                    offset: Offset(0, isSelected ? 2.h : 5.h),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      letter,
                      style: GoogleFonts.battambang(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 3.h,
                        right: 3.w,
                        child: Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${selectionIndex + 1}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressRow(_Level level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF8D6E63), // Rustic wooden board brown
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF5D4037), width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 6.h),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tấm Bảng Từ Của Bé 🪵',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(level.path.length, (idx) {
              final targetPoint = level.path[idx];
              final cellVal = level.grid[targetPoint.x][targetPoint.y];

              final isFilled = _selectedPoints.length > idx;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: isFilled ? const Color(0xFFFFD54F) : const Color(0xFF5D4037).withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFilled ? const Color(0xFFFFB300) : const Color(0xFF4E342E),
                    width: 2.5.w,
                  ),
                  boxShadow: [
                    if (isFilled)
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.4),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isFilled ? cellVal : '?',
                    style: GoogleFonts.battambang(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isFilled ? const Color(0xFF5D4037) : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Level {
  final String animalVietnamese;
  final String khmerWord;
  final String romanized;
  final String emoji;
  final String objective;
  final List<List<String>> grid;
  final List<Point<int>> path;

  _Level({
    required this.animalVietnamese,
    required this.khmerWord,
    required this.romanized,
    required this.emoji,
    required this.objective,
    required this.grid,
    required this.path,
  });
}
