import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../main_screen.dart';
import '../library/library_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../achievements/achievements_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/greeting_card.dart';
import 'widgets/category_card.dart';
import 'widgets/congrats_banner.dart';

/// Màn hình Trang chủ — 5 màu hài hòa, mỗi card khác biệt
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              color: AppColors.primary,
              height: 150,
              onTap: () => MainScreenState.of(context)?.switchTab(1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Trò chơi.png',
              label: 'Chơi',
              color: AppColors.coral,
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
              color: AppColors.tertiary,
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
              color: AppColors.secondary,
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
              color: AppColors.violet,
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
