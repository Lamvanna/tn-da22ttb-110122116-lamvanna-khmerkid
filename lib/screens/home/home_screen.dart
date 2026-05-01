import 'package:flutter/material.dart';
import '../main_screen.dart';
import '../learn/learn_screen.dart';
import '../play/play_screen.dart';
import '../library/library_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../achievements/achievements_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/greeting_card.dart';
import 'widgets/category_card.dart';
import 'widgets/congrats_banner.dart';

/// Màn hình Trang chủ
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 20),
            const GreetingCard(),
            const SizedBox(height: 20),
            _buildCategoryRow1(context),
            const SizedBox(height: 14),
            _buildCategoryRow2(context),
            const SizedBox(height: 20),
            const CongratsBanner(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Row 1: Học, Chơi — chuyển tab thay vì push
  Widget _buildCategoryRow1(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              icon: Icons.menu_book_rounded,
              label: 'Học',
              color: const Color(0xFF4CAF50),
              height: 130,
              onTap: () {
                // Chuyển sang tab Học (index 1) — giữ bottom nav
                MainScreenState.of(context)?.switchTab(1);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CategoryCard(
              icon: Icons.sports_esports_rounded,
              label: 'Chơi',
              color: const Color(0xFFE91E63),
              height: 130,
              onTap: () {
                // Chuyển sang tab Chơi (index 2) — giữ bottom nav
                MainScreenState.of(context)?.switchTab(2);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Row 2: Thư viện, Xếp hạng, Thành tích — push screen mới
  Widget _buildCategoryRow2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              icon: Icons.local_library_rounded,
              label: 'Thư viện',
              color: const Color(0xFF9C5BF5),
              height: 120,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CategoryCard(
              icon: Icons.leaderboard_rounded,
              label: 'Xếp hạng',
              color: const Color(0xFFF5A623),
              height: 120,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CategoryCard(
              icon: Icons.emoji_events_rounded,
              label: 'Thành tích',
              color: const Color(0xFF42A5F5),
              height: 120,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
