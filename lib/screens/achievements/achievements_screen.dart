import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/score_service.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../main_screen.dart';
import '../../l10n/app_localizations.dart';

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
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895771/khmerkid/badges/B%C6%B0%E1%BB%9Bc%20%C4%91%E1%BA%A7u%20ti%C3%AAn.png',
      done: false,
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Hoàn thành bài học đầu tiên của bé!',
    ),
    _Achievement(
      title: 'Nhà ngôn ngữ nhí',
      icon: Icons.auto_stories_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895799/khmerkid/badges/Nh%C3%A0%20ng%C3%B4n%20ng%E1%BB%AF%20nh%C3%AD.png',
      done: false,
      color: const Color(0xFF9C27B0),
      bgColor: const Color(0xFFF3E5F5),
      description: 'Học tập tích lũy đạt 50 điểm XP!',
    ),
    _Achievement(
      title: 'Bậc thầy phụ âm',
      icon: Icons.draw_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895774/khmerkid/badges/B%E1%BA%ADc%20th%E1%BA%A7y%20ph%E1%BB%A5%20%C3%A2m.png',
      done: false,
      color: const Color(0xFFFFB300),
      bgColor: const Color(0xFFFFF8E1),
      description: 'Đạt trình độ viết phụ âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Khám phá nguyên âm',
      icon: Icons.menu_book_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895793/khmerkid/badges/Kh%C3%A1m%20ph%C3%A1%20nguy%C3%AAn%20%C3%A2m.png',
      done: false,
      color: const Color(0xFF2196F3),
      bgColor: const Color(0xFFE3F2FD),
      description: 'Đạt trình độ đọc nguyên âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Vua nguyên âm',
      icon: Icons.explore_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895814/khmerkid/badges/Vua%20nguy%C3%AAn%20%C3%A2m.png',
      done: false,
      color: const Color(0xFF009688),
      bgColor: const Color(0xFFE0F2F1),
      description: 'Xuất sắc đạt trình độ đọc nguyên âm cấp độ 2.',
    ),
    _Achievement(
      title: 'Chính tả giỏi',
      icon: Icons.draw_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895778/khmerkid/badges/Ch%C3%ADnh%20t%E1%BA%A3%20gi%E1%BB%8Fi.png',
      done: false,
      color: const Color(0xFF3F51B5),
      bgColor: const Color(0xFFE8EAF6),
      description: 'Đạt trình độ viết phụ âm cấp độ 2.',
    ),
    _Achievement(
      title: 'Phát âm chuẩn',
      icon: Icons.record_voice_over_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895802/khmerkid/badges/Ph%C3%A1t%20%C3%A2m%20chu%E1%BA%A9n.png',
      done: false,
      color: const Color(0xFFE91E63),
      bgColor: const Color(0xFFFCE4EC),
      description: 'Đạt trình độ nói phát âm cấp độ 1.',
    ),
    _Achievement(
      title: 'Tai thính',
      icon: Icons.hearing_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895809/khmerkid/badges/Tai%20th%C3%ADnh.png',
      done: false,
      color: const Color(0xFF1E88E5),
      bgColor: const Color(0xFFEBF4FF),
      description: 'Đạt trình độ nghe tiếng Khmer cấp độ 1.',
    ),
    _Achievement(
      title: 'Viết chữ đẹp',
      icon: Icons.draw_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895813/khmerkid/badges/Vi%E1%BA%BFt%20ch%E1%BB%AF%20%C4%91%E1%BA%B9p.png',
      done: false,
      color: const Color(0xFF00BCD4),
      bgColor: const Color(0xFFE0F7FA),
      description: 'Đạt trình độ viết Khmer cấp độ 3.',
    ),
    _Achievement(
      title: 'Ngôi sao đầu tiên',
      icon: Icons.star_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895798/khmerkid/badges/Ng%C3%B4i%20sao%20%C4%91%E1%BA%A7u%20ti%C3%AAn.png',
      done: false,
      color: const Color(0xFFFFC107),
      bgColor: const Color(0xFFFFF8E1),
      description: 'Tích lũy được 15 ngôi sao danh giá đầu tiên.',
    ),
    _Achievement(
      title: 'Sao sáng',
      icon: Icons.wb_twilight_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895806/khmerkid/badges/Sao%20s%C3%A1ng.png',
      done: false,
      color: const Color(0xFF03A9F4),
      bgColor: const Color(0xFFE1F5FE),
      description: 'Tích lũy được tổng cộng 50 ngôi sao lấp lánh.',
    ),
    _Achievement(
      title: 'Siêu sao',
      icon: Icons.military_tech_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895808/khmerkid/badges/Si%C3%AAu%20sao.png',
      done: false,
      color: const Color(0xFF7C4DFF),
      bgColor: const Color(0xFFEDE7F6),
      description: 'Sở hữu 150 ngôi sao rực rỡ lấp lánh bầu trời.',
    ),
    _Achievement(
      title: 'Chăm chỉ',
      icon: Icons.local_fire_department_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895781/khmerkid/badges/Ch%C4%83m%20ch%E1%BB%89.png',
      done: false,
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      description: 'Đạt chuỗi học tập liên tục 2 ngày.',
    ),
    _Achievement(
      title: 'Kiên trì',
      icon: Icons.calendar_month_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895795/khmerkid/badges/Ki%C3%AAn%20tr%C3%AC.png',
      done: false,
      color: const Color(0xFFFF8F00),
      bgColor: const Color(0xFFFFF3CD),
      description: 'Duy trì chuỗi học tập bền bỉ liên tục 7 ngày.',
    ),
    _Achievement(
      title: 'Game thủ nhí',
      icon: Icons.sports_esports_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895785/khmerkid/badges/Game%20th%E1%BB%A7%20nh%C3%AD.png',
      done: false,
      color: const Color(0xFF00E5FF),
      bgColor: const Color(0xFFE0F7FA),
      description: 'Chơi hoàn thành 5 trò chơi học tập bổ ích.',
    ),
    _Achievement(
      title: 'Vô địch mini game',
      icon: Icons.emoji_events_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895816/khmerkid/badges/V%C3%B4%20%C4%91%E1%BB%8Bch%20mini%20game.png',
      done: false,
      color: const Color(0xFFD32F2F),
      bgColor: const Color(0xFFFFEBEE),
      description: 'Xuất sắc hoàn thành 20 trò chơi bổ ích.',
    ),
    _Achievement(
      title: 'Tốc độ ánh sáng',
      icon: Icons.flash_on_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895811/khmerkid/badges/T%E1%BB%91c%20%C4%91%E1%BB%99%20%C3%A1nh%20s%C3%A1ng.png',
      done: false,
      color: const Color(0xFF7C4DFF),
      bgColor: const Color(0xFFEDE7F6),
      description: 'Duy trì chuỗi học tập liên tục 15 ngày.',
    ),
    _Achievement(
      title: 'Hoàn hảo',
      icon: Icons.verified_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895787/khmerkid/badges/Ho%C3%A0n%20h%E1%BA%A3o.png',
      done: false,
      color: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFE8F5E9),
      description: 'Hoàn thành xuất sắc 15 bài học.',
    ),
    _Achievement(
      title: 'Nhà vô địch',
      icon: Icons.workspace_premium_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895801/khmerkid/badges/Nh%C3%A0%20v%C3%B4%20%C4%91%E1%BB%8Bch.png',
      done: false,
      color: const Color(0xFFFF5722),
      bgColor: const Color(0xFFFBE9E7),
      description: 'Hoàn thành xuất sắc 30 bài học.',
    ),
    _Achievement(
      title: 'Bậc thầy Khmer',
      icon: Icons.school_rounded,
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895773/khmerkid/badges/B%E1%BA%ADc%20th%E1%BA%A7y%20Khmer.png',
      done: false,
      color: const Color(0xFF651FFF),
      bgColor: const Color(0xFFEDE7F6),
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
        backgroundColor: const Color(0xFFF3F7FA),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final bool useFallback = _backendBadges.isEmpty;
    final int done = useFallback
        ? _fallbackAchievements.where((a) {
            final req = _getFallbackReqInfo(a.title);
            final String reqType = req['type'] ?? 'unknown';
            final int target = req['value'] ?? 20;
            final int current = _getCurrentProgress(reqType);
            return current >= target;
          }).length
        : _backendBadges.where((b) => _unlockedBadgeIds.contains(b['_id']?.toString())).length;
    final int total = useFallback ? _fallbackAchievements.length : _backendBadges.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
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
                            context.translate('achievements.title'),
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

          // ═══ BADGE GRID ═══
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.68,
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

  // Helper to calculate progress dynamically based on badge requirement type
  int _getCurrentProgress(String reqType) {
    if (_score == null) return 0;
    switch (reqType) {
      case 'lessons_complete':
        return _score!.totalLessonsCompleted;
      case 'xp_total':
        return _score!.totalXp;
      case 'writing_level':
        return _score!.writingLevel;
      case 'reading_level':
        return _score!.readingLevel;
      case 'speaking_level':
        return _score!.speakingLevel;
      case 'listening_level':
        return _score!.listeningLevel;
      case 'stars_total':
        return _score!.totalStars;
      case 'streak_days':
        return _score!.streak;
      case 'games_played':
        return _score!.totalGamesPlayed;
      case 'level_reach':
        return _score!.level;
      default:
        return 0;
    }
  }

  // Helper to map fallback badges to their requirements
  Map<String, dynamic> _getFallbackReqInfo(String title) {
    switch (title) {
      case 'Bước đầu tiên':
        return {'type': 'lessons_complete', 'value': 1};
      case 'Nhà ngôn ngữ nhí':
        return {'type': 'xp_total', 'value': 50};
      case 'Bậc thầy phụ âm':
        return {'type': 'writing_level', 'value': 1};
      case 'Khám phá nguyên âm':
        return {'type': 'reading_level', 'value': 1};
      case 'Vua nguyên âm':
        return {'type': 'reading_level', 'value': 2};
      case 'Chính tả giỏi':
        return {'type': 'writing_level', 'value': 2};
      case 'Phát âm chuẩn':
        return {'type': 'speaking_level', 'value': 1};
      case 'Tai thính':
        return {'type': 'listening_level', 'value': 1};
      case 'Viết chữ đẹp':
        return {'type': 'writing_level', 'value': 3};
      case 'Ngôi sao đầu tiên':
        return {'type': 'stars_total', 'value': 15};
      case 'Sao sáng':
        return {'type': 'stars_total', 'value': 50};
      case 'Siêu sao':
        return {'type': 'stars_total', 'value': 150};
      case 'Chăm chỉ':
        return {'type': 'streak_days', 'value': 2};
      case 'Kiên trì':
        return {'type': 'streak_days', 'value': 7};
      case 'Game thủ nhí':
        return {'type': 'games_played', 'value': 5};
      case 'Vô địch mini game':
        return {'type': 'games_played', 'value': 20};
      case 'Tốc độ ánh sáng':
        return {'type': 'streak_days', 'value': 15};
      case 'Hoàn hảo':
        return {'type': 'lessons_complete', 'value': 15};
      case 'Nhà vô địch':
        return {'type': 'lessons_complete', 'value': 30};
      case 'Bậc thầy Khmer':
        return {'type': 'level_reach', 'value': 20};
      default:
        return {'type': 'unknown', 'value': 1};
    }
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
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
                  context.translate('achievements.progress_title'),
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
              child: Text(
                context.translatePlural('achievements.achievements_remaining', remaining),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  height: 1.3,
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

    final reqMap = badge['requirement'] as Map?;
    final String reqType = reqMap?['type']?.toString() ?? 'unknown';
    final int target = (reqMap?['value'] as num?)?.toInt() ?? 20;
    final current = _getCurrentProgress(reqType);
    final bool isUnlocked = _unlockedBadgeIds.contains(id) || (current >= target);

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

    return GestureDetector(
      onTap: () {
        _showBadgeDetailDialog(name, description, isUnlocked, accentColor, iconUrl, fallbackIcon);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Badge Icon
            SizedBox(
              width: 60.w,
              height: 60.w,
              child: isUnlocked
                  ? (iconUrl.isNotEmpty
                      ? (iconUrl.startsWith('http')
                          ? Image.network(
                              AuthService.getOptimizedImageUrl(iconUrl, width: 150),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildIconCircle(fallbackIcon, accentColor, bgColor),
                            )
                          : Image.asset(
                              iconUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildIconCircle(fallbackIcon, accentColor, bgColor),
                            ))
                      : _buildIconCircle(fallbackIcon, accentColor, bgColor))
                  : _buildIconCircle(Icons.lock_rounded, const Color(0xFF94A3B8), const Color(0xFFF1F5F9), borderColor: const Color(0xFFE2E8F0)),
            ),
            SizedBox(height: 6.h),
            // Title
            Expanded(
              child: Center(
                child: Text(
                  context.translateBadgeName(name),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Status Indicator
            isUnlocked
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF4CAF50), size: 11.sp),
                      SizedBox(width: 2.w),
                      Text(
                        context.translate('achievements.unlocked'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '$current/$target',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FALLBACK BADGE ITEM
  // ══════════════════════════════════════════════════════════════
  Widget _buildFallbackBadge(_Achievement a) {
    final req = _getFallbackReqInfo(a.title);
    final String reqType = req['type'] ?? 'unknown';
    final int target = req['value'] ?? 20;
    final int current = _getCurrentProgress(reqType);
    final bool isUnlocked = current >= target;

    final Color accentColor = a.color;
    final Color bgColor = a.bgColor;

    return GestureDetector(
      onTap: () {
        _showBadgeDetailDialog(a.title, a.description, isUnlocked, accentColor, a.imagePath, a.icon);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Badge Icon
            SizedBox(
              width: 60.w,
              height: 60.w,
              child: isUnlocked
                  ? (a.imagePath.isNotEmpty
                      ? (a.imagePath.startsWith('http')
                          ? Image.network(
                              a.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildIconCircle(a.icon, accentColor, bgColor),
                            )
                          : Image.asset(
                              a.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildIconCircle(a.icon, accentColor, bgColor),
                            ))
                      : _buildIconCircle(a.icon, accentColor, bgColor))
                  : _buildIconCircle(Icons.lock_rounded, const Color(0xFF94A3B8), const Color(0xFFF1F5F9), borderColor: const Color(0xFFE2E8F0)),
            ),
            SizedBox(height: 6.h),
            // Title
            Expanded(
              child: Center(
                child: Text(
                  context.translateBadgeName(a.title),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Status Indicator
            isUnlocked
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF4CAF50), size: 11.sp),
                      SizedBox(width: 2.w),
                      Text(
                        context.translate('achievements.unlocked'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '$current/$target',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DETAIL DIALOG
  // ══════════════════════════════════════════════════════════════
  Widget _buildIconCircle(IconData icon, Color iconColor, Color bg, {Color? borderColor, double? iconSize}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: borderColor ?? iconColor.withValues(alpha: 0.25),
          width: 1.5.w,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? (icon == Icons.lock_rounded ? 24.sp : 30.sp), color: iconColor),
    );
  }

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
              SizedBox(
                width: 130.w,
                height: 130.w,
                child: isUnlocked
                    ? (iconUrl.isNotEmpty
                        ? (iconUrl.startsWith('http')
                            ? Image.network(
                                AuthService.getOptimizedImageUrl(iconUrl, width: 250),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildIconCircle(fallbackIcon, accentColor, accentColor.withValues(alpha: 0.12), iconSize: 64.sp),
                              )
                            : Image.asset(
                                iconUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildIconCircle(fallbackIcon, accentColor, accentColor.withValues(alpha: 0.12), iconSize: 64.sp),
                              ))
                        : _buildIconCircle(fallbackIcon, accentColor, accentColor.withValues(alpha: 0.12), iconSize: 64.sp))
                    : _buildIconCircle(Icons.lock_rounded, const Color(0xFF94A3B8), const Color(0xFFF1F5F9), borderColor: const Color(0xFFE2E8F0), iconSize: 56.sp),
              ),
              SizedBox(height: 20.h),
              // Badge Name
              Text(
                context.translateBadgeName(name),
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
                  context.translate(isUnlocked ? 'achievements.unlocked_status' : 'achievements.locked_status'),
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
                context.translateBadgeDesc(name, description),
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
                    context.translate('common.close'),
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
  final String imagePath;
  final bool done;
  final Color color;
  final Color bgColor;
  final String description;

  const _Achievement({
    required this.title,
    required this.icon,
    required this.imagePath,
    required this.done,
    required this.color,
    required this.bgColor,
    required this.description,
  });
}
