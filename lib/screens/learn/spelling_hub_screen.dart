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

/// Màn trung gian — chọn loại Ghép vần.
///   1. Phụ âm + Nguyên âm     → SpellingMapScreen
///   2. Phụ âm + Phụ âm + dấu ់  → ClosedSyllableMapScreen
///   3. Phụ âm có chân (coeng ្) → CoengMapScreen
class SpellingHubScreen extends StatelessWidget {
  const SpellingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = <_SpellingMode>[
      _SpellingMode(
        index: 1,
        title: 'Phụ âm + Nguyên âm',
        subtitle: 'Ghép phụ âm với nguyên âm cơ bản',
        example: 'ក + ា = កា',
        icon: Icons.spellcheck_rounded,
        color: const Color(0xFFAA00FF),
        gradient: const [Color(0xFFB833FF), Color(0xFF7C00CC)],
        ready: true,
        onTap: () => Navigator.push(
            context, AppPageRoute(page: const SpellingMapScreen())),
      ),
      _SpellingMode(
        index: 2,
        title: 'Phụ âm + Phụ âm + dấu ់',
        subtitle: 'Ghép vần đóng với dấu chặt cụt ់',
        example: 'ក + ត់ = កត់',
        icon: Icons.merge_type_rounded,
        color: const Color(0xFF1E88E5),
        gradient: const [Color(0xFF42A5F5), Color(0xFF1565C0)],
        ready: true,
        onTap: () => Navigator.push(
            context, AppPageRoute(page: const ClosedSyllableMapScreen())),
      ),
      _SpellingMode(
        index: 3,
        title: 'Phụ âm có chân ្',
        subtitle: 'Ghép vần với phụ âm chân (coeng)',
        example: 'ផ្ + កា = ផ្កា',
        icon: Icons.account_tree_rounded,
        color: const Color(0xFFFF6D00),
        gradient: const [Color(0xFFFFB300), Color(0xFFE65100)],
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

          // ─── Mascot elephant ──
          Positioned(
            right: 10.w, bottom: -10.h,
            child: Image.asset(
              'assets/images/elephant_mascot.png',
              width: 95.w, height: 95.w,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // ─── Content ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 95.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.only(left: 48.w),
                    child: Text(
                      'Chọn loại ghép vần để học',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final bool ready;
  final VoidCallback onTap;

  const _SpellingMode({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.example,
    required this.icon,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: mode.color.withValues(alpha: ready ? 0.20 : 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: mode.color.withValues(alpha: ready ? 0.14 : 0.06),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 22.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ─── Icon tile (gradient) ──
                    _buildIconTile(ready),
                    SizedBox(width: 16.w),

                    // ─── Text content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            // chừa chỗ cho badge "Sắp có" ở góc trên phải
                            padding: EdgeInsets.only(
                                right: ready ? 0 : 70.w),
                            child: Text(
                              mode.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
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
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Example chip
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              color: mode.color.withValues(
                                  alpha: ready ? 0.10 : 0.06),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: mode.color.withValues(
                                    alpha: ready ? 0.18 : 0.08),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              mode.example,
                              style: GoogleFonts.battambang(
                                fontSize: 14.sp,
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
                    SizedBox(width: 8.w),

                    // ─── Chevron / Lock ──
                    Container(
                      width: 38.w, height: 38.w,
                      decoration: BoxDecoration(
                        color: ready
                            ? mode.color.withValues(alpha: 0.12)
                            : const Color(0xFFEEF1F8),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        ready
                            ? Icons.chevron_right_rounded
                            : Icons.lock_rounded,
                        color: ready ? mode.color : const Color(0xFF8390A8),
                        size: ready ? 24.sp : 18.sp,
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
      width: 76.w, height: 76.w,
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
                .withValues(alpha: 0.30),
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(mode.icon, color: Colors.white, size: 36.sp),
          // Badge số thứ tự
          Positioned(
            top: 5.h, left: 5.w,
            child: Container(
              width: 20.w, height: 20.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${mode.index}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
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
