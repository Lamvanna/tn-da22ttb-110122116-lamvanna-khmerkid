import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'home/home_screen.dart';
import 'learn/learn_screen.dart';
import 'play/play_screen.dart';
import 'profile/profile_screen.dart';

/// Màn hình chính với Bottom Navigation Bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    PlayScreen(),
    ProfileScreen(),
  ];

  /// Cho phép chuyển tab từ bên ngoài (ví dụ: HomeScreen)
  void switchTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() => _currentIndex = index);
    }
  }

  /// Tìm MainScreenState từ context
  static MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainScreenState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
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
          child: ClipRect(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.navInactive,
              selectedFontSize: 12.sp,
              unselectedFontSize: 12.sp,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.home_outlined, size: 26.sp)),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.home_rounded, size: 26.sp)),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.school_outlined, size: 26.sp)),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.school_rounded, size: 26.sp)),
                  label: 'Học',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.sports_esports_outlined, size: 26.sp)),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.sports_esports_rounded, size: 26.sp)),
                  label: 'Chơi',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.person_outline_rounded, size: 26.sp)),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.person_rounded, size: 26.sp)),
                  label: 'Hồ sơ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
