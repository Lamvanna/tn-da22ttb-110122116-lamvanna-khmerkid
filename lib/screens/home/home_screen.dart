import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main_screen.dart';
import '../../constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: Offset(0, -18.h),
              child: const GreetingCard()),
            Transform.translate(
              offset: Offset(0, -6.h),
              child: _buildCategoryRow1(context)),
            SizedBox(height: 10.h),
            _buildCategoryRow2(context),
            SizedBox(height: 12.h),
            const CongratsBanner(),
            SizedBox(height: 90.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow1(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Học.png',
              label: 'Học',
              color: const Color(0xFF5B8FD4), // Xanh dương mềm
              height: 150.h,
              onTap: () => MainScreenState.of(context)?.switchTab(1),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Trò chơi.png',
              label: 'Chơi',
              color: const Color(0xFFE88070), // Coral ấm
              height: 150.h,
              onTap: () => MainScreenState.of(context)?.switchTab(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow2(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thư viện.png',
              label: 'Thư viện',
              color: const Color(0xFF3AA09A), // Teal
              height: 120.h,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LibraryScreen())),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Xếp hạng.png',
              label: 'Xếp hạng',
              color: const Color(0xFFF0A030), // Vàng cam ấm
              height: 120.h,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thành tích.png',
              label: 'Thành tích',
              color: const Color(0xFF9070CF), // Tím mềm
              height: 120.h,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
