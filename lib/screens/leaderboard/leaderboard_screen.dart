import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../main_screen.dart';

/// Màn hình Xếp hạng - Bảng xếp hạng học sinh
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  ScoreService? _score;
  int _selectedTab = 1; // 0: Tuần, 1: Tháng, 2: Tất cả
  int _myStars = 0;

  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Bé An', 'stars': 1560, 'avatar': 'image/Đại diện.png'},
    {'name': 'Bé Bình', 'stars': 1200, 'avatar': 'image/Đại diện111.png'},
    {'name': 'Bé Chi', 'stars': 1200, 'avatar': 'image/Đại diện.png'},
    {'name': 'Bé Dũng', 'stars': 1100, 'avatar': 'image/Đại diện111.png'},
    {'name': 'Bé Em', 'stars': 1000, 'avatar': 'image/Đại diện.png'},
    {'name': 'Bé Mỹ', 'stars': 900, 'avatar': 'image/Đại diện111.png'},
    {'name': 'Bé Dọc', 'stars': 960, 'avatar': 'image/Đại diện.png'},
    {'name': 'Bé Khánh', 'stars': 900, 'avatar': 'image/Đại diện111.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() => _myStars = _score?.totalStars ?? 850);
  }

  int get _myRank =>
      _leaderboard.where((e) => (e['stars'] as int) > _myStars).length + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: Column(
        children: [
          // ═══ HEADER GRADIENT ═══
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.r),
                bottomRight: Radius.circular(28.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                child: Column(
                  children: [
                    // Back + Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
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
                        const Spacer(),
                        Text(
                          'Bảng xếp hạng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 36.w),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    // Tab bar
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        children: [
                          _tab('Tuần này', 0),
                          _tab('Tháng này', 1),
                          _tab('Tất cả', 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══ CONTENT (scroll) ═══
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Column(
                children: [
                  _buildPodium(),
                  SizedBox(height: 16.h),
                  ..._buildRankList(),
                ],
              ),
            ),
          ),

          // ═══ MY RANK — CHỈ HIỆN KHI KHÔNG CÓ TRONG LIST ═══
          if (_myRank > 8)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
              child: _buildMyRank(),
            ),
        ],
      ),
      // ═══ BOTTOM NAV BAR ═══
      extendBody: false,
      bottomNavigationBar: Container(
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
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB
  // ══════════════════════════════════════════════════════════════
  Widget _tab(String text, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: active
                  ? AppColors.headerMid
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP 3 PODIUM
  // ══════════════════════════════════════════════════════════════
  Widget _buildPodium() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 — Silver
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 28.h),
              child: _podiumItem(
                rank: 2,
                data: _leaderboard[1],
                crownColor: const Color(0xFFB0BEC5),
                medalColors: [const Color(0xFFC0C0C0), const Color(0xFFA8A8A8)],
                avatarSize: 64.w,
              ),
            ),
          ),
          // #1 — Gold (tallest)
          Expanded(
            child: _podiumItem(
              rank: 1,
              data: _leaderboard[0],
              crownColor: const Color(0xFFFFCA28),
              medalColors: [const Color(0xFFFFCA28), const Color(0xFFE5A800)],
              avatarSize: 80.w,
            ),
          ),
          // #3 — Bronze
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 36.h),
              child: _podiumItem(
                rank: 3,
                data: _leaderboard[2],
                crownColor: const Color(0xFFCD7F32),
                medalColors: [const Color(0xFFD4915E), const Color(0xFFB5733A)],
                avatarSize: 58.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumItem({
    required int rank,
    required Map<String, dynamic> data,
    required Color crownColor,
    required List<Color> medalColors,
    required double avatarSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown + Avatar stacked
        SizedBox(
          width: avatarSize + 20.w,
          height: avatarSize + 24.h,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Avatar with medal ring (layer dưới)
              Positioned(
                bottom: 0,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: medalColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: medalColors[0].withValues(alpha: 0.4),
                        blurRadius: 10.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: ClipOval(
                    child: Image.asset(
                      data['avatar'] as String,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Crown (layer trên — hiện rõ)
              Positioned(
                top: rank == 1 ? -22.h : -15.h,
                child: Image.asset(
                  'image/Xếp hạng $rank.png',
                  width: rank == 1 ? 82.w : 66.w,
                  height: rank == 1 ? 82.h : 66.h,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // Name
        Text(
          data['name'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: rank == 1 ? 15.sp : 13.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 4.h),
        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              size: 16.sp,
              color: const Color(0xFFFFCA28),
            ),
            SizedBox(width: 3.w),
            Text(
              '${data['stars']} sao',
              style: GoogleFonts.plusJakartaSans(
                fontSize: rank == 1 ? 14.sp : 12.sp,
                fontWeight: FontWeight.w800,
                color: rank == 1
                    ? const Color(0xFFE65100)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // RANK LIST (4+)
  // ══════════════════════════════════════════════════════════════
  List<Widget> _buildRankList() {
    final items = <Widget>[];
    for (int i = 3; i < _leaderboard.length; i++) {
      items.add(_rankRow(i + 1, _leaderboard[i], false));
    }
    return items;
  }

  Widget _rankRow(int rank, Map<String, dynamic> data, bool isMe) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isMe
            ? Border.all(color: const Color(0xFFFFB300), width: 2.w)
            : Border.all(color: const Color(0xFFE8ECF2), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 30.w,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: isMe ? const Color(0xFFE65100) : const Color(0xFF374151),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFD1D5DB),
                width: 2.w),
            ),
            child: ClipOval(
              child: Image.asset(data['avatar'] as String, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 12.w),
          // Name
          Expanded(
            child: Text(
              isMe ? 'Bạn' : data['name'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isMe ? const Color(0xFFE65100) : AppColors.textPrimary,
              ),
            ),
          ),
          // Stars
          Icon(
            Icons.star_rounded,
            size: 20.sp,
            color: const Color(0xFFFFCA28),
          ),
          SizedBox(width: 4.w),
          Text(
            '${data['stars']} sao',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: isMe ? const Color(0xFFE65100) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MY RANK ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildMyRank() {
    return _rankRow(_myRank > 10 ? 10 : _myRank, {
      'name': 'Bạn',
      'stars': _myStars,
      'avatar': 'image/Đại diện.png',
    }, true);
  }
}
