import 'package:flutter/material.dart';
import '../main_screen.dart';
import '../library/library_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../achievements/achievements_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/greeting_card.dart';
import 'widgets/category_card.dart';
import 'widgets/congrats_banner.dart';

/// Màn hình Trang chủ — Màu tươi sáng theo mẫu
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: const Offset(0, -18),
              child: const GreetingCard()),
            _buildCategoryRow1(context),
            const SizedBox(height: 14),
            _buildCategoryRow2(context),
            const SizedBox(height: 20),
            const CongratsBanner(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow1(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Học.png',
              label: 'Học',
              color: const Color(0xFF5B8FD4), // Xanh dương mềm
              height: 150,
              onTap: () => MainScreenState.of(context)?.switchTab(1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Trò chơi.png',
              label: 'Chơi',
              color: const Color(0xFFE88070), // Coral ấm
              height: 150,
              onTap: () => MainScreenState.of(context)?.switchTab(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thư viện.png',
              label: 'Thư viện',
              color: const Color(0xFF3AA09A), // Teal
              height: 120,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LibraryScreen())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Xếp hạng.png',
              label: 'Xếp hạng',
              color: const Color(0xFFF0A030), // Vàng cam ấm
              height: 120,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thành tích.png',
              label: 'Thành tích',
              color: const Color(0xFF9070CF), // Tím mềm
              height: 120,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
