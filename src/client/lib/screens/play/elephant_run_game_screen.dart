import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_consonant_series.dart';
import '../../services/score_service.dart';
import 'package:khmerkid/utils/app_haptics.dart';

/// Trò chơi: 🐘 Voi con vượt ải (Khmer Consonant Series Runner)
/// Bé giúp Voi con chọn đúng cổng hàng giọng O hoặc giọng Ô tương ứng của phụ âm.
class ElephantRunGameScreen extends StatefulWidget {
  const ElephantRunGameScreen({super.key});

  @override
  State<ElephantRunGameScreen> createState() => _ElephantRunGameScreenState();
}

enum GamePhase { audioPlaying, waitingForInput, resultShowing, comparing }

class _ElephantRunGameScreenState extends State<ElephantRunGameScreen>
    with TickerProviderStateMixin {
  late List<KhmerConsonantSeries> _allConsonants;
  final List<KhmerConsonantSeries> _gameRounds = [];
  int _currentRoundIdx = 0;
  int _score = 0;
  ScoreService? _scoreService;

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 25;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _victory = false;

  // Flow & Scaffolding variables
  GamePhase _phase = GamePhase.audioPlaying;
  bool _isAudioPlaying = false;
  String? _selectedChoice; // 'o' hoặc 'ô'

  // Animations
  late AnimationController _elephantController;
  late Animation<double> _elephantAnimation;
  late AnimationController _gateController;
  
  // Direct consonant pairing map for quick comparison when wrong
  static const Map<String, String> consonantPairs = {
    'ក': 'គ', 'ខ': 'ឃ', 'ច': 'ជ', 'ឆ': 'ឈ', 'ដ': 'ឌ', 'ឋ': 'ឍ', 'ណ': 'ន', 'ត': 'ទ', 'ថ': 'ធ', 'ប': 'ព', 'ផ': 'ភ',
    'គ': 'ក', 'ឃ': 'ខ', 'ជ': 'ច', 'ឈ': 'ឆ', 'ឌ': 'ដ', 'ឍ': 'ឋ', 'ន': 'ណ', 'ទ': 'ត', 'ធ': 'ថ', 'ព': 'ប', 'ភ': 'ផ'
  };

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _allConsonants = KhmerConsonantSeriesData.consonants;
    _initAnimations();
  }

  void _initAnimations() {
    _elephantController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _elephantAnimation = Tween<double>(begin: 0, end: -15.h).animate(
      CurvedAnimation(parent: _elephantController, curve: Curves.easeInOut),
    );
    _gateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    // Đồng bộ vật phẩm hồi phục lên CSDL khi vào game
    await _scoreService?.syncRegeneratedInventory();
    if (mounted) setState(() {});
  }

  void _generateRounds() {
    _gameRounds.clear();
    final rng = Random();
    final List<KhmerConsonantSeries> shuffled = List.from(_allConsonants)..shuffle(rng);
    
    // Đảm bảo có ít nhất 2 phụ âm hàng O và 2 phụ âm hàng Ô cho 5 lượt đấu
    List<KhmerConsonantSeries> oSeries = shuffled.where((c) => c.series == 'o').toList();
    List<KhmerConsonantSeries> ooSeries = shuffled.where((c) => c.series == 'ô').toList();
    
    for (int i = 0; i < 5; i++) {
      if (i % 2 == 0 && oSeries.isNotEmpty) {
        _gameRounds.add(oSeries.removeLast());
      } else if (ooSeries.isNotEmpty) {
        _gameRounds.add(ooSeries.removeLast());
      } else if (oSeries.isNotEmpty) {
        _gameRounds.add(oSeries.removeLast());
      }
    }
    _gameRounds.shuffle(rng);
  }

  void _startGame() {
    _generateRounds();
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 0;
      _currentRoundIdx = 0;
      _gameOver = false;
      _victory = false;
      _selectedChoice = null;
    });
    _startRound();
  }

  void _startRound() {
    setState(() {
      _phase = GamePhase.audioPlaying;
      _isAudioPlaying = true;
      _selectedChoice = null;
    });

    // Giả lập Audio-first flow: Phát âm phụ âm và ví dụ trong 1.5 giây
    // Bé sẽ thấy sóng âm phát và voi nhún nhảy ngộ nghĩnh
    AppHaptics.lightImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _phase = GamePhase.waitingForInput;
        // Tính toán đếm ngược thích ứng theo cấp độ/vòng đấu
        // Lượt 1-2: 25 giây, Lượt 3-4: 20 giây, Lượt 5: 15 giây
        if (_currentRoundIdx <= 1) {
          _timeLeft = 25;
        } else if (_currentRoundIdx <= 3) {
          _timeLeft = 20;
        } else {
          _timeLeft = 15;
        }
      });
      _startTimer();
    });
  }

  void _playPronunciation() {
    AppHaptics.mediumImpact();
    setState(() {
      _isAudioPlaying = true;
    });
    
    // Dừng đếm ngược tạm thời khi đang nghe loa phát lại
    _timer?.cancel();
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
      });
      if (_phase == GamePhase.waitingForInput) {
        _startTimer();
      }
    });
  }

  void _startTimer() {
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

  void _onTimeOut() {
    AppHaptics.heavyImpact();
    setState(() {
      _lives = 0;
      _gameOver = true;
    });
  }

  void _onGateSelected(String series) {
    if (_phase != GamePhase.waitingForInput) return;

    _timer?.cancel();
    final current = _gameRounds[_currentRoundIdx];
    final isCorrect = (series == current.series);

    setState(() {
      _selectedChoice = series;
    });

    if (isCorrect) {
      AppHaptics.heavyImpact();
      setState(() {
        _phase = GamePhase.resultShowing;
        _score += 15;
      });

      // Voi nhảy cao ăn mừng thành công vượt qua cổng
      _elephantController.forward(from: 0).then((_) => _elephantController.repeat(reverse: true));

      Future.delayed(const Duration(seconds: 1500), () {
        if (mounted) {
          _nextRound();
        }
      });
    } else {
      AppHaptics.vibrate();
      setState(() {
        _phase = GamePhase.comparing; // Chuyển sang so sánh nhanh
        if (_lives > 1) {
          _lives--;
        } else {
          _lives = 0;
          _gameOver = true;
        }
      });

      // Panel so sánh tự động tắt sau 3 giây để tiếp tục
      Future.delayed(const Duration(seconds: 4000), () {
        if (!mounted) return;
        if (_gameOver) {
          setState(() {
            _phase = GamePhase.resultShowing;
          });
        } else {
          _startRound();
        }
      });
    }
  }

  void _nextRound() {
    if (_currentRoundIdx < _gameRounds.length - 1) {
      setState(() {
        _currentRoundIdx++;
      });
      _startRound();
    } else {
      _timer?.cancel();
      setState(() {
        _victory = true;
      });
      _scoreService?.completeGame('elephant_run', 15);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elephantController.dispose();
    _gateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: !_gameStarted
              ? _buildStartScreen()
              : _gameOver
                  ? _buildGameOverScreen()
                  : _victory
                      ? _buildVictoryScreen()
                      : Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 12.h),
                                      _buildRoundIndicator(),
                                      SizedBox(height: 14.h),
                                      
                                      if (_phase == GamePhase.comparing)
                                        _buildComparePanel()
                                      else ...[
                                        _buildWoodenBoard(),
                                        SizedBox(height: 20.h),
                                        _buildRunningZone(),
                                        SizedBox(height: 24.h),
                                        _buildActionGates(),
                                      ],
                                      SizedBox(height: 30.h),
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
                  colors: [Color(0xFF00ACC1), Color(0xFF80DEEA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ACC1).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text('🐘', style: TextStyle(fontSize: 54.sp)),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '🐘 Voi con vượt ải',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF006064),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Bé giúp Voi con phân biệt nhanh phụ âm\ngiọng O (អ) và giọng Ô (អូ) để vượt qua cổng rừng xanh!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5.sp,
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
                border: Border.all(color: const Color(0xFF00ACC1), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ACC1).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🔊', 'Lắng nghe âm thanh phát mẫu của phụ âm'),
                  SizedBox(height: 10.h),
                  _ruleRow('🚪', 'Chọn đúng Cổng Giọng O (អ) hoặc Cổng Giọng Ô (អូ)'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', 'Cấp độ thời gian tăng dần: 25s ➔ 20s ➔ 15s'),
                  SizedBox(height: 10.h),
                  _ruleRow('💖', 'Bé có 3 trái tim - Chọn sai Voi con sẽ bị húc ngã!'),
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
                    colors: [Color(0xFF00ACC1), Color(0xFF00B0FF)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF006064), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'BẮT ĐẦU VƯỢT ẢI',
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
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF006064),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00ACC1), Color(0xFF00E5FF)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006064).withOpacity(0.3),
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
              color: _timeLeft <= 6 && _phase == GamePhase.waitingForInput
                  ? const Color(0xFFFF1744).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: _timeLeft <= 6 && _phase == GamePhase.waitingForInput ? const Color(0xFFFF8A80) : Colors.white,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  _phase == GamePhase.audioPlaying ? 'Đọc...' : '$_timeLeft',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 6 && _phase == GamePhase.waitingForInput ? const Color(0xFFFF8A80) : Colors.white,
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

  Widget _buildRoundIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final isPassed = i < _currentRoundIdx;
        final isCurrent = i == _currentRoundIdx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isCurrent ? 28.w : 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            color: isPassed
                ? const Color(0xFF00C853)
                : isCurrent
                    ? const Color(0xFF00E5FF)
                    : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(7.r),
            border: Border.all(
              color: isCurrent ? const Color(0xFF006064) : Colors.transparent,
              width: 1.5.w,
            ),
          ),
          child: isPassed
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : null,
        );
      }),
    );
  }

  Widget _buildWoodenBoard() {
    final current = _gameRounds[_currentRoundIdx];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBE9),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF8D6E63), width: 4.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.15),
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ẢI THỬ THÁCH PHỤ ÂM 🏷️',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5D4037),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Phát âm & Loa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                current.character,
                style: GoogleFonts.battambang(
                  fontSize: 72.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006064),
                ),
              ),
              SizedBox(width: 24.w),
              GestureDetector(
                onTap: _isAudioPlaying ? null : _playPronunciation,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _isAudioPlaying ? const Color(0xFF80DEEA) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00ACC1), width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ACC1).withOpacity(0.2),
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: _isAudioPlaying
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF006064),
                          ),
                        )
                      : Icon(
                          Icons.volume_up_rounded,
                          color: const Color(0xFF006064),
                          size: 24.sp,
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // Text phát âm mẫu
          Text(
            _isAudioPlaying 
                ? 'Đang phát âm mẫu: "${current.romanized}" (${current.pronunciation})' 
                : 'Phiên âm: "${current.romanized}" - Giọng đọc: "${current.pronunciation}"',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF006064),
            ),
          ),
          if (current.example.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Từ ví dụ: ${current.example} (nghĩa: ${current.exampleMeaning})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRunningZone() {
    return SizedBox(
      height: 160.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Con đường chạy Neubrutalism
          Container(
            height: 45.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF81C784),
              border: Border.all(color: const Color(0xFF1B5E20), width: 3.w),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1B5E20),
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          
          // Mascot Voi con 3D bập bềnh
          Positioned(
            left: 24.w,
            bottom: 22.h,
            child: AnimatedBuilder(
              animation: _elephantAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _elephantAnimation.value),
                  child: child,
                );
              },
              child: Text(
                _phase == GamePhase.comparing ? '😭' : '🐘',
                style: TextStyle(fontSize: 64.sp),
              ),
            ),
          ),
          
          // Cánh cổng Neubrutalism ở đằng xa
          Positioned(
            right: 24.w,
            bottom: 20.h,
            child: Row(
              children: [
                _buildTinyGate('O', const Color(0xFF00E5FF)),
                SizedBox(width: 14.w),
                _buildTinyGate('Ô', const Color(0xFFFFB300)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyGate(String text, Color color) {
    return Container(
      width: 48.w,
      height: 65.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        border: Border.all(color: Colors.black87, width: 2.w),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionGates() {
    final current = _gameRounds[_currentRoundIdx];
    final isSelectedO = _selectedChoice == 'o';
    final isSelectedOO = _selectedChoice == 'ô';
    final showAnswer = _phase == GamePhase.resultShowing;
    
    Color gateOColor = const Color(0xFFE0F7FA);
    Color gateOOColor = const Color(0xFFFFF8E1);
    Color borderO = const Color(0xFF00ACC1);
    Color borderOO = const Color(0xFFFFB300);

    if (showAnswer) {
      if (current.series == 'o') {
        gateOColor = const Color(0xFFE8F5E9);
        borderO = const Color(0xFF4CAF50);
      } else {
        gateOOColor = const Color(0xFFE8F5E9);
        borderOO = const Color(0xFF4CAF50);
      }
    }

    return Column(
      children: [
        Text(
          'CHẠM CHỌN CỔNG GIỌNG ĐÚNG:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF006064),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            // Cổng giọng O
            Expanded(
              child: GestureDetector(
                onTap: _phase == GamePhase.waitingForInput ? () => _onGateSelected('o') : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: gateOColor,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: borderO,
                      width: isSelectedO ? 4.w : 3.w,
                    ),
                    boxShadow: isSelectedO
                        ? []
                        : [
                            BoxShadow(
                              color: borderO.withOpacity(0.4),
                              offset: Offset(0, 6.h),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'អ',
                        style: GoogleFonts.battambang(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF006064),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'GIỌNG O',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF006064),
                        ),
                      ),
                      Text(
                        '(Series 1 - Hàng 1)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Cổng giọng Ô
            Expanded(
              child: GestureDetector(
                onTap: _phase == GamePhase.waitingForInput ? () => _onGateSelected('ô') : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: gateOOColor,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: borderOO,
                      width: isSelectedOO ? 4.w : 3.w,
                    ),
                    boxShadow: isSelectedOO
                        ? []
                        : [
                            BoxShadow(
                              color: borderOO.withOpacity(0.4),
                              offset: Offset(0, 6.h),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'អូ',
                        style: GoogleFonts.battambang(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'GIỌNG Ô',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        '(Series 2 - Hàng 2)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparePanel() {
    final current = _gameRounds[_currentRoundIdx];
    final pairedChar = consonantPairs[current.character];
    
    // Tìm consonant tương đương để so sánh
    KhmerConsonantSeries? pairedConsonant;
    if (pairedChar != null) {
      try {
        pairedConsonant = _allConsonants.firstWhere((c) => c.character == pairedChar);
      } catch (_) {}
    }

    final isO = current.series == 'o';
    final correctGate = isO ? 'Cổng giọng O (អ)' : 'Cổng giọng Ô (អូ)';
    final wrongGate = isO ? 'Cổng giọng Ô (អូ)' : 'Cổng giọng O (អ)';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFC62828), width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💔', style: TextStyle(fontSize: 22.sp)),
              SizedBox(width: 8.w),
              Text(
                'SAI CỔNG GIỌNG! MẤT 1 TIM',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          Text(
            'Bé đã chọn nhầm $wrongGate! Phụ âm "${current.character}" phải thuộc $correctGate. Hãy so sánh sự khác biệt:',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16.h),
          
          Row(
            children: [
              // Cột trái: Phụ âm hỏi
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isO ? const Color(0xFFE0F7FA) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isO ? const Color(0xFF00ACC1) : const Color(0xFFFFB300),
                      width: 2.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        current.character,
                        style: GoogleFonts.battambang(
                          fontSize: 38.sp,
                          fontWeight: FontWeight.bold,
                          color: isO ? const Color(0xFF006064) : const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        isO ? 'Hàng Giọng O' : 'Hàng Giọng Ô',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: isO ? const Color(0xFF006064) : const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        'Đọc: ${current.pronunciation}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Icon(Icons.compare_arrows_rounded, color: const Color(0xFFC62828), size: 24.sp),
              ),
              
              // Cột phải: Phụ âm cặp đôi tương đồng
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: !isO ? const Color(0xFFE0F7FA) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: !isO ? const Color(0xFF00ACC1) : const Color(0xFFFFB300),
                      width: 2.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        pairedConsonant?.character ?? '?',
                        style: GoogleFonts.battambang(
                          fontSize: 38.sp,
                          fontWeight: FontWeight.bold,
                          color: !isO ? const Color(0xFF006064) : const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        !isO ? 'Hàng Giọng O' : 'Hàng Giọng Ô',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: !isO ? const Color(0xFF006064) : const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        'Đọc: ${pairedConsonant?.pronunciation ?? 'N/A'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 14.h),
          Text(
            '💡 Phụ âm hàng O (nhóm អ) có cao độ thấp hơn, phát âm bẹt hơn. Phụ âm hàng Ô (nhóm អូ) có cao độ cao hơn, vang hơn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Vượt ải sẽ tự động tiếp tục sau ít giây...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC62828),
            ),
          ),
        ],
      ),
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
              'Ải đã khép lại!',
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
              'Voi con bị ngã do chọn sai cổng quá nhiều. Bé hãy luyện tập và so sánh kỹ giọng của phụ âm để giúp Voi con qua ải nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
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
                    color: const Color(0xFFC62828).withOpacity(0.08),
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
                    label: '🚪 Số cổng đã vượt qua',
                    value: '$_currentRoundIdx / 5',
                    fallbackIcon: Icons.door_sliding_rounded,
                    themeColor: const Color(0xFFE57373),
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
                          colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF006064),
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

  Widget _buildVictoryScreen() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Trophy Container
            Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.w),
              child: Image.asset(
                'image/cúp hồ sơ.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'ẢI CHINH PHỤC THÀNH CÔNG!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E7D32),
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
              'Bé thật xuất sắc! Voi con đã vượt qua toàn bộ 5 cổng ải thám hiểm nhờ khả năng phân biệt cực chuẩn hai hàng giọng Khmer!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                height: 1.5,
              ),
            ),
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
                    color: const Color(0xFF00E676).withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPremiumStatTile(
                    label: '⭐ Điểm số thăng tiến',
                    value: '$_score',
                    fallbackIcon: Icons.emoji_events_rounded,
                    themeColor: const Color(0xFFF57C00),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: '🎁 Thưởng chiến thắng',
                    value: '+15 Sao vàng 🌟',
                    fallbackIcon: Icons.card_giftcard_rounded,
                    themeColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 52.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006064),
                      offset: Offset(0, 4.h),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Trở về thế giới trò chơi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return const SizedBox.shrink();
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
}
