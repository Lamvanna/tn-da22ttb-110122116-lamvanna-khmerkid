import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../widgets/app_page_route.dart';
import '../main_screen.dart';
import 'spelling_map_screen.dart';
import 'closed_syllable_map_screen.dart';
import 'coeng_map_screen.dart';

import '../../services/score_service.dart';

/// Màn trung gian — chọn loại Ghép vần.
///   1. Phụ âm + Nguyên âm     → SpellingMapScreen
///   2. Phụ âm + Phụ âm + dấu ់  → ClosedSyllableMapScreen
///   3. Phụ âm có chân (coeng ្) → CoengMapScreen
class SpellingHubScreen extends StatefulWidget {
  const SpellingHubScreen({super.key});

  @override
  State<SpellingHubScreen> createState() => _SpellingHubScreenState();
}

class _SpellingHubScreenState extends State<SpellingHubScreen> {
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final s = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _score = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = <_SpellingMode>[
      _SpellingMode(
        index: 1,
        title: 'Phụ âm + Nguyên âm',
        subtitle: 'Ghép phụ âm với nguyên âm cơ bản',
        example: 'ក + ា = កា',
        imagePath: 'image/Học phụ âm và nguyên âm.png',
        color: const Color(0xFF7F39FB),
        gradient: const [Color(0xFF9F6BFF), Color(0xFF6B21A8)],
        ready: true,
        onTap: () => Navigator.push(
            context, AppPageRoute(page: const SpellingMapScreen())),
      ),
      _SpellingMode(
        index: 2,
        title: 'Phụ âm + Phụ âm + dấu ់',
        subtitle: 'Ghép vần đóng với dấu chặt cụt ់',
        example: 'ក + ន + ់ = កន់',
        imagePath: 'image/Phụ âm va phụ âm.png',
        color: const Color(0xFF0084FF),
        gradient: const [Color(0xFF339CFF), Color(0xFF0056B3)],
        ready: true,
        onTap: () => Navigator.push(
            context, AppPageRoute(page: const ClosedSyllableMapScreen())),
      ),
      _SpellingMode(
        index: 3,
        title: 'Phụ âm có chân ្',
        subtitle: 'Ghép vần với phụ âm chân (coeng)',
        example: 'ក + ្ក = ក្ក',
        imagePath: 'image/phụ âm có chân.png',
        color: const Color(0xFFF97316),
        gradient: const [Color(0xFFFB923C), Color(0xFFC2410C)],
        ready: true,
        onTap: () => Navigator.push(
            context, AppPageRoute(page: const CoengMapScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.learnBackground,
      extendBody: true,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hint
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_rounded,
                            color: const Color(0xFFFFB300), size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Bé hãy chọn loại ghép vần để bắt đầu nhé!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D47A1),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Mode cards
                  ...modes.map((m) => Padding(
                        padding: EdgeInsets.only(bottom: 18.h),
                        child: _ModeCard(mode: m),
                      )),

                  SizedBox(height: 80.h), // chừa chỗ cho bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _HubBottomNav(currentIndex: 1),
    );
  }

  // ─── Header — đồng bộ với spelling_map_screen ────────────
  Widget _buildHeader(BuildContext context) {
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 80.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button — chuẩn của app
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36.w, height: 36.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Text(
                          'Ghép vần',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                '1000',
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

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
        backgroundColor: const Color(0xFF2E3849),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.access_time_rounded,
                color: const Color(0xFFFFD740), size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Sắp ra mắt — bé chờ một xíu nhé!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  MODEL
// ════════════════════════════════════════════════════════════════
class _SpellingMode {
  final int index;
  final String title;
  final String subtitle;
  final String example;
  final String imagePath;
  final Color color;
  final List<Color> gradient;
  final bool ready;
  final VoidCallback onTap;

  const _SpellingMode({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.example,
    required this.imagePath,
    required this.color,
    required this.gradient,
    required this.ready,
    required this.onTap,
  });
}

// ════════════════════════════════════════════════════════════════
//  MODE CARD — title 1 dòng, badge ở góc, layout sạch
// ════════════════════════════════════════════════════════════════
class _ModeCard extends StatelessWidget {
  final _SpellingMode mode;
  const _ModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final ready = mode.ready;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          mode.onTap();
        },
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ─── Card body ─────────────────────────────────────
            Ink(
              decoration: BoxDecoration(
                color: mode.index == 1
                    ? const Color(0xFFFAF7FF)
                    : mode.index == 2
                        ? const Color(0xFFF2F8FF)
                        : const Color(0xFFFFF9F2),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: mode.index == 1
                      ? const Color(0xFFEAD8FF)
                      : mode.index == 2
                          ? const Color(0xFFD0E3FF)
                          : const Color(0xFFFFE3C6),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: mode.color.withValues(alpha: ready ? 0.08 : 0.04),
                    blurRadius: 16.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 16.h, 10.w, 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ─── Icon tile (gradient) ──
                    _buildIconTile(ready),
                    SizedBox(width: 10.w),

                    // ─── Text content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            // chừa chỗ cho badge "Sắp có" ở góc trên phải
                            padding: EdgeInsets.only(
                                right: ready ? 0 : 30.w),
                            child: Text(
                              mode.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          // Subtitle dùng full width (không bị badge che)
                          Text(
                            mode.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Example chip
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                                color: mode.color.withValues(
                                    alpha: ready ? 0.12 : 0.06),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: mode.color.withValues(
                                      alpha: ready ? 0.28 : 0.10),
                                  width: 1,
                                )),
                            child: Text(
                              mode.example,
                              style: GoogleFonts.battambang(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: ready
                                    ? mode.color
                                    : const Color(0xFF8390A8),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // ─── Chevron / Lock ──
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: ready
                              ? mode.gradient
                              : [const Color(0xFFB0B7C5), const Color(0xFF8390A8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (ready ? mode.color : const Color(0xFF8390A8))
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        ready
                            ? Icons.chevron_right_rounded
                            : Icons.lock_rounded,
                        color: Colors.white,
                        size: ready ? 18.sp : 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Badge "Sắp có" — góc trên-phải card ────────────
            if (!ready)
              Positioned(
                top: -6.h, right: 14.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.30),
                        blurRadius: 6.r, offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 10.sp, color: Colors.white),
                      SizedBox(width: 3.w),
                      Text(
                        'Sắp có',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 0.3,
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

  Widget _buildIconTile(bool ready) {
    return Container(
      width: 120.w, height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ready
              ? mode.gradient
              : [const Color(0xFFB0B7C5), const Color(0xFF8390A8)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: (ready ? mode.color : const Color(0xFF8390A8))
                .withValues(alpha: 0.25),
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 5.h, 6.w, 5.h),
            child: Image.asset(
              mode.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_rounded,
                color: Colors.white,
                size: 30.sp,
              ),
            ),
          ),
          // Badge số thứ tự
          Positioned(
            top: 6.h, left: 6.w,
            child: Container(
              width: 24.w, height: 24.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: mode.color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${mode.index}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: ready ? mode.color : const Color(0xFF8390A8),
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  BOTTOM NAV — đồng bộ với MainScreen, pop về main + switchTab
// ════════════════════════════════════════════════════════════════
class _HubBottomNav extends StatelessWidget {
  final int currentIndex;
  const _HubBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _switchTab(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.navInactive,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          selectedLabelStyle:
              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            _navItem(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
            _navItem(Icons.school_outlined, Icons.school_rounded, 'Học'),
            _navItem(Icons.sports_esports_outlined,
                Icons.sports_esports_rounded, 'Chơi'),
            _navItem(Icons.person_outline_rounded, Icons.person_rounded,
                'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData inactive, IconData active, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Icon(inactive, size: 26.sp),
      ),
      activeIcon: Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Icon(active, size: 26.sp),
      ),
      label: label,
    );
  }

  /// Pop về MainScreen rồi switch tab tương ứng
  void _switchTab(BuildContext context, int index) {
    final mainState = MainScreenState.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    mainState?.switchTab(index);
  }
}
