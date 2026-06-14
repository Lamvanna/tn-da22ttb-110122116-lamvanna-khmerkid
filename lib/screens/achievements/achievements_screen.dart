import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/score_service.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../main_screen.dart';

/// Màn hình Thành tích — Grid badge tròn động 100% từ MongoDB
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  ScoreService? _score;
  bool _loading = true;
  List<dynamic> _backendBadges = [];
  Set<String> _unlockedBadgeIds = {};

  static final List<_Achievement> _fallbackAchievements = [
    _Achievement(
      title: 'Bước đầu tiên',
      icon: Icons.rocket_launch_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Hoàn thành bài học đầu tiên của bé!',
    ),
    _Achievement(
      title: 'Nhà ngôn ngữ nhí',
      icon: Icons.auto_stories_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Học tập tích lũy đạt 50 điểm XP!',
    ),
    _Achievement(
      title: 'Bậc thầy phụ âm',
      icon: Icons.draw_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Đạt trình độ viết phụ âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Khám phá nguyên âm',
      icon: Icons.menu_book_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Đạt trình độ đọc nguyên âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Vua nguyên âm',
      icon: Icons.explore_rounded,
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      description: 'Xuất sắc đạt trình độ đọc nguyên âm cấp độ 2.',
    ),
    _Achievement(
      title: 'Chính tả giỏi',
      icon: Icons.draw_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Đạt trình độ viết phụ âm cấp độ 2.',
    ),
    _Achievement(
      title: 'Phát âm chuẩn',
      icon: Icons.record_voice_over_rounded,
      done: false,
      color: const Color(0xFFFF5722),
      bgColor: const Color(0xFFFBE9E7),
      description: 'Đạt trình độ nói phát âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Tai thính',
      icon: Icons.hearing_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Đạt trình độ nghe tiếng Khmer cấp độ 1.',
    ),
    _Achievement(
      title: 'Viết chữ đẹp',
      icon: Icons.draw_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Đạt trình độ viết Khmer cấp độ 3.',
    ),
    _Achievement(
      title: 'Ngôi sao đầu tiên',
      icon: Icons.star_rounded,
      done: false,
      color: const Color(0xFFFFCA28),
      bgColor: const Color(0xFFFFF8E1),
      description: 'Tích lũy được 15 ngôi sao danh giá đầu tiên.',
    ),
    _Achievement(
      title: 'Sao sáng',
      icon: Icons.wb_twilight_rounded,
      done: false,
      color: const Color(0xFFFFCA28),
      bgColor: const Color(0xFFFFF8E1),
      description: 'Tích lũy được tổng cộng 50 ngôi sao lấp lánh.',
    ),
    _Achievement(
      title: 'Siêu sao',
      icon: Icons.military_tech_rounded,
      done: false,
      color: const Color(0xFFFFCA28),
      bgColor: const Color(0xFFFFF8E1),
      description: 'Sở hữu 150 ngôi sao rực rỡ lấp lánh bầu trời.',
    ),
    _Achievement(
      title: 'Chăm chỉ',
      icon: Icons.local_fire_department_rounded,
      done: false,
      color: const Color(0xFFE91E63),
      bgColor: const Color(0xFFFCE4EC),
      description: 'Đạt chuỗi học tập liên tục 2 ngày.',
    ),
    _Achievement(
      title: 'Kiên trì',
      icon: Icons.calendar_month_rounded,
      done: false,
      color: const Color(0xFFE91E63),
      bgColor: const Color(0xFFFCE4EC),
      description: 'Duy trì chuỗi học tập bền bỉ liên tục 7 ngày.',
    ),
    _Achievement(
      title: 'Game thủ nhí',
      icon: Icons.sports_esports_rounded,
      done: false,
      color: const Color(0xFF00E5FF),
      bgColor: const Color(0xFFE0F7FA),
      description: 'Chơi hoàn thành 5 trò chơi học tập bổ ích.',
    ),
    _Achievement(
      title: 'Vô địch mini game',
      icon: Icons.emoji_events_rounded,
      done: false,
      color: const Color(0xFF00E5FF),
      bgColor: const Color(0xFFE0F7FA),
      description: 'Xuất sắc hoàn thành 20 trò chơi bổ ích.',
    ),
    _Achievement(
      title: 'Tốc độ ánh sáng',
      icon: Icons.flash_on_rounded,
      done: false,
      color: const Color(0xFFE91E63),
      bgColor: const Color(0xFFFCE4EC),
      description: 'Duy trì chuỗi học tập liên tục 15 ngày.',
    ),
    _Achievement(
      title: 'Hoàn hảo',
      icon: Icons.verified_rounded,
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Hoàn thành xuất sắc 15 bài học.',
    ),
    _Achievement(
      title: 'Nhà vô địch',
      icon: Icons.workspace_premium_rounded,
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      description: 'Hoàn thành xuất sắc 30 bài học.',
    ),
    _Achievement(
      title: 'Bậc thầy Khmer',
      icon: Icons.school_rounded,
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      description: 'Đạt cấp độ 20, vươn tới danh hiệu Bậc thầy Khmer!',
    ),
  ];


  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _score = await ScoreService.getInstance();
    try {
      // 1. Tải danh sách tất cả các huy hiệu từ Backend MongoDB
      final badges = await AuthService().fetchBadges();
      
      // 2. Lấy danh sách ID các huy hiệu đã mở khóa của bé từ user profile
      final user = AuthService().userProfile;
      final userBadges = user?['badges'] as List<dynamic>? ?? [];
      final Set<String> unlockedIds = {};
      for (var b in userBadges) {
        if (b is Map) {
          unlockedIds.add(b['_id']?.toString() ?? '');
        } else {
          unlockedIds.add(b.toString());
        }
      }

      if (mounted) {
        setState(() {
          _backendBadges = badges;
          _unlockedBadgeIds = unlockedIds;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error initializing Achievements screen: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFD6E9F8),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final bool useFallback = _backendBadges.isEmpty;
    final int done = useFallback
        ? _fallbackAchievements.where((a) => a.done).length
        : _backendBadges.where((b) => _unlockedBadgeIds.contains(b['_id']?.toString())).length;
    final int total = useFallback ? _fallbackAchievements.length : _backendBadges.length;

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
                // Elephant Mascot (top right)
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
              itemCount: total,
              itemBuilder: (context, index) {
                if (useFallback) {
                  return _buildFallbackBadge(_fallbackAchievements[index]);
                } else {
                  return _buildDynamicBadge(_backendBadges[index]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TROPHY HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildTrophyHeader(int done, int total) {
    final remaining = total - done;
    final progress = total > 0 ? done / total : 0.0;
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
                Text(
                  'Tiến độ của bạn',
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
                    Text(
                      '$done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        '/$total',
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
                      widthFactor: progress.clamp(0.0, 1.0),
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
                    const TextSpan(text: ' thành tích nữa!'),
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
  // DYNAMIC BADGE ITEM (MongoDB Atlas data)
  // ══════════════════════════════════════════════════════════════
  Widget _buildDynamicBadge(Map<String, dynamic> badge) {
    final String id = badge['_id']?.toString() ?? '';
    final String name = badge['name']?.toString() ?? 'Huy chương';
    final String description = badge['description']?.toString() ?? '';
    final String iconUrl = badge['iconUrl']?.toString() ?? '';
    final String type = badge['type']?.toString() ?? 'learning';
    final bool isUnlocked = _unlockedBadgeIds.contains(id);

    // Dynamic colors based on badge type
    Color accentColor = const Color(0xFF7367D6);
    Color bgColor = const Color(0xFFF2F0FF);
    IconData fallbackIcon = Icons.stars_rounded;

    if (type == 'level') {
      accentColor = const Color(0xFFFF9800);
      bgColor = const Color(0xFFFFF3E0);
      fallbackIcon = Icons.rocket_launch_rounded;
    } else if (type == 'pronunciation') {
      accentColor = const Color(0xFFFF5722);
      bgColor = const Color(0xFFFBE9E7);
      fallbackIcon = Icons.record_voice_over_rounded;
    } else if (type == 'streak') {
      accentColor = const Color(0xFFE91E63);
      bgColor = const Color(0xFFFCE4EC);
      fallbackIcon = Icons.local_fire_department_rounded;
    } else if (type == 'learning') {
      accentColor = const Color(0xFF4CAF50);
      bgColor = const Color(0xFFE8F5E9);
      fallbackIcon = Icons.auto_stories_rounded;
    } else if (type == 'ranking') {
      accentColor = const Color(0xFFFFCA28);
      bgColor = const Color(0xFFFFF8E1);
      fallbackIcon = Icons.emoji_events_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular badge
        GestureDetector(
          onTap: () {
            _showBadgeDetailDialog(name, description, isUnlocked, accentColor, iconUrl, fallbackIcon);
          },
          child: Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isUnlocked
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: isUnlocked
                ? (iconUrl.isNotEmpty && iconUrl.startsWith('http')
                    ? ClipOval(
                        child: Image.network(
                          AuthService.getOptimizedImageUrl(iconUrl, width: 150),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(fallbackIcon, size: 30.sp, color: accentColor),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgColor,
                          border: Border.all(color: Colors.white, width: 2.w),
                        ),
                        child: Icon(fallbackIcon, size: 30.sp, color: accentColor),
                      ))
                : (iconUrl.isNotEmpty && iconUrl.startsWith('http')
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.network(
                                  AuthService.getOptimizedImageUrl(iconUrl, width: 150),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(fallbackIcon, size: 30.sp, color: const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE2E8F0),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 22.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      )),
          ),
        ),
        SizedBox(height: 6.h),
        // Label
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: isUnlocked ? const Color(0xFF334155) : const Color(0xFF94A3B8),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FALLBACK BADGE ITEM
  // ══════════════════════════════════════════════════════════════
  Widget _buildFallbackBadge(_Achievement a) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            _showBadgeDetailDialog(a.title, a.description, a.done, a.color, '', a.icon);
          },
          child: Container(
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
                      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: a.done
                      ? const Color(0xFFFFA000).withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            padding: EdgeInsets.all(4.w),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a.done ? a.bgColor : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: a.done
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.35),
                  width: 2.w,
                ),
              ),
              child: a.done
                  ? Icon(a.icon, size: 30.sp, color: a.color)
                  : Icon(
                      Icons.lock_rounded,
                      size: 22.sp,
                      color: const Color(0xFF94A3B8),
                    ),
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
            fontWeight: FontWeight.w700,
            color: a.done ? const Color(0xFF334155) : const Color(0xFF94A3B8),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DETAIL DIALOG
  // ══════════════════════════════════════════════════════════════
  void _showBadgeDetailDialog(
    String name,
    String description,
    bool isUnlocked,
    Color accentColor,
    String iconUrl,
    IconData fallbackIcon,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon stacked
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? accentColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isUnlocked ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                    width: 3.w,
                  ),
                ),
                padding: EdgeInsets.all(12.w),
                child: isUnlocked
                    ? ClipOval(
                        child: iconUrl.isNotEmpty && iconUrl.startsWith('http')
                            ? Image.network(
                                AuthService.getOptimizedImageUrl(iconUrl, width: 250),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(fallbackIcon, size: 48.sp, color: accentColor),
                              )
                            : Icon(fallbackIcon, size: 48.sp, color: accentColor),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        size: 44.sp,
                        color: const Color(0xFF94A3B8),
                      ),
              ),
              SizedBox(height: 20.h),
              // Badge Name
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              // Unlocked status chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFEDF8F2) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isUnlocked ? '🎉 Đã đạt được' : '🔒 Chưa mở khóa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? const Color(0xFF2D8054) : const Color(0xFFE11D48),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUnlocked ? accentColor : const Color(0xFF64748B),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  final String description;

  const _Achievement({
    required this.title,
    required this.icon,
    required this.done,
    required this.color,
    required this.bgColor,
    required this.description,
  });
}
