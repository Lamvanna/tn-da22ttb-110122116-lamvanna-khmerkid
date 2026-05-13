import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../report/report_screen.dart';
import '../achievements/achievements_screen.dart';
import '../../widgets/app_page_route.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await ScoreService.getInstance();
    if (mounted) setState(() => _score = s);
  }

  int get _xp => _score?.totalXp ?? 0;
  int get _level => _score?.level ?? 1;
  int get _stars => _score?.totalStars ?? 0;
  int get _streak => _score?.streak ?? 0;
  int get _medals => _score?.totalMedals ?? 0;
  int get _lettersLearned => _score?.lettersLearned ?? 0;
  int get _vowelsLearned => _score?.vowelsLearned ?? 0;

  String _levelTitle(int lv) {
    if (lv >= 20) return 'Bậc thầy ngôn ngữ';
    if (lv >= 15) return 'Nhà thông thái';
    if (lv >= 10) return 'Nhà thám hiểm';
    if (lv >= 5) return 'Nhà thám hiểm nhí';
    return 'Mới bắt đầu';
  }

  @override
  Widget build(BuildContext context) {
    final xpInLevel = _xp % 100;
    final xpNeeded = 100;
    final xpRemaining = xpNeeded - xpInLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          // ═══ HEADER ═══
          _buildHeader(xpInLevel, xpNeeded, xpRemaining),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(children: [
              SizedBox(height: 14.h),
              _buildProgressSection(),
              SizedBox(height: 16.h),
              _buildAchievements(),
              SizedBox(height: 16.h),
              _buildParentCorner(),
              SizedBox(height: 16.h),
              _buildBottomCards(),
              SizedBox(height: 100.h),
            ]),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER with avatar, name, XP bar, elephant + overlapping stats
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(int xpInLevel, int xpNeeded, int xpRemaining) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 52.h),
          decoration: BoxDecoration(
            gradient: AppColors.appGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r)),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(clipBehavior: Clip.none, children: [
              // Decorative stars
              Positioned(left: 30.w, top: 20.h,
                child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.12), size: 14.sp)),
              Positioned(right: 80.w, top: 15.h,
                child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.08), size: 10.sp)),
              // Elephant mascot — góc phải
              Positioned(right: -30.w, bottom: -20.h,
                child: Opacity(opacity: 0.85,
                  child: Image.asset('image/Voi header.png',
                    width: 140.w, height: 140.h, fit: BoxFit.contain))),
              // ── Main content ──
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 72.h),
                child: Column(children: [
                  // Row: Avatar + Name/Level
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Container(
                      width: 82.w, height: 82.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3.w),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12.r, offset: Offset(0, 4.h))]),
                      child: ClipOval(child: Image.asset('image/Đại diện.png', fit: BoxFit.cover)),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bé học giỏi', style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16.r)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 16.w, height: 16.w,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF66BB6A)),
                              child: Icon(Icons.eco_rounded, size: 10.sp, color: Colors.white)),
                            SizedBox(width: 5.w),
                            Text('Cấp $_level • ${_levelTitle(_level)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                          ])),
                      ],
                    )),
                  ]),
                  SizedBox(height: 16.h),
                  // XP bar
                  Padding(
                    padding: EdgeInsets.only(right: 50.w),
                    child: Container(
                      height: 26.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(13.r)),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Fill — xanh nhạt
                          Padding(
                            padding: EdgeInsets.all(2.w),
                            child: FractionallySizedBox(
                              widthFactor: (xpInLevel / xpNeeded).clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.35)]),
                                  borderRadius: BorderRadius.circular(11.r))))),
                          // Text
                          Center(child: Padding(
                            padding: EdgeInsets.only(left: 28.w),
                            child: Text('$xpInLevel / $xpNeeded XP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)))),
                          // XP star badge — overlaps left
                          Positioned(
                            left: -16.w,
                            top: -8.h,
                            bottom: -8.h,
                            child: Stack(alignment: Alignment.center, children: [
                              Icon(Icons.star_rounded, size: 44.sp,
                                color: const Color(0xFFFFCA28),
                                shadows: [Shadow(
                                  color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                                  blurRadius: 8.r, offset: Offset(0, 2.h))]),
                              Text('XP', style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp, fontWeight: FontWeight.w900,
                                color: const Color(0xFF5D4037))),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Padding(
                    padding: EdgeInsets.only(right: 50.w),
                    child: Center(child: Text('Còn $xpRemaining XP để lên cấp ${_level + 1}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8)))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        // ═══ STATS CARD (overlap) ═══
        Positioned(left: 16.w, right: 16.w, bottom: 0,
          child: _buildStatsRow()),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STATS ROW: 4 items
  // ══════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16.r, offset: Offset(0, 4.h))]),
      child: Row(children: [
        _statItem('image/sao.png', '$_stars', 'Tổng số sao'),
        _statDivider(),
        _statItem('image/Lửa chuổi.png', '$_streak ngày', 'Chuỗi ngày'),
        _statDivider(),
        _statItem(null, '$_medals', 'Huy hiệu', icon: Icons.military_tech_rounded, iconColor: const Color(0xFFFFC107)),
        _statDivider(),
        _statItem(null, 'Top 5', 'Thứ hạng', icon: Icons.emoji_events_rounded, iconColor: const Color(0xFF7C4DFF)),
      ]),
    );
  }

  Widget _statItem(String? img, String value, String label, {IconData? icon, Color? iconColor}) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (img != null)
        Image.asset(img, width: 28.w, height: 28.h)
      else
        Icon(icon, size: 28.sp, color: iconColor),
      SizedBox(height: 6.h),
      Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      SizedBox(height: 2.h),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 10.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
    ]));
  }

  Widget _statDivider() => Container(width: 1.w, height: 44.h, color: const Color(0xFFEEF1F8));

  // ══════════════════════════════════════════════════════════════
  // LEARNING PROGRESS
  // ══════════════════════════════════════════════════════════════
  Widget _buildProgressSection() {
    final totalProg = ((_lettersLearned / 33 + _vowelsLearned / 18) / 2 * 100).clamp(0, 100).toInt();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16.r, offset: Offset(0, 4.h))]),
      child: Column(children: [
        Row(children: [
          Icon(Icons.auto_graph_rounded, size: 20.sp, color: AppColors.headerMid),
          SizedBox(width: 6.w),
          Text('Tiến độ học tập', style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, AppPageRoute(page: const ReportScreen())),
            child: Text('Xem chi tiết ›', style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.headerMid))),
        ]),
        SizedBox(height: 14.h),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Circular progress
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalProg / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => SizedBox(
              width: 90.w, height: 90.w,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 90.w, height: 90.w, child: CircularProgressIndicator(
                  value: 1.0, strokeWidth: 8.w,
                  color: const Color(0xFFE8EDF5))),
                SizedBox(width: 90.w, height: 90.w, child: CircularProgressIndicator(
                  value: val, strokeWidth: 8.w,
                  color: const Color(0xFF4CAF50), strokeCap: StrokeCap.round)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(val * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  Text('Tổng tiến độ', style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
          ),
          SizedBox(width: 14.w),
          // Subject bars
          Expanded(child: Column(children: [
            _progressBar('Học chữ cái', _lettersLearned, 33, const Color(0xFF4CAF50), 'image/Phụ âm.png'),
            SizedBox(height: 10.h),
            _progressBar('Đánh vần', 0, 20, const Color(0xFF2196F3), 'image/Đánh vần.png'),
            SizedBox(height: 10.h),
            _progressBar('Luyện viết', 0, 20, const Color(0xFFFF9800), 'image/Tập viết.png'),
            SizedBox(height: 10.h),
            _progressBar('Tập đọc', 0, 20, const Color(0xFF9C27B0), 'image/Tập đọc.png'),
          ])),
        ]),
      ]),
    );
  }

  Widget _progressBar(String label, int done, int total, Color color, String img) {
    final pct = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      Image.asset(img, width: 22.w, height: 22.h, errorBuilder: (_, __, ___) =>
        Icon(Icons.book_rounded, size: 22.sp, color: color)),
      SizedBox(width: 8.w),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 3.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct, minHeight: 6.h,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: AlwaysStoppedAnimation(color))),
        ],
      )),
      SizedBox(width: 6.w),
      Text('$done/$total', style: GoogleFonts.plusJakartaSans(
        fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      SizedBox(width: 6.w),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r)),
        child: Text('${(pct * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(
          fontSize: 9.sp, fontWeight: FontWeight.w700, color: color))),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // WEEKLY GOAL
  // ══════════════════════════════════════════════════════════════
  Widget _buildWeeklyGoal() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12.r, offset: Offset(0, 3.h))]),
      child: Row(children: [
        Icon(Icons.track_changes_rounded, size: 22.sp, color: const Color(0xFF7C4DFF)),
        SizedBox(width: 8.w),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: AppColors.textPrimary),
              children: [
                TextSpan(text: 'Mục tiêu tuần: ', style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 12.sp, color: AppColors.textPrimary)),
                TextSpan(text: 'Hoàn thành 5 bài tập đọc'),
              ])),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: 0.6, minHeight: 6.h,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)))),
          ],
        )),
        SizedBox(width: 8.w),
        Text('3/5', style: GoogleFonts.plusJakartaSans(
          fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF7C4DFF))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════
  Widget _buildAchievements() {
    final badges = [
      {'icon': Icons.star_rounded, 'label': 'Siêu nhân\nchăm chỉ', 'color': const Color(0xFFFFCA28)},
      {'icon': Icons.edit_rounded, 'label': 'Bút vàng', 'color': const Color(0xFFFF7043)},
      {'icon': Icons.auto_stories_rounded, 'label': 'Siêu nhân\nbài tập', 'color': const Color(0xFF42A5F5)},
      {'icon': Icons.menu_book_rounded, 'label': 'Tập đọc', 'color': const Color(0xFFAB47BC)},
      {'icon': Icons.spellcheck_rounded, 'label': 'Đánh vần\nnhanh', 'color': const Color(0xFFEF5350)},
      {'icon': Icons.explore_rounded, 'label': 'Nhà thám\nhiểm', 'color': const Color(0xFF26A69A)},
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16.r, offset: Offset(0, 4.h))]),
      child: Column(children: [
        Row(children: [
          Text('🏆', style: TextStyle(fontSize: 18.sp)),
          SizedBox(width: 6.w),
          Text('Thành tích', style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, AppPageRoute(page: const AchievementsScreen())),
            child: Text('Xem tất cả ›', style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.headerMid))),
        ]),
        SizedBox(height: 14.h),
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, i) {
              final b = badges[i];
              return SizedBox(width: 65.w, child: Column(children: [
                Container(
                  width: 52.w, height: 52.w,
                  decoration: BoxDecoration(
                    color: (b['color'] as Color).withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                  child: Icon(b['icon'] as IconData, color: b['color'] as Color, size: 26.sp)),
                SizedBox(height: 4.h),
                Text(b['label'] as String, textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]));
            },
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PARENT CORNER
  // ══════════════════════════════════════════════════════════════
  Widget _buildParentCorner() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, AppPageRoute(page: const ReportScreen()));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.r, offset: Offset(0, 3.h))]),
        child: Row(children: [
          Container(
            width: 44.w, height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14.r)),
            child: Icon(Icons.family_restroom_rounded, size: 24.sp, color: AppColors.headerMid)),
          SizedBox(width: 12.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Góc phụ huynh', style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Theo dõi và đồng hành', style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 22.sp),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BOTTOM CARDS: Kho báu, Thư viện, Cài đặt
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomCards() {
    return Row(children: [
      _bottomCard('Kho báu', 'Phần thưởng\ncủa bé', Icons.card_giftcard_rounded,
        const Color(0xFF7C4DFF), () {}),
      SizedBox(width: 10.w),
      _bottomCard('Thư viện', 'Sách và\ntài liệu', Icons.auto_stories_rounded,
        const Color(0xFF26A69A), () => Navigator.push(context, AppPageRoute(page: const LibraryScreen()))),
      SizedBox(width: 10.w),
      _bottomCard('Cài đặt', 'Tùy chỉnh\nứng dụng', Icons.settings_rounded,
        const Color(0xFF78909C), () => Navigator.push(context, AppPageRoute(page: const SettingsScreen()))),
    ]);
  }

  Widget _bottomCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.r)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SizedBox(height: 2.h),
          Text(sub, style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
      ),
    ));
  }
}
