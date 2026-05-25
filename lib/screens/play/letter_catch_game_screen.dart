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
    _SyllableData(consonant: 'ប', vowel: 'ា', result: 'បา', meaning: 'cha'),
    _SyllableData(consonant: 'ស', vowel: 'ា', result: 'សា', meaning: 'xoay'),
    _SyllableData(consonant: 'ក', vowel: 'ី', result: 'កី', meaning: 'khó chịu'),
    _SyllableData(consonant: 'ម', vowel: 'ី', result: 'មី', meaning: 'mì'),
    _SyllableData(consonant: 'ដ', vowel: 'ី', result: 'ដី', meaning: 'đất'),
    _SyllableData(consonant: 'ក', vowel: 'ូ', result: 'កូ', meaning: 'con'),
    _SyllableData(consonant: 'រ', vowel: 'ូ', result: 'រូ', meaning: 'hình'),
    _SyllableData(consonant: 'ន', vowel: 'ំ', result: 'នំ', meaning: 'bánh'),
    _SyllableData(consonant: 'ក', vowel: 'ែ', result: 'កែ', meaning: 'sửa'),
    _SyllableData(consonant: 'ទ', vowel: 'ឹ', result: 'ទឹ', meaning: 'nước'),
    _SyllableData(consonant: 'ច', vowel: 'ា', result: 'ចា', meaning: 'chiên'),
    _SyllableData(consonant: 'ព', vowel: 'ី', result: 'ពី', meaning: 'từ'),
    _SyllableData(consonant: 'ល', vowel: 'ា', result: 'លា', meaning: 'tạm biệt'),
    _SyllableData(consonant: 'ថ', vowel: 'ា', result: 'ថា', meaning: 'nói'),
    _SyllableData(consonant: 'យ', vowel: 'ូ', result: 'យូ', meaning: 'lâu'),
    _SyllableData(consonant: 'ហ', vowel: 'ា', result: 'ហា', meaning: 'há'),
    _SyllableData(consonant: 'ផ', vowel: 'ា', result: 'ផ្កา', meaning: 'hoa'),
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
    final allVowels = ['ា', 'ិ', 'ី', 'ឹ', 'ូ', 'ុ', 'ែ', 'េ', 'ំ', 'ោ', 'ៅ', 'ួ'];

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
      s.completeGame('Bắt chữ Khmer', addedScore);
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
      'quạ': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7SOwpVEoEGWrNSPpTqKbj9DUpAaktI2LExUvbK0DtUp39gRoFTSraRlE2t4HAsNaP4eWS0hnq6mUjbNtB_8TN5KAdpo3syPg9JkVYfloMaVBvIeLmtm7a5Vo6KlgdEePC35TcvWR-VB5lbQTVDVd0IUTMnxMUYN7jvMvzFjNBd1CWlT2iU6_TLz8ioljKG7J3NysPhW24NbM2_TmEbOcB2xdHNX4TxW24WAfZKD3MGAPpGeFQUGwRoSoMGbsPlFJJ4TKusPZduQ',
      'mì': 'https://img.freepik.com/free-vector/ramen-noodle-soup-bowl-with-chopsticks-cartoon-illustration_138676-2603.jpg',
      'ông': 'https://img.freepik.com/free-vector/old-man-cartoon-character_1308-133939.jpg',
      'cha': 'https://img.freepik.com/free-vector/father-son-cartoon-illustration_1308-133919.jpg',
      'mẹ': 'https://img.freepik.com/free-vector/mother-with-daughter-cartoon_1308-133959.jpg',
      'hình': 'https://img.freepik.com/free-vector/geometric-shapes-cartoon_1308-133969.jpg',
      'bánh': 'https://img.freepik.com/free-vector/strawberry-cupcake-cartoon_1308-133979.jpg',
      'hoa': 'https://img.freepik.com/free-vector/yellow-flower-cartoon_1308-133989.jpg',
      'đất': 'https://img.freepik.com/free-vector/soil-ground-cartoon_1308-133999.jpg',
    };
    return map[meaning] ?? 'https://img.freepik.com/free-vector/cute-baby-elephant-cartoon_1308-134009.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient (Sky to Forest) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFF228B22)],
              ),
            ),
          ),
          // ── Beautiful Rural Scenery Overlay Layer ──
          Opacity(
            opacity: 0.8,
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
    return Column(children: [
      // ── HeaderStats (Hearts, Score, Timer, Level) ──
      _buildHeaderStats(),
      
      // ── Level Bar & Combo Pulsing indicator ──
      _buildLevelBarRow(),
      
      // ── Main Content Area ──
      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(children: [
            // ── Word Display Banner (Parchment Card) ──
            _buildParchmentCard(),
            SizedBox(height: 14.h),

            // ── Letter Selection Rows ──
            _buildSelectionTiles(),
            SizedBox(height: 14.h),

            // ── Workspace Formula (Wooden Board) ──
            _buildWoodenBoard(),
            SizedBox(height: 20.h),

            // ── Action Button (Confirm Button) ──
            _buildConfirmButton(),
            SizedBox(height: 16.h),
          ]),
        ),
      ),

      // ── Footer Navigation (Power-up Shelf) ──
      _buildPowerUpFooter(),
    ]);
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(0, 3), blurRadius: 0),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(0, 4), blurRadius: 4),
                    ]),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF475569), size: 20)),
              ),
              // Star score badge (yellow 3D)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFFD97706), offset: Offset(0, 3), blurRadius: 0),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 4), blurRadius: 4),
                  ]),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: const Color(0xFFFFEB3B), size: 18.w),
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
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 0),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, 3), blurRadius: 3),
                  ]),
                child: Row(
                  children: List.generate(3, (i) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                    child: Text(i < _lives ? '❤️' : '🤍', style: TextStyle(fontSize: 16.sp)),
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
                    : [const Color(0xFF60A5FA), const Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white, width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: _timeLeft <= 5 ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8),
                  offset: const Offset(0, 3), blurRadius: 0),
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 4), blurRadius: 4),
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
              color: Colors.blue.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 2), blurRadius: 4),
              ]),
            child: Stack(clipBehavior: Clip.none, children: [
              // Progress Fill
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 3),
                    ]),
                ),
              ),
              // Level text overlay
              Center(
                child: Text('Level $_level',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(0, 1), blurRadius: 2),
                    ])),
              ),
              // Floating star at progress edge (Premium 3D badge - Shrunk slightly to 35.h to fit perfectly)
              Positioned(
                left: (progress * 100 - 5).clamp(0, 92).w,
                top: -3.h,
                child: Container(
                  width: 35.h, height: 35.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3C4), Color(0xFFFFB300)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFFD97706), offset: Offset(0, 2.5), blurRadius: 0),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 3), blurRadius: 3),
                    ]),
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 20.h),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(width: 8.w),
        // Combo Box (Always-Visible Gamified HUD Element - Original Height 32.h)
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
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFFD97706), offset: Offset(0, 3), blurRadius: 0),
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10),
                  ])
              : BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5.w),
                ),
          child: Text('🔥 x$_combo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w900,
              color: _combo >= 2 ? Colors.white : Colors.white.withValues(alpha: 0.5),
              shadows: _combo >= 2 ? [
                Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 1)),
              ] : null)),
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
            color: const Color(0xFFFDF5E6), 
            border: Border.all(color: const Color(0xFFD4A373), width: 7.w),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 12)),
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
                        Shadow(color: const Color(0xFF881337), offset: Offset(2.w, 2.h), blurRadius: 0),
                        Shadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, 4.h), blurRadius: 5),
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
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE6D2B5), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                    ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.network(
                      _getIllustrationUrl(_currentSyllable.meaning),
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A373)));
                      },
                      errorBuilder: (_, __, ___) => const Center(child: Text('🎨', style: TextStyle(fontSize: 40))),
                    ),
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
                        color: const Color(0xFF60A5FA),
                        border: Border.all(color: Colors.white, width: 1.5.w),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA), 
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  const BoxShadow(color: Color(0xFF6B21A8), offset: Offset(0, 4), blurRadius: 0),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 4), blurRadius: 6),
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
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        // Row 1: Consonants
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8.r)),
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
              final colorIdx = _consonantChoices.indexOf(con) % 5;
              final colors = [
                const Color(0xFFAA00FF), 
                const Color(0xFF2979FF), 
                const Color(0xFF00E676), 
                const Color(0xFFFFD600), 
                const Color(0xFFFF1744), 
              ];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                child: ThreeDTile(
                  text: con,
                  color: colors[colorIdx],
                  isSelected: isSel,
                  isCorrect: isCorrect,
                  isWrong: isWrong,
                  onTap: () => _selectConsonant(con),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 10.h),
        // Row 2: Vowels
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(color: const Color(0xFF7F1D1D).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8.r)),
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
              final colors = [
                const Color(0xFF2979FF), 
                const Color(0xFFAA00FF), 
                const Color(0xFF00E676), 
                const Color(0xFFFFD600), 
              ];
              final colorIdx = _vowelChoices.indexOf(vow) % 4;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                child: ThreeDTile(
                  text: vow,
                  color: colors[colorIdx],
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
      if (_selectedConsonant == 'ក' && _selectedVowel == 'ា') combinedText = 'កា';
      else if (_selectedConsonant == 'ម' && _selectedVowel == 'ា') combinedText = 'មា';
      else if (_selectedConsonant == 'ត' && _selectedVowel == 'ា') combinedText = 'តា';
      else if (_selectedConsonant == 'ប' && _selectedVowel == 'ា') combinedText = 'បា';
      else if (_selectedConsonant == 'ស' && _selectedVowel == 'ា') combinedText = 'សា';
      else combinedText = '$_selectedConsonant$_selectedVowel';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFF5D2E0A)]), 
        border: Border.all(color: const Color(0xFF3D1E07), width: 5.w),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: -5),
        ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWorkspaceSlot(_selectedConsonant, const Color(0xFF8C34FF), 'Phụ âm'),
          SizedBox(width: 8.w),
          Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(width: 8.w),
          _buildWorkspaceSlot(_selectedVowel, const Color(0xFF2979FF), 'Nguyên âm'),
          SizedBox(width: 8.w),
          Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(width: 8.w),
          _buildWorkspaceSlot(
            showCombined ? combinedText : null,
            const Color(0xFF00E676),
            'Kết quả',
            isResult: true,
            isGlowing: _showResult && _lastCorrect,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSlot(String? char, Color color, String placeholder, {bool isResult = false, bool isGlowing = false}) {
    return Container(
      width: 58.w,
      height: 58.w,
      decoration: BoxDecoration(
        color: char != null ? color : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14.r),
        border: isGlowing
            ? Border.all(color: const Color(0xFF69F0AE), width: 3.5.w)
            : Border.all(color: char != null ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF3D1E07), width: 2.w),
        boxShadow: [
          if (isGlowing)
            BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2),
          if (char != null)
            const BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 2),
        ]),
      child: Center(
        child: char != null
            ? Text(char,
                style: GoogleFonts.battambang(
                  fontSize: isResult ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 1.5)),
                  ]))
            : Text(placeholder.substring(0, 1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp, fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.18))),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = _selectedConsonant != null && _selectedVowel != null && !_showResult;
    return GestureDetector(
      onTap: canConfirm ? _checkAnswer : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.symmetric(horizontal: 52.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: canConfirm
                ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                : [Colors.grey.shade400, Colors.grey.shade600]),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: canConfirm ? const Color(0xFF15803D) : Colors.grey.shade800,
              offset: const Offset(0, 6), blurRadius: 0),
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 8), blurRadius: 10),
          ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('XÁC NHẬN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 1.5)),
              ])),
          SizedBox(width: 10.w),
          Container(
            width: 22.w, height: 22.w,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: Icon(Icons.check_rounded,
                color: canConfirm ? const Color(0xFF16A34A) : Colors.grey, size: 14.w, weight: 900),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPowerUpFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10.w,
        childAspectRatio: 0.95,
        children: [
          _buildPowerUpBtn(
            emoji: '🔍',
            title: 'Kính lúp',
            count: _hintsLeft,
            onTap: _useHint,
          ),
          _buildPowerUpBtn(
            emoji: '⏰',
            title: '+10 Giây',
            count: _timePowerupsLeft,
            onTap: _useTimePowerup,
          ),
          _buildPowerUpBtn(
            emoji: '❤️',
            title: '+1 Mạng',
            count: _livesPowerupsLeft,
            onTap: _useLivesPowerup,
          ),
          _buildPowerUpBtn(
            emoji: '⭐',
            title: 'X2 Điểm',
            count: _doubleScorePowerupsLeft,
            onTap: _useDoubleScorePowerup,
            isActiveGlow: _isDoubleScoreActive,
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpBtn({
    required String emoji,
    required String title,
    required int count,
    required VoidCallback onTap,
    bool isActiveGlow = false,
  }) {
    final hasItem = count > 0;
    return GestureDetector(
      onTap: hasItem && !_showResult ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: isActiveGlow
                    ? [const Color(0xFFFFD600), const Color(0xFFFF8F00)]
                    : hasItem
                        ? [const Color(0xFF60A5FA), const Color(0xFF2563EB)]
                        : [Colors.grey.shade400, Colors.grey.shade600]),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isActiveGlow ? Colors.white : Colors.white.withValues(alpha: 0.4),
                width: isActiveGlow ? 2.5 : 1.5),
              boxShadow: [
                BoxShadow(
                  color: isActiveGlow
                      ? const Color(0xFFFF8F00)
                      : hasItem ? const Color(0xFF1D4ED8) : Colors.grey.shade800,
                  offset: const Offset(0, 3.5), blurRadius: 0),
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 3), blurRadius: 4),
              ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: 22.sp)),
                SizedBox(height: 3.h),
                Text(title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          if (count > 0)
            Positioned(
              top: -3.h,
              right: -3.w,
              child: Container(
                width: 20.w, height: 20.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(0, 1))
                  ]),
                child: Center(
                  child: Text('$count',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white)),
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
                colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)]),
              border: Border.all(color: Colors.white, width: 4.w),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))
              ]),
            child: const Center(child: Text('🏆', style: TextStyle(fontSize: 60))),
          ),
          SizedBox(height: 16.h),
          Text('KẾT THÚC HÀNH TRÌNH!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26.sp, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [
                Shadow(color: const Color(0xFF1B5E20), offset: Offset(2.w, 2.h), blurRadius: 4),
              ])),
          SizedBox(height: 24.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))
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
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                child: Center(child: Text('THOÁT', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1A237E)))),
              ),
            )),
            SizedBox(width: 12.w),
            Expanded(child: GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    const BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 4), blurRadius: 0),
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
        fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A237E))),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 18.sp, fontWeight: FontWeight.w900, color: const Color(0xFFD97706))),
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
