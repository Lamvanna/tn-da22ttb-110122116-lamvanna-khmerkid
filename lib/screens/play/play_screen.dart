import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_gradient_header.dart';
import 'matching_game_screen.dart';
import 'sorting_game_screen.dart';
import 'letter_find_game_screen.dart';
import 'quiz_game_screen.dart';
import '../../widgets/app_page_route.dart';

/// Màn hình Chơi - Play Screen
/// Hiển thị các trò chơi mini: Ghép hình, Xếp hình, Trò chơi chữ, Đố vui
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          const SliverToBoxAdapter(
            child: AppGradientHeader(title: 'Chơi'),
          ),

          // ── Game cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Text(
                    'Trò chơi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Game grid - 2 columns
                  Row(
                    children: [
                      Expanded(
                        child: _buildGameCard(
                          title: 'Ghép hình',
                          description: 'Ghép chữ với phiên âm',
                          icon: Icons.extension_rounded,
                          color: const Color(0xFFFF6B6B),
                          onTap: () {
                            Navigator.push(context, AppPageRoute(
                              page: const MatchingGameScreen(),
                            ));
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildGameCard(
                          title: 'Xếp hình',
                          description: 'Sắp xếp chữ cái',
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF42A5F5),
                          onTap: () {
                            Navigator.push(context, AppPageRoute(
                              page: const SortingGameScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildGameCard(
                          title: 'Trò chơi chữ',
                          description: 'Tìm chữ cái đúng',
                          icon: Icons.abc_rounded,
                          color: const Color(0xFF66BB6A),
                          onTap: () {
                            Navigator.push(context, AppPageRoute(
                              page: const LetterFindGameScreen(),
                            ));
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildGameCard(
                          title: 'Đố vui',
                          description: 'Câu đố về chữ Khmer',
                          icon: Icons.quiz_rounded,
                          color: const Color(0xFFFFCA28),
                          onTap: () {
                            Navigator.push(context, AppPageRoute(
                              page: const QuizGameScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // ── Thành tích ──
                  Text(
                    'Thành tích',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _buildAchievementCard(
                    title: 'Người chơi giỏi',
                    description: 'Hoàn thành 10 trò chơi',
                    icon: Icons.emoji_events_rounded,
                    progress: 0.7,
                    current: 7,
                    total: 10,
                  ),
                  SizedBox(height: 10.h),
                  _buildAchievementCard(
                    title: 'Tốc độ ánh sáng',
                    description: 'Hoàn thành trong 30 giây',
                    icon: Icons.bolt_rounded,
                    progress: 0.4,
                    current: 4,
                    total: 10,
                  ),

                  SizedBox(height: 90.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(24.r),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: EdgeInsets.all(16.w),
          height: 160.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.08),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, size: 28.sp, color: color),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required IconData icon,
    required double progress,
    required int current,
    required int total,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.accentYellow, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
                SizedBox(height: 2.h),
                Text(description, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                )),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6.h,
                          backgroundColor: AppColors.progressBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentYellow,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$current/$total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
