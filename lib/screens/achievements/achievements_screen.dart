import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/score_service.dart';
import '../../constants/app_colors.dart';
import '../main_screen.dart';

/// Màn hình Thành tích — Grid badge tròn
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  ScoreService? _score;
  bool _loading = true;

  static final List<_Achievement> _achievements = [
    _Achievement(
      title: 'Bước đầu tiên',
      icon: Icons.rocket_launch_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
    ),
    _Achievement(
      title: 'Đã vẽ đẹp',
      icon: Icons.draw_rounded,
      done: false,
      color: const Color(0xFFE91E63),
      bgColor: const Color(0xFFFCE4EC),
    ),
    _Achievement(
      title: 'Đọc chăm chỉ',
      icon: Icons.menu_book_rounded,
      done: false,
      color: const Color(0xFF2196F3),
      bgColor: const Color(0xFFE3F2FD),
    ),
    _Achievement(
      title: 'Ngôi sao\nsáng',
      icon: Icons.star_rounded,
      done: false,
      color: const Color(0xFFFFCA28),
      bgColor: const Color(0xFFFFF8E1),
    ),
    _Achievement(
      title: 'Khám phá\nthế giới',
      icon: Icons.public_rounded,
      done: false,
      color: const Color(0xFF00BCD4),
      bgColor: const Color(0xFFE0F7FA),
    ),
    _Achievement(
      title: 'Vui học\nToán',
      icon: Icons.calculate_rounded,
      done: false,
      color: const Color(0xFF9C27B0),
      bgColor: const Color(0xFFF3E5F5),
    ),
    _Achievement(
      title: 'Ngoan\nlễ phép',
      icon: Icons.emoji_people_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
    ),
    _Achievement(
      title: 'Chăm chỉ\nhọc',
      icon: Icons.abc_rounded,
      done: false,
      color: const Color(0xFF42A5F5),
      bgColor: const Color(0xFFE3F2FD),
    ),
    _Achievement(
      title: 'Nghệ sĩ nhí',
      icon: Icons.palette_rounded,
      done: false,
      color: const Color(0xFFFF5722),
      bgColor: const Color(0xFFFBE9E7),
    ),
    _Achievement(
      title: 'Siêu nhắn\ntài xíu',
      icon: Icons.shield_rounded,
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
    ),
    _Achievement(
      title: 'Học mỗi\nngày',
      icon: Icons.calendar_today_rounded,
      done: false,
      color: const Color(0xFF3F51B5),
      bgColor: const Color(0xFFE8EAF6),
    ),
    _Achievement(
      title: 'Đồng hành',
      icon: Icons.volunteer_activism_rounded,
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
    ),
    _Achievement(
      title: 'Nhà bác học',
      icon: Icons.biotech_rounded,
      done: false,
      color: const Color(0xFF607D8B),
      bgColor: const Color(0xFFECEFF1),
    ),
    _Achievement(
      title: 'Tiến độ\nthần tốc',
      icon: Icons.speed_rounded,
      done: false,
      color: const Color(0xFF795548),
      bgColor: const Color(0xFFEFEBE9),
    ),
    _Achievement(
      title: 'Diễn đạt tốt',
      icon: Icons.record_voice_over_rounded,
      done: false,
      color: const Color(0xFF009688),
      bgColor: const Color(0xFFE0F2F1),
    ),
    _Achievement(
      title: 'Đạt mốc lớn',
      icon: Icons.flag_rounded,
      done: false,
      color: const Color(0xFFE53935),
      bgColor: const Color(0xFFFFEBEE),
    ),
    _Achievement(
      title: 'Nghỉ xả hơi',
      icon: Icons.self_improvement_rounded,
      done: false,
      color: const Color(0xFF8BC34A),
      bgColor: const Color(0xFFF1F8E9),
    ),
    _Achievement(
      title: 'Siêu nhẫn\nkiên trì',
      icon: Icons.timer_rounded,
      done: false,
      color: const Color(0xFF757575),
      bgColor: const Color(0xFFF5F5F5),
    ),
    _Achievement(
      title: 'Học hỏi\nmỗi ngày',
      icon: Icons.auto_stories_rounded,
      done: false,
      color: const Color(0xFF5D4037),
      bgColor: const Color(0xFFEFEBE9),
    ),
    _Achievement(
      title: 'Đồng lòng',
      icon: Icons.handshake_rounded,
      done: false,
      color: const Color(0xFF455A64),
      bgColor: const Color(0xFFECEFF1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _score = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _achievements[0] = _achievements[0].copyWith(done: _score!.lettersLearned >= 1);
        _achievements[1] = _achievements[1].copyWith(done: _score!.lettersLearned >= 3);
        _achievements[2] = _achievements[2].copyWith(done: _score!.readingLearned >= 1);
        _achievements[3] = _achievements[3].copyWith(done: _score!.totalStars >= 15);
        _achievements[4] = _achievements[4].copyWith(done: _score!.vocabLearned >= 2);
        _achievements[5] = _achievements[5].copyWith(done: _score!.totalXp >= 50);
        _achievements[6] = _achievements[6].copyWith(done: _score!.streak >= 2);
        _achievements[7] = _achievements[7].copyWith(done: _score!.lettersLearned >= 10);
        _achievements[8] = _achievements[8].copyWith(done: _score!.lettersLearned >= 5);
        _achievements[9] = _achievements[9].copyWith(done: _score!.isAchievementUnlocked('perfect_test') || _score!.avgTestScore >= 90);
        _achievements[10] = _achievements[10].copyWith(done: _score!.streak >= 1);
        _achievements[11] = _achievements[11].copyWith(done: _score!.totalXp >= 100);
        _achievements[12] = _achievements[12].copyWith(done: _score!.totalTests >= 10 || _score!.isAchievementUnlocked('test_10'));
        _achievements[13] = _achievements[13].copyWith(done: _score!.totalMedals >= 5);
        _achievements[14] = _achievements[14].copyWith(done: _score!.vocabLearned >= 5);
        _achievements[15] = _achievements[15].copyWith(done: _score!.lettersLearned >= 33 || _score!.isAchievementUnlocked('all_consonants'));
        _achievements[16] = _achievements[16].copyWith(done: _score!.totalXp >= 80);
        _achievements[17] = _achievements[17].copyWith(done: _score!.streak >= 5 || _score!.isAchievementUnlocked('streak_5'));
        _achievements[18] = _achievements[18].copyWith(done: _score!.totalXp >= 150);
        _achievements[19] = _achievements[19].copyWith(done: _score!.purchasedItems.isNotEmpty);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFD6E9F8),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final done = _achievements.where((a) => a.done).length;
    final total = _achievements.length;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E9F8),
      body: Column(
        children: [
          // ═══ GRADIENT HEADER ═══
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.r),
                bottomRight: Radius.circular(28.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Image.asset(
                          'image/cúp hồ sơ.png',
                          width: 28.w,
                          height: 28.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Thành tích',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Hình Voi tràn ra ngoài
                Positioned(
                  right: 20.w,
                  bottom: -6.h,
                  child: Image.asset(
                    'image/Voi thành tích.png',
                    width: 105.w,
                    height: 105.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // ═══ TROPHY CARD ═══
          _buildTrophyHeader(done, total),

          // ═══ BADGE GRID ═══
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.7,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildBadge(_achievements[index]);
              },
            ),
          ),
        ],
      ),
      // ═══ BOTTOM NAV BAR ═══
      extendBody: false,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TROPHY HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildTrophyHeader(int done, int total) {
    final remaining = total - done;
    final progress = done / total;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 30.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medal
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE082), Color(0xFFFFA726)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.25),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            padding: EdgeInsets.all(3.w),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Image.asset(
                'image/cúp hồ sơ.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Progress info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiến độ của bạn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text('/$total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF1F7),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Motivation text
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(text: 'Còn '),
                    TextSpan(
                      text: '$remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const TextSpan(text: ' thành tích nữa để hoàn thành!'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BADGE ITEM
  // ══════════════════════════════════════════════════════════════
  Widget _buildBadge(_Achievement a) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular badge
        Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: a.done
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC0C0C0), Color(0xFF9E9E9E)],
                  ),
            boxShadow: [
              BoxShadow(
                color: a.done
                    ? const Color(0xFFFFA000).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(4.w),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.done ? a.bgColor : const Color(0xFFE0E0E0),
              border: Border.all(
                color: a.done
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.3),
                width: 2.w,
              ),
            ),
            child: a.done
                ? Icon(a.icon, size: 30.sp, color: a.color)
                : Icon(
                    Icons.lock_rounded,
                    size: 22.sp,
                    color: const Color(0xFFB0B0B0),
                  ),
          ),
        ),
        SizedBox(height: 6.h),
        // Label
        Text(
          a.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: a.done ? const Color(0xFF37474F) : const Color(0xFF9E9E9E),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
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
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            Navigator.pop(context);
            final mainState = MainScreenState.of(context);
            if (mainState != null) mainState.switchTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.navInactive,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.home_outlined, size: 26.sp),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.home_rounded, size: 26.sp),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.school_outlined, size: 26.sp),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.school_rounded, size: 26.sp),
              ),
              label: 'Học',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.sports_esports_outlined, size: 26.sp),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.sports_esports_rounded, size: 26.sp),
              ),
              label: 'Chơi',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.person_outline_rounded, size: 26.sp),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.person_rounded, size: 26.sp),
              ),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement {
  final String title;
  final IconData icon;
  final bool done;
  final Color color;
  final Color bgColor;

  const _Achievement({
    required this.title,
    required this.icon,
    required this.done,
    required this.color,
    required this.bgColor,
  });

  _Achievement copyWith({bool? done}) {
    return _Achievement(
      title: title,
      icon: icon,
      color: color,
      bgColor: bgColor,
      done: done ?? this.done,
    );
  }
}
