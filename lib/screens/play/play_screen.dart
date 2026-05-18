import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../widgets/app_page_route.dart';
import 'word_search_game_screen.dart';
import 'sentence_builder_game_screen.dart';
import 'math_garden_game_screen.dart';
import 'sub_consonant_game_screen.dart';
import 'board_game_screen.dart';

/// Màn hình Chơi - Lộ trình thế giới trò chơi tiểu học (đồng bộ hoàn hảo với trang Học)
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final games = _getGames();
    final nextGame = games.firstWhere((g) => g.prog < 1.0, orElse: () => games.first);

    return Scaffold(
      backgroundColor: AppColors.learnBackground, // Đồng bộ màu nền học tập nhẹ nhàng
      body: Column(
        children: [
          // ── Header đồng bộ trang Học ──
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // Thẻ làm nổi bật Game tiếp theo cần chinh phục
                  _buildContinueCard(nextGame),
                  SizedBox(height: 20.h),
                  // Danh sách game dưới dạng Timeline uốn lượn liên kết
                  ...games.map((g) => _buildGameRow(g, isLast: g.n == games.length)),
                  SizedBox(height: 8.h),
                  _buildDevBanner(),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_GameZone> _getGames() {
    return [
      _GameZone(
        n: 1,
        title: 'Giải cứu thú rừng',
        sub: 'Khmer Word Search & Rescue',
        icon: Icons.forest_rounded,
        img: 'image/Trò chơi.png',
        prog: 0.7, // Demo progress
        color: const Color(0xFF2E7D32),
        stars: 10,
        btn: 'Chơi ngay',
        objective: 'Tích lũy vốn từ vựng theo chủ đề (Trường học, Gia đình, Động vật) và rèn luyện kỹ năng viết chính tả của cả từ hoàn chỉnh.',
        gameplay: 'Màn hình hiển thị lưới chữ cái Khmer 5x5 hoặc 6x6 nằm lộn xộn. Hệ thống phát hình ảnh/âm thanh con vật bị nhốt trong bong bóng (ví dụ: ដំរី - con voi). Bé phải dùng tư duy quan sát nhanh để tìm các ký tự ដ, ំ, រ, ី đứng liền kề và vuốt nối chúng lại.',
        importance: 'Giúp trẻ tiểu học tăng cường khả năng quét hình ảnh, ghi nhớ thứ tự chính tả của từ phức tạp cực kỳ hiệu quả mà không cần học vẹt.',
        targetScreen: const WordSearchGameScreen(),
      ),
      _GameZone(
        n: 2,
        title: 'Đảo quốc Ngữ pháp',
        sub: 'Khmer Sentence Builder Island',
        icon: Icons.explore_rounded,
        img: 'image/Thư viện.png',
        prog: 0.4, // Demo progress
        color: const Color(0xFF0288D1),
        stars: 15,
        btn: 'Chơi ngay',
        objective: 'Học cấu trúc câu, ngữ pháp tiếng Khmer cơ bản (Chủ ngữ - Động từ - Tân ngữ) và cách sử dụng từ loại.',
        gameplay: 'Bé hóa thân thành thuyền trưởng phiêu lưu qua các đảo giải mã mật thư đá cổ. Sắp xếp câu tiếng Khmer bị xáo trộn vị trí các từ (ví dụ: Configs: ខ្ញុំ [Tôi] / ទៅ [đi] / សាលារៀន [trường học]) bằng cách kéo thả đá chữ vào đúng vị trí để hoàn thành câu.',
        importance: 'Giai đoạn tiểu học bắt đầu viết câu ngắn. Trò chơi này rèn luyện tư duy logic về ngữ pháp, giúp trẻ hiểu rõ vị trí của các từ loại trong câu.',
        targetScreen: const SentenceBuilderGameScreen(),
      ),
      _GameZone(
        n: 3,
        title: 'Khu vườn Toán học',
        sub: 'Khmer Math & Number Garden',
        icon: Icons.calculate_rounded,
        img: 'image/Học.png',
        prog: 0.2, // Demo progress
        color: const Color(0xFFF57C00),
        stars: 12,
        btn: 'Chơi ngay',
        objective: 'Thành thạo Hệ thống chữ số Khmer truyền thống (០, ១, ២, ៣, ៤, ៥, ៦, ៧, ៨, ៩) thông qua các phép toán đơn giản.',
        gameplay: 'Trong khu vườn xum xuê quả, hệ thống đưa ra phép toán đố bằng chữ Khmer (ví dụ: ២ + ៣ = ?). Bé kéo đúng chiếc giỏ mang đáp án chính xác (៥ hoặc từ chữ) để hứng quả táo rụng.',
        importance: 'Học sinh tiểu học bắt buộc phải học hệ chữ số Khmer cổ của dân tộc mình. Sự kết hợp liên môn (Toán + Ngôn ngữ) này giúp việc học số Khmer trở nên dễ dàng, sinh động.',
        targetScreen: const MathGardenGameScreen(),
      ),
      _GameZone(
        n: 4,
        title: 'Cờ tỷ phú Khmer kỳ thú',
        sub: 'Khmer Adventure Board Game',
        icon: Icons.casino_rounded,
        img: 'image/Xếp hạng.png',
        prog: 0.0,
        color: const Color(0xFFD32F2F),
        stars: 15,
        btn: 'Chơi ngay',
        objective: 'Chinh phục toàn diện 4 kỹ năng tích hợp (Nghe - Nói - Đọc - Viết) thông qua bàn cờ thám hiểm.',
        gameplay: 'Bé đổ xúc xắc để Voi con di chuyển qua Rừng phụ âm, Đầm lầy nguyên âm, Động phát âm và Đỉnh núi viết chữ, dứt điểm bằng trận chiến Boss Vua Bóng Tối hoành tráng!',
        importance: 'Hoạt động như một bài kiểm tra tổng hợp cuối chương (Summative Assessment) cực kỳ hấp dẫn, không áp lực mà kích thích tương tác toàn diện.',
        targetScreen: const BoardGameScreen(),
      ),
      _GameZone(
        n: 5,
        title: 'Nhà khảo cổ nhí',
        sub: 'Khmer Sub-consonant Detective',
        icon: Icons.auto_awesome_rounded,
        img: 'image/Thành tích.png',
        prog: 0.0,
        color: const Color(0xFF7B1FA2),
        stars: 20,
        btn: 'Chơi ngay',
        objective: 'Ghi nhớ và viết đúng các Chân chữ (Châng) - phần khó nhất và dễ viết sai nhất trong tiếng Khmer cấp độ tiểu học.',
        gameplay: 'Bé đóng vai nhà khảo cổ đi tìm cổ vật chữ chôn giấu dưới các khối đá. Hệ thống đưa ra từ vựng bị khuyết chân chữ (ví dụ: từ អក្សរ bị mất chân chữ ្ស). Bé dùng kính lúp tìm kiếm và búa gõ khai quật chân chữ đúng.',
        importance: 'Lên lớp 2, lớp 3 bắt đầu viết từ ghép phức tạp có chân chữ. Trò chơi thám hiểm đầy kịch tính này giúp trẻ ghi nhớ chân chữ vô cùng dễ dàng.',
        targetScreen: const SubConsonantGameScreen(),
      ),
    ];
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.construction_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              'Trò chơi này sắp được ra mắt! 🚀',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.headerMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Header đồng bộ trang Học ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.appGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
          child: Row(
            children: [
              // Stars badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('image/sao.png', width: 18.w, height: 18.h),
                        SizedBox(width: 5.w),
                        Text(
                          '${_score?.totalStars ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Điểm của bạn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Thế giới trò chơi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Streak badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('image/Lửa chuổi.png', width: 18.w, height: 18.h),
                        SizedBox(width: 5.w),
                        Text(
                          '${_score?.streak ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Chuỗi ngày',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
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

  // ── Highlight Continue Card ──
  Widget _buildContinueCard(_GameZone game) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: SizedBox(
                  width: 140.w,
                  height: 140.h,
                  child: Image.asset('image/Thành tích.png', fit: BoxFit.contain),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thử thách tiếp theo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        SizedBox(
                          width: 65.w,
                          height: 65.w,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: game.prog),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 65.w,
                                  height: 65.w,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 5.w,
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                  ),
                                ),
                                SizedBox(
                                  width: 65.w,
                                  height: 65.w,
                                  child: CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 5.w,
                                    color: const Color(0xFFFFB300),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(value * 100).toInt()}%',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Tiến độ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 65.w,
                          height: 65.w,
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('image/sao.png', width: 18.w, height: 18.h),
                              SizedBox(height: 2.h),
                              Text(
                                '+${game.stars}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF0A030),
                                ),
                              ),
                              Text(
                                'Điểm',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => _showGameIntroDialog(context, game),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB340), Color(0xFFF0A030)],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF0A030).withValues(alpha: 0.30),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chơi ngay thôi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18.sp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline Row ──
  Widget _buildGameRow(_GameZone game, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dotted Timeline Node
            SizedBox(
              width: 36.w,
              child: Column(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: game.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: game.color.withValues(alpha: 0.3),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${game.n}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: CustomPaint(
                        painter: _DottedLinePainter(color: game.color.withValues(alpha: 0.3)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Game Card
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Game thumbnail
                    Container(
                      width: 85.w,
                      height: 90.h,
                      decoration: BoxDecoration(
                        color: game.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: game.img != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18.r),
                              child: Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Image.asset(game.img!, fit: BoxFit.contain),
                              ),
                            )
                          : Icon(game.icon, color: game.color, size: 36.sp),
                    ),
                    SizedBox(width: 12.w),
                    // Detail content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  game.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('image/sao.png', width: 14.w, height: 14.h),
                                    SizedBox(width: 3.w),
                                    Text(
                                      '+${game.stars}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF0A030),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            game.sub,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // Progress indicators
                          Row(
                            children: [
                              Text(
                                '${(game.prog * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: game.color,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5.r),
                                  child: LinearProgressIndicator(
                                    value: game.prog,
                                    minHeight: 5.h,
                                    backgroundColor: game.color.withValues(alpha: 0.12),
                                    color: game.color,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              GestureDetector(
                                onTap: () => _showGameIntroDialog(context, game),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: game.isComingSoon && game.targetScreen == null
                                        ? game.color.withValues(alpha: 0.4)
                                        : game.color,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (game.isComingSoon && game.targetScreen == null)
                                        Padding(
                                          padding: EdgeInsets.only(right: 4.w),
                                          child: Icon(
                                            Icons.lock_rounded,
                                            size: 12.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      Text(
                                        game.isComingSoon && game.targetScreen == null ? 'Sắp ra mắt' : game.btn,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom Game Intro Dialog with Educational Metadata ──
  void _showGameIntroDialog(BuildContext context, _GameZone game) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🎨 Banner Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.r),
                        topRight: Radius.circular(28.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: game.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: game.color.withValues(alpha: 0.3),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Icon(game.icon, color: Colors.white, size: 30.sp),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          game.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          game.sub,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🎯 Mục tiêu
                        _buildDialogSection(
                          icon: Icons.track_changes_rounded,
                          color: const Color(0xFF1E88E5),
                          title: 'Mục tiêu học tập',
                          content: game.objective,
                        ),
                        SizedBox(height: 16.h),

                        // 🎮 Cách chơi
                        _buildDialogSection(
                          icon: Icons.sports_esports_rounded,
                          color: const Color(0xFF43A047),
                          title: 'Cách chơi',
                          content: game.gameplay,
                        ),
                        SizedBox(height: 16.h),

                        // 🏆 Tầm quan trọng
                        _buildDialogSection(
                          icon: Icons.verified_user_rounded,
                          color: const Color(0xFFFF8F00),
                          title: 'Ý nghĩa sư phạm',
                          content: game.importance,
                        ),
                        SizedBox(height: 24.h),

                        // 🚀 CTA Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    side: BorderSide(color: AppColors.textHint.withValues(alpha: 0.4)),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Đóng',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: game.isComingSoon && game.targetScreen == null
                                        ? [Colors.grey.shade400, Colors.grey.shade500]
                                        : [game.color, game.color.withValues(alpha: 0.85)],
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: game.isComingSoon && game.targetScreen == null
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: game.color.withValues(alpha: 0.3),
                                            blurRadius: 8.r,
                                            offset: Offset(0, 3.h),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (game.isComingSoon && game.targetScreen == null) {
                                      _showComingSoon(context);
                                    } else if (game.targetScreen != null) {
                                      Navigator.push(
                                        context,
                                        AppPageRoute(page: game.targetScreen!),
                                      );
                                    }
                                  },
                                  child: Text(
                                    game.isComingSoon && game.targetScreen == null ? 'Sắp ra mắt' : 'Bắt đầu chơi',
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogSection({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dev Banner ──
  Widget _buildDevBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.25),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('🚧', style: TextStyle(fontSize: 28.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang phát triển game mới',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Thế giới trò chơi sẽ liên tục cập nhật!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gamepad_rounded, color: Colors.white, size: 20.sp),
          ),
        ],
      ),
    );
  }
}

class _GameZone {
  final int n, stars;
  final String title, sub, btn;
  final String? img;
  final IconData icon;
  final double prog;
  final Color color;
  final bool isComingSoon;

  // New fields for rich educational descriptions
  final String objective;
  final String gameplay;
  final String importance;
  final Widget? targetScreen;

  _GameZone({
    required this.n,
    required this.title,
    required this.sub,
    required this.icon,
    this.img,
    required this.prog,
    required this.color,
    required this.btn,
    required this.stars,
    this.isComingSoon = false,
    required this.objective,
    required this.gameplay,
    required this.importance,
    this.targetScreen,
  });
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5.w
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    double y = 6.h;
    while (y < size.height) {
      canvas.drawCircle(Offset(cx, y), 1.5.r, paint);
      y += 8.h;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
