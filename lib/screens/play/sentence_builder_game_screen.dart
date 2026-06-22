import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/admin_service.dart';

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
  Map<String, dynamic>? _rewardResult;

  // Game Loop variables
  int _lives = 3;
  int _timeLeft = 60;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;

  // Powerups State
  int _hintsLeft = 2;
  int _timePowerupsLeft = 2;
  int _livesPowerupsLeft = 1;
  int _doubleScorePowerupsLeft = 1;
  bool _isDoubleScoreActive = false;

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
    _loadGameQuestions();
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
      final result = await AdminService().fetchGameQuestionsForUser('sentence_builder');
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null && (result['data'] as List).isNotEmpty) {
        final list = result['data'] as List;
        final parsed = list.map((q) {
          final additional = q['additionalData'] as Map?;
          final List<dynamic> rawChoices = q['choices'] ?? [];
          final correctWords = rawChoices.map((w) => w.toString()).toList();
          
          if (correctWords.isEmpty) return null;
          
          final vietnameseTranslation = q['prompt'] ?? '';
          
          // Parse wordMeanings
          final Map<String, String> wordMeanings = {};
          final rawMeanings = additional?['wordMeanings'];
          if (rawMeanings is Map) {
            rawMeanings.forEach((key, val) {
              wordMeanings[key.toString()] = val.toString();
            });
          } else {
            for (var w in correctWords) {
              wordMeanings[w] = '';
            }
          }
          
          // Parse wordTypes
          final List<WordType> wordTypes = [];
          final rawTypes = additional?['wordTypes'] as List?;
          if (rawTypes != null) {
            for (var t in rawTypes) {
              switch (t.toString()) {
                case 'subject':
                  wordTypes.add(WordType.subject);
                  break;
                case 'verb':
                  wordTypes.add(WordType.verb);
                  break;
                case 'object':
                  wordTypes.add(WordType.object);
                  break;
                case 'modifier':
                  wordTypes.add(WordType.modifier);
                  break;
                default:
                  wordTypes.add(WordType.object);
              }
            }
          }
          while (wordTypes.length < correctWords.length) {
            wordTypes.add(WordType.object);
          }

          final islandName = additional?['islandName']?.toString() ?? 'Đảo Hoang';
          final emoji = additional?['emoji']?.toString() ?? '🏝️';

          return _SentenceLevel(
            vietnameseTranslation: vietnameseTranslation,
            correctWords: correctWords,
            wordMeanings: wordMeanings,
            wordTypes: wordTypes,
            islandName: islandName,
            emoji: emoji,
          );
        }).whereType<_SentenceLevel>().toList();

        if (parsed.isNotEmpty) {
          setState(() {
            _levels = parsed;
          });
          _loadLevel(_currentLevelIdx);
        }
      }
    } catch (e) {
      debugPrint('Error loading sentence builder questions: $e');
    }
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
      _rewardResult = null;
      wrongAttempts = 0;
      _mismatchIndex = null;
      _hintsLeft = _scoreService?.hintsLeft ?? 2;
      _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
      _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
      _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      _isDoubleScoreActive = false;
    });
    _loadLevel(_currentLevelIdx);
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
    _scoreService?.completeGame(
      'sentence_island',
      _score,
      syncToBackend: true,
      correctAnswers: _currentLevelIdx,
      totalQuestions: _levels.length,
    ).then((result) {
      if (mounted) setState(() => _rewardResult = result);
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

        if (_gameOver) {
          _scoreService?.completeGame(
            'sentence_island',
            _score,
            syncToBackend: true,
            correctAnswers: _currentLevelIdx,
            totalQuestions: _levels.length,
          ).then((result) {
            if (mounted) setState(() => _rewardResult = result);
          });
        } else {
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
    int addedScore = 15;
    if (_isDoubleScoreActive) {
      addedScore = 30;
      _isDoubleScoreActive = false;
    }
    setState(() {
      _isRoundCompleted = true;
      _score += addedScore;
    });

    _scoreService?.completeGame('sentence_island', addedScore, syncToBackend: false);

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
      _startTimer();
    } else {
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() async {
    final result = await _scoreService?.completeGame(
      'sentence_island',
      _score,
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
    
    // Find how many words are correct so far
    int correctLen = 0;
    for (int i = 0; i < _selectedWords.length; i++) {
      if (i < currentLevel.correctWords.length && _selectedWords[i] == currentLevel.correctWords[i]) {
        correctLen++;
      } else {
        break;
      }
    }
    
    if (correctLen < currentLevel.correctWords.length) {
      HapticFeedback.mediumImpact();
      setState(() {
        _hintsLeft--;
        _selectedWords = currentLevel.correctWords.sublist(0, correctLen + 1);
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
                color: isActiveGlow ? Colors.white : Colors.white.withValues(alpha: 0.6),
                width: isActiveGlow ? 2.0 : 1.2),
              boxShadow: [
                BoxShadow(
                  color: isActiveGlow
                      ? const Color(0xFFFF8F00)
                      : hasItem ? shadowColor : const Color(0xFFB0BEC5),
                  offset: const Offset(0, 3), blurRadius: 0),
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 3),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2, offset: const Offset(0, 1))
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
          // ── Background Gradient (Soft Pastel Sky to Beach) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
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
          // ── Safe Area Content ──
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

                                    // 🏝️ BẢN ĐỒ ĐẢO QUỐC (Floating Animation) with Vertical Powerups
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: AnimatedBuilder(
                                            animation: _islandAnimation,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(0, _islandAnimation.value),
                                                child: child,
                                              );
                                            },
                                            child: _buildIslandCard(currentLevel),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
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

                                    SizedBox(height: 24.h),

                                    // 📜 KHU VỰC THẢ CHỮ & CẤU TRÚC NGỮ PHÁP KHMER (Sentence Slots)
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
            // Bubbly 3D Icon Container
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                ),
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.explore_rounded, size: 56.w, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            // Bold title with deep-teal shadow
            Text(
              'Đảo quốc Ngữ pháp 🏝️',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFF004D40),
                    offset: Offset(2.w, 2.h),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Ghép các khối đá từ vựng Khmer cổ đại\nđể khám phá mật thư của hòn đảo huyền bí!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            // Glassmorphic Rules Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
            // Premium 3D Green Play Button
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 52.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFF15803D),
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
              color: const Color(0xFF004D40),
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
              'Đảo cổ đang bị bao phủ bởi sương mù. Bé hãy thử lại để tiếp tục hành trình khám phá nhé!',
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
                    color: const Color(0xFF004D40).withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                    label: '🏝️ Số đảo đã khám phá',
                    value: '$_currentLevelIdx / ${_levels.length}',
                    fallbackIcon: Icons.explore_rounded,
                    themeColor: const Color(0xFF00796B),
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
                          colors: [Color(0xFF00E676), Color(0xFF00C853)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF009624),
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

  Widget _buildHeader(_SentenceLevel level) {
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 3), blurRadius: 3),
                  ]),
                child: Row(children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18.w),
                  SizedBox(width: 4.w),
                  Text('$_score',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w900, color: const Color(0xFFF57C00))),
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

  Widget _buildIslandCard(_SentenceLevel level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFB2DFDB), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90.w,
                height: 90.w,
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
                      color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
              ),
              Text(
                level.emoji,
                style: TextStyle(fontSize: 48.sp),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MẬT THƯ TIẾNG VIỆT:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00796B),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '"${level.vietnameseTranslation}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF004D40),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Bé hãy xếp các khối đá chữ Khmer dưới đây vào các rãnh thuyền cát tương ứng.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
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
    List<Widget> wrapChildren = [];
    for (int idx = 0; idx < level.correctWords.length; idx++) {
      final isSlotFilled = _selectedWords.length > idx;
      final word = isSlotFilled ? _selectedWords[idx] : '';
      final wordType = level.wordTypes[idx];
      final isMismatched = _mismatchIndex == idx;

      Color borderCol;
      Color textCol;
      List<Color> gradientColors;
      Color shadowCol;
      double shadowHeight = 0;

      final lightColor = _getWordTypeLightColor(wordType);
      final darkColor = _getWordTypeDarkColor(wordType);
      final baseColor = _getWordTypeColor(wordType);
      final vnLabel = _getWordTypeLabel(wordType);

      if (isMismatched) {
        gradientColors = [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)];
        borderCol = const Color(0xFFEF5350);
        textCol = const Color(0xFFC62828);
        shadowCol = const Color(0xFFEF5350).withValues(alpha: 0.3);
        shadowHeight = 3.h;
      } else if (isSlotFilled) {
        gradientColors = [baseColor.withValues(alpha: 0.9), baseColor];
        borderCol = darkColor;
        textCol = Colors.white;
        shadowCol = borderCol.withValues(alpha: 0.4);
        shadowHeight = 4.h;
      } else {
        gradientColors = [];
        borderCol = Colors.transparent;
        textCol = Colors.transparent;
        shadowCol = Colors.transparent;
        shadowHeight = 0;
      }

      if (isMismatched || isSlotFilled) {
        wrapChildren.add(
          Container(
            width: 96.w,
            height: 100.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: borderCol,
                width: 3.w,
              ),
              boxShadow: [
                if (shadowHeight > 0)
                  BoxShadow(
                    color: shadowCol,
                    offset: Offset(0, shadowHeight),
                    blurRadius: 0,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word,
                  style: GoogleFonts.battambang(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '($vnLabel)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: textCol.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        wrapChildren.add(
          CustomPaint(
            painter: DashedBorderPainter(
              color: baseColor.withValues(alpha: 0.6),
              borderRadius: 20.r,
              strokeWidth: 2.5.w,
              dashLength: 6.w,
              gap: 4.w,
            ),
            child: Container(
              width: 96.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: lightColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${idx + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: darkColor.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '($vnLabel)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: darkColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (idx < level.correctWords.length - 1) {
        wrapChildren.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
              size: 22.sp,
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7), // Soft beach cream/sand color
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 3.w), // Driftwood brown border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.15),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Rãnh Thuyền Cát Ghép Câu 🛶',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5D4037),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 18.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: wrapChildren,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordBlocks(_SentenceLevel level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Text(
              '💎 Khối đá chữ cổ gợi ý (Chạm để chọn/hủy):',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF004D40),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14.w,
            runSpacing: 14.h,
            children: _shuffledWords.map((word) {
              final isSelected = _selectedWords.contains(word);
              final meaning = level.wordMeanings[word] ?? '';

              final correctIdx = level.correctWords.indexOf(word);
              final type = correctIdx != -1 ? level.wordTypes[correctIdx] : WordType.object;
              final baseColor = _getWordTypeColor(type);
              final darkColor = _getWordTypeDarkColor(type);

              return GestureDetector(
                onTap: () => _onWordTap(word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(0, isSelected ? 4.h : 0, 0),
                  constraints: BoxConstraints(minWidth: 100.w, minHeight: 80.h, maxWidth: 125.w),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFECEFF1) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFCFD8DC) : baseColor,
                      width: 3.5.w,
                    ),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: darkColor,
                          offset: Offset(0, 5.h),
                          blurRadius: 0,
                        )
                      else
                        BoxShadow(
                          color: const Color(0xFFCFD8DC).withValues(alpha: 0.5),
                          offset: Offset(0, 1.h),
                          blurRadius: 0,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word,
                          style: GoogleFonts.battambang(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF90A4AE) : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (meaning.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            meaning,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? const Color(0xFFB0BEC5) : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlRow() {
    final canConfirm = _selectedWords.isNotEmpty && !_isRoundCompleted;
    return GestureDetector(
      onTap: canConfirm ? _checkAnswer : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: canConfirm
                ? [const Color(0xFF00E676), const Color(0xFF00C853)]
                : [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)]),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: canConfirm ? const Color(0xFF00A343) : const Color(0xFFB0BEC5),
            width: 3.w,
          ),
          boxShadow: [
            if (canConfirm) ...[
              const BoxShadow(
                color: Color(0xFF007E33),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ] else ...[
              const BoxShadow(
                color: Color(0xFFB0BEC5),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ]
          ]),
        child: Center(
          child: Text(
            'Giải mã mật thư',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: canConfirm ? Colors.white : const Color(0xFF90A4AE),
            ),
          ),
        ),
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
        return const Color(0xFFFF8F00);
      case WordType.modifier:
        return const Color(0xFF8E24AA);
    }
  }

  Color _getWordTypeLightColor(WordType type) {
    switch (type) {
      case WordType.subject:
        return const Color(0xFFE3F2FD);
      case WordType.verb:
        return const Color(0xFFE8F5E9);
      case WordType.object:
        return const Color(0xFFFFF3E0);
      case WordType.modifier:
        return const Color(0xFFF3E5F5);
    }
  }

  Color _getWordTypeDarkColor(WordType type) {
    switch (type) {
      case WordType.subject:
        return const Color(0xFF0D47A1);
      case WordType.verb:
        return const Color(0xFF1B5E20);
      case WordType.object:
        return const Color(0xFFE65100);
      case WordType.modifier:
        return const Color(0xFF4A148C);
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          strokeWidth / 2,
          strokeWidth / 2,
          size.width - strokeWidth,
          size.height - strokeWidth,
        ),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
      distance = 0.0;
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
