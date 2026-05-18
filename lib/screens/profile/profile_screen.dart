import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../settings/settings_screen.dart';
import '../report/report_screen.dart';
import '../achievements/achievements_screen.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/game_xp_progress_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await ScoreService.getInstance();
    if (mounted) setState(() => _score = s);
  }

  int get _xp => _hasRealData ? _score!.totalXp : 1250;
  int get _level => _hasRealData ? _score!.level : 5;
  int get _stars => _hasRealData ? _score!.totalStars : 250;
  int get _streak => _hasRealData ? _score!.streak : 7;
  int get _medals => _hasRealData ? _score!.totalMedals : 12;
  int get _lettersLearned => _hasRealData ? _score!.lettersLearned : 18;
  int get _vowelsLearned => _hasRealData ? _score!.vowelsLearned : 8;

  /// Có dữ liệu thật khi user đã học (XP > 0)
  bool get _hasRealData => _score != null && _score!.totalXp > 0;

  String _levelTitle(int lv) {
    if (lv >= 20) return 'Bậc thầy ngôn ngữ';
    if (lv >= 15) return 'Nhà thông thái';
    if (lv >= 10) return 'Nhà thám hiểm';
    if (lv >= 5) return 'Nhà thám hiểm nhí';
    return 'Mới bắt đầu';
  }

  @override
  Widget build(BuildContext context) {
    // Demo mode: hiển thị 1250/2000 cho level 5; mode thật: 100 XP/level
    final xpInLevel = _hasRealData ? (_xp % 100) : 1250;
    final xpNeeded = _hasRealData ? 100 : 2000;
    final xpRemaining = xpNeeded - xpInLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ═══ HEADER ═══
            _buildHeader(xpInLevel, xpNeeded, xpRemaining),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 14.h),
                  _buildProgressSection(),
                  SizedBox(height: 16.h),
                  _buildAchievements(),
                  SizedBox(height: 16.h),
                  _buildSettingsRow(),
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER — Blue → Violet gradient, sky theme (match reference)
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(int xpInLevel, int xpNeeded, int xpRemaining) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 50.h),
          decoration: BoxDecoration(
            gradient: AppColors.appGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ─── Glowing light sources for ultimate depth ───
                  Positioned(
                    left: -40.w,
                    top: -20.h,
                    child: Container(
                      width: 220.w,
                      height: 220.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF818CF8).withValues(alpha: 0.40),
                            const Color(0xFF818CF8).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40.w,
                    top: 0.h,
                    child: Container(
                      width: 240.w,
                      height: 240.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF60A5FA).withValues(alpha: 0.35),
                            const Color(0xFF60A5FA).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Cloud decoration (bottom) ────────────────
                  Positioned(
                    left: -20.w,
                    bottom: 8.h,
                    child: _cloud(width: 110.w, alpha: 0.22),
                  ),
                  Positioned(
                    right: 30.w,
                    bottom: 24.h,
                    child: _cloud(width: 80.w, alpha: 0.18),
                  ),
                  Positioned(
                    left: 140.w,
                    bottom: 50.h,
                    child: _cloud(width: 60.w, alpha: 0.14),
                  ),

                  // ─── Star sparkles ────────────────────────────
                  Positioned(
                    left: 30.w,
                    top: 16.h,
                    child: _spark(14.sp, 0.45, color: const Color(0xFFFFF176)),
                  ),
                  Positioned(left: 90.w, top: 8.h, child: _spark(8.sp, 0.35)),
                  Positioned(
                    right: 120.w,
                    top: 12.h,
                    child: _spark(12.sp, 0.40, color: const Color(0xFFFFF176)),
                  ),
                  Positioned(
                    right: 180.w,
                    top: 48.h,
                    child: _spark(9.sp, 0.30),
                  ),
                  Positioned(
                    left: 170.w,
                    top: 62.h,
                    child: _spark(10.sp, 0.35, color: const Color(0xFFFFF176)),
                  ),

                  // ─── Elephant mascot — to lớn, bóng bẩy, đè lên phần card dưới cực sinh động ───
                  Positioned(
                    right: -12.w,
                    bottom: 52.h,
                    width: 120.w,
                    child: Image.asset(
                      'image/Voi hồ sơ.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // ─── Main content ────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 64.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Avatar (left) + Name + chip
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarWithBadges(),
                            SizedBox(
                              width: 10.w,
                            ), // Xích cột tên và cấp độ sang bên trái nhiều hơn
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                ), // Căn giữa thẳng hàng
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bé Na',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize:
                                            27.sp, // Lớn và nổi bật hơn nhiều
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: const Color(
                                              0xFF1E1B4B,
                                            ).withOpacity(0.40),
                                            blurRadius: 8.r,
                                            offset: Offset(0, 3.h),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    _buildLevelChip(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),

                        // ─── XP Bar (dịch lên trên) ─────────────────
                        // ─── XP Bar (dịch xuống dưới và sang phải một chút) ───
                        Transform.translate(
                          offset: Offset(0, -22.h),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 102.w,
                              right: 70.w,
                            ),
                            child: _buildXpBar(xpInLevel, xpNeeded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ═══ STATS CARD (overlap) ═══
        Positioned(left: 12.w, right: 12.w, bottom: 0, child: _buildStatsRow()),
      ],
    );
  }

  // ─── Helper: cloud shape (3 overlapping circles) ──────────────
  Widget _cloud({required double width, required double alpha}) {
    final color = Colors.white.withValues(alpha: alpha);
    return SizedBox(
      width: width,
      height: width * 0.55,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: width * 0.55,
              height: width * 0.55,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          Positioned(
            left: width * 0.30,
            bottom: width * 0.10,
            child: Container(
              width: width * 0.50,
              height: width * 0.50,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: width * 0.45,
              height: width * 0.45,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper: small star sparkle ───────────────────────────────
  Widget _spark(double size, double alpha, {Color color = Colors.white}) =>
      Icon(
        Icons.star_rounded,
        color: color.withValues(alpha: alpha),
        size: size,
      );

  // ─── Avatar with star badge (top-right) + edit button (bottom-right)
  Widget _buildAvatarWithBadges() {
    return SizedBox(
      width: 90.w,
      height: 90.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3.5.w),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withOpacity(0.28),
                  blurRadius: 16.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('image/Đại diện.png', fit: BoxFit.cover),
            ),
          ),
          // Edit pencil (bottom-right)
          Positioned(
            right: -2.w,
            bottom: -2.h,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFAB40), // Bright shiny orange
                    Color(0xFFFF6D00), // Rich warm orange
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withOpacity(0.35),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Level chip (shield + level title) ────────────────────────
  Widget _buildLevelChip() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 2.h, 12.w, 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_rounded,
            size: 14.sp,
            color: const Color(0xFFFFD700), // Gold shield
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'Cấp $_level • ${_levelTitle(_level)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── XP Bar (yellow fill, dark blue track, STAR badge — match ref) ──
  Widget _buildXpBar(int xpInLevel, int xpNeeded) {
    return GameXpProgressBar(
      xpInLevel: xpInLevel,
      xpNeeded: xpNeeded,
      height: 30,
      trackHeight: 18,
      starSize: 24,
      fontSize: 9.2,
      animationDuration: const Duration(milliseconds: 1200),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STATS ROW: 4 items — Label trên, Value lớn dưới (match ref)
  // ══════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.08),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2.w),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _statItem(
              iconIndex: 0,
              label: 'Tổng số sao',
              value: '$_stars',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 1,
              label: 'Chuỗi ngày',
              value: '$_streak ngày',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 2,
              label: 'Huy hiệu',
              value: '$_medals',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 3,
              label: 'Thứ hạng',
              value: 'Top 5',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1.5.w,
      height: 48.h,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildStatIcon(int index) {
    switch (index) {
      case 0: // Star: beautiful multi-colored 3D gradient star
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFFEC4899), Color(0xFFFBBF24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(Icons.star_rounded, size: 40.sp, color: Colors.white),
        );
      case 1: // Flame: glossy intense orange-red to bright gold fire
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFFFD000)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(bounds),
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 40.sp,
            color: Colors.white,
          ),
        );
      case 2: // Medal: rich gold medallion
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Icon(Icons.stars_rounded, size: 40.sp, color: Colors.white),
        );
      case 3: // Trophy: premium gold tournament trophy
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF4F46E5), Color(0xFFFFD700)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ).createShader(bounds),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 40.sp,
            color: Colors.white,
          ),
        );
      default:
        return Icon(Icons.help_rounded, size: 40.sp, color: Colors.grey);
    }
  }

  Widget _statItem({
    required int iconIndex,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44.h,
              alignment: Alignment.center,
              child: _buildStatIcon(iconIndex),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: labelColor,
                height: 1.2,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17.5.sp,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LEARNING PROGRESS
  // ══════════════════════════════════════════════════════════════
  Widget _buildProgressSection() {
    // Demo data fallback khi user chưa học
    final letters = _hasRealData ? _lettersLearned : 18;
    final spelling = _hasRealData ? 0 : 12;
    final writing = _hasRealData ? 0 : 8;
    final reading = _hasRealData ? 0 : 14;

    final totalProg = ((letters / 33 + _vowelsLearned / 18) / 2 * 100)
        .clamp(0, 100)
        .toInt();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header row ──
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.headerMid.withValues(alpha: 0.15),
                      AppColors.headerMid.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.headerMid.withValues(alpha: 0.20),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 18.sp,
                  color: AppColors.headerMid,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Tiến độ học tập',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(page: const ReportScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                  child: Row(
                    children: [
                      Text(
                        'Chi tiết',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerMid,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: AppColors.headerMid,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // ─── Body: circular + bars ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress with gradient ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalProg / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, val, _) => Container(
                  width: 98.w,
                  height: 98.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                        blurRadius: 16.r,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer premium border plate
                      Container(
                        width: 98.w,
                        height: 98.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFEEF2F6),
                            width: 1.5.w,
                          ),
                        ),
                      ),
                      // Track
                      SizedBox(
                        width: 90.w,
                        height: 90.w,
                        child: Padding(
                          padding: EdgeInsets.all(5.w),
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8.w,
                            color: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                      // Active ring with beautiful SweepGradient ShaderMask!
                      SizedBox(
                        width: 90.w,
                        height: 90.w,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const SweepGradient(
                            colors: [
                              Color(0xFF66BB6A), // light vibrant green
                              Color(0xFF388E3C), // deep emerald green
                            ],
                            stops: [0.0, 1.0],
                          ).createShader(bounds),
                          child: Padding(
                            padding: EdgeInsets.all(5.w),
                            child: CircularProgressIndicator(
                              value: val,
                              strokeWidth: 8.w,
                              color: Colors.white,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(val * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Tổng tiến độ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Subject bars
              Expanded(
                child: Column(
                  children: [
                    _progressBar(
                      'Học chữ cái',
                      letters,
                      33,
                      const Color(0xFF4CAF50),
                      'image/Phụ âm.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Đánh vần',
                      spelling,
                      20,
                      const Color(0xFF2196F3),
                      'image/Đánh vần.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Luyện viết',
                      writing,
                      20,
                      const Color(0xFFFF9800),
                      'image/Tập viết.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Tập đọc',
                      reading,
                      20,
                      const Color(0xFF9C27B0),
                      'image/Tập đọc.png',
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

  Widget _progressBar(
    String label,
    int done,
    int total,
    Color color,
    String img,
  ) {
    final pct = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.16),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.2.w,
            ),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            img,
            width: 20.w,
            height: 20.h,
            errorBuilder: (_, _, _) =>
                Icon(Icons.book_rounded, size: 16.sp, color: color),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  Text(
                    '$done/$total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.80),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.24),
                          blurRadius: 4.r,
                          offset: Offset(0, 1.h),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════
  Widget _buildAchievements() {
    final badges = [
      {
        'icon': Icons.star_rounded,
        'label': 'Siêu nhân\nchăm chỉ',
        'color': const Color(0xFFFFB300),
        'unlocked': true,
      },
      {
        'icon': Icons.edit_rounded,
        'label': 'Bút vàng',
        'color': const Color(0xFFFB8C00),
        'unlocked': true,
      },
      {
        'icon': Icons.auto_stories_rounded,
        'label': 'Siêu nhân\nbài tập',
        'color': const Color(0xFF1E88E5),
        'unlocked': true,
      },
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Tập đọc',
        'color': const Color(0xFF8E24AA),
        'unlocked': false,
      },
      {
        'icon': Icons.spellcheck_rounded,
        'label': 'Đánh vần\nnhanh',
        'color': const Color(0xFFE53935),
        'unlocked': false,
      },
      {
        'icon': Icons.explore_rounded,
        'label': 'Nhà thám\nhiểm',
        'color': const Color(0xFF00897B),
        'unlocked': false,
      },
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      blurRadius: 8.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text('🏆', style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(width: 10.w),
              Text(
                'Thành tích',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8.w),
              // Gold Gradient Capsule Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.30),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Text(
                  '$_medals/24',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(page: const AchievementsScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                  child: Row(
                    children: [
                      Text(
                        'Tất cả',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerMid,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: AppColors.headerMid,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ─── Badges list ──
          SizedBox(
            height: 106.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (_, _) => SizedBox(width: 14.w),
              itemBuilder: (_, i) {
                final b = badges[i];
                final color = b['color'] as Color;
                final unlocked = b['unlocked'] as bool;
                return SizedBox(
                  width: 64.w,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Outer double-border ring
                          Container(
                            width: 58.w,
                            height: 58.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: unlocked
                                    ? color.withValues(alpha: 0.35)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5.w,
                              ),
                            ),
                            padding: EdgeInsets.all(2.w),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: unlocked
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.80),
                                        ],
                                      )
                                    : null,
                                color: unlocked ? null : const Color(0xFFF1F5F9),
                                border: unlocked
                                    ? Border.all(
                                        color: Colors.white.withValues(alpha: 0.60),
                                        width: 1.5.w,
                                      )
                                    : null,
                                boxShadow: unlocked
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 8.r,
                                          offset: Offset(0, 3.h),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                b['icon'] as IconData,
                                color: unlocked ? Colors.white : const Color(0xFF94A3B8),
                                size: 26.sp,
                              ),
                            ),
                          ),
                          // Lock indicator
                          if (!unlocked)
                            Positioned(
                              right: -1.w,
                              bottom: -1.w,
                              child: Container(
                                width: 18.w,
                                height: 18.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5.w,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 10.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        b['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? AppColors.textPrimary
                              : const Color(0xFF94A3B8),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SYSTEM SETTINGS ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildSettingsRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            AppPageRoute(page: const SettingsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF94A3B8),
                        Color(0xFF64748B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.20),
                        blurRadius: 8.r,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.settings_rounded,
                    size: 22.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt hệ thống',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Âm thanh, thông báo & tài khoản',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF64748B),
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

