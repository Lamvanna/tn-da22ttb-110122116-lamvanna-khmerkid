import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/score_service.dart';
import '../achievements/achievements_screen.dart';
import '../shop/shop_screen.dart';
import '../profile/inventory_screen.dart';
import '../main_screen.dart';
import '../../l10n/app_localizations.dart';

/// Màn hình Nhiệm vụ — Header gradient + Điểm + Daily/Weekly + Thành tích
class DailyQuestScreen extends StatefulWidget {
  const DailyQuestScreen({super.key});
  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  late Timer _timer;
  Duration _dailyRemaining = Duration.zero;
  Duration _weeklyRemaining = Duration.zero;

  // ── Data ──
  final List<_DailyQuest> _dailyQuests = [
    _DailyQuest(
      id: 'mock_d1',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895800/khmerkid/badges/Nh%C3%A0%20th%C3%B4ng%20th%C3%A1i%20nh%C3%AD.png', title: 'Nhà thông thái nhí 📚',
      subtitle: 'Hoàn thành bài học mới bất kỳ',
      current: 0, total: 2, rewardXp: 60, rewardStars: 20,
      accentColor: const Color(0xFF1E88E5),
      action: 'complete_lesson',
    ),
    _DailyQuest(
      id: 'mock_d2',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895797/khmerkid/badges/Luy%E1%BB%87n%20vi%E1%BA%BFt%20ch%E1%BB%AF%20%C4%91%E1%BA%B9p.png', title: 'Luyện viết chữ đẹp ✍️',
      subtitle: 'Luyện viết chữ cái qua nhận diện viết tay',
      current: 0, total: 5, rewardXp: 70, rewardStars: 25,
      accentColor: const Color(0xFFE91E63),
      action: 'write_lesson',
    ),
    _DailyQuest(
      id: 'mock_d3',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895820/khmerkid/badges/%C4%90%C3%B4i%20tai%20nh%E1%BA%A1y%20b%C3%A9n.png', title: 'Đôi tai nhạy bén 🎧',
      subtitle: 'Luyện nghe phát âm và chọn đúng đáp án',
      current: 0, total: 5, rewardXp: 60, rewardStars: 20,
      accentColor: const Color(0xFF7C4DFF),
      action: 'listen_lesson',
    ),
  ];

