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
    _bubbleController.dispose();
    super.dispose();
  }

  void _onCellTap(int row, int col) {
    if (_isRoundCompleted) return;

    final currentLevel = _levels[_currentLevelIdx];
    final tappedPoint = Point(row, col);

    // Kiểm tra xem bé có ấn đúng chữ cái tiếp theo trong đường dẫn không
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
          _onRoundSuccess();
        }
      } else {
        // Bé ấn sai nét hoặc sai ký tự tiếp theo -> Rung phản hồi báo sai và reset lựa chọn hiện tại
        HapticFeedback.vibrate();
        setState(() {
          _selectedPoints.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chưa đúng rồi! Bé hãy tìm chữ cái theo thứ tự nhé! 💫',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
          ),
        );
      }
    }
  }

  void _onRoundSuccess() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRoundCompleted = true;
      _score += 15;
    });

    // Cộng điểm vào ScoreService
    _scoreService?.completeGame('word_search', 15);

    // Hiển thị dialog chúc mừng cực sinh động
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎉 TUYỆT VỜI! 🎉',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                _levels[_currentLevelIdx].emoji,
                style: TextStyle(fontSize: 72.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Bé đã giải cứu thành công ${_levels[_currentLevelIdx].animalVietnamese}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _levels[_currentLevelIdx].khmerWord,
                    style: GoogleFonts.battambang(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '(${_levels[_currentLevelIdx].romanized})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Thưởng: +15 Điểm 🌟',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0A030),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      child: Text(
                        'Thoát',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _nextLevel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _currentLevelIdx < _levels.length - 1
                            ? 'Vòng tiếp theo'
                            : 'Hoàn thành!',
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
            ],
          ),
        ),
      ),
    );
  }

  void _nextLevel() {
    if (_currentLevelIdx < _levels.length - 1) {
      setState(() {
        _currentLevelIdx++;
        _selectedPoints.clear();
        _isRoundCompleted = false;
      });
    } else {
      // Bé đã vượt qua toàn bộ 5 màn!
      _showGameFinishedDialog();
    }
  }

  void _showGameFinishedDialog() {
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
      backgroundColor: const Color(0xFFF1F8E9), // Xanh lá cây cực dịu nhẹ
      body: Column(
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

                    // 🐘 KHU VỰC THÚ CẦN GIẢI CỨU (Bubble Animation)
                    AnimatedBuilder(
                      animation: _bubbleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bubbleAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildRescueCard(currentLevel),
                    ),

                    SizedBox(height: 20.h),

                    // 🧩 LƯỚI Ô CHỮ KHMER 5X5
                    _buildWordGrid(currentLevel),

                    SizedBox(height: 24.h),

                    // 📝 HƯỚNG DẪN TỪNG CHỮ CÁI
                    _buildProgressRow(currentLevel),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_Level level) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giải cứu thú rừng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Vòng ${_currentLevelIdx + 1}/${_levels.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('image/sao.png', width: 16.w, height: 16.h),
                    SizedBox(width: 4.w),
                    Text(
                      '$_score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        border: Border.all(color: const Color(0xFFC8E6C9), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
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
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.cyan.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.4),
                    width: 2.w,
                  ),
                ),
              ),
              Text(
                level.emoji,
                style: TextStyle(fontSize: 42.sp),
              ),
              if (!_isRoundCompleted)
                // Lock overlay to show it is trapped!
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
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
                  'Bé hãy giải cứu:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      level.animalVietnamese,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  level.objective,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 25, // 5x5
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFA5D6A7) // Green success fill
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 3.w : 1.5.w,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
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
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 2.h,
                        right: 2.w,
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${selectionIndex + 1}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }

  Widget _buildProgressRow(_Level level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Text(
            'Từ bé ghép được:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(level.path.length, (idx) {
              final targetPoint = level.path[idx];
              final cellVal = level.grid[targetPoint.x][targetPoint.y];

              final isFilled = _selectedPoints.length > idx;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: isFilled ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF81C784),
                    width: 1.5.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    isFilled ? cellVal : '?',
                    style: GoogleFonts.battambang(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isFilled ? Colors.white : AppColors.textHint,
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
