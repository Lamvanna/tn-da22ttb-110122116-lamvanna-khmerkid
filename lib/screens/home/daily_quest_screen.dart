import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../achievements/achievements_screen.dart';
import '../shop/shop_screen.dart';

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
      icon: '📚', title: 'Học 3 bài học',
      subtitle: 'Hoàn thành 3 bài học bất kỳ',
      current: 2, total: 3, reward: 20,
      accentColor: const Color(0xFF1E88E5),
    ),
    _DailyQuest(
      id: 'mock_d2',
      icon: '✏️', title: 'Luyện tập 2 lần',
      subtitle: 'Hoàn thành 2 bài luyện tập',
      current: 2, total: 2, reward: 15,
      accentColor: const Color(0xFF43A047),
      done: true,
      isCompleted: true,
      isClaimed: true,
    ),
    _DailyQuest(
      id: 'mock_d3',
      icon: '🎧', title: 'Nghe phát âm 5 lần',
      subtitle: 'Nghe phát âm của bất kỳ 5 chữ',
      current: 3, total: 5, reward: 10,
      accentColor: const Color(0xFF7C4DFF),
    ),
  ];

  final List<_WeeklyQuest> _weeklyQuests = [
    _WeeklyQuest(
      id: 'mock_w1',
      icon: '🏆', title: 'Hoàn thành 10 bài',
      current: 0, total: 10, reward: 100,
      gradient: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
    ),
    _WeeklyQuest(
      id: 'mock_w2',
      icon: '🎯', title: 'Luyện tập 15 lần',
      current: 7, total: 15, reward: 80,
      gradient: const [Color(0xFFE53935), Color(0xFFD32F2F)],
    ),
    _WeeklyQuest(
      id: 'mock_w3',
      icon: '👑', title: 'Đạt 3 ngày liên tiếp',
      current: 1, total: 3, reward: 120,
      gradient: const [Color(0xFF7C4DFF), Color(0xFF651FFF)],
    ),
  ];

  final List<_Achievement> _achievements = [
    _Achievement(icon: '📖', title: 'Học sinh chăm chỉ', subtitle: 'Học 10 bài học', value: 10, color: const Color(0xFF1E88E5)),
    _Achievement(icon: '💪', title: 'Luyện tập tốt', subtitle: 'Luyện tập 5 lần', value: 5, color: const Color(0xFF43A047)),
    _Achievement(icon: '🎧', title: 'Người nghe siêu đẳng', subtitle: 'Nghe 10 lần phát âm', value: 10, color: const Color(0xFFFF6D00)),
    _Achievement(icon: '🔥', title: 'Chuỗi ngày vàng', subtitle: '3 ngày liên tiếp', value: 3, color: const Color(0xFFE53935)),
  ];

  bool _loadingMissions = true;

  int get _totalPoints {
    int pts = 0;
    for (final q in _dailyQuests) { if (q.done) pts += q.reward; }
    for (final q in _weeklyQuests) { if (q.isClaimed) pts += q.reward; }
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
      if (mounted) setState(() {});
    });
  }

  String _getEmoji(String title) {
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
          final reward = rewardMap?['stars'] as int? ?? rewardMap?['xp'] as int? ?? 10;
          
          final icon = _getEmoji(title);

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
              reward: reward,
              accentColor: accentColor,
              done: isClaimed,
              isCompleted: isCompleted,
              isClaimed: isClaimed,
            ));
          } else {
            List<Color> gradient = const [Color(0xFFFFB300), Color(0xFFFF8F00)];
            if (title.contains('Game') || title.contains('Trò chơi')) gradient = const [Color(0xFFE53935), Color(0xFFD32F2F)];
            else if (title.contains('Nói') || title.contains('Phát âm')) gradient = const [Color(0xFF7C4DFF), Color(0xFF651FFF)];
            else if (title.contains('Viết') || title.contains('Chữ')) gradient = const [Color(0xFF00BCD4), Color(0xFF0097A7)];

            weekly.add(_WeeklyQuest(
              id: id,
              icon: icon,
              title: title,
              current: current,
              total: total,
              reward: reward,
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
            content: const Text('🎉 Nhận phần thưởng thành công! Bé giỏi quá! ⭐'),
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
            content: Text('⚠️ Không thể nhận thưởng: ${res['message']}'),
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
      return 'Còn $days ngày ${h % 24}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return 'Cập nhật sau: ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
                  _buildSectionHeader('Nhiệm vụ hằng ngày', '⏱ ${_formatDuration(_dailyRemaining)}'),
                  SizedBox(height: 10.h),
                  ...List.generate(_dailyQuests.length, (i) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildDailyCard(_dailyQuests[i]),
                  )),
                  SizedBox(height: 0),
                  _buildSectionHeader('Nhiệm vụ hằng tuần', '⏱ ${_formatWeekly(_weeklyRemaining)}'),
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
    return 'Còn $days ngày ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1565C0).withValues(alpha: 0.30),
          blurRadius: 16, offset: const Offset(0, 6))]),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -30.w, top: -20.h,
            child: Container(width: 100.w, height: 100.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(left: -15.w, bottom: -10.h,
            child: Container(width: 60.w, height: 60.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36.w, height: 36.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w)),
                  ),
                  SizedBox(width: 12.w),
                  Text('Nhiệm vụ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  
                  // Streak Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                    child: Row(children: [
                      Text('🔥', style: TextStyle(fontSize: 14.sp)),
                      SizedBox(width: 4.w),
                      Text('${AuthService().userProfile?['streak'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ),
                  SizedBox(width: 8.w),
                  
                  // Star Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                    child: Row(children: [
                      Icon(Icons.star_rounded, color: const Color(0xFFFFD54F), size: 16.sp),
                      SizedBox(width: 4.w),
                      Text('${AuthService().userProfile?['stars'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ POINTS CARD ═══════════════════
  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1E88E5).withValues(alpha: 0.08), const Color(0xFF42A5F5).withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
          blurRadius: 16.r, offset: Offset(0, 4.h))]),
      child: Row(
        children: [
          // Gift icon
          Container(
            width: 60.w, height: 60.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)]),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [BoxShadow(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                blurRadius: 12.r, offset: Offset(0, 4.h))]),
            child: Center(child: Text('🎁', style: TextStyle(fontSize: 28.sp))),
          ),
          SizedBox(width: 14.w),
          // Points
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Điểm của bạn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 28.sp),
                    SizedBox(width: 6.w),
                    Text('$_totalPoints',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          // Reward milestones
          Column(
            children: [
              _buildRewardBtn(),
              SizedBox(height: 8.h),
              _buildMilestones(),
            ],
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
            blurRadius: 8.r, offset: Offset(0, 2.h))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 16.sp),
          SizedBox(width: 4.w),
          Text('Đổi thưởng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildMilestones() {
    return Row(children: [
      _milestone('🎁', '50'),
      SizedBox(width: 6.w),
      Container(width: 20.w, height: 3.h, decoration: BoxDecoration(
        color: _totalPoints >= 50 ? const Color(0xFF43A047) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2.r))),
      SizedBox(width: 6.w),
      _milestone('🎁', '100'),
      SizedBox(width: 6.w),
      Container(width: 20.w, height: 3.h, decoration: BoxDecoration(
        color: _totalPoints >= 100 ? const Color(0xFF43A047) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2.r))),
      SizedBox(width: 6.w),
      _milestone('🎁', '150'),
    ]);
  }

  Widget _milestone(String emoji, String label) {
    final reached = _totalPoints >= int.parse(label);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: TextStyle(fontSize: 14.sp)),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 9.sp, fontWeight: FontWeight.w700,
        color: reached ? const Color(0xFF43A047) : AppColors.textHint)),
    ]);
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
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: quest.done
              ? const Color(0xFF43A047).withValues(alpha: 0.20)
              : Colors.grey.withValues(alpha: 0.10),
          width: 1.2),
        boxShadow: [
          BoxShadow(
            color: quest.accentColor.withValues(alpha: 0.06),
            blurRadius: 18.r, offset: Offset(0, 6.h)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r, offset: Offset(0, 2.h)),
        ]),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            // Emoji icon with gradient bg
            Container(
              width: 54.w, height: 54.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    quest.accentColor.withValues(alpha: 0.12),
                    quest.accentColor.withValues(alpha: 0.04),
                  ]),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: quest.accentColor.withValues(alpha: 0.10))),
              child: Center(child: Text(quest.icon, style: TextStyle(fontSize: 26.sp))),
            ),
            SizedBox(width: 12.w),
            // Title + subtitle + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  SizedBox(height: 3.h),
                  Text(quest.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  SizedBox(height: 16.h),
                  // Custom progress bar
                  Row(children: [
                    Expanded(
                      child: Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4.r)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: quest.done
                                    ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                                    : [barColor.withValues(alpha: 0.65), barColor]),
                              borderRadius: BorderRadius.circular(4.r),
                              boxShadow: [BoxShadow(
                                color: barColor.withValues(alpha: 0.30),
                                blurRadius: 4.r, offset: Offset(0, 1.h))]),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text('${quest.current} / ${quest.total}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Reward badge
            quest.isClaimed
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [const Color(0xFF66BB6A).withValues(alpha: 0.15), const Color(0xFF43A047).withValues(alpha: 0.08)]),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.18))),
                    child: Column(children: [
                      Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 22.sp),
                      SizedBox(height: 1.h),
                      Text('+${quest.reward}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF43A047))),
                    ]),
                  )
                : (quest.isCompleted && !quest.isClaimed)
                    ? GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _claimReward(quest.id);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFFFFCA28), Color(0xFFF57C00)]),
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFFF57C00).withValues(alpha: 0.3),
                              blurRadius: 8.r, offset: Offset(0, 3.h))]),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.white, size: 22.sp),
                              SizedBox(height: 1.h),
                              Text('NHẬN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)]),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.10),
                            blurRadius: 6.r, offset: Offset(0, 2.h))]),
                        child: Column(children: [
                          Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 22.sp),
                          SizedBox(height: 1.h),
                          Text('+${quest.reward}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFFF8F00))),
                        ]),
                      ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ WEEKLY QUEST ROW ═══════════════════
  Widget _buildWeeklyRow() {
    return SizedBox(
      height: 195.h,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: done
              ? const Color(0xFF43A047).withValues(alpha: 0.3)
              : quest.gradient[0].withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: quest.gradient[0].withValues(alpha: 0.06),
            blurRadius: 16.r, offset: Offset(0, 6.h)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r, offset: Offset(0, 2.h)),
        ]),
      child: Column(
        children: [
          // Icon
          Container(
            width: 58.w, height: 58.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: quest.gradient),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(
                color: quest.gradient[1].withValues(alpha: 0.35),
                blurRadius: 12.r, offset: Offset(0, 6.h))]),
            child: Center(child: Text(quest.icon, style: TextStyle(fontSize: 28.sp))),
          ),
          SizedBox(height: 20.h),
          // Title
          Text(quest.title,
            textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.25)),
          SizedBox(height: 8.h),
          // Progress text & bar
          Text('${quest.current} / ${quest.total}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w700,
              color: done ? const Color(0xFF43A047) : AppColors.textSecondary)),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress, minHeight: 4.h,
              backgroundColor: quest.gradient[0].withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                done ? const Color(0xFF43A047) : quest.gradient[0]),
            ),
          ),
          const Spacer(),
          // Reward pill
          quest.isClaimed
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 14.sp),
                    SizedBox(width: 4.w),
                    Text('+${quest.reward}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF43A047))),
                  ]),
                )
              : (quest.isCompleted && !quest.isClaimed)
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _claimReward(quest.id);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.25),
                            blurRadius: 6.r, offset: Offset(0, 2.h))]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 14.sp),
                          SizedBox(width: 4.w),
                          Text('NHẬN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                        ]),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 14.sp),
                        SizedBox(width: 4.w),
                        Text('+${quest.reward}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFFF8F00))),
                      ]),
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
          Text('Thành tích',
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
                Text('Xem tất cả',
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
          height: 145.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _achievements.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, i) => SizedBox(
              width: 110.w,
              child: _buildAchievementTile(_achievements[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementTile(_Achievement ach) {
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 16.h, 6.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: ach.color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: ach.color.withValues(alpha: 0.05),
            blurRadius: 12.r, offset: Offset(0, 4.h)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4.r, offset: Offset(0, 2.h)),
        ]),
      child: Column(
        children: [
          // Icon box with badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 52.w, height: 52.w,
                decoration: BoxDecoration(
                  color: ach.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: ach.color.withValues(alpha: 0.15))),
                child: Center(child: Text(ach.icon, style: TextStyle(fontSize: 24.sp))),
              ),
              Positioned(
                bottom: -4.w, right: -4.w,
                child: Container(
                  width: 22.w, height: 22.w,
                  decoration: BoxDecoration(
                    color: ach.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5.w),
                    boxShadow: [BoxShadow(
                      color: ach.color.withValues(alpha: 0.3),
                      blurRadius: 4.r, offset: Offset(0, 2.h))]),
                  child: Center(child: Text('${ach.value}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(ach.title,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.25)),
          SizedBox(height: 4.h),
          Text(ach.subtitle,
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class _DailyQuest {
  final String id;
  final String icon, title, subtitle;
  final int current, total, reward;
  final Color accentColor;
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
    required this.reward,
    required this.accentColor,
    this.done = false,
    this.isCompleted = false,
    this.isClaimed = false,
  });
}

class _WeeklyQuest {
  final String id;
  final String icon, title;
  final int current, total, reward;
  final List<Color> gradient;
  final bool isCompleted;
  final bool isClaimed;

  _WeeklyQuest({
    required this.id,
    required this.icon,
    required this.title,
    required this.current,
    required this.total,
    required this.reward,
    required this.gradient,
    this.isCompleted = false,
    this.isClaimed = false,
  });
}

class _Achievement {
  final String icon, title, subtitle;
  final int value;
  final Color color;
  _Achievement({required this.icon, required this.title, required this.subtitle,
    required this.value, required this.color});
}