  final List<_WeeklyQuest> _weeklyQuests = [
    _WeeklyQuest(
      id: 'mock_w1',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895777/khmerkid/badges/Chu%E1%BB%97i%20ng%C3%A0y%20v%C3%A0ng.png', title: 'Chuỗi ngày vàng 🔥',
      current: 0, total: 5, rewardXp: 500, rewardStars: 120,
      gradient: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
    ),
    _WeeklyQuest(
      id: 'mock_w2',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895821/khmerkid/badges/%C4%90%E1%BA%A1i%20s%E1%BB%A9%20v%E1%BB%B1ng.png', title: 'Đại sứ từ vựng 👑',
      current: 0, total: 15, rewardXp: 600, rewardStars: 180,
      gradient: const [Color(0xFF7C4DFF), Color(0xFF651FFF)],
    ),
    _WeeklyQuest(
      id: 'mock_w3',
      icon: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895775/khmerkid/badges/Cao%20th%E1%BB%A7%20tr%C3%B2%20ch%C6%A1i.png', title: 'Cao thủ trò chơi 🕹️',
      current: 0, total: 10, rewardXp: 500, rewardStars: 150,
      gradient: const [Color(0xFFE53935), Color(0xFFD32F2F)],
    ),
  ];

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
  ];

  ScoreService? _score;
  List<dynamic> _backendBadges = [];
  Set<String> _unlockedBadgeIds = {};
  // ignore: unused_field
  bool _loadingBadges = true;
  // ignore: unused_field
  bool _loadingMissions = true;

  int get _totalPoints {
    int pts = 0;
    for (final q in _dailyQuests) { if (q.done) pts += q.rewardStars; }
    for (final q in _weeklyQuests) { if (q.isClaimed) pts += q.rewardStars; }
    return pts;
  }

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_calcRemaining);
    });
    _loadMissions();
    AuthService().fetchProfile().then((_) {
      _loadAchievements();
    });
  }

  String _getEmoji(String title) {
    if (title.contains('Nhà thông thái nhí')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895800/khmerkid/badges/Nh%C3%A0%20th%C3%B4ng%20th%C3%A1i%20nh%C3%AD.png';
    if (title.contains('Luyện viết chữ đẹp')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895797/khmerkid/badges/Luy%E1%BB%87n%20vi%E1%BA%BFt%20ch%E1%BB%AF%20%C4%91%E1%BA%B9p.png';
    if (title.contains('Đôi tai nhạy bén')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895820/khmerkid/badges/%C4%90%C3%B4i%20tai%20nh%E1%BA%A1y%20b%C3%A9n.png';
    if (title.contains('Giọng ca oanh vàng')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895786/khmerkid/badges/Gi%E1%BB%8Dng%20ca%20oanh%20v%C3%A0ng.png';
    if (title.contains('Vừa học vừa chơi')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895817/khmerkid/badges/V%E1%BB%ABa%20h%E1%BB%8Dc%20v%E1%BB%ABa%20ch%C6%A1i.png';
    if (title.contains('Điểm số hoàn hảo')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895819/khmerkid/badges/%C4%90i%E1%BB%83m%20s%E1%BB%91%20ho%C3%A0n%20h%E1%BA%A3o.png';
    if (title.contains('Khởi đầu ngày mới')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895794/khmerkid/badges/Kh%E1%BB%9Fi%20%C4%91%E1%BA%A7u%20ng%C3%A0y%20m%E1%BB%9Bi.png';
    if (title.contains('Thợ săn sao vàng')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895806/khmerkid/badges/Sao%20s%C3%A1ng.png';
    if (title.contains('Trí nhớ siêu đỉnh')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895804/khmerkid/badges/Quy%E1%BB%83n%20s%C3%A1ch%20tri%20th%E1%BB%A9c%20ho%C3%A0ng%20gia.png';
    if (title.contains('Gặp gỡ bạn bè')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895801/khmerkid/badges/Nh%C3%A0%20v%C3%B4%20%C4%91%E1%BB%8Bch.png';
    
    if (title.contains('Chuỗi ngày vàng')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895777/khmerkid/badges/Chu%E1%BB%97i%20ng%C3%A0y%20v%C3%A0ng.png';
    if (title.contains('Đại sứ từ vựng') || title.contains('Đại sứ vựng')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895821/khmerkid/badges/%C4%90%E1%BA%A1i%20s%E1%BB%A9%20v%E1%BB%B1ng.png';
    if (title.contains('Cao thủ trò chơi')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895775/khmerkid/badges/Cao%20th%E1%BB%A7%20tr%C3%B2%20ch%C6%A1i.png';
    if (title.contains('Cơn mưa quà tặng')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895784/khmerkid/badges/C%C6%A1n%20m%C6%B0a%20qu%C3%A0%20t%E1%BA%B7ng.png';
    if (title.contains('Bàn tay khéo léo')) return 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895770/khmerkid/badges/B%C3%A0n%20tay%20kh%C3%A9o%20l%C3%A9o.png';

    // Fallbacks
    if (title.contains('☀️')) return '☀️';
    if (title.contains('🎧')) return '🎧';
    if (title.contains('🗣️') || title.contains('🗣')) return '🗣️';
    if (title.contains('✍️') || title.contains('✍')) return '✍️';
    if (title.contains('📖')) return '📖';
    if (title.contains('🎮')) return '🎮';
    if (title.contains('🎓')) return '🎓';
    if (title.contains('🏆')) return '🏆';
    if (title.contains('👑')) return '👑';
    if (title.contains('📣')) return '📣';
    if (title.contains('✒️') || title.contains('✒')) return '✒️';
    if (title.contains('📚')) return '📚';
    if (title.contains('✏️') || title.contains('✏')) return '✏️';
    if (title.contains('🎯')) return '🎯';
    return '🎁';
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;
    setState(() => _loadingMissions = true);

    try {
      final backendList = await AuthService().fetchMissions();
      if (backendList.isNotEmpty) {
        final List<_DailyQuest> daily = [];
        final List<_WeeklyQuest> weekly = [];

        for (var item in backendList) {
          final id = item['_id']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Nhiệm vụ';
          final desc = item['description']?.toString() ?? '';
          final type = item['type']?.toString() ?? 'daily';
          final current = item['progress'] as int? ?? 0;
          final total = item['requirement'] as int? ?? 1;
          final isCompleted = item['isCompleted'] as bool? ?? false;
          final isClaimed = item['isClaimed'] as bool? ?? false;
          
          final rewardMap = item['reward'] as Map?;
          final rewardXp = rewardMap?['xp'] as int? ?? 0;
          final rewardStars = rewardMap?['stars'] as int? ?? 0;
          
          final iconUrl = item['iconUrl']?.toString() ?? '';
          final icon = iconUrl.isNotEmpty ? iconUrl : _getEmoji(title);
          final action = item['action']?.toString() ?? '';

          if (type == 'daily') {
            Color accentColor = const Color(0xFF1E88E5);
            if (title.contains('Nghe') || title.contains('Tai')) accentColor = const Color(0xFF7C4DFF);
            else if (title.contains('Nói') || title.contains('Phát âm')) accentColor = const Color(0xFFFF9800);
            else if (title.contains('Viết') || title.contains('Vẽ')) accentColor = const Color(0xFFE91E63);
            else if (title.contains('Đọc')) accentColor = const Color(0xFF00BCD4);
            else if (title.contains('Chơi') || title.contains('Game')) accentColor = const Color(0xFF43A047);

            daily.add(_DailyQuest(
              id: id,
              icon: icon,
              title: title,
              subtitle: desc,
              current: current,
              total: total,
              rewardXp: rewardXp,
              rewardStars: rewardStars,
              accentColor: accentColor,
              action: action,
              done: isClaimed,
              isCompleted: isCompleted,
              isClaimed: isClaimed,
            ));
          } else {
            List<Color> gradient = const [Color(0xFFFFB300), Color(0xFFFF8F00)];
            final lowerTitle = title.toLowerCase();
            if (lowerTitle.contains('game') || lowerTitle.contains('trò chơi')) {
              gradient = const [Color(0xFFE53935), Color(0xFFD32F2F)];
            } else if (lowerTitle.contains('nói') || lowerTitle.contains('phát âm') || lowerTitle.contains('vựng')) {
              gradient = const [Color(0xFF7C4DFF), Color(0xFF651FFF)];
            } else if (lowerTitle.contains('viết') || lowerTitle.contains('chữ') || lowerTitle.contains('khéo léo')) {
              gradient = const [Color(0xFF00BCD4), Color(0xFF0097A7)];
            }

            weekly.add(_WeeklyQuest(
              id: id,
              icon: icon,
              title: title,
              current: current,
              total: total,
              rewardXp: rewardXp,
              rewardStars: rewardStars,
              gradient: gradient,
              isCompleted: isCompleted,
              isClaimed: isClaimed,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _dailyQuests.clear();
            _dailyQuests.addAll(daily);
            _weeklyQuests.clear();
            _weeklyQuests.addAll(weekly);
            _loadingMissions = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingMissions = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      if (mounted) {
        setState(() => _loadingMissions = false);
      }
    }
  }

  Future<void> _claimReward(String missionId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await AuthService().claimMissionReward(missionId);
      if (res['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.translate('tasks.claim_reward_success')),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
        await _loadMissions();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.translate('tasks.claim_reward_failed', args: {'message': res['message']})),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
    }
  }

  void _calcRemaining() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _dailyRemaining = endOfDay.difference(now);
    // Weekly: end of Sunday
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final endOfWeek = DateTime(now.year, now.month, now.day + (daysUntilSunday <= 0 ? 7 : daysUntilSunday), 23, 59, 59);
    _weeklyRemaining = endOfWeek.difference(now);
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 24) {
      final days = d.inDays;
      final timeStr = '${(h % 24).toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      return context.translate('tasks.time_remaining', args: {'days': days, 'time': timeStr});
    }
    final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return context.translate('tasks.update_in', args: {'time': timeStr});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsCard(),
                  SizedBox(height: 14.h),
                  _buildSectionHeader(context.translate('tasks.title'), '⏱ ${_formatDuration(_dailyRemaining)}'),
                  SizedBox(height: 10.h),
                  ...List.generate(
                    _dailyQuests.length,
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildDailyCard(_dailyQuests[i]),
                    ),
                  ),
                  SizedBox(height: 0),
                  _buildSectionHeader(context.translate('tasks.weekly_tasks'), '⏱ ${_formatWeekly(_weeklyRemaining)}'),
                  SizedBox(height: 14.h),
                  _buildWeeklyRow(),
                  SizedBox(height: 28.h),
                  _buildAchievementsSection(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeekly(Duration d) {
    final days = d.inDays;
    final h = d.inHours % 24;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return context.translate('tasks.time_remaining', args: {'days': days, 'time': timeStr});
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -30.w, top: -20.h,
            child: Container(width: 100.w, height: 100.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(left: -15.w, bottom: -10.h,
            child: Container(width: 60.w, height: 60.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          
          // ─── Center Title ───
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(80.w, 4.h, 80.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          context.translate('tasks.quests_header'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Back Button (Positioned Left) ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 10.w,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44.w,
                height: 44.w,
                alignment: Alignment.center,
                child: Container(
                  width: 32.w, height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18.w)),
              ),
            ),
          ),

          // ─── Stats (Positioned Right) ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 2.h,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Star Badge (Above)
                Container(
                  width: 64.w,
                  height: 28.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('image/sao.png', width: 14.w, height: 14.w, fit: BoxFit.contain),
                      SizedBox(width: 4.w),
                      Text('${_score?.totalStars ?? (AuthService().userProfile?['stars'] ?? 0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                    ]),
                ),
                SizedBox(height: 5.h),
                
                // Streak Badge (Below)
                Container(
                  width: 64.w,
                  height: 28.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('image/Lửa chuổi.png', width: 14.w, height: 14.w, fit: BoxFit.contain),
                      SizedBox(width: 4.w),
                      Text('${_score?.streak ?? (AuthService().userProfile?['streak'] ?? 0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                    ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ POINTS CARD ═══════════════════
  // ═══════════════════ POINTS CARD ═══════════════════
  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEBF4FF),
            Color(0xFFD6E9F8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color(0xFFB3D7FF).withValues(alpha: 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot / Gift image wrapper (Left side)
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.06),
                  blurRadius: 10.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'image/Hộp quà.png',
              width: 68.w,
              height: 68.w,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 14.w),
          // Title, claim button, and milestones (Right side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        context.translate('tasks.points_gift'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E6DEB),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildRewardBtn(),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildMilestones(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBtn() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ShopScreen()));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              context.translate('tasks.claim_gift_btn'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _milestoneCircle(250),
            Expanded(child: _milestoneLine(250)),
            _milestoneCircle(500),
            Expanded(child: _milestoneLine(500)),
            _milestoneCircle(1000),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _milestoneLabel(250),
            const Spacer(),
            _milestoneLabel(500),
            const Spacer(),
            _milestoneLabel(1000),
          ],
        ),
      ],
    );
  }

  Widget _milestoneCircle(int target) {
    final reached = _totalPoints >= target;
    return SizedBox(
      width: 42.w,
      height: 42.w,
      child: Center(
        child: AnimatedScale(
          scale: reached ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: reached ? const Color(0xFFEDF8F2) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: reached ? const Color(0xFF43A047) : const Color(0xFFE2E2F2),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: (reached ? const Color(0xFF43A047) : const Color(0xFF94A3B8)).withValues(alpha: 0.15),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Text(
              reached ? '🎉' : '🎁',
              style: TextStyle(fontSize: 18.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _milestoneLabel(int target) {
    final reached = _totalPoints >= target;
    return SizedBox(
      width: 42.w,
      child: Center(
        child: Text(
          '$target',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: reached ? const Color(0xFF43A047) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _milestoneLine(int target) {
    final reached = _totalPoints >= target;
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: reached ? const Color(0xFF43A047) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  // ═══════════════════ SECTION HEADER ═══════════════════
  Widget _buildSectionHeader(String title, String trailing) {
    return Row(children: [
      Text(title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.0)),
      const Spacer(),
      Text(trailing,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.0)),
    ]);
  }

  // ═══════════════════ DAILY QUEST CARD ═══════════════════
  Widget _buildDailyCard(_DailyQuest quest) {
    final progress = quest.total > 0 ? quest.current / quest.total : 0.0;
    final barColor = quest.done ? const Color(0xFF43A047) : quest.accentColor;
    return GestureDetector(
      onTap: quest.isClaimed ? null : () => _navigateForAction(quest),
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: quest.isClaimed
              ? const Color(0xFF43A047).withValues(alpha: 0.15)
              : (quest.isCompleted && !quest.isClaimed)
                  ? const Color(0xFFFFB300).withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: quest.accentColor.withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Enlarged Icon without circular border or background container
            SizedBox(
              width: 80.w,
              height: 80.w,
              child: Center(
                child: quest.icon.startsWith('http')
                    ? Image.network(
                        AuthService.getOptimizedImageUrl(quest.icon, width: 150),
                        width: 76.w,
                        height: 76.w,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          '🎁',
                          style: TextStyle(fontSize: 34.sp),
                        ),
                      )
                    : (quest.icon.contains('/') || quest.icon.endsWith('.png')
                        ? Image.asset(
                            quest.icon,
                            width: 76.w,
                            height: 76.w,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              '🎁',
                              style: TextStyle(fontSize: 34.sp),
                            ),
                          )
                        : Text(
                            quest.icon,
                            style: TextStyle(fontSize: 34.sp),
                          )),
              ),
            ),
            SizedBox(width: 14.w),
            // Title + subtitle + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translateQuestTitle(quest.title),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    context.translateQuestDesc(quest.title, quest.subtitle),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  // Thicker custom progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: quest.done
                                      ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                                      : [barColor.withValues(alpha: 0.65), barColor],
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: barColor.withValues(alpha: 0.20),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 1.h),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        '${quest.current}/${quest.total}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 14.w),
            // Reward / Action badge
            quest.isClaimed
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF66BB6A).withValues(alpha: 0.15),
                          const Color(0xFF43A047).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFF43A047).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 24.sp),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('image/sao.png', width: 14.w, height: 14.w, fit: BoxFit.contain),
                            SizedBox(width: 2.w),
                            Text(
                              '+${quest.rewardStars}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF43A047),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : (quest.isCompleted && !quest.isClaimed)
                    ? GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _claimReward(quest.id);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 16.sp),
                              SizedBox(width: 4.w),
                              Text(
                                context.translate('tasks.claim_btn'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('image/sao.png', width: 16.w, height: 16.w, fit: BoxFit.contain),
                            SizedBox(width: 3.w),
                            Text(
                              '+${quest.rewardStars}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF8F00),
                              ),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    ),
    );
  }

  /// Điều hướng đến màn hình tương ứng dựa trên loại nhiệm vụ
  void _navigateForAction(_DailyQuest quest) {
    HapticFeedback.lightImpact();
    final action = quest.action;

    // Nếu không có action, dựa vào title để xác định
    String resolvedAction = action;
    if (resolvedAction.isEmpty) {
      final t = quest.title.toLowerCase();
      if (t.contains('viết') || t.contains('vẽ') || t.contains('chữ')) {
        resolvedAction = 'write_lesson';
      } else if (t.contains('nghe') || t.contains('tai')) {
        resolvedAction = 'listen_lesson';
      } else if (t.contains('nói') || t.contains('phát âm') || t.contains('giọng')) {
        resolvedAction = 'speak_lesson';
      } else if (t.contains('đọc') || t.contains('sách')) {
        resolvedAction = 'read_lesson';
      } else if (t.contains('chơi') || t.contains('game') || t.contains('trò chơi')) {
        resolvedAction = 'play_game';
      } else {
        resolvedAction = 'complete_lesson';
      }
    }

    // Pop trang nhiệm vụ trước khi điều hướng
    Navigator.pop(context);

    switch (resolvedAction) {
      case 'complete_lesson':
      case 'write_lesson':
      case 'listen_lesson':
      case 'read_lesson':
      case 'speak_lesson':
        // Tất cả bài học → chuyển sang tab Học (index 1)
        MainScreenState.of(context)?.switchTab(1);
        break;
      case 'play_game':
        // Trò chơi → chuyển sang tab Chơi (index 2)
        MainScreenState.of(context)?.switchTab(2);
        break;
      case 'daily_login':
        // Không cần điều hướng - đã hoàn thành khi đăng nhập
        break;
      default:
        // Mặc định: chuyển sang tab Học
        MainScreenState.of(context)?.switchTab(1);
    }
  }

  // ═══════════════════ WEEKLY QUEST ROW ═══════════════════
  Widget _buildWeeklyRow() {
    return SizedBox(
      height: 245.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _weeklyQuests.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (_, i) => _buildWeeklyCard(_weeklyQuests[i]),
      ),
    );
  }

  Widget _buildWeeklyCard(_WeeklyQuest quest) {
    final progress = quest.total > 0 ? quest.current / quest.total : 0.0;
    final done = quest.current >= quest.total;
    return Container(
      width: 145.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: quest.gradient[0].withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: done
              ? const Color(0xFF43A047).withValues(alpha: 0.3)
              : quest.gradient[0].withValues(alpha: 0.15),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: quest.gradient[0].withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with support for network images (Cloudinary)
          SizedBox(
            width: 96.w,
            height: 96.w,
            child: Center(
              child: quest.icon.startsWith('http')
                  ? Image.network(
                      AuthService.getOptimizedImageUrl(quest.icon, width: 200),
                      width: 92.w,
                      height: 92.w,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        '🎁',
                        style: TextStyle(fontSize: 48.sp),
                      ),
                    )
                  : (quest.icon.contains('/') || quest.icon.endsWith('.png')
                      ? Image.asset(
                          quest.icon,
                          width: 92.w,
                          height: 92.w,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Text(
                            '🎁',
                            style: TextStyle(fontSize: 48.sp),
                          ),
                        )
                      : Text(
                          quest.icon,
                          style: TextStyle(fontSize: 48.sp),
                        )),
            ),
          ),
          SizedBox(height: 12.h),
          // Title
          SizedBox(
            height: 34.h,
            child: Center(
              child: Text(
                context.translateQuestTitle(quest.title),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Progress text & bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('home.today_progress').split(' ').last,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${quest.current}/${quest.total}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: done ? const Color(0xFF43A047) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            height: 8.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                        : quest.gradient,
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Reward pill / Button
          quest.isClaimed
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF8F2),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFF43A047).withValues(alpha: 0.2),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 12.sp),
                      SizedBox(width: 4.w),
                      Text(
                        context.translate('tasks.claimed_btn'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF43A047),
                        ),
                      ),
                    ],
                  ),
                )
              : (quest.isCompleted && !quest.isClaimed)
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _claimReward(quest.id);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 12.sp),
                            SizedBox(width: 4.w),
                            Text(
                              context.translate('tasks.claim_btn'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF5),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                          width: 1.2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.05),
                            blurRadius: 4.r,
                            offset: Offset(0, 1.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'image/sao.png',
                            width: 14.w,
                            height: 14.w,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '+${quest.rewardStars}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF8F00),
                            ),
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  // ═══════════════════ ACHIEVEMENTS ═══════════════════
  Widget _buildAchievementsSection() {
    return Column(
      children: [
        Row(children: [
          Text(context.translate('achievements.title'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AchievementsScreen()));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.15))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(context.translate('tasks.view_all'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E88E5))),
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right_rounded, color: const Color(0xFF1E88E5), size: 16.sp),
              ]),
            ),
          ),
        ]),
        SizedBox(height: 14.h),
        SizedBox(
          height: 172.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _backendBadges.isEmpty ? _fallbackAchievements.length : _backendBadges.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, i) => SizedBox(
              width: 110.w,
              child: _backendBadges.isEmpty
                  ? _buildFallbackAchievementTile(_fallbackAchievements[i])
                  : _buildDynamicAchievementTile(_backendBadges[i]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadAchievements() async {
    try {
      _score = await ScoreService.getInstance();
      final badges = await AuthService().fetchBadges();
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
          _loadingBadges = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading achievements in DailyQuestScreen: $e');
      if (mounted) {
        setState(() => _loadingBadges = false);
      }
    }
  }

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

  Widget _buildDynamicAchievementTile(Map<String, dynamic> badge) {
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

    return _buildAchievementTileLayout(
      title: name,
      subtitle: description,
      iconUrl: iconUrl,
      fallbackIcon: fallbackIcon,
      accentColor: accentColor,
      bgColor: bgColor,
      target: target,
      current: current,
      isUnlocked: isUnlocked,
    );
  }

  Widget _buildFallbackAchievementTile(_Achievement a) {
    final req = _getFallbackReqInfo(a.title);
    final String reqType = req['type'] ?? 'unknown';
    final int target = req['value'] ?? 20;
    final int current = _getCurrentProgress(reqType);
    final bool isUnlocked = current >= target;

    return _buildAchievementTileLayout(
      title: a.title,
      subtitle: a.description,
      iconUrl: a.imagePath,
      fallbackIcon: a.icon,
      accentColor: a.color,
      bgColor: a.bgColor,
      target: target,
      current: current,
      isUnlocked: isUnlocked,
    );
  }

  Widget _buildAchievementTileLayout({
    required String title,
    required String subtitle,
    required String iconUrl,
    required IconData fallbackIcon,
    required Color accentColor,
    required Color bgColor,
    required int target,
    required int current,
    required bool isUnlocked,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 14.h, 6.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 72.w,
            height: 72.w,
            child: Center(
              child: isUnlocked
                  ? (iconUrl.isNotEmpty
                      ? (iconUrl.startsWith('http')
                          ? Image.network(
                              AuthService.getOptimizedImageUrl(iconUrl, width: 150),
                              width: 68.w,
                              height: 68.w,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackCircle(fallbackIcon, accentColor, bgColor),
                            )
                          : Image.asset(
                              iconUrl,
                              width: 68.w,
                              height: 68.w,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackCircle(fallbackIcon, accentColor, bgColor),
                            ))
                      : _buildFallbackCircle(fallbackIcon, accentColor, bgColor))
                  : _buildFallbackCircle(Icons.lock_rounded, const Color(0xFF94A3B8), const Color(0xFFF1F5F9), borderColor: const Color(0xFFE2E8F0)),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            context.translateBadgeName(title),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            context.translateBadgeDesc(title, subtitle),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          // Status indicator matching achievements page
          isUnlocked
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF4CAF50), size: 11.sp),
                    SizedBox(width: 2.w),
                    Text(
                      context.translate('tasks.unlocked'),
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
    );
  }

  Widget _buildFallbackCircle(IconData icon, Color iconColor, Color bg, {Color? borderColor}) {
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
      child: Icon(icon, size: 24.sp, color: iconColor),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class _DailyQuest {
  final String id;
  final String icon, title, subtitle;
  final int current, total, rewardXp, rewardStars;
  final Color accentColor;
  final String action;
  final bool done;
  final bool isCompleted;
  final bool isClaimed;

  _DailyQuest({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.total,
    required this.rewardXp,
    required this.rewardStars,
    required this.accentColor,
    this.action = '',
    this.done = false,
    this.isCompleted = false,
    this.isClaimed = false,
  });
}

class _WeeklyQuest {
  final String id;
  final String icon, title;
  final int current, total, rewardXp, rewardStars;
  final List<Color> gradient;
  final bool isCompleted;
  final bool isClaimed;

  _WeeklyQuest({
    required this.id,
    required this.icon,
    required this.title,
    required this.current,
    required this.total,
    required this.rewardXp,
    required this.rewardStars,
    required this.gradient,
    this.isCompleted = false,
    this.isClaimed = false,
  });
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
