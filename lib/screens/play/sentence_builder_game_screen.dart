import 'dart:async';
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

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 60;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;

  // UX & Scaffolding variables
  int wrongAttempts = 0;
  int? _mismatchIndex;

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
        wordTypes: [WordType.subject, WordType.verb, WordType.object],
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
        wordTypes: [WordType.subject, WordType.verb, WordType.object],
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
        wordTypes: [WordType.subject, WordType.verb, WordType.object],
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
        wordTypes: [WordType.subject, WordType.verb, WordType.verb, WordType.object],
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
        wordTypes: [WordType.subject, WordType.verb, WordType.object],
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
      wrongAttempts = 0;
      _mismatchIndex = null;
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
    _timer?.cancel();
    _islandController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 0;
      _currentLevelIdx = 0;
      _selectedWords.clear();
      _isRoundCompleted = false;
      _gameOver = false;
      wrongAttempts = 0;
      _mismatchIndex = null;
    });
    _loadLevel(_currentLevelIdx);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_currentLevelIdx == 0) {
      setState(() {
        _timeLeft = 999;
      });
      return;
    }
    _timeLeft = 60;
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
    if (_isRoundCompleted || _gameOver) return;

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
      wrongAttempts = 0;
      _mismatchIndex = null;
      _onRoundSuccess();
    } else {
      int mismatchIdx = 0;
      for (int i = 0; i < _selectedWords.length; i++) {
        if (_selectedWords[i] != currentLevel.correctWords[i]) {
          mismatchIdx = i;
          break;
        }
      }

      wrongAttempts++;
      HapticFeedback.vibrate();

      if (wrongAttempts == 1) {
        // Lần sai thứ nhất: KHÔNG trừ tim
        setState(() {
          _mismatchIndex = mismatchIdx;
        });

        final incorrectWord = _selectedWords[mismatchIdx];
        final correctIdxOfSelectedWord = currentLevel.correctWords.indexOf(incorrectWord);
        final correctType = correctIdxOfSelectedWord != -1 
            ? currentLevel.wordTypes[correctIdxOfSelectedWord] 
            : WordType.object;
            
        final targetSlotType = currentLevel.wordTypes[mismatchIdx];
        _showFirstWrongAttemptHint(incorrectWord, targetSlotType, correctType);
      } else {
        // Lần sai thứ hai: Trừ 1 mạng tim + hiện đáp án đúng 2 giây
        wrongAttempts = 0;
        setState(() {
          _mismatchIndex = null;
          if (_lives > 1) {
            _lives--;
          } else {
            _lives = 0;
            _gameOver = true;
            _timer?.cancel();
          }
        });

        if (!_gameOver) {
          _showSecondWrongAttemptHelp(currentLevel);
        }
      }
    }
  }

  void _showFirstWrongAttemptHint(String word, WordType targetSlotType, WordType correctType) {
    final targetLabel = _getWordTypeLabel(targetSlotType);
    final meaning = _levels[_currentLevelIdx].wordMeanings[word] ?? '';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gợi ý đảo cổ:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'Từ "$word" ($meaning) có phải thuộc vị trí $targetLabel không? Bé hãy thử sắp xếp lại nhé!',
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
        backgroundColor: const Color(0xFFF57C00),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }

  void _showSecondWrongAttemptHelp(_SentenceLevel level) {
    setState(() {
      _selectedWords = List<String>.from(level.correctWords);
      _isRoundCompleted = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('💔', style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Năng lượng đá cổ lung lay! Bé mất 1 mạng tim 💔. Đáp án đúng là:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    level.correctWords.join(" "),
                    style: GoogleFonts.battambang(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _selectedWords.clear();
        _isRoundCompleted = false;
        _mismatchIndex = null;
        _startTimer();
      });
    });
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
                    'Mật thư đã giải mã thành công! 🔑',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'Chuẩn bị tiến sang hòn đảo tiếp theo...',
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
        backgroundColor: const Color(0xFF4CAF50),
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
      });
      _loadLevel(_currentLevelIdx);
    } else {
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
    _score = 15;
    _scoreService?.completeGame('sentence_island', 15);
    
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
                'Tổng điểm đạt được: +15 Điểm 🌟',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB), Color(0xFF80CBC4)],
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

                                  // 📜 THANH CẤU TRÚC CÂU KHMER (Sentence Frame Bar)
                                  _buildSentenceFrameBar(currentLevel),

                                  SizedBox(height: 16.h),

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
                  colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.explore_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '🏝️ Đảo quốc Ngữ pháp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF004D40),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Ghép các khối đá từ vựng Khmer cổ đại\nđể khám phá mật thư của hòn đảo huyền bí!',
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
                border: Border.all(color: const Color(0xFF4DB6AC), width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ruleRow('🧩', 'Ghép các khối đá thành câu Khmer có nghĩa'),
                  SizedBox(height: 10.h),
                  _ruleRow('⏱️', '40 giây cho mỗi mật thư trên đảo'),
                  SizedBox(height: 10.h),
                  _ruleRow('💖', '3 mạng tim - Bấm sai sẽ bị trừ mạng'),
                  SizedBox(height: 10.h),
                  _ruleRow('🏆', 'Vượt qua cả 5 hòn đảo cổ để chiến thắng!'),
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
                    colors: [Color(0xFF00897B), Color(0xFF00B0FF)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF004D40), width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withOpacity(0.4),
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
              color: const Color(0xFF004D40),
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
              'Đảo cổ đang bị bao phủ bởi sương mù. Bé hãy thử lại để tiếp tục hành trình khám phá nhé!',
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
                  _statRow('🏝️ Số đảo đã khám phá', '$_currentLevelIdx / ${_levels.length}'),
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
                          colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF004D40), width: 2.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00897B).withOpacity(0.3),
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

  Widget _buildHeader(_SentenceLevel level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF26C6DA)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01579B).withOpacity(0.3),
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
              color: _timeLeft <= 8 && _currentLevelIdx != 0
                  ? const Color(0xFFFF1744).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: _timeLeft <= 8 && _currentLevelIdx != 0 ? const Color(0xFFFF8A80) : Colors.white,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  _currentLevelIdx == 0 ? '∞' : '$_timeLeft',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 8 && _currentLevelIdx != 0 ? const Color(0xFFFF8A80) : Colors.white,
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

  Widget _buildIslandCard(_SentenceLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF00897B), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.12),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFFFF9C4), Color(0xFFFFE082)],
              ),
              border: Border.all(
                color: const Color(0xFFFFB300),
                width: 3.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.3),
                  blurRadius: 8.r,
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Center(
              child: Text(
                level.emoji,
                style: TextStyle(fontSize: 44.sp),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MẬT THƯ TIẾNG VIỆT:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00796B),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '"${level.vietnameseTranslation}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF004D40),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Bé hãy xếp các khối đá chữ Khmer dưới đây vào các rãnh thuyền cát tương ứng.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.35,
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
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8), // Sandstone drift wood
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: const Color(0xFF8D6E63), width: 4.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.2),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Rãnh Thuyền Cát Ghép Câu 🛶',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5D4037),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.w,
            runSpacing: 12.h,
            children: List.generate(level.correctWords.length, (idx) {
              final isSlotFilled = _selectedWords.length > idx;
              final word = isSlotFilled ? _selectedWords[idx] : '';
              final wordType = level.wordTypes[idx];
              final isMismatched = _mismatchIndex == idx;

              Color bgColor;
              Color borderColor;
              Color textColor;
              
              if (isMismatched) {
                bgColor = const Color(0xFFFFCDD2);
                borderColor = const Color(0xFFC62828);
                textColor = const Color(0xFFC62828);
              } else if (isSlotFilled) {
                bgColor = _getWordTypeColor(wordType);
                borderColor = _getWordTypeDarkColor(wordType);
                textColor = Colors.white;
              } else {
                bgColor = _getWordTypeLightColor(wordType);
                borderColor = _getWordTypeColor(wordType).withOpacity(0.5);
                textColor = _getWordTypeColor(wordType);
              }

              return Container(
                constraints: BoxConstraints(minWidth: 85.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: borderColor,
                    width: 2.5.w,
                  ),
                  boxShadow: [
                    if (isSlotFilled && !isMismatched)
                      BoxShadow(
                        color: _getWordTypeDarkColor(wordType),
                        offset: Offset(0, 3.h),
                      ),
                  ],
                ),
                child: Text(
                  isSlotFilled ? word : '?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.battambang(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWordBlocks(_SentenceLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
          child: Text(
            'Khối đá chữ cổ gợi ý (Chạm để chọn/hủy):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF004D40),
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

            final correctIdx = level.correctWords.indexOf(word);
            final type = correctIdx != -1 ? level.wordTypes[correctIdx] : WordType.object;
            final borderColor = _getWordTypeColor(type);
            final lightColor = _getWordTypeLightColor(type);

            return GestureDetector(
              onTap: () => _onWordTap(word),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB0BEC5) : lightColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF78909C) : borderColor,
                    width: 2.5.w,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: borderColor.withOpacity(0.3),
                            offset: Offset(0, 5.h),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word,
                      style: GoogleFonts.battambang(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : _getWordTypeDarkColor(type),
                      ),
                    ),
                    if (meaning.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 3.h),
                        child: Text(
                          meaning,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white.withOpacity(0.9) : _getWordTypeDarkColor(type).withOpacity(0.8),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFB0BEC5), width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCFD8DC),
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
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              onPressed: _clearSelection,
              child: Text(
                'Làm lại 🔄',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5D4037),
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
                colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFF01579B), width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF01579B),
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              onPressed: _checkAnswer,
              child: Text(
                'Giải mã mật thư 🗿',
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

  Widget _buildSentenceFrameBar(_SentenceLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF00897B).withOpacity(0.5), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gavel_rounded, color: const Color(0xFF00796B), size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'CẤU TRÚC NGỮ PHÁP KHMER:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00796B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6.w,
            runSpacing: 6.h,
            children: List.generate(level.wordTypes.length, (i) {
              final type = level.wordTypes[i];
              final lightColor = _getWordTypeLightColor(type);
              final darkColor = _getWordTypeDarkColor(type);
              final border = _getWordTypeColor(type);
              
              String khmerLabel = '';
              String vnLabel = '';
              switch (type) {
                case WordType.subject:
                  khmerLabel = 'ប្រធានបទ';
                  vnLabel = 'Chủ ngữ';
                  break;
                case WordType.verb:
                  khmerLabel = 'កិរិយាសព្ទ';
                  vnLabel = 'Động từ';
                  break;
                case WordType.object:
                  khmerLabel = 'កម្មបទ';
                  vnLabel = 'Tân ngữ';
                  break;
                case WordType.modifier:
                  khmerLabel = 'គុណនាម';
                  vnLabel = 'Bổ ngữ';
                  break;
              }
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: border, width: 1.5.w),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          khmerLabel,
                          style: GoogleFonts.battambang(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        Text(
                          vnLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: darkColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < level.wordTypes.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: const Color(0xFF00796B).withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getWordTypeColor(WordType type) {
    switch (type) {
      case WordType.subject:
        return const Color(0xFF1E88E5);
      case WordType.verb:
        return const Color(0xFF43A047);
      case WordType.object:
      case WordType.modifier:
        return const Color(0xFFFF8F00);
    }
  }

  Color _getWordTypeLightColor(WordType type) {
    switch (type) {
      case WordType.subject:
        return const Color(0xFFE3F2FD);
      case WordType.verb:
        return const Color(0xFFE8F5E9);
      case WordType.object:
      case WordType.modifier:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _getWordTypeDarkColor(WordType type) {
    switch (type) {
      case WordType.subject:
        return const Color(0xFF0D47A1);
      case WordType.verb:
        return const Color(0xFF1B5E20);
      case WordType.object:
      case WordType.modifier:
        return const Color(0xFFE65100);
    }
  }

  String _getWordTypeLabel(WordType type) {
    switch (type) {
      case WordType.subject:
        return 'Chủ ngữ';
      case WordType.verb:
        return 'Động từ';
      case WordType.object:
        return 'Tân ngữ';
      case WordType.modifier:
        return 'Bổ ngữ';
    }
  }
}

enum WordType { subject, verb, object, modifier }

class _SentenceLevel {
  final String vietnameseTranslation;
  final List<String> correctWords;
  final Map<String, String> wordMeanings;
  final List<WordType> wordTypes;
  final String islandName;
  final String emoji;

  _SentenceLevel({
    required this.vietnameseTranslation,
    required this.correctWords,
    required this.wordMeanings,
    required this.wordTypes,
    required this.islandName,
    required this.emoji,
  });
}
