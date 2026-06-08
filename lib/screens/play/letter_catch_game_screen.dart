import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/khmer_letter.dart';
import '../../models/khmer_vowel.dart';
import '../../services/score_service.dart';

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
  int _score = 150; // Khởi đầu 150 điểm cho sinh động giống HTML
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
  String? _selectedConsonant;
  String? _selectedVowel;

  // Timer
  int _timeLeft = 25; // 25s giống HTML
  Timer? _timer;

  // Powerups State
  int _hintsLeft = 2;
  int _timePowerupsLeft = 2;
  int _livesPowerupsLeft = 1;
  int _doubleScorePowerupsLeft = 1;
  bool _isDoubleScoreActive = false;

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

  @override
  void initState() {
    super.initState();
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
    _shuffled = List.of(_allSyllables)..shuffle(_random);
    setState(() {
      _gameStarted = true;
      _lives = 3;
      _score = 150;
      _combo = 0;
      _maxCombo = 0;
      _level = 1;
      _questionIndex = 0;
      _correctCount = 0;
      _totalQuestions = 0;
      _gameOver = false;
      _hintsLeft = 2;
      _timePowerupsLeft = 2;
      _livesPowerupsLeft = 1;
      _doubleScorePowerupsLeft = 1;
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

    _selectedConsonant = null;
    _selectedVowel = null;
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

  void _checkAnswer() {
    if (_selectedConsonant == null || _selectedVowel == null || _showResult) return;
    _timer?.cancel();

    final correct = _selectedConsonant == _currentSyllable.consonant &&
        _selectedVowel == _currentSyllable.vowel;

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

    try {
      _tts.speak(_currentSyllable.result);
    } catch (_) {}

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
      ScoreService.getInstance().then((s) {
        s.completeGame('Bắt chữ Khmer', _score, syncToBackend: true);
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

  // ── Powerups Logic ──
  void _useHint() {
    if (_hintsLeft <= 0 || _showResult) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _hintsLeft--;
      if (_selectedConsonant != _currentSyllable.consonant) {
        _selectedConsonant = _currentSyllable.consonant;
      } else {
        _selectedVowel = _currentSyllable.vowel;
      }
    });
  }

  void _useTimePowerup() {
    if (_timePowerupsLeft <= 0 || _showResult) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _timePowerupsLeft--;
      _timeLeft += 10;
    });
  }

  void _useLivesPowerup() {
    if (_livesPowerupsLeft <= 0 || _showResult) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _livesPowerupsLeft--;
      if (_lives < 3) _lives++;
    });
  }

  void _useDoubleScorePowerup() {
    if (_doubleScorePowerupsLeft <= 0 || _showResult || _isDoubleScoreActive) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _doubleScorePowerupsLeft--;
      _isDoubleScoreActive = true;
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
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
          Text('Bắt chữ Khmer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32.sp, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [
                Shadow(color: const Color(0xFF1B5E20), offset: Offset(2.w, 2.h), blurRadius: 4),
              ])),
          SizedBox(height: 12.h),
          Text('Ghép phụ âm + nguyên âm Khmer\nthành từ có nghĩa thật nhanh!',
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
              _ruleRow('🔵', 'Chọn phụ âm tương ứng'),
              SizedBox(height: 10.h),
              _ruleRow('🔴', 'Chọn nguyên âm tương ứng'),
              SizedBox(height: 10.h),
              _ruleRow('🔥', 'Tạo Combo nhân hệ số điểm'),
              SizedBox(height: 10.h),
              _ruleRow('❤️', '3 Mạng chơi — Bảo vệ kỹ càng'),
              SizedBox(height: 10.h),
              _ruleRow('🛡️', 'Sử dụng bảo bối trợ giúp ở dưới'),
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
              child: Text('BẮT ĐẦU CHƠI',
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
                onTap: () => Navigator.pop(context),
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
                    _currentSyllable.meaning.toUpperCase(),
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
                        _lastCorrect ? 'Chính xác! 🎉' : 'Bé thử lại nhé ⏰',
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
              child: Text('TỪ CẦN GHÉP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionTiles() {
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
            child: Text('PHỤ ÂM', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
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
        SizedBox(height: 12.h),
        // Row 2: Vowels
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
            child: Text('NGUYÊN ÂM', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
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
      ]),
    );
  }

  Widget _buildWoodenBoard() {
    final showCombined = _selectedConsonant != null && _selectedVowel != null;
    String combinedText = '';
    if (showCombined) {
      if (_selectedConsonant == 'ក' && _selectedVowel == 'ា') combinedText = 'កา';
      else if (_selectedConsonant == 'ម' && _selectedVowel == 'ា') combinedText = 'មា';
      else if (_selectedConsonant == 'ត' && _selectedVowel == 'ា') combinedText = 'តា';
      else if (_selectedConsonant == 'ប' && _selectedVowel == 'ា') combinedText = 'បา';
      else if (_selectedConsonant == 'ស' && _selectedVowel == 'ា') combinedText = 'សា';
      else combinedText = '$_selectedConsonant$_selectedVowel';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
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
        ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWorkspaceSlot(_selectedConsonant, const Color(0xFF42A5F5), 'P'),
          SizedBox(width: 12.w),
          Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w900, color: const Color(0xFF558B2F))),
          SizedBox(width: 12.w),
          _buildWorkspaceSlot(_selectedVowel != null ? 'អ$_selectedVowel' : null, const Color(0xFFFFB74D), 'N'),
          SizedBox(width: 12.w),
          Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w900, color: const Color(0xFF558B2F))),
          SizedBox(width: 12.w),
          _buildWorkspaceSlot(
            showCombined ? combinedText : null,
            const Color(0xFF66BB6A),
            'K',
            isResult: true,
            isGlowing: _showResult && _lastCorrect,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSlot(String? char, Color color, String placeholder, {bool isResult = false, bool isGlowing = false}) {
    return Container(
      width: 68.w,
      height: 68.w,
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
      onTap: hasItem && !_showResult && !_gameOver ? onTap : null,
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
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))
              ]),
            child: Column(children: [
              _statRow('⭐ Điểm tích lũy', '$_score'),
              SizedBox(height: 12.h),
              _statRow('✅ Đúng', '$_correctCount / $_totalQuestions'),
              SizedBox(height: 12.h),
              _statRow('🎯 Chính xác', '$accuracy%'),
              SizedBox(height: 12.h),
              _statRow('🔥 Combo cao nhất', 'x$_maxCombo'),
              SizedBox(height: 12.h),
              _statRow('📊 Cấp độ tối đa', 'Level $_level'),
            ]),
          ),
          SizedBox(height: 32.h),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
        ]),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF374151))),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 18.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE65100))),
    ]);
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
  final String result;
  final String meaning;
  const _SyllableData({
    required this.consonant,
    required this.vowel,
    required this.result,
    required this.meaning,
  });
}
