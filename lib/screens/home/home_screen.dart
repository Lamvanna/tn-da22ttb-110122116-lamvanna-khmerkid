import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main_screen.dart';
import '../../constants/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../library/library_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../achievements/achievements_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/greeting_card.dart';
import 'widgets/category_card.dart';
import 'widgets/congrats_banner.dart';
import '../../widgets/app_page_route.dart';

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
            SizedBox(height: Spacing.v3),
            const GreetingCard(),
            SizedBox(height: Spacing.v2),
            _buildCategoryRow1(context),
            SizedBox(height: Spacing.v3 - 2.h), // 10.h
            _buildCategoryRow2(context),
            SizedBox(height: Spacing.v3),
            const CongratsBanner(),
            SizedBox(height: 90.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow1(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Học.png',
              label: 'Học',
              color: AppColors.primaryLight, // Xanh dương mềm
              height: 150.h,
              onTap: () => MainScreenState.of(context)?.switchTab(1),
            ),
          ),
          SizedBox(width: Spacing.s4 - 2.w), // 14.w
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Trò chơi.png',
              label: 'Chơi',
              color: AppColors.coralLight, // Coral ấm
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
      padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Row(
        children: [
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thư viện.png',
              label: 'Thư viện',
              color: AppColors.tertiaryLight, // Teal / Green
              height: 120.h,
              onTap: () => Navigator.push(context,
                AppPageRoute(page: const LibraryScreen())),
            ),
          ),
          SizedBox(width: Spacing.s3),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Xếp hạng.png',
              label: 'Xếp hạng',
              color: AppColors.secondaryLight, // Vàng cam ấm
              height: 120.h,
              onTap: () => Navigator.push(context,
                AppPageRoute(page: const LeaderboardScreen())),
            ),
          ),
          SizedBox(width: Spacing.s3),
          Expanded(
            child: CategoryCard(
              imagePath: 'image/Thành tích.png',
              label: 'Thành tích',
              color: AppColors.violetLight, // Tím mềm
              height: 120.h,
              onTap: () => Navigator.push(context,
                AppPageRoute(page: const AchievementsScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
