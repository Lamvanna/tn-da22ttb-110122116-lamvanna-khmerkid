import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/admin_service.dart';

/// Trò chơi: 🌲 Giải cứu thú rừng (Khmer Word Search & Rescue)
/// Bé tìm các chữ cái tạo nên tên con vật để giải cứu chúng.
class WordSearchGameScreen extends StatefulWidget {
  const WordSearchGameScreen({super.key});

  @override
  State<WordSearchGameScreen> createState() => _WordSearchGameScreenState();
}

class _WordSearchGameScreenState extends State<WordSearchGameScreen>
    with SingleTickerProviderStateMixin {
  List<_Level> _levels = [];
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

  // Powerups State
  int _hintsLeft = 2;
  int _timePowerupsLeft = 2;
  int _livesPowerupsLeft = 1;
  int _doubleScorePowerupsLeft = 1;
  bool _isDoubleScoreActive = false;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initLevels();
    _loadGameQuestions();
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
    if (mounted) {
      setState(() {
        _hintsLeft = _scoreService?.hintsLeft ?? 2;
        _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
        _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
        _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      });
    }
  }

  Future<void> _loadGameQuestions() async {
    try {
      final result = await AdminService().fetchGameQuestionsForUser('word_search');
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null && (result['data'] as List).isNotEmpty) {
        final list = result['data'] as List;
        final parsed = list.map((q) {
          final additional = q['additionalData'] as Map?;
          
          // Parse grid
          final rawGrid = additional?['grid'] as List?;
          final List<List<String>> parsedGrid = [];
          if (rawGrid != null) {
            for (var r in rawGrid) {
              if (r is List) {
                parsedGrid.add(r.map((c) => c.toString()).toList());
              }
            }
          }
          
          // Parse path
          final rawPath = additional?['path'] as List?;
          final List<Point<int>> parsedPath = [];
          if (rawPath != null) {
            for (var p in rawPath) {
              if (p is List && p.length >= 2) {
                parsedPath.add(Point((p[0] as num).toInt(), (p[1] as num).toInt()));
              }
            }
          }
          
          final khmerWord = q['answer'] ?? '';
          final animalViet = q['prompt'] ?? '';
          final romanized = additional?['romanized']?.toString() ?? '';
          final emoji = additional?['emoji']?.toString() ?? '🐾';
          final objective = additional?['objective']?.toString() ?? 'Tìm các chữ cái';

          if (parsedGrid.isNotEmpty && parsedPath.isNotEmpty) {
            return _Level(
              animalVietnamese: animalViet,
              khmerWord: khmerWord,
              romanized: romanized,
              emoji: emoji,
              objective: objective,
              grid: parsedGrid,
              path: parsedPath,
            );
          }
          return null;
        }).whereType<_Level>().toList();

        if (parsed.isNotEmpty) {
          setState(() {
            _levels = parsed;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading word search questions: $e');
    }
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
          ['ផ', 'ព', 'ភ', 'ម', 'យ'],
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
          ['ឡ', 'អ', 'ក', 'ខ', 'គ'],
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
          ['ផ', 'ព', 'ភ', 'ម', 'យ'],
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
          ['ឡ', 'អ', 'ក', 'ខ', 'គ'],
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
          ['ត', 'ថ', 'ទ', 'ធ', 'ន'],
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
    _scoreService?.completeGame('Giải cứu thú rừng', _score, syncToBackend: true);
  }

  void _onCellTap(int row, int col) {
    if (_isRoundCompleted || _gameOver) return;

    final currentLevel = _levels[_currentLevelIdx];
    final tappedPoint = Point(row, col);

    setState(() {
      if (_selectedPoints.contains(tappedPoint)) {
        // Nếu ô đã được chọn, xóa ô đó và tất cả các ô sau nó
        final idx = _selectedPoints.indexOf(tappedPoint);
        _selectedPoints.removeRange(idx, _selectedPoints.length);
        HapticFeedback.lightImpact();
      } else {
        // Nếu chưa được chọn và chưa chọn đủ số lượng chữ
        if (_selectedPoints.length < currentLevel.path.length) {
          _selectedPoints.add(tappedPoint);
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  void _checkAnswer() {
    if (_isRoundCompleted || _gameOver) return;

    final currentLevel = _levels[_currentLevelIdx];
    
    // Kiểm tra xem các ô đã chọn có khớp hoàn toàn với đường dẫn đáp án không
    bool isCorrect = true;
    if (_selectedPoints.length != currentLevel.path.length) {
      isCorrect = false;
    } else {
      for (int i = 0; i < currentLevel.path.length; i++) {
        if (_selectedPoints[i] != currentLevel.path[i]) {
          isCorrect = false;
          break;
        }
      }
    }

    if (isCorrect) {
      _timer?.cancel();
      _onRoundSuccess();
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
      
      if (_gameOver) {
        _scoreService?.completeGame('Giải cứu thú rừng', _score, syncToBackend: true);
      } else {
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

  Widget _buildConfirmButton() {
    final currentLevel = _levels[_currentLevelIdx];
    final canConfirm = _selectedPoints.length == currentLevel.path.length && !_isRoundCompleted && !_gameOver;
    return GestureDetector(
      onTap: canConfirm ? _checkAnswer : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: canConfirm
                ? [const Color(0xFF00E676), const Color(0xFF00C853)]
                : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)]),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: canConfirm ? Colors.white.withOpacity(0.5) : Colors.white24,
            width: 1.5,
          ),
          boxShadow: [
            if (canConfirm) ...[
              const BoxShadow(
                color: Color(0xFF00A343),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.3),
                offset: const Offset(0, 6),
                blurRadius: 10,
              ),
            ] else ...[
              const BoxShadow(
                color: Color(0xFFB0BEC5),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ]
          ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('XÁC NHẬN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: canConfirm ? Colors.white : const Color(0xFF90A4AE),
              letterSpacing: 0.5,
              shadows: canConfirm
                  ? [Shadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 1.5))]
                  : null,
            )),
          SizedBox(width: 10.w),
          Container(
            width: 22.w, height: 22.w,
            decoration: BoxDecoration(
              color: canConfirm ? Colors.white : const Color(0xFFB0BEC5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.check_rounded,
                color: canConfirm ? const Color(0xFF00C853) : Colors.white,
                size: 14.w,
                weight: 900),
            ),
          ),
        ]),
      ),
    );
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    int addedScore = 15;
    if (_isDoubleScoreActive) {
      addedScore = 30;
      _isDoubleScoreActive = false; // Reset multiplier after use
    }
    setState(() {
      _isRoundCompleted = true;
      _score += addedScore;
    });

    _scoreService?.completeGame('Giải cứu thú rừng', addedScore, syncToBackend: false);

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
    _scoreService?.completeGame('Giải cứu thú rừng', _score, syncToBackend: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90.w, height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3C4), Color(0xFFFFB300)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  border: Border.all(color: Colors.white, width: 3.w),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFFD97706), offset: Offset(0, 4.5), blurRadius: 0),
                    BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 5), blurRadius: 5),
                  ]),
                child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48.w),
              ),
              SizedBox(height: 20.h),
              Text(
                'CHIẾN THẮNG MỸ MÃN! 🏆',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Chúc mừng Bé đã giải cứu thành công toàn bộ thú rừng và hoàn thành thử thách xuất sắc!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  'Tổng điểm đạt được: +$_score Điểm 🌟',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0A030),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF1B5E20), width: 1.5),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFF1B5E20), offset: Offset(0, 4), blurRadius: 0),
                    ]),
                  child: Center(
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
    if (_levels.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
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
          // ── Background Gradient (Soft Pastel Sky to Mint) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFE0F7FA), Color(0xFFC8E6C9)],
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
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // ── Safe Area Content ──
          SafeArea(
            child: !_gameStarted
                ? _buildStartScreen()
                : _gameOver
                    ? _buildGameOverScreen()
                    : _buildGamePlay(currentLevel),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildGamePlay(_Level level) {
    return Column(
      children: [
        _buildHeaderStats(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 16.w, right: 10.w, top: 8.h, bottom: 40.h),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animal Card on the left
                    Expanded(
                      child: _buildRescueCard(level),
                    ),
                    SizedBox(width: 8.w),
                    // Vertical Powerups Column next to the card
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallVerticalPowerUpBtn(
                          emoji: '🔍',
                          count: _hintsLeft,
                          onTap: _useHint,
                          activeColors: [const Color(0xFFFFD54F), const Color(0xFFFFA000)],
                          shadowColor: const Color(0xFFE65100),
                        ),
                        SizedBox(height: 8.h),
                        _buildSmallVerticalPowerUpBtn(
                          emoji: '⏰',
                          count: _timePowerupsLeft,
                          onTap: _useTimePowerup,
                          activeColors: [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
                          shadowColor: const Color(0xFF01579B),
                        ),
                        SizedBox(height: 8.h),
                        _buildSmallVerticalPowerUpBtn(
                          emoji: '❤️',
                          count: _livesPowerupsLeft,
                          onTap: _useLivesPowerup,
                          activeColors: [const Color(0xFFFF8A80), const Color(0xFFE53935)],
                          shadowColor: const Color(0xFFB71C1C),
                        ),
                        SizedBox(height: 8.h),
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
                  ],
                ),
                SizedBox(height: 16.h),

                // 🧩 LƯỚI Ô CHỮ KHMER 5X5 (Full width, centered)
                _buildWordGrid(level),

                SizedBox(height: 20.h),

                // ── Action Button (Confirm Button) ──
                _buildConfirmButton(),

                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ],
    );
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
    final currentLevel = _levels[_currentLevelIdx];
    
    int correctLen = 0;
    for (int i = 0; i < _selectedPoints.length; i++) {
      if (i < currentLevel.path.length && _selectedPoints[i] == currentLevel.path[i]) {
        correctLen++;
      } else {
        break;
      }
    }

    if (correctLen < currentLevel.path.length) {
      HapticFeedback.mediumImpact();
      setState(() {
        _hintsLeft--;
        _selectedPoints = currentLevel.path.sublist(0, correctLen + 1);
      });
      _scoreService?.useHint();
    }
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
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: isActiveGlow
                    ? [const Color(0xFFFFD600), const Color(0xFFFF8F00)]
                    : hasItem
                        ? activeColors
                        : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)]),
              border: Border.all(
                color: isActiveGlow ? Colors.white : Colors.white.withOpacity(0.6),
                width: isActiveGlow ? 2.0 : 1.2),
              boxShadow: [
                BoxShadow(
                  color: isActiveGlow
                      ? const Color(0xFFFF8F00)
                      : hasItem ? shadowColor : const Color(0xFFB0BEC5),
                  offset: const Offset(0, 3), blurRadius: 0),
                BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 3), blurRadius: 3),
              ]),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -3.h,
              right: -3.w,
              child: Container(
                width: 18.w, height: 18.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 2, offset: const Offset(0, 1))
                  ]),
                child: Center(
                  child: Text('$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5.sp, 
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



  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36.w, height: 36.w,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, 3), blurRadius: 6),
                    ]),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF374151), size: 20)),
              ),
            ),
            Container(
              width: 120.w, height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF81C784), Color(0xFF388E3C)]),
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8)),
                ]),
              child: Center(
                child: Text('🌲', style: TextStyle(fontSize: 60.sp)),
              ),
            ),
            SizedBox(height: 24.h),
            Text('Giải cứu thú rừng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20),
                shadows: [
                  Shadow(color: Colors.white.withOpacity(0.8), offset: Offset(2.w, 2.h), blurRadius: 4),
                ])),
            SizedBox(height: 12.h),
            Text('Tìm các chữ cái Khmer để ghép thành tên\ncác loài thú và giải thoát chúng khỏi bong bóng!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp, fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32), height: 1.5)),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFE8F5E9)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))
                ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ruleRow('🦁', 'Tìm tên con thú trong lưới ô chữ'),
                SizedBox(height: 12.h),
                _ruleRow('⏱️', '30 giây cho mỗi lượt chơi'),
                SizedBox(height: 12.h),
                _ruleRow('💖', '3 mạng tim - Bấm sai nét sẽ bị trừ mạng'),
                SizedBox(height: 12.h),
                _ruleRow('🏆', 'Giải cứu thành công để nhận điểm thưởng'),
              ]),
            ),
            SizedBox(height: 40.h),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 52.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFF00A343), offset: Offset(0, 5), blurRadius: 0),
                    BoxShadow(color: const Color(0xFF00C853).withOpacity(0.3), offset: const Offset(0, 6), blurRadius: 10),
                  ]),
                child: Text('BẮT ĐẦU CHƠI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 1.5)),
                    ])),
              ),
            ),
          ]),
      ),
    );
  }

  Widget _ruleRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 20.sp)),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF374151),
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
            Container(
              width: 120.w, height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)]),
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE65100).withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))
                ]),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 60))),
            ),
            SizedBox(height: 16.h),
            Text('KẾT THÚC HÀNH TRÌNH!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20),
                shadows: [
                  Shadow(color: Colors.white.withOpacity(0.8), offset: Offset(2.w, 2.h), blurRadius: 4),
                ])),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFE8F5E9)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))
                ]),
              child: Column(children: [
                _statRow('⭐ Điểm số đạt được', '$_score'),
                SizedBox(height: 12.h),
                _statRow('🦁 Số thú giải cứu', '$_currentLevelIdx / ${_levels.length}'),
              ]),
            ),
            SizedBox(height: 32.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFCFD8DC)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 2),
                    ]),
                  child: Center(child: Text('THOÁT', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF546E7A)))),
                ),
              )),
              SizedBox(width: 12.w),
              Expanded(child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFF00A343), offset: Offset(0, 4), blurRadius: 0),
                    ]),
                  child: Center(child: Text('CHƠI LẠI', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              )),
            ]),
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
            color: const Color(0xFF374151),
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

  Widget _buildHeaderStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(color: Colors.white, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3), blurRadius: 6),
                    ]),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF374151), size: 20)),
              ),
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
                    BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 3), blurRadius: 3),
                  ]),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 18.w),
                  SizedBox(width: 4.w),
                  Text('$_score',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3), blurRadius: 6),
                  ]),
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
                  color: _timeLeft <= 5 ? const Color(0xFFB91C1C) : const Color(0xFF00838F),
                  offset: const Offset(0, 2), blurRadius: 0),
                BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 3), blurRadius: 3),
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

  Widget _buildRescueCard(_Level level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 38.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.04),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
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
                width: 125.w,
                height: 125.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Colors.white,
                      const Color(0xFFE0F7FA),
                      const Color(0xFF4DD0E1).withOpacity(0.7),
                      const Color(0xFF00ACC1).withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 3.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withOpacity(0.25),
                      blurRadius: 10.r,
                      spreadRadius: 1.5.r,
                    ),
                  ],
                ),
              ),
              Text(
                level.emoji,
                style: TextStyle(fontSize: 76.sp),
              ),
              if (!_isRoundCompleted)
                // Lock overlay to show it is trapped!
                Positioned(
                  bottom: 4.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF5350),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'BÉ HÃY GIẢI CỨU:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF66BB6A),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  level.khmerWord,
                  style: GoogleFonts.battambang(
                    fontSize: 52.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
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
    final rowCount = level.grid.length;
    final colCount = level.grid.isNotEmpty ? level.grid[0].length : 0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), // Clean, bright ivory/pastel grid board
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFC5E1A5), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33691E).withOpacity(0.08),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pass 1: Grid of backgrounds (handles taps)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * colCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount > 0 ? colCount : 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final r = index ~/ colCount;
              final c = index % colCount;
              final point = Point(r, c);
              final isSelected = _selectedPoints.contains(point);

              return GestureDetector(
                onTap: () => _onCellTap(r, c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(0, isSelected ? 3.h : 0, 0),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2.w : 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE0E0E0),
                        offset: Offset(0, isSelected ? 1.h : 4.h),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 6.r,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Pass 2: Connection Line Painter (placed between background and text)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GridConnectionPainter(
                  selectedPoints: _selectedPoints,
                  spacing: 10,
                  rowCount: rowCount,
                  columnCount: colCount,
                ),
              ),
            ),
          ),

          // Pass 3: Grid of texts & badges (foreground)
          IgnorePointer(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rowCount * colCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colCount > 0 ? colCount : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final r = index ~/ colCount;
                final c = index % colCount;
                final letter = level.grid[r][c];

                final point = Point(r, c);
                final isSelected = _selectedPoints.contains(point);
                final selectionIndex = _selectedPoints.indexOf(point);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(0, isSelected ? 3.h : 0, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(
                        letter,
                        style: GoogleFonts.battambang(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                          shadows: isSelected
                              ? [
                                  const Shadow(color: Color(0xFF2E7D32), offset: Offset(-1.2, -1.2), blurRadius: 0),
                                  const Shadow(color: Color(0xFF2E7D32), offset: Offset(1.2, -1.2), blurRadius: 0),
                                  const Shadow(color: Color(0xFF2E7D32), offset: Offset(1.2, 1.2), blurRadius: 0),
                                  const Shadow(color: Color(0xFF2E7D32), offset: Offset(-1.2, 1.2), blurRadius: 0),
                                ]
                              : null,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: -6.h,
                          left: -6.w,
                          child: Container(
                            width: 18.w,
                            height: 18.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5.w),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${selectionIndex + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
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

class _GridConnectionPainter extends CustomPainter {
  final List<Point<int>> selectedPoints;
  final double spacing;
  final int rowCount;
  final int columnCount;

  _GridConnectionPainter({
    required this.selectedPoints,
    required this.spacing,
    required this.rowCount,
    required this.columnCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedPoints.length < 2) return;

    final cellWidth = (size.width - (columnCount - 1) * spacing) / (columnCount > 0 ? columnCount : 1);
    final cellHeight = (size.height - (rowCount - 1) * spacing) / (rowCount > 0 ? rowCount : 1);

    Offset getCenter(Point<int> p) {
      final x = p.y * (cellWidth + spacing) + cellWidth / 2;
      final y = p.x * (cellHeight + spacing) + cellHeight / 2;
      return Offset(x, y);
    }

    final path = Path();
    final firstCenter = getCenter(selectedPoints.first);
    path.moveTo(firstCenter.dx, firstCenter.dy);

    for (int i = 1; i < selectedPoints.length; i++) {
      final center = getCenter(selectedPoints[i]);
      path.lineTo(center.dx, center.dy);
    }

    // Layer 1: Broad soft glow (Mint-Teal theme)
    final glowPaint1 = Paint()
      ..color = const Color(0xFF26A69A).withOpacity(0.2)
      ..strokeWidth = 20.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Layer 2: Medium glow
    final glowPaint2 = Paint()
      ..color = const Color(0xFF26A69A).withOpacity(0.5)
      ..strokeWidth = 12.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Layer 3: Solid white inner line
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint1);
    canvas.drawPath(path, glowPaint2);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GridConnectionPainter oldDelegate) {
    return oldDelegate.selectedPoints != selectedPoints;
  }
}
