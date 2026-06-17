import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Dashboard Admin — Tổng quan hệ thống (Redesigned Premium UI)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _statistics = {};
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  void _initAnimationIfNeeded() {
    if (_pulseCtrl == null) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initAnimationIfNeeded();
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
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
    _initAnimationIfNeeded();
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0084FF)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF0084FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & Pulse Dot ──
              _buildHeader(),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Tổng quan hệ thống',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                'Dữ liệu realtime từ hệ thống KhmerKid',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnim!,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Thời gian thực',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem('Người dùng', _dashboard['totalUsers'] ?? 0, Icons.people_rounded, const Color(0xFF0084FF), const Color(0xFF0084FF).withValues(alpha: 0.08)),
      _StatItem('Bài học', _dashboard['totalLessons'] ?? 0, Icons.menu_book_rounded, AppColors.violet, AppColors.violetSurface),
      _StatItem('Huy hiệu', _dashboard['totalBadges'] ?? 0, Icons.emoji_events_rounded, AppColors.secondary, AppColors.secondarySurface),
      _StatItem('Nhiệm vụ', _dashboard['totalMissions'] ?? 0, Icons.flag_rounded, AppColors.tertiary, AppColors.tertiarySurface),
      _StatItem('Game đã chơi', _dashboard['totalGames'] ?? 0, Icons.sports_esports_rounded, AppColors.coral, AppColors.coralSurface),
      _StatItem('Đăng ký tuần', _dashboard['recentSignups'] ?? 0, Icons.person_add_rounded, const Color(0xFF00C6FF), const Color(0xFF0084FF).withValues(alpha: 0.08)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 1.45,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Stack(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: s.color.withValues(alpha: 0.12), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: s.color.withValues(alpha: 0.04),
                    blurRadius: 16.r,
                    offset: const Offset(0, 8),
                  ),
                  ...AppColors.cardShadowList,
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [s.color.withValues(alpha: 0.15), s.color.withValues(alpha: 0.03)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: s.color.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Icon(s.icon, color: s.color, size: 20.sp),
                      ),
                      Text(
                        '${s.value}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: s.color,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    s.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -8.w,
              top: -8.w,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.color.withValues(alpha: 0.02),
                ),
              ),
            ),
          ],
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
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFF4F46E5), // Primary dark Indigo
            Color(0xFF8B5CF6), // Purple
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            bottom: -20.w,
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.white.withValues(alpha: 0.07),
              size: 100.sp,
            ),
          ),
          Row(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 26),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoạt động hôm nay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '$activeToday',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'người dùng trực tuyến',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.stars_rounded, color: AppColors.secondary, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'Top 10 học sinh xuất sắc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          ...topUsers.asMap().entries.map((entry) {
            final i = entry.key;
            final user = entry.value as Map<String, dynamic>;
            final name = user['name'] ?? 'Học sinh';
            final level = user['level'] ?? 1;
            final stars = user['stars'] ?? 0;
            final xp = user['xp'] ?? 0;

            // Podium specific styles
            final isPodium = i < 3;
            Color cardBg = Colors.transparent;
            Color borderColor = Colors.transparent;
            Widget rankWidget;
            Color rankColor;
            double avatarSize = 18.r;

            if (i == 0) {
              cardBg = const Color(0xFFFFFBEB); // Amber light
              borderColor = const Color(0xFFFDE68A); // Amber border
              rankWidget = Text('🥇', style: TextStyle(fontSize: 22.sp));
              rankColor = const Color(0xFFD97706);
              avatarSize = 21.r;
            } else if (i == 1) {
              cardBg = const Color(0xFFF9FAFB); // Gray light
              borderColor = const Color(0xFFE5E7EB); // Gray border
              rankWidget = Text('🥈', style: TextStyle(fontSize: 20.sp));
              rankColor = const Color(0xFF4B5563);
              avatarSize = 19.r;
            } else if (i == 2) {
              cardBg = const Color(0xFFFFF7ED); // Orange light
              borderColor = const Color(0xFFFED7AA); // Orange border
              rankWidget = Text('🥉', style: TextStyle(fontSize: 20.sp));
              rankColor = const Color(0xFFEA580C);
              avatarSize = 19.r;
            } else {
              rankWidget = Text(
                '${i + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              );
              rankColor = AppColors.textSecondary;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(
                horizontal: isPodium ? 12.w : 6.w,
                vertical: isPodium ? 10.h : 8.h,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18.r),
                border: isPodium ? Border.all(color: borderColor, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32.w,
                    child: Center(child: rankWidget),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isPodium
                          ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 2.w)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: isPodium ? rankColor.withValues(alpha: 0.1) : const Color(0xFF0084FF).withValues(alpha: 0.08),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: (avatarSize - 4.r),
                          fontWeight: FontWeight.w800,
                          color: isPodium ? rankColor : const Color(0xFF0084FF),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isPodium ? 14.sp : 13.sp,
                            fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Cấp $level',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.star_rounded, color: Colors.amber, size: 13.sp),
                            SizedBox(width: 2.w),
                            Text(
                              '$stars',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPodium
                            ? [rankColor, rankColor.withValues(alpha: 0.8)]
                            : [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: (isPodium ? rankColor : AppColors.secondary).withValues(alpha: 0.2),
                          blurRadius: 8.r,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '$xp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
      'vowel': const Color(0xFF0084FF),
      'spelling': const Color(0xFF7F39FB),
      'closed_syllable': const Color(0xFF0084FF),
      'coeng': const Color(0xFF0054B3),
      'vocabulary': AppColors.tertiary,
      'sentence': AppColors.coral,
      'number': AppColors.secondary,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.pie_chart_rounded, color: AppColors.violet, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'Bài học theo loại',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
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

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$count bài',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Stack(
                    children: [
                      Container(
                        height: 8.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.75)],
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 4.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
