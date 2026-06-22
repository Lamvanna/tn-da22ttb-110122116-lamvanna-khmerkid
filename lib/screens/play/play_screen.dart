import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_page_route.dart';
import 'word_search_game_screen.dart';
import 'sentence_builder_game_screen.dart';
import 'math_garden_game_screen.dart';
import 'sub_consonant_game_screen.dart';
import 'board_game_screen.dart';
import 'letter_catch_game_screen.dart';
import 'elephant_run_game_screen.dart';

/// Màn hình Chơi - Lộ trình thế giới trò chơi tiểu học (đồng bộ hoàn hảo với trang Học)
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  ScoreService? _score;
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadScore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Đồng bộ vật phẩm hồi phục lên CSDL khi app quay lại foreground
      _score?.syncRegeneratedInventory();
    }
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    _storage = await StorageService.getInstance();
    // Đồng bộ vật phẩm đã hồi phục lên CSDL khi mở trang trò chơi
    await _score?.syncRegeneratedInventory();
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
    final scores = _storage?.getGameScores() ?? {};
    double getProg(String key, {String? altKey}) {
      final s = scores[key] ?? (altKey != null ? (scores[altKey] ?? 0) : 0);
      return (s / 100.0).clamp(0.0, 1.0);
    }

    return [
      _GameZone(
        n: 1,
        title: context.translate('games.game1_title'),
        sub: context.translate('games.game1_sub'),
        icon: Icons.catching_pokemon_rounded,
        img: 'image/Bắt chữ Khmer.png',
        prog: getProg('Bắt chữ Khmer', altKey: 'catch_letter'),
        color: const Color(0xFF1A237E),
        stars: 10,
        btn: context.translate('games.play_now'),
        objective: context.translate('games.game1_obj'),
        gameplay: context.translate('games.game1_play'),
        importance: context.translate('games.game1_imp'),
        targetScreen: const LetterCatchGameScreen(),
      ),
      _GameZone(
        n: 2,
        title: context.translate('games.game2_title'),
        sub: context.translate('games.game2_sub'),
        icon: Icons.forest_rounded,
        img: 'image/Giải cứu thú rừng.png',
        prog: getProg('Giải cứu thú rừng', altKey: 'match_word'),
        color: const Color(0xFF2E7D32),
        stars: 10,
        btn: context.translate('games.play_now'),
        objective: context.translate('games.game2_obj'),
        gameplay: context.translate('games.game2_play'),
        importance: context.translate('games.game2_imp'),
        targetScreen: const WordSearchGameScreen(),
      ),
      _GameZone(
        n: 3,
        title: context.translate('games.game3_title'),
        sub: context.translate('games.game3_sub'),
        icon: Icons.explore_rounded,
        img: 'image/Đảo quốc Ngữ pháp.png',
        prog: getProg('Đảo quốc Ngữ pháp', altKey: 'arrange_letter'),
        color: const Color(0xFF0288D1),
        stars: 15,
        btn: context.translate('games.play_now'),
        objective: context.translate('games.game3_obj'),
        gameplay: context.translate('games.game3_play'),
        importance: context.translate('games.game3_imp'),
        targetScreen: const SentenceBuilderGameScreen(),
      ),
      _GameZone(
        n: 4,
        title: context.translate('games.game4_title'),
        sub: context.translate('games.game4_sub'),
        icon: Icons.calculate_rounded,
        img: 'image/Khu vườn Toán học.png',
        prog: getProg('Khu vườn Toán học', altKey: 'listening_quiz'),
        color: const Color(0xFFF57C00),
        stars: 12,
        btn: context.translate('games.play_now'),
        objective: context.translate('games.game4_obj'),
        gameplay: context.translate('games.game4_play'),
        importance: context.translate('games.game4_imp'),
        targetScreen: const MathGardenGameScreen(),
      ),
      _GameZone(
        n: 5,
        title: context.translate('games.game5_title'),
        sub: context.translate('games.game5_sub'),
        icon: Icons.casino_rounded,
        img: 'image/Cờ tỷ phú Khmer kỳ thú.png',
        prog: getProg('Cờ tỷ phú Khmer kỳ thú'),
        color: const Color(0xFFD32F2F),
        stars: 15,
        btn: context.translate('games.play_now'),
        locked: true,
        objective: context.translate('games.game5_obj'),
        gameplay: context.translate('games.game5_play'),
        importance: context.translate('games.game5_imp'),
        targetScreen: const BoardGameScreen(),
      ),
      _GameZone(
        n: 6,
        title: context.translate('games.game6_title'),
        sub: context.translate('games.game6_sub'),
        icon: Icons.auto_awesome_rounded,
        img: 'image/Nhà khảo cổ nhí.png',
        prog: getProg('Nhà khảo cổ nhí'),
        color: const Color(0xFF7B1FA2),
        stars: 20,
        btn: context.translate('games.play_now'),
        locked: true,
        objective: context.translate('games.game6_obj'),
        gameplay: context.translate('games.game6_play'),
        importance: context.translate('games.game6_imp'),
        targetScreen: const SubConsonantGameScreen(),
      ),
      _GameZone(
        n: 7,
        title: context.translate('games.game7_title'),
        sub: context.translate('games.game7_sub'),
        icon: Icons.pets_rounded,
        img: 'image/Voi con vượt ải.png',
        prog: getProg('Voi con vượt ải'),
        color: const Color(0xFF00ACC1),
        stars: 15,
        btn: context.translate('games.play_now'),
        locked: true,
        objective: context.translate('games.game7_obj'),
        gameplay: context.translate('games.game7_play'),
        importance: context.translate('games.game7_imp'),
        targetScreen: const ElephantRunGameScreen(),
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
              context.translate('games.coming_soon_toast'),
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

  void _showLockedMessage(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.translate('games.locked_toast'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Header đồng bộ trang Học ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ─── Decorative circles ──
          Positioned(
            right: -40.w, top: -30.h,
            child: Container(
              width: 120.w, height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -25.w, bottom: -20.h,
            child: Container(
              width: 80.w, height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ─── Content ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(80.w, 4.h, 80.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          context.translate('games.title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats positioned beautifully at top right of the header!
          Positioned(
            top: MediaQuery.of(context).padding.top + 2.h,
            right: 16.w,
            child: _buildHeaderStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Stars
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⭐', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text(
                '${_score?.totalStars ?? 0}', // Dynamically loaded from ScoreService
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        // Streak
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔥', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text(
                '${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
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
                      context.translate('games.next_challenge'),
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
                                      context.translate('profile.progress'),
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
                                context.translate('learning_path.points'),
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
                      onTap: () => _startGame(context, game),
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
                              context.translate('games.play_now_button'),
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
    final bool isLocked = game.locked;
    final bool isComingSoon = game.targetScreen == null;
    final bool isDisabled = isLocked || isComingSoon;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 14.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFF5F5F5) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLocked ? 0.02 : 0.04),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Game thumbnail
                Stack(
                  children: [
                    Container(
                      width: 110.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: game.img != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: ColorFiltered(
                                colorFilter: isLocked
                                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                                child: Image.asset(game.img!, fit: BoxFit.cover),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: game.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(game.icon, color: game.color, size: 36.sp),
                            ),
                    ),
                    // Lock icon overlay on thumbnail
                    if (isLocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.grey.shade600,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                // Detail content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        game.sub,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: isLocked ? AppColors.textHint : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Status Row
                      Row(
                        children: [
                          Expanded(
                            child: () {
                              String text;
                              Color textColor;
                              IconData icon;

                              if (isLocked) {
                                text = context.translate('games.locked');
                                textColor = Colors.grey.shade500;
                                icon = Icons.lock_outline_rounded;
                              } else if (isComingSoon) {
                                text = context.translate('games.coming_soon');
                                textColor = Colors.grey.shade500;
                                icon = Icons.lock_outline_rounded;
                              } else if (game.prog == 0.0) {
                                text = context.translate('games.not_played');
                                textColor = Colors.grey.shade500;
                                icon = Icons.play_circle_outline_rounded;
                              } else if (game.prog >= 1.0) {
                                text = context.translate('games.completed');
                                textColor = const Color(0xFF43A047);
                                icon = Icons.check_circle_outline_rounded;
                              } else {
                                text = context.translate('games.playing');
                                textColor = const Color(0xFFF57C00);
                                icon = Icons.trending_up_rounded;
                              }

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 14.sp, color: textColor),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }(),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: isLocked
                                ? () => _showLockedMessage(context)
                                : () => _startGame(context, game),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? Colors.grey.shade400
                                    : game.color,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDisabled)
                                    Padding(
                                      padding: EdgeInsets.only(right: 4.w),
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 12.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  Text(
                                    isLocked
                                        ? context.translate('games.locked_btn')
                                        : (isComingSoon ? context.translate('games.coming_soon_btn') : game.btn),
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
        ],
      ),
    );
  }

  // ── Start Game Directly ──
  void _startGame(BuildContext context, _GameZone game) {
    HapticFeedback.lightImpact();
    if (game.targetScreen == null) {
      _showComingSoon(context);
    } else {
      Navigator.push(
        context,
        AppPageRoute(page: game.targetScreen!),
      );
    }
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
                  context.translate('games.developing_new_game'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.translate('games.game_world_update_desc'),
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
  final bool locked;

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
    required this.objective,
    required this.gameplay,
    required this.importance,
    this.targetScreen,
    this.locked = false,
  });
}


