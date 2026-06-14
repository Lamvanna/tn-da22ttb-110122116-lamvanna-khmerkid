import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_missions_screen.dart';
import 'admin_badges_screen.dart';
import 'admin_library_screen.dart';
import 'admin_games_screen.dart';
import 'admin_tests_screen.dart';

/// Màn hình chính Admin — Drawer Navigation
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _titles = [
    'Dashboard',
    'Quản lý Người dùng',
    'Quản lý Bài học',
    'Quản lý Nhiệm vụ',
    'Quản lý Huy hiệu',
    'Quản lý Thư viện',
    'Quản lý Câu hỏi Game',
    'Quản lý Bài kiểm tra',
  ];

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.menu_book_rounded,
    Icons.flag_rounded,
    Icons.emoji_events_rounded,
    Icons.auto_stories_rounded,
    Icons.sports_esports_rounded,
    Icons.assignment_turned_in_rounded,
  ];

  static const _colors = [
    AppColors.primary,
    AppColors.violet,
    AppColors.tertiary,
    AppColors.coral,
    AppColors.secondary,
    Color(0xFF27AE60),
    Color(0xFFF2994A),
    Color(0xFF5C6BC0),
  ];

  final _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminLessonsScreen(),
    AdminMissionsScreen(),
    AdminBadgesScreen(),
    AdminLibraryScreen(),
    AdminGamesScreen(),
    AdminTestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26.sp),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32.w, height: 32.w,
            decoration: BoxDecoration(
              color: _colors[_currentIndex].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(_icons[_currentIndex], color: _colors[_currentIndex], size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              _titles[_currentIndex],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        // Admin badge
        Container(
          margin: EdgeInsets.only(right: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 16.sp, color: AppColors.secondary),
              SizedBox(width: 4.w),
              Text('Admin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(height: 1.h, color: AppColors.outlineVariant),
      ),
    );
  }

  Widget _buildDrawer() {
    final profile = AuthService().userProfile;
    final name = profile?['name'] ?? 'Admin';
    final email = profile?['email'] ?? '';
    final avatar = profile?['avatar']?.toString() ?? '';

    return Drawer(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 24.h),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.headerDark, AppColors.headerAccent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                  child: avatar.startsWith('http')
                    ? null
                    : Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32.sp),
                ),
                SizedBox(height: 14.h),
                Text(name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 2.h),
                Text(email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('🛡️ Quản trị viên',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Menu Items ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              children: [
                _drawerSectionHeader('QUẢN LÝ'),
                ...List.generate(8, (i) => _drawerItem(i)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  child: Divider(color: AppColors.outlineVariant, height: 1),
                ),
                _drawerSectionHeader('HỆ THỐNG'),
                _drawerActionItem(
                  Icons.logout_rounded,
                  'Đăng xuất',
                  AppColors.errorRed,
                  _confirmLogout,
                ),
              ],
            ),
          ),

          // ── Footer ──
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
            child: Text(
              'KhmerKid Admin v1.0.0',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
      child: Text(title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.textHint,
        )),
    );
  }

  Widget _drawerItem(int index) {
    final selected = _currentIndex == index;
    final color = _colors[index];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentIndex = index);
            Navigator.pop(context); // Close drawer
          },
          borderRadius: BorderRadius.circular(14.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.w, height: 38.w,
                  decoration: BoxDecoration(
                    color: selected ? color : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(_icons[index],
                    color: selected ? Colors.white : AppColors.textSecondary,
                    size: 20.sp),
                ),
                SizedBox(width: 14.w),
                Text(_titles[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : AppColors.textPrimary,
                  )),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 6.w, height: 6.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            child: Row(
              children: [
                Container(
                  width: 38.w, height: 38.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                SizedBox(width: 14.w),
                Text(label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    Navigator.pop(context); // Close drawer first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Đăng xuất?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    await AuthService().logout();

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
