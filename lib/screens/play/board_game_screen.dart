import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

/// Trò chơi: 🎲 CỜ TỶ PHÚ KHMER KỲ THÚ (Khmer Adventure Board Game)
/// Hỗ trợ 2 chế độ:
/// 1. Chơi 1 mình (Đua với Vua Bóng Tối AI 👿)
/// 2. Chơi 2 người (Voi Con 🐘 vs Khỉ Con 🐒 so tài trên cùng 1 màn hình)
class BoardGameScreen extends StatefulWidget {
  const BoardGameScreen({super.key});

  @override
  State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> with TickerProviderStateMixin {
  // Trạng thái chọn chế độ chơi ban đầu
  bool _hasSelectedMode = false;
  bool _isSinglePlayerMode = true; // true: 1 Người vs Máy, false: 2 Người chơi với nhau

  // Vị trí bàn cờ
  int _player1Pos = 0; // Vị trí Voi Con 🐘 (Player 1)
  int _player2Pos = 0; // Vị trí Khỉ Con 🐒 (Player 2) HOẶC Vua Bóng Tối 👿 (AI)
  
  // Lượt chơi hiện tại: 1 = Lượt Player 1 (Voi Con), 2 = Lượt Player 2 (Khỉ Con / AI)
  int _activePlayer = 1;
  String _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc!';
  
  final int _maxTiles = 20; // Tăng chiều dài bàn cờ lên 20 ô để trải nghiệm lâu và hay hơn
  bool _isRolling = false;
  int _diceValue = 1;
  
  // Bảng điểm riêng của hai người chơi
  int _player1Score = 0;
  int _player2Score = 0;
  ScoreService? _scoreService;

  // HP cho trận chiến Boss hoành tráng
  int _bossHP = 100;
  int _playerHP = 100; // Máu của người chơi hiện tại khi đấu Boss
  String _battleLog = 'Hãy dùng sức mạnh Nghe - Nói - Viết để tiêu diệt Vua Bóng Tối!';
  bool _isBossHit = false;   // Hiệu ứng chớp đỏ khi Boss trúng đòn
  bool _isPlayerHit = false; // Hiệu ứng chớp đỏ khi Bé trúng đòn

  // Trạng thái thử thách hiện tại
  String? _activeChallengeType; // 'consonant', 'vowel', 'speaking', 'writing', 'chance', 'boss'
  bool _isChallengeCompleted = false;

  // Bộ điều khiển hoạt ảnh xúc xắc
  late AnimationController _diceController;
  late Animation<double> _diceAnimation;

  // Danh sách các ô đất thám hiểm
  List<_BoardTile> _tiles = [];

  // POOL HỆ THỐNG CÂU HỎI NGẪU NHIÊN ĐỂ ĐÁP ỨNG SƯ PHẠM ĐA DẠNG
  int _selectedConsonantQIdx = 0;
  final List<Map<String, dynamic>> _consonantQuestions = [
    {
      'audio': 'Kọ',
      'choices': ['ក', 'ខ', 'គ'],
      'correct': 'ក',
      'label': '"Kọ" (Phụ âm đầu nhóm O)'
    },
    {
      'audio': 'Khọ',
      'choices': ['ខ', 'ក', 'ឃ'],
      'correct': 'ខ',
      'label': '"Khọ" (Phụ âm đầu nhóm O)'
    },
    {
      'audio': 'Chọ',
      'choices': ['ច', 'ឆ', 'ជ'],
      'correct': 'ច',
      'label': '"Chọ" (Phụ âm đầu nhóm O)'
    },
    {
      'audio': 'Nhọ',
      'choices': ['ញ', 'ណ', 'ញា'],
      'correct': 'ញ',
      'label': '"Nhọ" (Phụ âm đầu nhóm O)'
    }
  ];

  int _selectedSpeakingQIdx = 0;
  final List<Map<String, dynamic>> _speakingQuestions = [
    {
      'word': 'ចេក',
      'read': 'Cếk',
      'emoji': '🍌',
      'desc': 'Quả chuối thơm ngon'
    },
    {
      'word': 'ដំរី',
      'read': 'Dom-rey',
      'emoji': '🐘',
      'desc': 'Chú voi con Khmer'
    },
    {
      'word': 'ផ្កា',
      'read': 'Phka',
      'emoji': '🌸',
      'desc': 'Bông hoa rực rỡ'
    },
    {
      'word': 'សៀវភៅ',
      'read': 'Siev-phov',
      'emoji': '📚',
      'desc': 'Quyển sách học tập'
    }
  ];

  int _selectedWritingQIdx = 0;
  final List<Map<String, dynamic>> _writingQuestions = [
    {'char': 'ក', 'name': 'Phụ âm Ka (ក)'},
    {'char': 'ច', 'name': 'Phụ âm Cha (ច)'},
    {'char': 'ស', 'name': 'Phụ âm Sa (ស)'},
  ];

  // TRẠNG THÁI CHO TỪNG THỬ THÁCH CON
  // 1. Phụ âm
  String? _selectedConsonant;

  // 2. Nguyên âm - NÂNG CẤP THÀNH HỆ THỐNG GHÉP VẦN 3 CÂU HỎI THỰC TẾ (MULTI-STEP SPELLING)
  int _spellingStep = 1; // 1: Sa-la (សាលា), 2: Dom-rey (ដំរី), 3: Phka (ផ្កា)
  String? _spellingSelectedVowel1;
  String? _spellingSelectedVowel2;
  String? _spellingSelectedSubConsonant;

  // 3. Nói
  bool _isRecording = false;
  bool _speakSuccess = false;

  // 4. Viết
  final List<Offset> _points = [];
  bool _writeSuccess = false;

  // 5. Boss Battle (Combo 3 câu hỏi)
  int _bossStep = 1; // 1: Nghe, 2: Viết, 3: Nói
  String? _bossQ1Selected;
  final List<Offset> _bossQ2Points = [];
  bool _bossQ2Success = false;
  bool _bossQ3Recording = false;

  // 6. Thẻ Khí Vận & Cơ Hội (Chance System)
  int _selectedChanceIndex = 0;
  bool _isChanceCardFlipped = false;
  final List<Map<String, dynamic>> _chanceCards = [
    {
      'title': '🌟 BẠN BÈ GIÚP ĐỠ',
      'text1': 'Voi con giúp Khỉ Hanuman nhặt chuối! Khỉ con biết ơn dẫn đường giúp Voi con tiến thêm 2 ô.',
      'text2': 'Khỉ con chia sẻ hoa quả cho Voi con! Cả hai vui vẻ dắt tay nhau giúp Khỉ con tiến thêm 2 ô.',
      'type': 'forward',
      'offset': 2,
      'emoji': '🐒🍌',
      'color': Colors.green,
    },
    {
      'title': '🌪️ CƠN BÃO NGÔN NGỮ',
      'text1': 'Một cơn bão cát đen quét qua! Voi con phải lùi lại 1 ô để tìm nơi trú ẩn an toàn.',
      'text2': 'Một cơn bão lá cây thổi mạnh làm lạc đường! Khỉ con phải lùi lại 1 ô để tránh bão.',
      'type': 'backward',
      'offset': -1,
      'emoji': '🌪️🏜️',
      'color': Colors.red,
    },
    {
      'title': '💎 KHO BÁU CỔ ĐẠI',
      'text1': 'Voi con tìm thấy một hòm sách cổ Khmer cực quý giá! Nhận ngay +20 Điểm thưởng tích lũy.',
      'text2': 'Khỉ con đào được chiếc vòng cổ Angkor lấp lánh! Nhận ngay +20 Điểm thưởng tích lũy.',
      'type': 'score',
      'offset': 20,
      'emoji': '🎁📚',
      'color': Colors.amber,
    },
    {
      'title': '🐘 MASCOT CHĂM CHỈ',
      'text1': 'Voi con chăm chỉ ôn bài trước khi thám hiểm! Thần rừng ban phước giúp Voi con tiến thẳng thêm 1 ô.',
      'text2': 'Khỉ con tập viết chữ Khmer suốt cả đêm! Tinh thần hiếu học giúp Khỉ con tiến thẳng thêm 1 ô.',
      'type': 'forward',
      'offset': 1,
      'emoji': '🐘✨',
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadScoreService();
    _initBoardTiles();
    _initAnimations();
  }

  void _initAnimations() {
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _diceAnimation = CurvedAnimation(parent: _diceController, curve: Curves.elasticOut);
  }

  Future<void> _loadScoreService() async {
    _scoreService = await ScoreService.getInstance();
    // Đồng bộ vật phẩm hồi phục lên CSDL khi vào game
    await _scoreService?.syncRegeneratedInventory();
    if (mounted) setState(() {});
  }

  // Khởi tạo 20 ô cờ chi tiết cho bản đồ phiêu lưu sâu sắc hơn
  void _initBoardTiles() {
    _tiles = [
      _BoardTile(
        id: 0,
        name: 'Khởi Hành ⛵',
        type: 'start',
        color: Colors.grey,
        emoji: '⛵',
        desc: 'Điểm xuất phát phiêu lưu',
      ),
      _BoardTile(
        id: 1,
        name: 'Rừng Phụ Âm ក',
        type: 'consonant',
        color: const Color(0xFF2196F3),
        emoji: '🔵',
        desc: 'Thử thách nhận biết phụ âm đầu Khmer',
      ),
      _BoardTile(
        id: 2,
        name: 'Đầm Lầy Ghép Vần',
        type: 'vowel', // Thử thách Ghép vần liên tiếp
        color: const Color(0xFF9C27B0),
        emoji: '🟣',
        desc: 'Ghép vần nguyên âm',
      ),
      _BoardTile(
        id: 3,
        name: 'Thẻ Khí Vận 🔮',
        type: 'chance',
        color: const Color(0xFFFFD54F),
        emoji: '❓',
        desc: 'Rút thẻ bài vận may',
      ),
      _BoardTile(
        id: 4,
        name: 'Động Phát Âm 🗣️',
        type: 'speaking',
        color: const Color(0xFFFF9800),
        emoji: '🟠',
        desc: 'Phát âm chuẩn tiếng Khmer',
      ),
      _BoardTile(
        id: 5,
        name: 'Núi Bút Vàng ✍️',
        type: 'writing',
        color: const Color(0xFF4CAF50),
        emoji: '🟢',
        desc: 'Tập viết phụ âm',
      ),
      _BoardTile(
        id: 6,
        name: 'Ải Phụ Âm ខ',
        type: 'consonant',
        color: const Color(0xFF2196F3),
        emoji: '🔵',
        desc: 'Chọn bong bóng phụ âm',
      ),
      _BoardTile(
        id: 7,
        name: 'Sa Mạc Bẫy 🌵',
        type: 'trap_back', // Bẫy lùi lại
        color: const Color(0xFF78909C),
        emoji: '🌵',
        desc: 'Bão cát sa mạc thổi lùi bé lại 2 ô!',
      ),
      _BoardTile(
        id: 8,
        name: 'Ốc Đảo Ghép Vần',
        type: 'vowel', // Thử thách Ghép vần liên tiếp
        color: const Color(0xFF9C27B0),
        emoji: '🟣',
        desc: 'Ghép vần nguyên âm',
      ),
      _BoardTile(
        id: 9,
        name: 'Cầu Cầu Nguyện 🗣️',
        type: 'speaking',
        color: const Color(0xFFFF9800),
        emoji: '🟠',
        desc: 'Tập phát âm từ vựng',
      ),
      _BoardTile(
        id: 10,
        name: 'Thẻ Khí Vận 🔮',
        type: 'chance',
        color: const Color(0xFFFFD54F),
        emoji: '❓',
        desc: 'Rút thẻ bài vận may',
      ),
      _BoardTile(
        id: 11,
        name: 'Ải Phụ Âm គ',
        type: 'consonant',
        color: const Color(0xFF2196F3),
        emoji: '🔵',
        desc: 'Chọn phụ âm Khmer',
      ),
      _BoardTile(
        id: 12,
        name: 'Lò Viết Chữ ✍️',
        type: 'writing',
        color: const Color(0xFF4CAF50),
        emoji: '🟢',
        desc: 'Tập viết phụ âm trên cát',
      ),
      _BoardTile(
        id: 13,
        name: 'Thung Lũng Ghép Vần',
        type: 'vowel',
        color: const Color(0xFF9C27B0),
        emoji: '🟣',
        desc: 'Ghép nguyên âm phụ',
      ),
      _BoardTile(
        id: 14,
        name: 'Gia Tốc Voi 🚀',
        type: 'boost_forward', // Cổng gia tốc tiến thêm
        color: const Color(0xFFFF5722),
        emoji: '🚀',
        desc: 'Gia tốc phóng đại tiến thẳng thêm 2 ô!',
      ),
      _BoardTile(
        id: 15,
        name: 'Cổng Phát Âm 🗣️',
        type: 'speaking',
        color: const Color(0xFFFF9800),
        emoji: '🟠',
        desc: 'Nói chuẩn câu từ',
      ),
      _BoardTile(
        id: 16,
        name: 'Thẻ Khí Vận 🔮',
        type: 'chance',
        color: const Color(0xFFFFD54F),
        emoji: '❓',
        desc: 'Rút thẻ vận may',
      ),
      _BoardTile(
        id: 17,
        name: 'Đỉnh Bút Vàng ✍️',
        type: 'writing',
        color: const Color(0xFF4CAF50),
        emoji: '🟢',
        desc: 'Viết phụ âm nâng cao',
      ),
      _BoardTile(
        id: 18,
        name: 'Vách Đá Bẫy 🪨',
        type: 'trap_back', // Bẫy lùi lại
        color: const Color(0xFF78909C),
        emoji: '🪨',
        desc: 'Đá lở nguy hiểm bé phải lùi lại 2 ô!',
      ),
      _BoardTile(
        id: 19,
        name: 'Đại Chiến Boss 🏰',
        type: 'boss',
        color: const Color(0xFFD32F2F),
        emoji: '👿',
        desc: 'Trận đấu Boss Vua Bóng Tối hoành tráng!',
      ),
    ];
  }

  bool get _isPlayerTurn => !_isSinglePlayerMode || _activePlayer == 1;

  @override
  Widget build(BuildContext context) {
    if (!_hasSelectedMode) {
      return _buildModeSelectionScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Đại Dương & Đảo Cổ hoang dã
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F7FA), Color(0xFFFFF8E1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Column(
            children: [
              _buildHeader(),
              _buildRaceProgressBar(), // Thanh đua so tài trực quan
              Expanded(
                child: Stack(
                  children: [
                    // Bản đồ cờ tỷ phú uốn lượn uốn khúc tuyệt mỹ
                    _buildBoardMap(),

                    // Panel tung xúc xắc và lượt đi ở góc dưới
                    _buildDiceControlPanel(),
                  ],
                ),
              ),
            ],
          ),

          // Lớp phủ Thử thách khi dẫm trúng ô cờ
          if (_activeChallengeType != null) _buildChallengeModal(),
        ],
      ),
    );
  }

