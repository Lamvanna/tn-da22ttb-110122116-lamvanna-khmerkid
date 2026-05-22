import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../constants/app_colors.dart';

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
      icon: '📚', title: 'Học 3 bài học',
      subtitle: 'Hoàn thành 3 bài học bất kỳ',
      current: 2, total: 3, reward: 20,
      accentColor: const Color(0xFF1E88E5),
    ),
    _DailyQuest(
      icon: '✏️', title: 'Luyện tập 2 lần',
      subtitle: 'Hoàn thành 2 bài luyện tập',
      current: 2, total: 2, reward: 15,
      accentColor: const Color(0xFF43A047),
      done: true,
    ),
    _DailyQuest(
      icon: '🎧', title: 'Nghe phát âm 5 lần',
      subtitle: 'Nghe phát âm của bất kỳ 5 chữ',
      current: 3, total: 5, reward: 10,
      accentColor: const Color(0xFF7C4DFF),
    ),
  ];

  final List<_WeeklyQuest> _weeklyQuests = [
    _WeeklyQuest(
      icon: '🏆', title: 'Hoàn thành 10 bài học',
      current: 0, total: 10, reward: 100,
      gradient: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
    ),
    _WeeklyQuest(
      icon: '🎯', title: 'Luyện tập 15 lần',
      current: 7, total: 15, reward: 80,
      gradient: const [Color(0xFFE53935), Color(0xFFD32F2F)],
    ),
    _WeeklyQuest(
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

  int get _totalPoints {
    int pts = 0;
    for (final q in _dailyQuests) { if (q.done) pts += q.reward; }
    for (final q in _weeklyQuests) { if (q.current >= q.total) pts += q.reward; }
    return pts;
  }

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_calcRemaining);
    });
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
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Nhiệm vụ hằng ngày', '⏱ ${_formatDuration(_dailyRemaining)}'),
                  SizedBox(height: 12.h),
                  ...List.generate(_dailyQuests.length, (i) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildDailyCard(_dailyQuests[i]),
                  )),
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Nhiệm vụ hằng tuần', '⏱ ${_formatWeekly(_weeklyRemaining)}'),
                  SizedBox(height: 12.h),
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
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -40.w, top: -30.h,
            child: Container(width: 120.w, height: 120.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(left: -25.w, bottom: -20.h,
            child: Container(width: 80.w, height: 80.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
          // Mascot
          Positioned(right: 10.w, bottom: -8.h,
            child: Image.asset('assets/images/elephant_mascot.png',
              width: 95.w, height: 95.w, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 100.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36.w, height: 36.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w)),
                    ),
                    SizedBox(width: 12.w),
                    Text('Nhiệm vụ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.only(left: 48.w),
                    child: Text('Hoàn thành nhiệm vụ để nhận thưởng ⭐',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp, fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85))),
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
      padding: EdgeInsets.all(16.w),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tính năng đổi thưởng sắp ra mắt!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            backgroundColor: const Color(0xFF2E3849),
          ),
        );
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
          fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const Spacer(),
      Text(trailing,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    ]);
  }

  // ═══════════════════ DAILY QUEST CARD ═══════════════════
  Widget _buildDailyCard(_DailyQuest quest) {
    final progress = quest.total > 0 ? quest.current / quest.total : 0.0;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: quest.done
              ? const Color(0xFF43A047).withValues(alpha: 0.25)
              : quest.accentColor.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12.r, offset: Offset(0, 3.h))]),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 52.w, height: 52.w,
            decoration: BoxDecoration(
              color: quest.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r)),
            child: Center(child: Text(quest.icon, style: TextStyle(fontSize: 24.sp))),
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
                SizedBox(height: 2.h),
                Text(quest.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 7.h,
                        backgroundColor: quest.accentColor.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation(
                          quest.done ? const Color(0xFF43A047) : quest.accentColor))),
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
          quest.done
              ? Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 20.sp),
                    Text('+${quest.reward}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp, fontWeight: FontWeight.w800, color: const Color(0xFF43A047))),
                  ]),
                )
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3))),
                  child: Column(children: [
                    Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 20.sp),
                    Text('+${quest.reward}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFFFF8F00))),
                  ]),
                ),
        ],
      ),
    );
  }

  // ═══════════════════ WEEKLY QUEST ROW ═══════════════════
  Widget _buildWeeklyRow() {
    return SizedBox(
      height: 190.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _weeklyQuests.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => _buildWeeklyCard(_weeklyQuests[i]),
      ),
    );
  }

  Widget _buildWeeklyCard(_WeeklyQuest quest) {
    final progress = quest.total > 0 ? quest.current / quest.total : 0.0;
    final done = quest.current >= quest.total;
    return Container(
      width: 140.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: quest.gradient[0].withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
          color: quest.gradient[0].withValues(alpha: 0.10),
          blurRadius: 14.r, offset: Offset(0, 4.h))]),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56.w, height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: quest.gradient),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [BoxShadow(
                color: quest.gradient[1].withValues(alpha: 0.3),
                blurRadius: 10.r, offset: Offset(0, 4.h))]),
            child: Center(child: Text(quest.icon, style: TextStyle(fontSize: 26.sp))),
          ),
          SizedBox(height: 10.h),
          // Title
          Text(quest.title,
            textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
          SizedBox(height: 6.h),
          // Progress
          Text('${quest.current} / ${quest.total}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w800,
              color: done ? const Color(0xFF43A047) : AppColors.textSecondary)),
          const Spacer(),
          // Reward
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 16.sp),
            SizedBox(width: 2.w),
            Text('+${quest.reward}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.w800,
                color: done ? const Color(0xFF43A047) : const Color(0xFFFF8F00))),
          ]),
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
            onTap: () => HapticFeedback.lightImpact(),
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
        Row(
          children: List.generate(_achievements.length, (i) {
            if (i > 0) return Expanded(child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _buildAchievementTile(_achievements[i])));
            return Expanded(child: _buildAchievementTile(_achievements[i]));
          }),
        ),
      ],
    );
  }

  Widget _buildAchievementTile(_Achievement ach) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: ach.color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8.r, offset: Offset(0, 2.h))]),
      child: Column(
        children: [
          // Shield badge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48.w, height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [ach.color.withValues(alpha: 0.15), ach.color.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: ach.color.withValues(alpha: 0.2))),
                child: Center(child: Text(ach.icon, style: TextStyle(fontSize: 22.sp))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 20.w, height: 20.w,
                  decoration: BoxDecoration(
                    color: ach.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.w)),
                  child: Center(child: Text('${ach.value}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.sp, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(ach.title,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2)),
          SizedBox(height: 2.h),
          Text(ach.subtitle,
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class _DailyQuest {
  final String icon, title, subtitle;
  final int current, total, reward;
  final Color accentColor;
  final bool done;
  _DailyQuest({required this.icon, required this.title, required this.subtitle,
    required this.current, required this.total, required this.reward,
    required this.accentColor, this.done = false});
}

class _WeeklyQuest {
  final String icon, title;
  final int current, total, reward;
  final List<Color> gradient;
  _WeeklyQuest({required this.icon, required this.title, required this.current,
    required this.total, required this.reward, required this.gradient});
}

class _Achievement {
  final String icon, title, subtitle;
  final int value;
  final Color color;
  _Achievement({required this.icon, required this.title, required this.subtitle,
    required this.value, required this.color});
}
