import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          LearnScreen(),
          PlayScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF6C63FF),
            unselectedItemColor: const Color(0xFF9E9E9E),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 26),
                activeIcon: Icon(Icons.home_rounded, size: 26),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined, size: 26),
                activeIcon: Icon(Icons.school_rounded, size: 26),
                label: 'Học',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports_outlined, size: 26),
                activeIcon: Icon(Icons.sports_esports_rounded, size: 26),
                label: 'Chơi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 26),
                activeIcon: Icon(Icons.person_rounded, size: 26),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