  // ==========================================
  // I. GIAO DIỆN CHỌN CHẾ ĐỘ CHƠI (PREMIUM MODE SELECTION)
  // ==========================================
  Widget _buildModeSelectionScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF004D40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                // Icon quay lại
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  ),
                ),
                Text(
                  '🎲 CỜ TỶ PHÚ KHMER 🎲',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Bé hãy chọn chế độ phiêu lưu nhé!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 32.h),

                // Thẻ chọn chế độ 1 Người chơi
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        _isSinglePlayerMode = true;
                        _hasSelectedMode = true;
                        _activePlayer = 1;
                        _player1Pos = 0;
                        _player2Pos = 0;
                        _player1Score = 0;
                        _player2Score = 0;
                        _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc!';
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2.w),
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🐘 🆚 👿', style: TextStyle(fontSize: 48.sp)),
                          SizedBox(height: 12.h),
                          Text(
                            'ĐƠN HÀNH GIẢI CỨU (1 NGƯỜI CHƠI)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Bé nhập vai Voi Con 🐘 đua tài 20 ô phiêu lưu với Vua Bóng Tối 👿 để giải cứu bờ cõi KhmerKid!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Thẻ chọn chế độ 2 Người chơi
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        _isSinglePlayerMode = false;
                        _hasSelectedMode = true;
                        _activePlayer = 1;
                        _player1Pos = 0;
                        _player2Pos = 0;
                        _player1Score = 0;
                        _player2Score = 0;
                        _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc!';
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: const Color(0xFF81C784), width: 2.w),
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🐘 🆚 🐒', style: TextStyle(fontSize: 48.sp)),
                          SizedBox(height: 12.h),
                          Text(
                            'SONG HÙNG TRANH CÚP (2 NGƯỜI CHƠI)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF81C784),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Hai bé (Voi Con 🐘 và Khỉ Con 🐒) cùng so tài 20 ô kịch tính trên cùng 1 màn hình xem ai chạm Cúp Vàng trước!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // II. CƠ CHẾ VẬN HÀNH BÀN CỜ MULTIPLAYER
  // ==========================================

  // CƠ CHẾ TUNG XÚC XẮC CHUNG
  void _rollDice() {
    if (_isRolling || _activeChallengeType != null) return;
    
    // Nếu đang ở chế độ 1 người và đang lượt của Máy AI
    if (_isSinglePlayerMode && _activePlayer == 2) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isRolling = true;
    });

    _diceController.forward(from: 0.0);

    Timer(const Duration(milliseconds: 1000), () {
      final rng = Random();
      final steps = rng.nextInt(3) + 1; // 1 -> 3 ô

      setState(() {
        _diceValue = steps;
        _isRolling = false;
      });

      _moveActivePlayer(steps);
    });
  }

  // DI CHUYỂN NGƯỜI CHƠI HIỆN TẠI TỪNG BƯỚC MỘT
  void _moveActivePlayer(int steps) {
    final int currentPos = (_activePlayer == 1) ? _player1Pos : _player2Pos;
    int targetPos = currentPos + steps;
    if (targetPos >= _maxTiles - 1) {
      targetPos = _maxTiles - 1; // Điểm dừng cao nhất là ô Boss cuối
    }

    int stepCount = 0;
    Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (stepCount < steps) {
        HapticFeedback.lightImpact();
        setState(() {
          if (_activePlayer == 1) {
            if (_player1Pos < targetPos) _player1Pos++;
          } else {
            if (_player2Pos < targetPos) _player2Pos++;
          }
        });
        stepCount++;
      } else {
        timer.cancel();
        // Kích hoạt thử thách tại ô dừng chân của người chơi đó
        final finalPos = (_activePlayer == 1) ? _player1Pos : _player2Pos;
        _triggerTileChallenge(finalPos);
      }
    });
  }

  // LƯỢT ĐUA TỰ ĐỘNG CỦA MÁY AI (CHỈ CHẠY TRONG CHẾ ĐỘ 1 NGƯỜI)
  void _executeRivalTurn() {
    if (_player2Pos >= _maxTiles - 1) return;

    setState(() {
      _activePlayer = 2;
      _turnStatusText = 'Vua Bóng Tối 👿 đang suy nghĩ...';
    });

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final rng = Random();
      final steps = rng.nextInt(3) + 1; // Di chuyển 1 -> 3 ô

      setState(() {
        _diceValue = steps;
        _isRolling = true;
      });

      _diceController.forward(from: 0.0).then((_) {
        setState(() {
          _isRolling = false;
        });

        int targetRivalPos = _player2Pos + steps;
        if (targetRivalPos >= _maxTiles - 1) {
          targetRivalPos = _maxTiles - 1;
        }

        int stepCount = 0;
        Timer.periodic(const Duration(milliseconds: 350), (timer) {
          if (stepCount < steps && _player2Pos < targetRivalPos) {
            setState(() {
              _player2Pos++;
            });
            stepCount++;
            HapticFeedback.lightImpact();
          } else {
            timer.cancel();

            // Nếu máy dẫm trúng ô trap hay boost, xử lý nhanh cho máy
            final tile = _tiles[_player2Pos];
            if (tile.type == 'trap_back') {
              setState(() {
                _player2Pos = max(0, _player2Pos - 2);
              });
            } else if (tile.type == 'boost_forward') {
              setState(() {
                _player2Pos = min(_maxTiles - 1, _player2Pos + 2);
              });
            }

            setState(() {
              _activePlayer = 1;
              _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc! 🎲';
            });

            // Nếu Vua Bóng Tối về đích trước người chơi
            if (_player2Pos == _maxTiles - 1) {
              _showDefeatDialog();
            }
          }
        });
      });
    });
  }

  // KÍCH HOẠT THỬ THÁCH VÀ BẪY/GIA TỐC
  void _triggerTileChallenge(int pos) {
    final tile = _tiles[pos];
    if (tile.type == 'start') {
      _passTurn();
      return;
    }

    final mascotName = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';

    // BẪY LÙI 2 Ô
    if (tile.type == 'trap_back') {
      HapticFeedback.vibrate();
      _showTrapDialog(mascotName, tile.name);
      return;
    }

    // GIA TỐC TIẾN 2 Ô
    if (tile.type == 'boost_forward') {
      HapticFeedback.heavyImpact();
      _showBoostDialog(mascotName, tile.name);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _activeChallengeType = tile.type;
      _isChallengeCompleted = false;

      // Chọn câu hỏi ngẫu nhiên từ cơ sở dữ liệu
      final rng = Random();
      _selectedConsonantQIdx = rng.nextInt(_consonantQuestions.length);
      _selectedSpeakingQIdx = rng.nextInt(_speakingQuestions.length);
      _selectedWritingQIdx = rng.nextInt(_writingQuestions.length);

      // Reset các biến thử thách con
      _selectedConsonant = null;

      // Reset Trạng thái Thử thách Ghép vần 3 câu
      _spellingStep = 1;
      _spellingSelectedVowel1 = null;
      _spellingSelectedVowel2 = null;
      _spellingSelectedSubConsonant = null;

      // Reset Nói / Viết
      _isRecording = false;
      _speakSuccess = false;
      _points.clear();
      _writeSuccess = false;

      // Reset trạng thái Boss
      _bossStep = 1;
      _bossQ1Selected = null;
      _bossQ2Points.clear();
      _bossQ2Success = false;
      _bossQ3Recording = false;
      _bossHP = 100;
      _playerHP = 100;
      _battleLog = 'Hãy trả lời chính xác 3 câu hỏi để đánh bại Boss Vua Bóng Tối!';

      // Reset trạng thái thẻ Khí Vận
      _isChanceCardFlipped = false;
      _selectedChanceIndex = rng.nextInt(_chanceCards.length);
    });

    if (tile.type == 'chance') {
      // Tự động kích hoạt hiệu ứng rút thẻ bài sau 0.8 giây
      Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isChanceCardFlipped = true;
            _isChallengeCompleted = true;
            
            // Áp dụng hiệu ứng của thẻ bài cho người chơi hiện tại
            final card = _chanceCards[_selectedChanceIndex];
            if (card['type'] == 'score') {
              final scoreOffset = card['offset'] as int;
              if (_activePlayer == 1) {
                _player1Score += scoreOffset;
              } else {
                _player2Score += scoreOffset;
              }
              _scoreService?.completeGame('board_chance_score', scoreOffset);
            }
          });
        }
      });
    }
  }

  // HIỂN THỊ HỘP THOẠI TRÚNG BẪY LÙI Ô
  void _showTrapDialog(String mascotName, String tileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚠️ GẶP CHƯỚNG NGẠI VẬT! ⚠️',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12.h),
              Text('🏜️🌵🪨💨', style: TextStyle(fontSize: 40.sp)),
              SizedBox(height: 12.h),
              Text(
                'Ối không! $mascotName dẫm trúng ô $tileName! Gặp chướng ngại vật ngẫu nhiên trên đường phiêu lưu, bé bị phạt lùi lại 2 ô!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyChanceMove(-2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text(
                    'Lùi lại củng cố trang bị 🛡️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
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

  // HIỂN THỊ HỘP THOẠI CỔNG GIA TỐC TIẾN Ô
  void _showBoostDialog(String mascotName, String tileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🚀 CỔNG GIA TỐC PHÓNG ĐẠI! 🚀',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 12.h),
              Text('⚡✨💫🔥', style: TextStyle(fontSize: 40.sp)),
              SizedBox(height: 12.h),
              Text(
                'Tuyệt vời! $mascotName dẫm trúng ô $tileName! Nguồn năng lượng cổ xưa ban tặng giúp bé phóng thẳng tiến lên thêm 2 ô!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyChanceMove(2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text(
                    'Phóng vút tiến lên thôi! 🚀',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
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

  // ĐÁNH GIÁ THỬ THÁCH PHỤ ÂM
  void _submitConsonantChallenge(String answer, String correct) {
    setState(() {
      _selectedConsonant = answer;
      _isChallengeCompleted = (answer == correct);
    });

    if (_isChallengeCompleted) {
      HapticFeedback.heavyImpact();
      setState(() {
        if (_activePlayer == 1) {
          _player1Score += 15;
        } else {
          _player2Score += 15;
        }
      });
      _scoreService?.completeGame('board_consonant', 15);
    } else {
      HapticFeedback.vibrate();
    }
  }

  // ĐÁNH GIÁ CÁC BƯỚC THỬ THÁCH GHÉP VẦN 3 CÂU LIÊN TIẾP (MULTI-STEP SPELLING)
  void _submitSpellingVowel1(String vowel) {
    if (vowel == 'ា') {
      HapticFeedback.heavyImpact();
      setState(() {
        _spellingSelectedVowel1 = vowel;
      });
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _spellingStep = 2; // Chuyển sang Câu 2: Ghép ដំរី (Con voi)
          });
        }
      });
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _submitSpellingVowel2(String vowel) {
    if (vowel == 'ី') {
      HapticFeedback.heavyImpact();
      setState(() {
        _spellingSelectedVowel2 = vowel;
      });
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _spellingStep = 3; // Chuyển sang Câu 3: Ghép ផ្កា (Bông hoa)
          });
        }
      });
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _submitSpellingSubConsonant(String sub) {
    if (sub == '្ក') {
      HapticFeedback.heavyImpact();
      setState(() {
        _spellingSelectedSubConsonant = sub;
        _isChallengeCompleted = true; // ĐÃ HOÀN THÀNH CẢ 3 CÂU GHÉP VẦN!
        if (_activePlayer == 1) {
          _player1Score += 25; // Ghép vần 3 câu khó nhận được +25 điểm!
        } else {
          _player2Score += 25;
        }
      });
      _scoreService?.completeGame('board_vowel', 25);
    } else {
      HapticFeedback.vibrate();
    }
  }

  // GIẢ LẬP PHÁT ÂM CHI TIẾT
  void _startSpeakingSimulate() {
    setState(() {
      _isRecording = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _speakSuccess = true;
          _isChallengeCompleted = true;
          if (_activePlayer == 1) {
            _player1Score += 15;
          } else {
            _player2Score += 15;
          }
        });
        _scoreService?.completeGame('board_speaking', 15);
        HapticFeedback.heavyImpact();
      }
    });
  }

  // ĐÁNH GIÁ THỬ THÁCH VIẾT NHANH
  void _submitWritingChallenge() {
    if (_points.length < 5) return;

    setState(() {
      _writeSuccess = true;
      _isChallengeCompleted = true;
      if (_activePlayer == 1) {
        _player1Score += 15;
      } else {
        _player2Score += 15;
      }
    });
    _scoreService?.completeGame('board_writing', 15);
    HapticFeedback.heavyImpact();
  }

  // ĐỐI ĐẦU BOSS: TRẬN CHIẾN HP KỊCH TÍNH
  void _submitBossQ1(String choice) {
    setState(() {
      _bossQ1Selected = choice;
    });

    final currentMascotName = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';

    if (choice == 'ខ្លា') {
      HapticFeedback.heavyImpact();
      setState(() {
        _isBossHit = true;
        _bossHP -= 33;
        _battleLog = '⚡ $currentMascotName đánh đúng! Phun nước làm ướt Boss! Boss mất 33 HP!';
      });
      Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isBossHit = false);
      });

      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _bossStep = 2; // Qua câu 2
          });
        }
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isPlayerHit = true;
        _playerHP -= 20;
        _battleLog = '❌ Bé chọn sai rồi! Boss phản công quất đuôi lửa! $currentMascotName mất 20 HP!';
        _bossQ1Selected = null;
      });
      Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isPlayerHit = false);
      });
      _checkBossBattleState();
    }
  }

  void _submitBossQ2() {
    if (_bossQ2Points.length < 5) return;
    HapticFeedback.heavyImpact();
    final currentMascotName = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';
    setState(() {
      _bossQ2Success = true;
      _isBossHit = true;
      _bossHP -= 33;
      _battleLog = '⚡ Viết chữ rất chuẩn! $currentMascotName dùng bút thần chém vương miện Boss! Boss mất 33 HP!';
    });
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isBossHit = false);
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _bossStep = 3; // Qua câu 3
        });
      }
    });
  }

  void _startBossQ3Simulate() {
    setState(() {
      _bossQ3Recording = true;
    });
    final currentMascotName = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _bossQ3Recording = false;
          _bossHP = 0; // Boss chết hoàn toàn
          _isChallengeCompleted = true;
          if (_activePlayer == 1) {
            _player1Score += 40;
          } else {
            _player2Score += 40;
          }
          _battleLog = '🏆 TUYỆT VỜI! $currentMascotName hét to câu chào vang dội đánh bay hoàn toàn Vua Bóng Tối!';
        });
        _scoreService?.completeGame('board_boss', 40);
      }
    });
  }

  void _checkBossBattleState() {
    if (_playerHP <= 0) {
      HapticFeedback.vibrate();
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _playerHP = 100;
            _bossHP = 100;
            _bossStep = 1;
            _bossQ1Selected = null;
            _bossQ2Points.clear();
            _bossQ2Success = false;
            _bossQ3Recording = false;
            _battleLog = '💔 Bé đã hết máu! Hãy tập trung cao độ để thử thách lại nhé!';
          });
        }
      });
    }
  }

  // ĐÓNG POPUP THỬ THÁCH VÀ TIẾP TỤC DI CHUYỂN
  void _closeChallengePopup() {
    final prevChallengeType = _activeChallengeType;
    setState(() {
      _activeChallengeType = null;
    });

    // Nếu vừa vượt qua thẻ Khí Vận
    if (prevChallengeType == 'chance') {
      final card = _chanceCards[_selectedChanceIndex];
      if (card['type'] == 'forward' || card['type'] == 'backward') {
        final offset = card['offset'] as int;
        _applyChanceMove(offset);
        return;
      }
    }

    // Nếu vượt qua thử thách thành công
    if (_isChallengeCompleted) {
      final currentPos = (_activePlayer == 1) ? _player1Pos : _player2Pos;
      if (currentPos == _maxTiles - 1) {
        // Bé đã chiến thắng Boss cuối
        _showVictoryDialog();
        return;
      }
      
      // Chuyển lượt sang người chơi tiếp theo
      _passTurn();
    } else {
      // Nếu rút lui phạt lùi lại 1 ô
      _applyChanceMove(-1);
    }
  }

  // CHUYỂN LƯỢT CHƠI XOAY VÒNG LUÂN PHIÊN
  void _passTurn() {
    if (_isSinglePlayerMode) {
      // Chế độ 1 Người: Luân chuyển Bé (1) -> Máy AI (2)
      if (_activePlayer == 1) {
        _executeRivalTurn();
      } else {
        setState(() {
          _activePlayer = 1;
          _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc! 🎲';
        });
      }
    } else {
      // Chế độ 2 Người: Voi Con (1) <-> Khỉ Con (2)
      setState(() {
        if (_activePlayer == 1) {
          _activePlayer = 2;
          _turnStatusText = 'Đến lượt Khỉ Con 🐒 tung xúc xắc! 🎲';
        } else {
          _activePlayer = 1;
          _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc! 🎲';
        }
      });
    }
  }

  // ÁP DỤNG DI CHUYỂN PHẠT HOẶC THƯỞNG DI CHUYỂN SAU THỬ THÁCH
  void _applyChanceMove(int offset) {
    final int currentPos = (_activePlayer == 1) ? _player1Pos : _player2Pos;
    int target = currentPos + offset;
    if (target < 0) target = 0;
    if (target >= _maxTiles - 1) target = _maxTiles - 1;

    int steps = offset.abs();
    int stepCount = 0;
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (stepCount < steps) {
        setState(() {
          if (_activePlayer == 1) {
            if (offset > 0) {
              if (_player1Pos < target) _player1Pos++;
            } else {
              if (_player1Pos > target) _player1Pos--;
            }
          } else {
            if (offset > 0) {
              if (_player2Pos < target) _player2Pos++;
            } else {
              if (_player2Pos > target) _player2Pos--;
            }
          }
        });
        stepCount++;
      } else {
        timer.cancel();
        // Chuyển lượt sang người tiếp theo
        _passTurn();
      }
    });
  }

  // POPUP CHIẾN THẮNG CHUNG CUỘC
  void _showVictoryDialog() {
    final winnerMascot = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';
    final winnerScore = (_activePlayer == 1) ? _player1Score : _player2Score;
    
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
                _isSinglePlayerMode ? '🏆 KHẢO CỔ VÔ ĐỊCH CÚP VÀNG! 🏆' : '🏆 CHIẾN THẮNG CHUNG CUỘC! 🏆',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFB300),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                _activePlayer == 1 ? '🐘👑✨🏆🎖️' : '🐒👑✨🏆🎖️',
                style: TextStyle(fontSize: 48.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                _isSinglePlayerMode 
                    ? 'Chúc mừng bé! Bé đã xuất sắc đánh bại Vua Bóng Tối, giải cứu bờ cõi KhmerKid và làm chủ hoàn toàn các kỹ năng!'
                    : 'Chúc mừng $winnerMascot! Bạn đã xuất sắc về đích đầu tiên, vượt qua mọi thử thách tiếng Khmer và giành được Cúp Vàng danh giá!',
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
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Tổng sao thám hiểm tích lũy: +$winnerScore Điểm 🌟',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0A030),
                  ),
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
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Nhận Cúp & Trở về thế giới',
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

  // POPUP THẤT BẠI KHI ĐỐI THỦ VỀ ĐÍCH TRƯỚC (CHỈ DÙNG CHO 1 NGƯỜI CHƠI)
  void _showDefeatDialog() {
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
                '😈 VUA BÓNG TỐI ĐÃ VỀ ĐÍCH TRƯỚC! 😈',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD32F2F),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '👿😢🥀🌪️',
                style: TextStyle(fontSize: 48.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Ối! Vua Bóng Tối đã nhanh chân xâm chiếm Lâu đài cuối cùng trước mất rồi! Bé đừng nản lòng nhé, hãy thử lại để đánh bại hắn ta!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _player1Pos = 0;
                      _player2Pos = 0;
                      _activePlayer = 1;
                      _player1Score = 0;
                      _player2Score = 0;
                      _turnStatusText = 'Đến lượt Voi Con 🐘 tung xúc xắc! 🎲';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Làm lại ván mới 🔄',
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

  // ==========================================
  // III. GIAO DIỆN CHÍNH CỦA BÀN CỜ
  // ==========================================

  // HEADER PHÍA TRÊN
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 16.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _hasSelectedMode = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cờ Tỷ Phú Khmer Kỳ Thú',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isSinglePlayerMode 
                          ? 'Chế độ: Đua tài với Vua Bóng Tối 👿' 
                          : 'Chế độ: Voi Con 🐘 và Khỉ Con 🐒 tranh tài',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bảng hiển thị điểm số
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🐘: $_player1Score 🌟',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (!_isSinglePlayerMode) ...[
                      SizedBox(width: 8.w),
                      Text(
                        '🐒: $_player2Score 🌟',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // THANH TIẾN TRÌNH CUỘC ĐUA TỐC ĐỘ 20 Ô CỜ
  Widget _buildRaceProgressBar() {
    final double player1Prog = _player1Pos / (_maxTiles - 1);
    final double player2Prog = _player2Pos / (_maxTiles - 1);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🐘 Voi Con: Ô ${_player1Pos + 1}/20',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal,
                ),
              ),
              Text(
                _isSinglePlayerMode
                    ? '👿 Vua Bóng Tối: Ô ${_player2Pos + 1}/20'
                    : '🐒 Khỉ Con: Ô ${_player2Pos + 1}/20',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: _isSinglePlayerMode ? Colors.redAccent : Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              // Thanh nền
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              // Tiến trình người chơi 2 (Khỉ Con hoặc Vua Bóng Tối)
              FractionallySizedBox(
                widthFactor: player2Prog,
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _isSinglePlayerMode ? Colors.redAccent.withValues(alpha: 0.6) : Colors.orange,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              // Tiến trình người chơi 1 (Voi Con)
              FractionallySizedBox(
                widthFactor: player1Prog,
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BẢN ĐỒ CỜ TỶ PHÚ 4 CỘT
  Widget _buildBoardMap() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 140.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2), width: 1.5.w),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.orange),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isSinglePlayerMode
                          ? 'Bản đồ 20 ô thám hiểm dài và cực hấp dẫn! Bé hãy né tránh các ô Bẫy cát 🌵/Đá lở 🪨 và dẫm vào ô Gia tốc 🚀 nhé! 🎲'
                          : 'Đại lộ 20 ô kỳ bí! Cùng so tài nảy lửa né bẫy 🌵 và dẫm vào cổng phóng đại 🚀 để bứt phá về đích trước bạn mình! 🌟',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Sơ đồ lưới 4 Cột uốn lượn uốn khúc tuyệt đẹp cho 20 ô cờ
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 cột giúp hiển thị 20 ô cờ cân đối, tinh tế
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 20.h,
                childAspectRatio: 0.8,
              ),
              itemCount: _tiles.length,
              itemBuilder: (context, index) {
                // S-curve snaking path mapping: 4 columns
                final int row = index ~/ 4;
                final int col = index % 4;
                final int tileIndex = (row % 2 == 1) ? (row * 4 + (3 - col)) : (row * 4 + col);

                final tile = _tiles[tileIndex];
                final isPlayer1Here = (_player1Pos == tileIndex);
                final isPlayer2Here = (_player2Pos == tileIndex);

                // Màu viền và màu nền của ô cờ tùy vị trí đứng
                Color tileBorderColor = tile.color.withValues(alpha: 0.4);
                Color tileBgColor = Colors.white;
                double borderW = 2.w;

                if (isPlayer1Here && isPlayer2Here) {
                  tileBgColor = Colors.teal[50]!;
                  tileBorderColor = Colors.teal;
                  borderW = 4.w;
                } else if (isPlayer1Here) {
                  tileBgColor = Colors.teal[50]!;
                  tileBorderColor = Colors.teal;
                  borderW = 3.w;
                } else if (isPlayer2Here) {
                  tileBgColor = _isSinglePlayerMode ? Colors.red[50]! : Colors.orange[50]!;
                  tileBorderColor = _isSinglePlayerMode ? Colors.redAccent : Colors.orange;
                  borderW = 3.w;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hòn đảo cờ nhỏ (Tile block)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: tileBgColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: tileBorderColor,
                          width: borderW,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tile.color.withValues(alpha: 0.1),
                            blurRadius: 6.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () {
                            if (_isPlayerTurn) {
                              if (_activePlayer == 1 && _player1Pos == tileIndex) {
                                _triggerTileChallenge(tileIndex);
                              } else if (_activePlayer == 2 && _player2Pos == tileIndex) {
                                _triggerTileChallenge(tileIndex);
                              }
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tile.emoji,
                                  style: TextStyle(fontSize: 24.sp),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  tile.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Nhãn chỉ thứ tự ô đất
                    Positioned(
                      top: -10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: tile.color,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${tileIndex + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Chú Voi Mascot 🐘 đại diện cho người chơi 1 đứng ở đây
                    if (isPlayer1Here)
                      Positioned(
                        top: -20.h,
                        left: -4.w,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Text('🐘', style: TextStyle(fontSize: 16.sp)),
                        ),
                      ),

                    // Khỉ Con 🐒 (2 người) hoặc Vua Bóng Tối 👿 (1 người) đứng ở đây
                    if (isPlayer2Here)
                      Positioned(
                        top: -20.h,
                        right: -4.w,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            _isSinglePlayerMode ? '👿' : '🐒',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // PANEL TUNG XÚC XẮC PHÙ HỢP THEO LƯỢT CHƠI
  Widget _buildDiceControlPanel() {
    // Tùy theo người chơi kích hoạt để chọn màu chủ đạo cho bảng điều khiển xúc xắc
    final Color turnThemeColor = (_activePlayer == 1) 
        ? Colors.teal 
        : (_isSinglePlayerMode ? Colors.redAccent : Colors.orange);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Xúc xắc 3D xoay
            GestureDetector(
              onTap: _rollDice,
              child: AnimatedBuilder(
                animation: _diceAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _isRolling ? _diceAnimation.value * pi * 4 : 0,
                    child: child,
                  );
                },
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: turnThemeColor, width: 2.w),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isRolling
                        ? Text('🎲', style: TextStyle(fontSize: 32.sp))
                        : Text(
                            '$_diceValue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: turnThemeColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Thanh trạng thái lượt đi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _turnStatusText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: turnThemeColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ElevatedButton(
                    onPressed: (!_isRolling && (_isSinglePlayerMode ? _activePlayer == 1 : true)) 
                        ? _rollDice 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: turnThemeColor,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'TUNG XÚC XẮC 🎲',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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

  // ==========================================
  // IV. CÁC PANEL THỬ THÁCH TƯƠNG TÁC (4-IN-1 MODALS)
  // ==========================================
  Widget _buildChallengeModal() {
    Widget challengeBody = const SizedBox();
    String title = '';
    Color themeColor = Colors.teal;

    // Lựa chọn đại diện cho người chơi hiện tại làm nhiệm vụ
    final currentMascotName = (_activePlayer == 1) ? 'Bé Voi 🐘' : 'Bé Khỉ 🐒';

    switch (_activeChallengeType) {
      case 'consonant':
        title = '🔵 THỬ THÁCH PHỤ ÂM ($currentMascotName)';
        themeColor = const Color(0xFF2196F3);
        challengeBody = _buildConsonantChallengeBody();
        break;
      case 'vowel':
        title = '🟣 ĐẠI LỘ GHÉP VẦN KHMER ($currentMascotName)';
        themeColor = const Color(0xFF9C27B0);
        challengeBody = _buildVowelSpellingChallengeBody(); // THỬ THÁCH GHÉP VẦN 3 BƯỚC MỚI
        break;
      case 'speaking':
        title = '🟠 THỬ THÁCH PHÁT ÂM ($currentMascotName)';
        themeColor = const Color(0xFFFF9800);
        challengeBody = _buildSpeakingChallengeBody();
        break;
      case 'writing':
        title = '🟢 THỬ THÁCH VIẾT NHANH ($currentMascotName)';
        themeColor = const Color(0xFF4CAF50);
        challengeBody = _buildWritingChallengeBody();
        break;
      case 'chance':
        title = '🔮 THẺ KHÍ VẬN ($currentMascotName)';
        themeColor = const Color(0xFFFFD54F);
        challengeBody = _buildTreasureBody();
        break;
      case 'boss':
        title = '👿 ĐẠI CHIẾN BOSS CUỐI ($currentMascotName)';
        themeColor = const Color(0xFFD32F2F);
        challengeBody = _buildBossChallengeBody();
        break;
    }

    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: themeColor, width: 3.w),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                  ),
                  if (_isChallengeCompleted && _activeChallengeType != 'chance')
                    const Icon(Icons.check_circle_rounded, color: Colors.green)
                ],
              ),
              const Divider(thickness: 1.5),
              SizedBox(height: 8.h),

              // Nội dung thử thách tương ứng
              challengeBody,

              SizedBox(height: 16.h),
              // Nút điều khiển hành trình
              Row(
                children: [
                  if (!_isChallengeCompleted)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _activeChallengeType = null;
                          });
                          _applyChanceMove(-1);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(color: themeColor),
                        ),
                        child: Text(
                          'Rút lui (-1 ô) 🚩',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  if (!_isChallengeCompleted) SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isChallengeCompleted ? _closeChallengePopup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _isChallengeCompleted ? 'TIẾP TỤC HÀNH TRÌNH 🎲' : 'ĐANG LÀM THỬ THÁCH',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
  }

  // 🔵 1. THỬ THÁCH PHỤ ÂM BODY (ÂM HỌC NGẪU NHIÊN TỪ POOL)
  Widget _buildConsonantChallengeBody() {
    final q = _consonantQuestions[_selectedConsonantQIdx];
    final String correctLetter = q['correct'] as String;

    return Column(
      children: [
        Text(
          'Bé hãy nhấn vào Loa dưới đây, lắng nghe âm đọc thật kỹ và chọn đúng bong bóng phụ âm Khmer tương ứng nhé! 🔊',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        // Nút loa phát âm
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: const BoxDecoration(
            color: Color(0xFFE1F5FE),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
            },
            icon: const Icon(Icons.volume_up_rounded, color: Colors.blue, size: 36),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '"${q['audio']}" - ${q['label']}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 20.h),
        // Bong bóng chứa chữ
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: (q['choices'] as List<String>).map((letter) {
            final isSelected = (_selectedConsonant == letter);
            final isCorrect = (letter == correctLetter);

            Color bubbleColor = Colors.white;
            if (isSelected) {
              bubbleColor = isCorrect ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);
            }

            return GestureDetector(
              onTap: () => _submitConsonantChallenge(letter, correctLetter),
              child: Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2.w),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.battambang(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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

  // 🟣 2. THỬ THÁCH NGUYÊN ÂM - GHÉP VẦN CHUYÊN SÂU 3 CÂU HỎI LIÊN TIẾP (MULTI-STEP SPELLING)
  Widget _buildVowelSpellingChallengeBody() {
    Widget spellingStepWidget = const SizedBox();

    if (_spellingStep == 1) {
      // Câu 1: Ghép từ សាលា (Sa-la: Trường học)
      spellingStepWidget = Column(
        children: [
          Text(
            '🌟 Ghép Vần Câu 1/3: Bé hãy ghép nguyên âm ា (A) vào bên phải phụ âm ស (So) để hoàn thiện từ trường học សាលា (Sa-la)! 🏫',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF9C27B0), width: 1.5.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ស',
                  style: GoogleFonts.battambang(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
                SizedBox(width: 4.w),
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: _spellingSelectedVowel1 != null ? const Color(0xFFC8E6C9) : Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: _spellingSelectedVowel1 != null ? Colors.green : Colors.grey, width: 2.w),
                  ),
                  child: Center(
                    child: Text(
                      _spellingSelectedVowel1 ?? '?',
                      style: GoogleFonts.battambang(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: _spellingSelectedVowel1 != null ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'លា',
                  style: GoogleFonts.battambang(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Các lựa chọn nguyên âm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['ា', 'ិ', 'ី'].map((vowel) {
              final isCorrect = (vowel == 'ា');
              return ElevatedButton(
                onPressed: () => _submitSpellingVowel1(vowel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _spellingSelectedVowel1 == vowel
                      ? (isCorrect ? Colors.green : Colors.red)
                      : const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
                child: Text(
                  vowel,
                  style: GoogleFonts.battambang(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_spellingSelectedVowel1 != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                'Chúc mừng bé ghép đúng từ: សាលា (Trường học) 🏫',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.green),
              ),
            ),
        ],
      );
    } else if (_spellingStep == 2) {
      // Câu 2: Ghép ដំរី (Dom-rey: Con voi)
      spellingStepWidget = Column(
        children: [
          Text(
            '🌟 Ghép Vần Câu 2/3: Bé hãy ghép nguyên âm ី (Ee) vào trên phụ âm រ (Ro) để hoàn thiện từ con voi ដំរី (Dom-rey)! 🐘',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF9C27B0), width: 1.5.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ដំ',
                  style: GoogleFonts.battambang(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _spellingSelectedVowel2 != null ? const Color(0xFFC8E6C9) : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _spellingSelectedVowel2 != null ? Colors.green : Colors.grey, width: 2.w),
                      ),
                      child: Center(
                        child: Text(
                          _spellingSelectedVowel2 ?? '?',
                          style: GoogleFonts.battambang(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: _spellingSelectedVowel2 != null ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'រ',
                      style: GoogleFonts.battambang(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Các lựa chọn nguyên âm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['ំ', 'ី', 'ុ'].map((vowel) {
              final isCorrect = (vowel == 'ី');
              return ElevatedButton(
                onPressed: () => _submitSpellingVowel2(vowel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _spellingSelectedVowel2 == vowel
                      ? (isCorrect ? Colors.green : Colors.red)
                      : const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
                child: Text(
                  vowel,
                  style: GoogleFonts.battambang(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_spellingSelectedVowel2 != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                'Chúc mừng bé ghép đúng từ: ដំរី (Con voi) 🐘',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.green),
              ),
            ),
        ],
      );
    } else if (_spellingStep == 3) {
      // Câu 3: Ghép ផ្កា (Phka: Bông hoa)
      spellingStepWidget = Column(
        children: [
          Text(
            '🌟 Ghép Vần Câu 3/3: Bé hãy ghép chân chữ ្ក (chân Ka) vào dưới phụ âm ផ (Pho) để hoàn thành từ bông hoa ផ្កា (Phka)! 🌸',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF9C27B0), width: 1.5.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ផ',
                      style: GoogleFonts.battambang(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _spellingSelectedSubConsonant != null ? const Color(0xFFC8E6C9) : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _spellingSelectedSubConsonant != null ? Colors.green : Colors.grey, width: 2.w),
                      ),
                      child: Center(
                        child: Text(
                          _spellingSelectedSubConsonant ?? '?',
                          style: GoogleFonts.battambang(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: _spellingSelectedSubConsonant != null ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8.w),
                Text(
                  'ា',
                  style: GoogleFonts.battambang(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Các lựa chọn chân chữ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['្ខ', '្ក', '្ច'].map((sub) {
              final isCorrect = (sub == '្ក');
              return ElevatedButton(
                onPressed: () => _submitSpellingSubConsonant(sub),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _spellingSelectedSubConsonant == sub
                      ? (isCorrect ? Colors.green : Colors.red)
                      : const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
                child: Text(
                  sub,
                  style: GoogleFonts.battambang(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_spellingSelectedSubConsonant != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                'Chúc mừng bé ghép đúng từ khó: ផ្កា (Bông hoa) 🌸',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.green),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        // Bảng thanh tiến độ ghép vần 3 câu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final active = (_spellingStep > index);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF9C27B0) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 16.h),
        spellingStepWidget,
      ],
    );
  }

  // 🟠 3. THỬ THÁCH PHÁT ÂM BODY (TỪ VỰNG PHONG PHÚ TỪ POOL)
  Widget _buildSpeakingChallengeBody() {
    final q = _speakingQuestions[_selectedSpeakingQIdx];

    return Column(
      children: [
        Text(
          'Bé hãy nghe âm mẫu thật kỹ, sau đó nhấn giữ Micro dưới đây để phát âm chuẩn từ vựng Khmer nhé! 🗣️',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.orangeAccent, width: 2.w),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Text(q['emoji'] as String, style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 4.h),
              Text(
                q['word'] as String,
                style: GoogleFonts.battambang(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Phiên âm: ${q['read']} - ${q['desc']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        GestureDetector(
          onTap: _startSpeakingSimulate,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
              border: Border.all(color: _isRecording ? Colors.red : Colors.orange, width: 2.w),
            ),
            child: Icon(
              _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isRecording ? Colors.red : Colors.orange,
              size: 40.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _isRecording ? 'Mascot đang lắng nghe âm thanh...' : 'Nhấn Micro phát âm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: _isRecording ? Colors.red : AppColors.textHint,
          ),
        ),
        if (_speakSuccess)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Text(
              'Tuyệt vời! Phát âm của bé đạt chuẩn 5/5 sao! ⭐⭐⭐⭐⭐',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  // 🟢 4. THỬ THÁCH VIẾT NHANH BODY (PHỤ ÂM PHONG PHÚ TỪ POOL)
  Widget _buildWritingChallengeBody() {
    final q = _writingQuestions[_selectedWritingQIdx];

    return Column(
      children: [
        Text(
          'Bé hãy di ngón tay vẽ theo nét chữ cát mờ ${q['name']} thật nắn nót nhé! ✍️',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          height: 160.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFFBC02D), width: 2.w),
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.25,
                  child: Text(
                    q['char'] as String,
                    style: GoogleFonts.battambang(
                      fontSize: 100.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onPanUpdate: (details) {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    _points.add(localPosition);
                  });
                },
                onPanEnd: (details) {
                  _submitWritingChallenge();
                },
                child: CustomPaint(
                  painter: _DrawingPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _points.clear();
                  _writeSuccess = false;
                });
              },
              child: Text(
                'Làm sạch 🔄',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              _writeSuccess ? 'Viết chuẩn nét! Hoàn hảo 🎉' : 'Bé hãy di ngón tay vẽ chữ nhé!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: _writeSuccess ? Colors.green : AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔮 5. HỆ THỐNG THẺ KHÍ VẬN ĐỊNH MỆNH
  Widget _buildTreasureBody() {
    final card = _chanceCards[_selectedChanceIndex];
    // Hiển thị text tương thích với người chơi hiện tại
    final cardText = (_activePlayer == 1) ? card['text1'] as String : card['text2'] as String;

    return AnimatedScale(
      scale: _isChanceCardFlipped ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: card['color'] as Color,
            width: 3.w,
          ),
          boxShadow: [
            BoxShadow(
              color: (card['color'] as Color).withValues(alpha: 0.2),
              blurRadius: 12.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              card['emoji'] as String,
              style: TextStyle(fontSize: 56.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              card['title'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: card['color'] as Color,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              cardText,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: (card['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                card['type'] == 'forward'
                    ? 'Hiệu ứng: Được tiến thêm ${card['offset']} ô! 🚀'
                    : (card['type'] == 'backward'
                        ? 'Hiệu ứng: Bị lùi lại ${card['offset']?.abs()} ô! 🌪️'
                        : 'Hiệu ứng: Nhận ngay +${card['offset']} Sao Vàng! 💎'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: card['color'] as Color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👿 6. TRẬN CHIẾN BOSS CUỐI THỰC THỤ
  Widget _buildBossChallengeBody() {
    Widget stepWidget = const SizedBox();
    final currentMascotName = (_activePlayer == 1) ? 'Voi Con 🐘' : 'Khỉ Con 🐒';

    if (_bossStep == 1) {
      stepWidget = Column(
        children: [
          Text(
            '🌟 Combo Câu 1/3 (Nghe âm): Nhấn loa phát âm và chọn đúng từ "Con hổ" trong tiếng Khmer!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
            },
            icon: const Icon(Icons.volume_up, color: Colors.red, size: 36),
          ),
          Text(
            '"Khla" (Âm mẫu)',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['ឆ្កែ', 'ខ្លា', 'ផ្កា'].map((choice) {
              final isSelected = (_bossQ1Selected == choice);
              return ElevatedButton(
                onPressed: () => _submitBossQ1(choice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.green : const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  choice,
                  style: GoogleFonts.battambang(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else if (_bossStep == 2) {
      stepWidget = Column(
        children: [
          Text(
            '🌟 Combo Câu 2/3 (Viết chữ): Bé hãy di ngón tay vẽ nhanh phụ âm đầu ក (Ka) trên bảng cát!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.redAccent, width: 2.w),
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: 0.25,
                    child: Text(
                      'ក',
                      style: GoogleFonts.battambang(
                        fontSize: 80.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onPanUpdate: (details) {
                    RenderBox renderBox = context.findRenderObject() as RenderBox;
                    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                    setState(() {
                      _bossQ2Points.add(localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    _submitBossQ2();
                  },
                  child: CustomPaint(
                    painter: _DrawingPainter(_bossQ2Points),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _bossQ2Success ? 'Thành công! Đang tung đòn phép thuật...' : 'Di tay viết phụ âm Ka',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: _bossQ2Success ? Colors.green : AppColors.textHint,
            ),
          ),
        ],
      );
    } else if (_bossStep == 3) {
      stepWidget = Column(
        children: [
          Text(
            '🌟 Combo Câu 3/3 (Nói câu chào): Nhấn micro đọc to câu chào "សួស្តី" (Sua-sdey) để chiến thắng!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'សួស្តី (Sua-sdey)',
              style: GoogleFonts.battambang(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _startBossQ3Simulate,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _bossQ3Recording ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2.w),
              ),
              child: Icon(
                _bossQ3Recording ? Icons.mic : Icons.mic_none,
                color: Colors.red,
                size: 32.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _bossQ3Recording ? 'Boss đang run rẩy lắng nghe...' : 'Nhấn Micro nói dứt điểm Boss!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: _bossQ3Recording ? Colors.red : AppColors.textHint,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // THANH HP MÁU CỦA NGƯỜI CHƠI VS BOSS
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _isBossHit ? Colors.red[100] : (_isPlayerHit ? Colors.orange[100] : const Color(0xFFECEFF1)),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _isBossHit ? Colors.red : (_isPlayerHit ? Colors.orange : Colors.grey),
              width: 2.w,
            ),
          ),
          child: Column(
            children: [
              // Thanh máu của Mascot hiện tại
              Row(
                children: [
                  Text('$currentMascotName:', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 10.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5.r))),
                        FractionallySizedBox(
                          widthFactor: _playerHP / 100,
                          child: Container(height: 10.h, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5.r))),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text('$_playerHP/100 HP', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8.h),
              // Thanh máu của Boss Vua Bóng Tối
              Row(
                children: [
                  Text('👿 Boss Vua:', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 10.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5.r))),
                        FractionallySizedBox(
                          widthFactor: _bossHP / 100,
                          child: Container(height: 10.h, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5.r))),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text('$_bossHP/100 HP', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 16),
              // Nhật ký chiến đấu (Battle Log)
              Text(
                _battleLog,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal[900],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Thử thách con tương ứng với từng bước đấu Boss
        stepWidget,
      ],
    );
  }
}

class _BoardTile {
  final int id;
  final String name;
  final String type;
  final Color color;
  final String emoji;
  final String desc;

  _BoardTile({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.emoji,
    required this.desc,
  });
}

// LỚP VẼ NÉT CHỮ TRÊN BẢNG CÁT
class _DrawingPainter extends CustomPainter {
  final List<Offset> points;

  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.brown
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
