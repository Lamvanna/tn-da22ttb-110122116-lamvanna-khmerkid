import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Dashboard Admin — Tổng quan hệ thống
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AdminService().fetchDashboard(),
      AdminService().fetchStatistics(),
    ]);

    if (!mounted) return;
    setState(() {
      if (results[0]['success'] == true) _dashboard = results[0]['data'] ?? {};
      if (results[1]['success'] == true) _statistics = results[1]['data'] ?? {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            Text(
              '📊 Tổng quan hệ thống',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Dữ liệu realtime từ hệ thống KhmerKid',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            // ── Stats Grid ──
            _buildStatsGrid(),
            SizedBox(height: 24.h),

            // ── Activity Summary ──
            _buildActivityCard(),
            SizedBox(height: 24.h),

            // ── Top Users ──
            _buildTopUsersCard(),
            SizedBox(height: 24.h),

            // ── Lesson Stats ──
            _buildLessonStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem('Người dùng', _dashboard['totalUsers'] ?? 0, Icons.people_rounded, AppColors.primary, AppColors.primarySurface),
      _StatItem('Bài học', _dashboard['totalLessons'] ?? 0, Icons.menu_book_rounded, AppColors.violet, AppColors.violetSurface),
      _StatItem('Huy hiệu', _dashboard['totalBadges'] ?? 0, Icons.emoji_events_rounded, AppColors.secondary, AppColors.secondarySurface),
      _StatItem('Nhiệm vụ', _dashboard['totalMissions'] ?? 0, Icons.flag_rounded, AppColors.tertiary, AppColors.tertiarySurface),
      _StatItem('Game đã chơi', _dashboard['totalGames'] ?? 0, Icons.sports_esports_rounded, AppColors.coral, AppColors.coralSurface),
      _StatItem('Đăng ký tuần', _dashboard['recentSignups'] ?? 0, Icons.person_add_rounded, AppColors.primaryLight, AppColors.primarySurface),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: AppColors.cardShadowList,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w, height: 40.w,
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(s.icon, color: s.color, size: 22.sp),
                  ),
                  const Spacer(),
                  Text(
                    '${s.value}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                    ),
                  ),
                ],
              ),
              Text(
                s.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard() {
    final activeToday = _dashboard['activeToday'] ?? 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w, height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoạt động hôm nay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$activeToday người dùng đang hoạt động',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersCard() {
    final topUsers = (_statistics['topUsers'] as List<dynamic>?) ?? [];
    if (topUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.secondary, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'Top 10 học sinh xuất sắc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...topUsers.asMap().entries.map((entry) {
            final i = entry.key;
            final user = entry.value as Map<String, dynamic>;
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 28.w,
                    child: Text(
                      i < 3 ? medals[i] : '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: i < 3 ? 18.sp : 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      (user['name'] ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Lv.${user['level'] ?? 1} · ⭐ ${user['stars'] ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${user['xp'] ?? 0} XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLessonStatsCard() {
    final lessonStats = (_statistics['lessonStats'] as List<dynamic>?) ?? [];
    if (lessonStats.isEmpty) return const SizedBox.shrink();

    final typeLabels = {
      'consonant': 'Phụ âm',
      'vowel': 'Nguyên âm',
      'spelling': 'Ghép vần',
      'closed_syllable': 'Vần đóng',
      'coeng': 'Chữ ghép',
      'vocabulary': 'Từ vựng',
      'sentence': 'Câu',
      'number': 'Số',
    };

    final typeColors = {
      'consonant': AppColors.violet,
      'vowel': AppColors.primary,
      'spelling': const Color(0xFF7F39FB),
      'closed_syllable': const Color(0xFF0084FF),
      'coeng': AppColors.primaryDark,
      'vocabulary': AppColors.tertiary,
      'sentence': AppColors.coral,
      'number': AppColors.secondary,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.violet, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'Bài học theo loại',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...lessonStats.map((stat) {
            final type = stat['_id']?.toString() ?? '';
            final count = (stat['count'] as num?)?.toInt() ?? 0;
            final label = typeLabels[type] ?? type;
            final color = typeColors[type] ?? AppColors.textSecondary;
            final maxCount = lessonStats.fold<int>(0, (max, s) {
              final c = (s['count'] as num?)?.toInt() ?? 0;
              return c > max ? c : max;
            });
            final ratio = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$count bài',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8.h,
                      backgroundColor: AppColors.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatItem(this.label, this.value, this.icon, this.color, this.bgColor);
}
