import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/khmer_letter.dart';
import '../../models/khmer_vowel.dart';
import '../../services/score_service.dart';
import '../../services/admin_service.dart';
import '../../l10n/app_localizations.dart';

/// Trò chơi Bắt chữ Khmer — Premium High-Fidelity 3D UI giống mẫu HTML (Compile-Safe)
class LetterCatchGameScreen extends StatefulWidget {
  const LetterCatchGameScreen({super.key});

  @override
  State<LetterCatchGameScreen> createState() => _LetterCatchGameScreenState();
}

class _LetterCatchGameScreenState extends State<LetterCatchGameScreen>
    with TickerProviderStateMixin {

  // ── Game data ──
  static final List<_SyllableData> _allSyllables = [
    _SyllableData(consonant: 'ក', vowel: 'ា', result: 'កា', meaning: 'quạ'),
    _SyllableData(consonant: 'ម', vowel: 'ា', result: 'មា', meaning: 'mẹ'),
    _SyllableData(consonant: 'ត', vowel: 'ា', result: 'តា', meaning: 'ông'),
    _SyllableData(consonant: 'ប', vowel: 'ា', result: 'បា', meaning: 'cha'),
    _SyllableData(consonant: 'ស', vowel: 'ា', result: 'សា', meaning: 'xoay'),
    _SyllableData(consonant: 'ក', vowel: 'ី', result: 'កី', meaning: 'khó chịu'),
    _SyllableData(consonant: 'ម', vowel: 'ី', result: 'មី', meaning: 'mì'),
    _SyllableData(consonant: 'ដ', vowel: 'ី', result: 'ដី', meaning: 'đất'),
    _SyllableData(consonant: 'ក', vowel: 'ូ', result: 'កូ', meaning: 'con'),
    _SyllableData(consonant: 'រ', vowel: 'ូ', result: 'រូ', meaning: 'hình'),
    _SyllableData(consonant: 'ន', vowel: 'ំ', result: 'នំ', meaning: 'bánh'),
    _SyllableData(consonant: 'ក', vowel: 'ែ', result: 'កែ', meaning: 'sửa'),
    _SyllableData(consonant: 'ទ', vowel: 'ៅ', result: 'ទៅ', meaning: 'đi'),
    _SyllableData(consonant: 'ច', vowel: 'ា', result: 'ចា', meaning: 'chiên'),
    _SyllableData(consonant: 'ព', vowel: 'ី', result: 'ពី', meaning: 'từ'),
    _SyllableData(consonant: 'ល', vowel: 'ា', result: 'លា', meaning: 'tạm biệt'),
    _SyllableData(consonant: 'ថ', vowel: 'ា', result: 'ថា', meaning: 'nói'),
    _SyllableData(consonant: 'យ', vowel: 'ូ', result: 'យូ', meaning: 'lâu'),
    _SyllableData(consonant: 'ហ', vowel: 'ា', result: 'ហា', meaning: 'há'),
    _SyllableData(consonant: 'ឈ', vowel: 'ឺ', result: 'ឈឺ', meaning: 'đau/ốm'),
  ];

  // ── State ──
  int _lives = 3;
  int _score = 0; // Khởi đầu từ 0 điểm
  int _combo = 0;
  int _maxCombo = 0;
  int _level = 2; // Khởi đầu Level 2 giống HTML
  int _questionIndex = 0;
  int _correctCount = 0;
  int _totalQuestions = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  bool _showResult = false;
  bool _lastCorrect = false;

  // Current question
  late _SyllableData _currentSyllable;
  List<String> _consonantChoices = [];
  List<String> _vowelChoices = [];
  List<String> _finalConsonantChoices = [];
  String? _selectedConsonant;
  String? _selectedVowel;
  String? _selectedFinalConsonant;

  // Timer
  int _timeLeft = 25; // 25s giống HTML
  Timer? _timer;

  // Powerups State
  int _hintsLeft = 2;
  int _timePowerupsLeft = 2;
  int _livesPowerupsLeft = 1;
  int _doubleScorePowerupsLeft = 1;
  bool _isDoubleScoreActive = false;
  ScoreService? _scoreService;
  Map<String, dynamic>? _rewardResult;

  // Animations
  late AnimationController _shakeCtrl;
  late AnimationController _celebrateCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _shakeAnim;
  late Animation<double> _celebrateAnim;
  late Animation<double> _resultAnim;

  // TTS
  final FlutterTts _tts = FlutterTts();

  // Shuffled syllables
  late List<_SyllableData> _shuffled;

  final _random = Random();

  List<_SyllableData> _activeSyllables = [];

  @override
  void initState() {
    super.initState();
    _activeSyllables = _allSyllables;
    _loadScoreService();
    _loadGameQuestions();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _celebrateCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _celebrateAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _celebrateCtrl, curve: Curves.elasticOut));

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _resultAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutBack));

    _initTts();
  }

  Future<void> _loadGameQuestions() async {
    try {
      final result = await AdminService().fetchGameQuestionsForUser('letter_catch');
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null && (result['data'] as List).isNotEmpty) {
        final list = result['data'] as List;
        final parsed = list.map((q) {
          final additional = q['additionalData'] as Map?;
          final consonant = additional?['consonant']?.toString() ?? '';
          final vowel = additional?['vowel']?.toString() ?? '';
          final finalConsonant = additional?['finalConsonant']?.toString() ?? '';
          final imageUrl = additional?['imageUrl']?.toString() ?? additional?['image']?.toString();
          final audioUrl = additional?['audioUrl']?.toString() ?? additional?['audio']?.toString();
          final answer = q['answer'] ?? '';
          final prompt = q['prompt'] ?? '';
          return _SyllableData(
            consonant: consonant.isNotEmpty ? consonant : (answer.isNotEmpty ? answer.substring(0, 1) : ''),
            vowel: vowel.isNotEmpty ? vowel : (answer.length > 1 ? answer.substring(1) : ''),
            finalConsonant: finalConsonant,
            result: answer,
            meaning: prompt,
            imageUrl: imageUrl,
            audioUrl: audioUrl,
          );
        }).toList();

        setState(() {
          _activeSyllables = parsed;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    // Đồng bộ vật phẩm hồi phục lên CSDL khi vào game
    await _scoreService?.syncRegeneratedInventory();
    if (mounted) {
      setState(() {
        _hintsLeft = _scoreService?.hintsLeft ?? 2;
        _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
        _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
        _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      });
    }
  }

  Future<void> _initTts() async {
    try {
      final languages = await _tts.getLanguages;
      final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
      final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
      await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
      await _tts.setSpeechRate(0.4);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  void _startGame() {
    _shuffled = List.of(_activeSyllables)..shuffle(_random);
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _level = 1;
      _questionIndex = 0;
      _correctCount = 0;
      _totalQuestions = 0;
      _gameOver = false;
      _rewardResult = null;
      _hintsLeft = _scoreService?.hintsLeft ?? 2;
      _timePowerupsLeft = _scoreService?.timePowerupsLeft ?? 2;
      _livesPowerupsLeft = _scoreService?.livesPowerupsLeft ?? 1;
      _doubleScorePowerupsLeft = _scoreService?.doubleScorePowerupsLeft ?? 1;
      _isDoubleScoreActive = false;
    });
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_questionIndex >= _shuffled.length) {
      _shuffled.shuffle(_random);
      _questionIndex = 0;
      _level++;
    }

    _currentSyllable = _shuffled[_questionIndex];
    _questionIndex++;
    _totalQuestions++;

    // Generate choices
    final allConsonants = KhmerLetterData.consonants
        .where((l) => !l.isTest)
        .map((l) => l.character)
        .toSet()
        .toList();
    final allVowels = ['ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ំ'];

    int consonantChoiceCount = 5;
    int vowelChoiceCount = 4;

    // Consonant choices
    _consonantChoices = [_currentSyllable.consonant];
    final otherConsonants = allConsonants.where((c) => c != _currentSyllable.consonant).toList()..shuffle(_random);
    _consonantChoices.addAll(otherConsonants.take(consonantChoiceCount - 1));
    _consonantChoices.shuffle(_random);

    // Vowel choices
    _vowelChoices = [_currentSyllable.vowel];
    final otherVowels = allVowels.where((v) => v != _currentSyllable.vowel).toList()..shuffle(_random);
    _vowelChoices.addAll(otherVowels.take(vowelChoiceCount - 1));
    _vowelChoices.shuffle(_random);

    // Final Consonant choices
    if (_currentSyllable.finalConsonant.isNotEmpty) {
      _finalConsonantChoices = [_currentSyllable.finalConsonant];
      final otherFinals = allConsonants.where((c) => c != _currentSyllable.finalConsonant).toList()..shuffle(_random);
      _finalConsonantChoices.addAll(otherFinals.take(3));
      _finalConsonantChoices.shuffle(_random);
    } else {
      _finalConsonantChoices = [];
    }

    _selectedConsonant = null;
    _selectedVowel = null;
    _selectedFinalConsonant = null;
    _showResult = false;
    _isDoubleScoreActive = false;

    // Timer
    _timeLeft = 25; 
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _onWrong();
      }
    });

    if (mounted) setState(() {});
  }

  void _selectConsonant(String c) {
    if (_showResult) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedConsonant == c) {
        _selectedConsonant = null; 
      } else {
        _selectedConsonant = c;
      }
    });
  }

  void _selectVowel(String v) {
    if (_showResult) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedVowel == v) {
        _selectedVowel = null; 
      } else {
        _selectedVowel = v;
      }
    });
  }

  void _selectFinalConsonant(String fc) {
    if (_showResult) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedFinalConsonant == fc) {
        _selectedFinalConsonant = null;
      } else {
        _selectedFinalConsonant = fc;
      }
    });
  }

  void _checkAnswer() {
    final needsVowel = _currentSyllable.vowel.isNotEmpty;
    final needsFinal = _currentSyllable.finalConsonant.isNotEmpty;

    if (_selectedConsonant == null ||
        (needsVowel && _selectedVowel == null) ||
        (needsFinal && _selectedFinalConsonant == null) ||
        _showResult) {
      return;
    }
    _timer?.cancel();

    final correct = _selectedConsonant == _currentSyllable.consonant &&
        (!needsVowel || _selectedVowel == _currentSyllable.vowel) &&
        (!needsFinal || _selectedFinalConsonant == _currentSyllable.finalConsonant);

    if (correct) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _onCorrect() {
    HapticFeedback.mediumImpact();
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _correctCount++;
    final bonus = _combo >= 5 ? 3 : _combo >= 3 ? 2 : 1;
    
    int addedScore = 10 * bonus;
    if (_isDoubleScoreActive) {
      addedScore *= 2;
    }
    _score += addedScore;

    if (_currentSyllable.audioUrl != null && _currentSyllable.audioUrl!.isNotEmpty) {
      try {
        final player = AudioPlayer();
        player.play(UrlSource(_currentSyllable.audioUrl!));
      } catch (e) {
        debugPrint('Error playing custom audio: $e');
        try {
          _tts.speak(_currentSyllable.result);
        } catch (_) {}
      }
    } else {
      try {
        _tts.speak(_currentSyllable.result);
      } catch (_) {}
    }

    setState(() {
      _showResult = true;
      _lastCorrect = true;
    });
    _celebrateCtrl.forward(from: 0);
    _resultCtrl.forward(from: 0);

    ScoreService.getInstance().then((s) {
      s.completeGame('Bắt chữ Khmer', addedScore, syncToBackend: false);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted || _gameOver) return;
      _nextQuestion();
    });
  }

  void _onWrong() {
    HapticFeedback.heavyImpact();
    _combo = 0;
    _lives--;

    setState(() {
      _showResult = true;
      _lastCorrect = false;
      _selectedConsonant = _currentSyllable.consonant;
      _selectedVowel = _currentSyllable.vowel;
    });
    _shakeCtrl.forward(from: 0);
    _resultCtrl.forward(from: 0);

    if (_lives <= 0) {
      // Đồng bộ kết quả tổng kết lên backend database
      ScoreService.getInstance().then((s) async {
        final result = await s.completeGame(
          'Bắt chữ Khmer',
          _score,
          syncToBackend: true,
          correctAnswers: _correctCount,
          totalQuestions: _totalQuestions,
        );
        if (mounted) {
          setState(() {
            _rewardResult = result;
          });
        }
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _gameOver = true);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted || _gameOver) return;
        _nextQuestion();
      });
    }
  }

  // Helper to format cooldown remaining seconds into readable time
  String _formatCooldown(int seconds) {
    if (seconds <= 0) return context.translate('game_catch_letter.cooldown_zero');
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    
    if (h > 0) {
      return context.translate('game_catch_letter.cooldown_hours_mins', args: {
        'hours': h.toString(),
        'mins': m.toString(),
      });
    } else if (m > 0) {
      return context.translate('game_catch_letter.cooldown_mins_secs', args: {
        'mins': m.toString(),
        'secs': s.toString(),
      });
    } else {
      return context.translate('game_catch_letter.cooldown_secs', args: {
        'secs': s.toString(),
      });
    }
  }

  String _getTranslatedMeaning(String meaning) {
    final sanitized = meaning.toLowerCase().trim()
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll('đ', 'd')
        .replaceAll('â', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ư', 'u')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y');
    
    final translationKey = 'game_catch_letter.meaning_$sanitized';
    final translated = context.translate(translationKey);
    if (translated != translationKey) {
      return translated;
    }
    return meaning;
  }

  void _showCooldownMessage(String itemKey, int remainingSeconds) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    final itemName = context.translate('game_catch_letter.$itemKey');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.translate('game_catch_letter.powerup_cooldown', args: {
                  'name': itemName,
                  'time': _formatCooldown(remainingSeconds),
                }),
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
    if (_showResult || _gameOver) return;
    if (_hintsLeft <= 0) {
      final remaining = _scoreService?.hintsCooldownRemaining ?? 0;
      _showCooldownMessage('hint_name', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _hintsLeft--;
      if (_selectedConsonant != _currentSyllable.consonant) {
        _selectedConsonant = _currentSyllable.consonant;
      } else {
        _selectedVowel = _currentSyllable.vowel;
      }
    });
    _scoreService?.useHint();
  }

  void _useTimePowerup() {
    if (_showResult || _gameOver) return;
    if (_timePowerupsLeft <= 0) {
      final remaining = _scoreService?.timeCooldownRemaining ?? 0;
      _showCooldownMessage('time_name', remaining);
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
    if (_showResult || _gameOver) return;
    if (_livesPowerupsLeft <= 0) {
      final remaining = _scoreService?.livesCooldownRemaining ?? 0;
      _showCooldownMessage('live_name', remaining);
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
    if (_showResult || _gameOver || _isDoubleScoreActive) return;
    if (_doubleScorePowerupsLeft <= 0) {
      final remaining = _scoreService?.doubleScoreCooldownRemaining ?? 0;
      _showCooldownMessage('double_name', remaining);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _doubleScorePowerupsLeft--;
      _isDoubleScoreActive = true;
    });
    _scoreService?.useDoubleScorePowerup();
  }

  String _getIllustrationUrl(String meaning) {
    final map = {
      'quạ': 'https://images.unsplash.com/photo-1597005089699-56d30d10aa29?w=300&auto=format&fit=crop',
      'mì': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300&auto=format&fit=crop',
      'ông': 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=300&auto=format&fit=crop',
      'cha': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&auto=format&fit=crop',
      'mẹ': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300&auto=format&fit=crop',
      'hình': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=300&auto=format&fit=crop',
      'bánh': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300&auto=format&fit=crop',
      'đất': 'https://images.unsplash.com/photo-1581291518633-83b4ebd1d83e?w=300&auto=format&fit=crop',
      'sửa': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300&auto=format&fit=crop',
      'đi': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&auto=format&fit=crop',
      'đau/ốm': 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=300&auto=format&fit=crop',
      'khó chịu': 'https://images.unsplash.com/photo-1542382257-201b72a276b9?w=300&auto=format&fit=crop',
      'xoay': 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=300&auto=format&fit=crop',
      'con': 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?w=300&auto=format&fit=crop',
      'chiên': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=300&auto=format&fit=crop',
      'từ': 'https://images.unsplash.com/photo-1508847154043-be12a62861c1?w=300&auto=format&fit=crop',
      'tạm biệt': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=300&auto=format&fit=crop',
      'nói': 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=300&auto=format&fit=crop',
      'lâu': 'https://images.unsplash.com/photo-1508962914676-134849a727f0?w=300&auto=format&fit=crop',
      'há': 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=300&auto=format&fit=crop',
    };
    return map[meaning] ?? 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?w=300&auto=format&fit=crop';
  }

  Widget _buildIllustrationWidget() {
    if (_currentSyllable.imageUrl != null && _currentSyllable.imageUrl!.isNotEmpty) {
      final imgUrl = _currentSyllable.imageUrl!;
      if (imgUrl.startsWith('http')) {
        return Image.network(
          imgUrl,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A373)));
          },
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/elephant_mascot.png',
            fit: BoxFit.contain,
          ),
        );
      } else {
        return Image.asset(
          imgUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/elephant_mascot.png',
            fit: BoxFit.contain,
          ),
        );
      }
    }

    final meaning = _currentSyllable.meaning;
    final url = _getIllustrationUrl(meaning);

    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A373)));
      },
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/elephant_mascot.png',
        fit: BoxFit.contain,
      ),
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _celebrateCtrl.dispose();
    _resultCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _onWrong();
      }
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
                context.translate('game_catch_letter.exit_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE65100),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                context.translate('game_catch_letter.exit_desc'),
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
                            context.translate('game_catch_letter.continue_playing'),
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
                            context.translate('game_catch_letter.exit_btn'),
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
                    : _buildGamePlay(),
          ),
        ],
      ),
    ),
    );
  }

  // ═══════════════════════════════════════════
  // START SCREEN
  // ═══════════════════════════════════════════
  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Bubbly 3D Icon Container
          Container(
            width: 120.w, height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB300), Color(0xFFFF6D00)]),
              border: Border.all(color: Colors.white, width: 4.w),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                  blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 8)),
              ]),
            child: Center(
              child: Text('🎮', style: TextStyle(fontSize: 60.sp)),
            ),
          ),
          SizedBox(height: 24.h),
          // Title
          Text(context.translate('game_catch_letter.title'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32.sp, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [
                Shadow(color: const Color(0xFF1B5E20), offset: Offset(2.w, 2.h), blurRadius: 4),
              ])),
          SizedBox(height: 12.h),
          Text(context.translate('game_catch_letter.subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp, fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95), height: 1.5)),
          SizedBox(height: 32.h),
          // Rules Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))
              ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ruleRow('🔵', context.translate('game_catch_letter.rule_consonant')),
              SizedBox(height: 10.h),
              _ruleRow('🔴', context.translate('game_catch_letter.rule_vowel')),
              SizedBox(height: 10.h),
              _ruleRow('🔥', context.translate('game_catch_letter.rule_combo')),
              SizedBox(height: 10.h),
              _ruleRow('❤️', context.translate('game_catch_letter.rule_lives')),
              SizedBox(height: 10.h),
              _ruleRow('🛡️', context.translate('game_catch_letter.rule_powerups')),
            ]),
          ),
          SizedBox(height: 40.h),
          // Premium 3D Green Play Button
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 52.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  const BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 6), blurRadius: 0),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 8), blurRadius: 10),
                ]),
              child: Text(context.translate('games.start_playing').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 1.5)),
                  ])),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _ruleRow(String emoji, String text) {
    return Row(children: [
      Text(emoji, style: TextStyle(fontSize: 20.sp)),
      SizedBox(width: 12.w),
      Text(text, style: GoogleFonts.plusJakartaSans(
        fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A237E))),
    ]);
  }

  // ═══════════════════════════════════════════
  // GAMEPLAY UI
  // ═══════════════════════════════════════════
  Widget _buildGamePlay() {
    return Column(
      children: [
        // ── HeaderStats (Hearts, Score, Timer, Level) ──
        _buildHeaderStats(),
        
        // ── Level Bar & Combo Pulsing indicator ──
        _buildLevelBarRow(),
        
        // ── Main Content Area ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 16.w, right: 10.w, top: 8.h, bottom: 8.h),
            child: Column(
              children: [
                // Top Row: Parchment Card on left, Powerups Column on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildParchmentCard(),
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
                SizedBox(height: 14.h),

                // ── Workspace Formula (Wooden Board) ──
                _buildWoodenBoard(),
                SizedBox(height: 14.h),

                // ── Letter Selection Rows ──
                _buildSelectionTiles(),
                SizedBox(height: 20.h),

                // ── Action Button (Confirm Button) ──
                _buildConfirmButton(),
                SizedBox(height: 16.h),
              ],
            ),
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
          // Left: Score & Hearts grouped together (Beautiful asymmetrical HUD)
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
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(color: Colors.white, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3), blurRadius: 6),
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
          
          // Right: Timer (blue 3D)
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

  Widget _buildLevelBarRow() {
    double progress = (_questionIndex - 1).clamp(0, 5) / 5.0;
    if (progress == 0) progress = 0.15;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(children: [
        // Level Progress bar (Original Height 32.h)
        Expanded(
          child: Container(
            height: 32.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 2.w),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 4),
              ]),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final starSize = 34.h;
                // Center the star exactly on the right edge of the progress fill
                final starLeft = (progress * barWidth - starSize / 2).clamp(0.0, barWidth - starSize);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Progress Fill
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1)]),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 3),
                          ]),
                      ),
                    ),
                    // Level text overlay
                    Center(
                      child: Text('Level $_level',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF006064),
                        )),
                    ),
                    // Floating star at progress edge
                    Positioned(
                      left: starLeft,
                      top: -3.h,
                      child: Container(
                        width: starSize, height: starSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF176), Color(0xFFFBC02D)],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          border: Border.all(color: Colors.white, width: 1.5.w),
                          boxShadow: [
                            const BoxShadow(color: Color(0xFFF57F17), offset: Offset(0, 2), blurRadius: 0),
                            BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 3), blurRadius: 3),
                          ]),
                        child: Icon(Icons.star_rounded, color: Colors.white, size: 20.h),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Combo Box
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          width: 82.w,
          height: 32.h,
          alignment: Alignment.center,
          decoration: _combo >= 2
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFB923C), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5.w),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFFD97706), offset: Offset(0, 2), blurRadius: 0),
                    BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 10),
                  ])
              : BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFCFD8DC), width: 1.5.w),
                ),
          child: Text('🔥 x$_combo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w900,
              color: _combo >= 2 ? Colors.white : const Color(0xFF78909C),
            )),
        ),
      ]),
    );
  }

  Widget _buildParchmentCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Parchment card frame
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white, 
            border: Border.all(color: const Color(0xFFE8F5E9), width: 2.w),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF33691E).withOpacity(0.06),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.04),
                blurRadius: 24.r,
                offset: Offset(0, 12.h),
              ),
            ]),
          child: Row(children: [
            // Left: Meaning styled 3D
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getTranslatedMeaning(_currentSyllable.meaning).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE11D48),
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 2), blurRadius: 3),
                      ]),
                  ),
                  if (_showResult) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _lastCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _lastCorrect ? const Color(0xFF81C784) : const Color(0xFFE57373),
                          width: 1)),
                      child: Text(
                        _lastCorrect
                            ? context.translate('game_catch_letter.correct_banner')
                            : context.translate('game_catch_letter.incorrect_banner'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp, fontWeight: FontWeight.bold,
                          color: _lastCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Right: Illustration & TTS Speak Button
            Expanded(
              child: Stack(alignment: Alignment.center, children: [
                // Illustration image
                Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFECEFF1), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                    ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: _buildIllustrationWidget(),
                  ),
                ),
                // Audio Speak icon overlay
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      try {
                        _tts.speak(_currentSyllable.result);
                      } catch (_) {}
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4DD0E1),
                        border: Border.all(color: Colors.white, width: 1.5.w),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ]),
                      child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        // Absolute Purple ribbon header
        Positioned(
          top: -12.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB388FF), Color(0xFF6200EA)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                boxShadow: [
                  const BoxShadow(color: Color(0xFF4527A0), offset: Offset(0, 3), blurRadius: 0),
                  BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 4), blurRadius: 4),
                ]),
              child: Text(context.translate('game_catch_letter.to_combine'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionTiles() {
    final needsVowel = _currentSyllable.vowel.isNotEmpty;
    final needsFinal = _currentSyllable.finalConsonant.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1), 
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFCFD8DC), width: 2.w),
      ),
      child: Column(children: [
        // Row 1: Consonants
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(context.translate('game_catch_letter.consonant_section'), style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
        ]),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _consonantChoices.map((con) {
              final isSel = _selectedConsonant == con;
              final isCorrect = _showResult && con == _currentSyllable.consonant;
              final isWrong = _showResult && isSel && con != _currentSyllable.consonant;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                child: ThreeDTile(
                  text: con,
                  color: const Color(0xFF42A5F5), // Cohesive Consonant color
                  isSelected: isSel,
                  isCorrect: isCorrect,
                  isWrong: isWrong,
                  onTap: () => _selectConsonant(con),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Row 2: Vowels (conditional)
        if (needsVowel) ...[
          SizedBox(height: 12.h),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(context.translate('game_catch_letter.vowel_section'), style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _vowelChoices.map((vow) {
                final isSel = _selectedVowel == vow;
                final isCorrect = _showResult && vow == _currentSyllable.vowel;
                final isWrong = _showResult && isSel && vow != _currentSyllable.vowel;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                  child: ThreeDTile(
                    text: 'អ$vow',
                    color: const Color(0xFFFFB74D), // Cohesive Vowel color
                    isSelected: isSel,
                    isCorrect: isCorrect,
                    isWrong: isWrong,
                    onTap: () => _selectVowel(vow),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Row 3: Final Consonants (conditional)
        if (needsFinal) ...[
          SizedBox(height: 12.h),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(context.translate('game_catch_letter.final_consonant_section') ?? 'PHỤ ÂM CUỐI', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _finalConsonantChoices.map((fc) {
                final isSel = _selectedFinalConsonant == fc;
                final isCorrect = _showResult && fc == _currentSyllable.finalConsonant;
                final isWrong = _showResult && isSel && fc != _currentSyllable.finalConsonant;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                  child: ThreeDTile(
                    text: fc,
                    color: const Color(0xFF7C4DFF), // Cohesive Final Consonant color
                    isSelected: isSel,
                    isCorrect: isCorrect,
                    isWrong: isWrong,
                    onTap: () => _selectFinalConsonant(fc),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildWoodenBoard() {
    final needsVowel = _currentSyllable.vowel.isNotEmpty;
    final needsFinal = _currentSyllable.finalConsonant.isNotEmpty;

    final showCombined = _selectedConsonant != null &&
        (!needsVowel || _selectedVowel != null) &&
        (!needsFinal || _selectedFinalConsonant != null);

    final double slotWidth = (needsVowel && needsFinal) ? 52.w : 64.w;

    String combinedText = '';
    if (showCombined) {
      String consonantPart = _selectedConsonant!;
      String vowelPart = needsVowel ? _selectedVowel! : '';
      String finalPart = needsFinal ? _selectedFinalConsonant! : '';

      if (consonantPart == 'ក' && vowelPart == 'ា' && finalPart.isEmpty) {
        combinedText = 'កា';
      } else if (consonantPart == 'ម' && vowelPart == 'ា' && finalPart.isEmpty) {
        combinedText = 'មា';
      } else if (consonantPart == 'ត' && vowelPart == 'ា' && finalPart.isEmpty) {
        combinedText = 'តា';
      } else if (consonantPart == 'ប' && vowelPart == 'ា' && finalPart.isEmpty) {
        combinedText = 'បា';
      } else if (consonantPart == 'ស' && vowelPart == 'ា' && finalPart.isEmpty) {
        combinedText = 'សា';
      } else {
        combinedText = '$consonantPart$vowelPart$finalPart';
      }
    }

    List<Widget> children = [];

    // 1. Consonant slot
    children.add(_buildWorkspaceSlot(_selectedConsonant, const Color(0xFF42A5F5), 'P', width: slotWidth));

    // 2. Vowel slot
    if (needsVowel) {
      children.add(SizedBox(width: 8.w));
      children.add(Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF558B2F))));
      children.add(SizedBox(width: 8.w));
      children.add(_buildWorkspaceSlot(_selectedVowel != null ? 'អ$_selectedVowel' : null, const Color(0xFFFFB74D), 'N', width: slotWidth));
    }

    // 3. Final consonant slot
    if (needsFinal) {
      children.add(SizedBox(width: 8.w));
      children.add(Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF558B2F))));
      children.add(SizedBox(width: 8.w));
      children.add(_buildWorkspaceSlot(_selectedFinalConsonant, const Color(0xFF8B5CF6), 'C', width: slotWidth));
    }

    // 4. Equal and Combined
    children.add(SizedBox(width: 8.w));
    children.add(Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF558B2F))));
    children.add(SizedBox(width: 8.w));
    children.add(_buildWorkspaceSlot(
      showCombined ? combinedText : null,
      const Color(0xFF66BB6A),
      'K',
      isResult: true,
      isGlowing: _showResult && _lastCorrect,
      width: slotWidth,
    ));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFC5E1A5), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33691E).withOpacity(0.08),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildWorkspaceSlot(String? char, Color color, String placeholder, {bool isResult = false, bool isGlowing = false, double? width}) {
    final w = width ?? 64.w;
    return Container(
      width: w,
      height: w,
      decoration: BoxDecoration(
        color: char != null ? color : const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(16.r),
        border: isGlowing
            ? Border.all(color: const Color(0xFF00E676), width: 3.w)
            : Border.all(
                color: char != null ? Colors.white.withOpacity(0.5) : const Color(0xFFCFD8DC),
                width: 2.w,
              ),
        boxShadow: [
          if (isGlowing)
            BoxShadow(color: const Color(0xFF00E676).withOpacity(0.5), blurRadius: 12, spreadRadius: 2),
          if (char != null)
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 3),
              blurRadius: 4,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 2,
            )
        ]),
      child: Center(
        child: char != null
            ? Text(char,
                style: GoogleFonts.battambang(
                  fontSize: isResult ? 24.sp : 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 1.5)),
                  ]))
            : Text(placeholder,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp, fontWeight: FontWeight.w900,
                  color: const Color(0xFFB0BEC5))),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = _selectedConsonant != null && _selectedVowel != null && !_showResult;
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
          Text(context.translate('game_catch_letter.confirm_btn'),
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
      onTap: !_showResult && !_gameOver ? onTap : null,
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

  // ═══════════════════════════════════════════
  // GAME OVER UI
  // ═══════════════════════════════════════════
  Widget _buildGameOverScreen() {
    final accuracy = _totalQuestions > 0 ? (_correctCount / _totalQuestions * 100).toInt() : 0;
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
                    color: const Color(0xFFE65100).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 4),
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
              context.translate('game_catch_letter.game_over_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B5E20),
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: Offset(2.w, 2.h),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            if (_rewardResult != null) ...[
              SizedBox(height: 16.h),
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPremiumStatTile(
                    label: context.translate('game_catch_letter.score_label'),
                    value: '$_score',
                    fallbackIcon: Icons.emoji_events_rounded,
                    themeColor: const Color(0xFFF57C00),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: context.translate('game_catch_letter.correct_label'),
                    value: '$_correctCount / $_totalQuestions',
                    fallbackIcon: Icons.check_circle_rounded,
                    themeColor: const Color(0xFF2E7D32),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: context.translate('game_catch_letter.accuracy_label'),
                    value: '$accuracy%',
                    fallbackIcon: Icons.track_changes_rounded,
                    themeColor: const Color(0xFF1565C0),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: context.translate('game_catch_letter.max_combo_label'),
                    value: 'x$_maxCombo',
                    fallbackIcon: Icons.local_fire_department_rounded,
                    themeColor: const Color(0xFFC62828),
                  ),
                  SizedBox(height: 12.h),
                  _buildPremiumStatTile(
                    label: context.translate('game_catch_letter.max_level_label'),
                    value: 'Level $_level',
                    fallbackIcon: Icons.bar_chart_rounded,
                    themeColor: const Color(0xFF6A1B9A),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                          context.translate('game_catch_letter.exit_btn_gameover'),
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
                          context.translate('game_catch_letter.replay_btn_gameover'),
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
}

// ── 3D Tile Widget ──
class ThreeDTile extends StatelessWidget {
  final String text;
  final Color color;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;
  final double size;

  const ThreeDTile({
    super.key,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
    required this.onTap,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    Color mainColor = color;
    Color shadowColor = Color.lerp(color, Colors.black, 0.25)!;
    if (isCorrect) {
      mainColor = const Color(0xFF43A047);
      shadowColor = const Color(0xFF2E7D32);
    } else if (isWrong) {
      mainColor = const Color(0xFFD32F2F);
      shadowColor = const Color(0xFFC62828);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, isSelected ? 4.h : 0, 0),
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, 4.h),
                blurRadius: 0,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: Offset(0, isSelected ? 1.5.h : 5.h),
              blurRadius: 4.r,
            ),
          ]),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.battambang(
              fontSize: (size * 0.42).sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyllableData {
  final String consonant;
  final String vowel;
  final String finalConsonant;
  final String result;
  final String meaning;
  final String? imageUrl;
  final String? audioUrl;
  const _SyllableData({
    required this.consonant,
    required this.vowel,
    this.finalConsonant = '',
    required this.result,
    required this.meaning,
    this.imageUrl,
    this.audioUrl,
  });
}
