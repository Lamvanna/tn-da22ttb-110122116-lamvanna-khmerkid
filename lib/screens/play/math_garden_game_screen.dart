import 'dart:async';
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

  // Power-ups
  int _hintsLeft = 2;
  int _timePowerupsLeft = 2;
  int _livesPowerupsLeft = 1;
  int _doubleScorePowerupsLeft = 1;
  bool _isDoubleScoreActive = false;

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
    if (mounted) {
      setState(() {
        _hintsLeft = _scoreService?.hintsLeft ?? 2;
        _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
        _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
        _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      });
    }
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
        question: 'Bé hãy tính phép cộng sau bằng chữ số Khmer: ១ + ½ = ?',
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

  // Helper to format cooldown remaining seconds into readable time
  String _formatCooldown(int seconds) {
    if (seconds <= 0) return '0 giây';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    
    if (h > 0) {
      return '$h giờ $m phút';
    } else if (m > 0) {
      return '$m phút $s giây';
    } else {
      return '$s giây';
    }
  }

  void _showCooldownMessage(String itemName, int remainingSeconds) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                'Vật phẩm $itemName đang hồi phục! Cần thêm ${_formatCooldown(remainingSeconds)} ⏳',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Powerups Logic ──
  void _useHint() {
    if (_isRoundCompleted || _gameOver) return;
    if (_hintsLeft <= 0) {
      final remaining = _scoreService?.hintsCooldownRemaining ?? 0;
      _showCooldownMessage('Gợi ý 🔍', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    final currentLevel = _levels[_currentLevelIdx];
    setState(() {
      _hintsLeft--;
    });
    _scoreService?.useHint();
    _onChoiceSelected(currentLevel.correctAnswer);
  }

  void _useTimePowerup() {
    if (_isRoundCompleted || _gameOver) return;
    if (_timePowerupsLeft <= 0) {
      final remaining = _scoreService?.timeCooldownRemaining ?? 0;
      _showCooldownMessage('Thêm giờ ⏰', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _timePowerupsLeft--;
      _timeLeft += 10;
    });
    _scoreService?.useTimePowerup();
  }

  void _useLivesPowerup() {
    if (_isRoundCompleted || _gameOver) return;
    if (_livesPowerupsLeft <= 0) {
      final remaining = _scoreService?.livesCooldownRemaining ?? 0;
      _showCooldownMessage('Thêm mạng ❤️', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _livesPowerupsLeft--;
      if (_lives < 3) _lives++;
    });
    _scoreService?.useLivesPowerup();
  }

  void _useDoubleScorePowerup() {
    if (_isRoundCompleted || _gameOver || _isDoubleScoreActive) return;
    if (_doubleScorePowerupsLeft <= 0) {
      final remaining = _scoreService?.doubleScoreCooldownRemaining ?? 0;
      _showCooldownMessage('Nhân đôi điểm ⭐', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _doubleScorePowerupsLeft--;
      _isDoubleScoreActive = true;
    });
    _scoreService?.useDoubleScorePowerup();
  }

  Widget _buildSmallVerticalPowerUpBtn({
    required String emoji,
    required int count,
    required VoidCallback onTap,
    required List<Color> activeColors,
    required Color shadowColor,
    bool isActiveGlow = false,
  }) {
    final hasItem = count > 0;
    return GestureDetector(
      onTap: !_isRoundCompleted && !_gameOver ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: isActiveGlow
                    ? [const Color(0xFFFFD600), const Color(0xFFFF8F00)]
                    : hasItem
                        ? activeColors
                        : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)]),
              border: Border.all(
                color: isActiveGlow ? Colors.white : Colors.white.withValues(alpha: 0.6),
                width: isActiveGlow ? 2.8 : 1.8),
              boxShadow: [
                BoxShadow(
                  color: isActiveGlow
                      ? const Color(0xFFFF8F00)
                      : hasItem ? shadowColor : const Color(0xFFB0BEC5),
                  offset: const Offset(0, 5), blurRadius: 0),
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 5), blurRadius: 5),
              ]),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 30.sp)),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -5.h,
              right: -5.w,
              child: Container(
                width: 26.w, height: 26.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2, offset: const Offset(0, 1))
                  ]),
                child: Center(
                  child: Text('$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0.sp, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white,
                      height: 1.0,
                    )),
                ),
              ),
            ),
        ],
      ),
    );
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
      _hintsLeft = _scoreService?.hintsLeft ?? 2;
      _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
      _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
      _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      _isDoubleScoreActive = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 40;
    });
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
    _scoreService?.completeGame('math_garden', _score, syncToBackend: true);
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

      if (_gameOver) {
        _scoreService?.completeGame('math_garden', _score, syncToBackend: true);
      } else {
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
    int addedScore = 15;
    if (_isDoubleScoreActive) {
      addedScore = 30;
      _isDoubleScoreActive = false;
    }
    setState(() {
      _score += addedScore;
    });
    _scoreService?.completeGame('math_garden', addedScore, syncToBackend: false);

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
    _scoreService?.completeGame('math_garden', _score, syncToBackend: true);
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

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _timer?.cancel();
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

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    _pauseTimer();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFFFCC80), width: 2.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đợi đã Bé ơi! 🥺',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE65100),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Bé có chắc chắn muốn thoát trò chơi không? Tiến trình chơi hiện tại sẽ không được lưu lại đâu! 😭',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D4037),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5.w),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0xFFBF360C),
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Tiếp tục chơi 🎮',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFB0BEC5), width: 1.5.w),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0xFFB0BEC5),
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Thoát 🚪',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFE53935),
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
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = _levels[_currentLevelIdx];

    return PopScope(
      canPop: !_gameStarted || _gameOver,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        body: Stack(
        children: [
          // ── Background Gradient (Soft Pastel Gold) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // ── Beautiful Rural Scenery Overlay Layer ──
          Opacity(
            opacity: 0.35,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBoJptYW0FURDJyaNotaS25b4rd3BMGg54qWp9sofqqLryGPpHttzs3n7fWq_6hwuZxJbZWw9x27OLzQ0TcxJowDDF6psN04fEqfXpnKk-ciWw-Cwoe43jFvmY4md5yJxBlBws14RTo3W4ySrM_xsXMFWHWFze0YckgGbo39IyIZzHP1_VYzsMQ9pnnj7yNYMAlh84lig__sTm7yDHG2feGTJ-PkLHZu88Q6S4roim5toebUO4Yi_IuB3zhK39Ol-7QaiTaHvdFow',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          SafeArea(
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
                                      child: _buildUnifiedQuestionCard(currentLevel),
                                    ),

                                    SizedBox(height: 24.h),

                                    // 🪧 BẢNG HIỆU LỰA CHỌN PHONG CÁCH BẢNG GỖ (Choices)
                                    _buildChoicesGrid(currentLevel),

                                    SizedBox(height: 24.h),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ⚡ THANH PHẦN BỔ TRỢ (Pinned Power-ups Horizontal Row at bottom)
                          Padding(
                            padding: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSmallVerticalPowerUpBtn(
                                  emoji: '🔍',
                                  count: _hintsLeft,
                                  onTap: _useHint,
                                  activeColors: [const Color(0xFFFFD54F), const Color(0xFFFFA000)],
                                  shadowColor: const Color(0xFFE65100),
                                ),
                                SizedBox(width: 16.w),
                                _buildSmallVerticalPowerUpBtn(
                                  emoji: '⏰',
                                  count: _timePowerupsLeft,
                                  onTap: _useTimePowerup,
                                  activeColors: [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
                                  shadowColor: const Color(0xFF01579B),
                                ),
                                SizedBox(width: 16.w),
                                _buildSmallVerticalPowerUpBtn(
                                  emoji: '❤️',
                                  count: _livesPowerupsLeft,
                                  onTap: _useLivesPowerup,
                                  activeColors: [const Color(0xFFFF8A80), const Color(0xFFE53935)],
                                  shadowColor: const Color(0xFFB71C1C),
                                ),
                                SizedBox(width: 16.w),
                                _buildSmallVerticalPowerUpBtn(
                                  emoji: '⭐',
                                  count: _doubleScorePowerupsLeft,
                                  onTap: _useDoubleScorePowerup,
                                  activeColors: [const Color(0xFFB388FF), const Color(0xFF6200EA)],
                                  shadowColor: const Color(0xFF4527A0),
                                  isActiveGlow: _isDoubleScoreActive,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
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
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.local_florist_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '🍎 Khu vườn Toán học',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFF5D4037),
                    offset: Offset(2.w, 2.h),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Đếm số trái chín và làm các phép tính đố\nthú vị cùng các bạn nhỏ bằng chữ số Khmer!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🍏', 'Đếm số quả chín hoặc giải phép toán đố'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', '40 giây cho mỗi lượt tính đố vui'),
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
                padding: EdgeInsets.symmetric(horizontal: 52.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFBF360C),
                      offset: Offset(0, 6),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 8),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  'BẮT ĐẦU CHƠI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 1.5),
                      ),
                    ],
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
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
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
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFFB71C1C),
                    offset: Offset(2.w, 2.h),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Khu vườn đang gặp bão cát tàn phá. Bé hãy chơi lại để giúp bảo vệ khu vườn chín ngọt nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16.r,
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
                        border: Border.all(color: const Color(0xFFB0BEC5), width: 1.5.w),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xFFB0BEC5),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Thoát',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF374151),
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
                          colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5.w),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xFFBF360C),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
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
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 1),
                              ),
                            ],
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
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFF176),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(_MathLevel level) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exit back (Tactile 3D White Glassmorphic Button)
              GestureDetector(
                onTap: () async {
                  final shouldPop = await _showExitConfirmationDialog(context);
                  if (shouldPop && mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 36.w, height: 36.w,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    border: Border.all(color: Colors.white, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, 3), blurRadius: 6),
                    ]),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF374151), size: 20)),
              ),
              // Star score badge (yellow 3D)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF176), Color(0xFFFBC02D)]),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5.w),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFFF57F17), offset: Offset(0, 2), blurRadius: 0),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 3),
                  ]),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 18.w),
                  SizedBox(width: 4.w),
                  Text('$_score',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
              ),
              SizedBox(width: 8.w),
              // Hearts badge (Premium 3D Glassmorphic Capsule)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFFEBEE)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5.w),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFEF9A9A),
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 3),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(3, (i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                    child: Icon(
                      i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: i < _lives ? const Color(0xFFEF5350) : const Color(0xFFB0BEC5),
                      size: 16.w,
                    ),
                  )),
                ),
              ),
            ],
          ),
          // Timer (blue 3D or red 3D if time is low)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: _timeLeft <= 5
                    ? [const Color(0xFFF87171), const Color(0xFFEF4444)]
                    : [const Color(0xFF4DD0E1), const Color(0xFF00ACC1)]),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white, width: 1.5.w),
              boxShadow: [
                BoxShadow(
                  color: _timeLeft <= 5
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF00838F),
                  offset: const Offset(0, 2), blurRadius: 0),
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 3),
              ]),
            child: Row(children: [
              Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 16.w),
              SizedBox(width: 6.w),
              Text('${_timeLeft}s',
                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedQuestionCard(_MathLevel level) {
    final isCounting = !level.khmerProblem.contains('+') && !level.khmerProblem.contains('-');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main parchment container
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 14.h),
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF0), // Parchment cream background
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFF8D6E63), width: 3.5.w), // Wooden frame border
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: 0.15),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Question text
              Text(
                level.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5D4037),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),

              // Visual emojis display inside warm basket box
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), // Picnic basket blanket
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1.5.w),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14.w,
                  runSpacing: 14.h,
                  children: level.visualEmojis.map((emoji) {
                    return Text(
                      emoji,
                      style: TextStyle(fontSize: 52.sp),
                    );
                  }).toList(),
                ),
              ),

              // Equation blackboard (only shown for math equation rounds)
              if (!isCounting) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20), // Chalkboard green
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 3.w), // Wooden frame
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: Offset(0, 4.h),
                        blurRadius: 6.r,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      level.khmerProblem,
                      style: GoogleFonts.battambang(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFF59D), // Pastel yellow chalk
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Overlapping Purple Level Banner at the top center
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white, width: 1.5.w),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFF4A148C),
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Câu ${_currentLevelIdx + 1} / ${_levels.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
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

  Widget _buildChoicesGrid(_MathLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Green banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2.w),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFF1B5E20),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 3),
                blurRadius: 3,
              ),
            ],
          ),
          child: Text(
            'Chọn chữ số Khmer tương ứng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: level.choices.map((choice) {
            final isSelected = (_selectedChoice == choice);
            final isCorrect = (choice == level.correctAnswer);

            // Default wood gradient styling
            Gradient btnGradient = const LinearGradient(
              colors: [Color(0xFFE2C29D), Color(0xFFC49A6C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            );
            Color borderColor = const Color(0xFF8D6E63);
            Color shadowColor = const Color(0xFF5D4037);
            Color textColor = const Color(0xFF4E342E);

            if (_isRoundCompleted && isSelected) {
              if (isCorrect) {
                btnGradient = const LinearGradient(
                  colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
                borderColor = const Color(0xFF1B5E20);
                shadowColor = const Color(0xFF1B5E20);
                textColor = const Color(0xFF1B5E20);
              } else {
                btnGradient = const LinearGradient(
                  colors: [Color(0xFFEF9A9A), Color(0xFFEF5350)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
                borderColor = const Color(0xFFB71C1C);
                shadowColor = const Color(0xFFB71C1C);
                textColor = const Color(0xFFB71C1C);
              }
            }

            return Expanded(
              child: AspectRatio(
                aspectRatio: 1.0, // Square choice cards
                child: GestureDetector(
                  onTap: () => _onChoiceSelected(choice),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    decoration: BoxDecoration(
                      gradient: btnGradient,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 3.5.w : 2.5.w,
                      ),
                      boxShadow: isSelected && _isRoundCompleted
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: shadowColor,
                                offset: Offset(0, 6.h),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                offset: Offset(0, 6.h),
                                blurRadius: 4,
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        // Screws at 4 corners
                        Positioned(
                          left: 6.w, top: 6.h,
                          child: _buildScrew(),
                        ),
                        Positioned(
                          right: 6.w, top: 6.h,
                          child: _buildScrew(),
                        ),
                        Positioned(
                          left: 6.w, bottom: 6.h,
                          child: _buildScrew(),
                        ),
                        Positioned(
                          right: 6.w, bottom: 6.h,
                          child: _buildScrew(),
                        ),

                        // The choice number text
                        Center(
                          child: Text(
                            choice,
                            style: GoogleFonts.battambang(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildScrew() {
    return Container(
      width: 4.w,
      height: 4.w,
      decoration: BoxDecoration(
        color: const Color(0xFFB0BEC5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF78909C), width: 0.5.w),
      ),
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
