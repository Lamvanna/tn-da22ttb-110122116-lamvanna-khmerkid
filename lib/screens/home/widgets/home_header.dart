import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/storage_service.dart';
import '../../../services/score_service.dart';
import '../../../services/auth_service.dart';
import '../../../constants/app_colors.dart';

/// Header trang chủ — Gradient xanh nhạt + avatar + stats card trắng
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});
  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  StorageService? _storage;
  ScoreService? _score;
  String _username = 'Bé học giỏi';
  String _avatarUrl = '';
  int _level = 1;
  int _streak = 0;
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    AuthService().addListener(_onAuthChanged);
    _loadData();
    AuthService().fetchProfile();
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _updateStats();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    _score = await ScoreService.getInstance();
    _updateStats();
  }

  void _updateStats() {
    if (!mounted) return;
    final user = AuthService().userProfile;
    setState(() {
      _username = user?['name'] ?? (_storage?.getUsername() ?? 'Bé học giỏi');
      _avatarUrl = user?['avatar'] ?? (_storage?.getAvatarUrl() ?? '');
      _level = user?['level'] ?? (_score?.level ?? 1);
      _streak = user?['streak'] ?? (_score?.streak ?? 0);
      _totalStars = user?['stars'] ?? (_score?.totalStars ?? 0);
    });
  }

  String _getLevelTitle(int level) {
    if (level >= 20) return 'Kim Cương';
    if (level >= 15) return 'Bạch Kim';
    if (level >= 10) return 'Sao Vàng';
    if (level >= 5) return 'Sao Bạc';
    return 'Mới bắt đầu';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ═══ HEADER GRADIENT ═══
        Container(
          // Extra padding at bottom to make room for the overlapping stats card
          margin: EdgeInsets.only(bottom: 34.h),
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            gradient: AppColors.appGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r)),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            // Decorative stars
            Positioned(right: 20.w, top: 45.h,
              child: Icon(Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.15), size: 20.sp)),
            Positioned(right: 55.w, top: 35.h,
              child: Icon(Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.1), size: 14.sp)),
            Positioned(left: 30.w, top: 55.h,
              child: Icon(Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.08), size: 12.sp)),
            // Elephant mascot — bên phải, to rõ
            Positioned(right: -42.w, bottom: -70.h,
              child: IgnorePointer(
                child: Image.asset('image/Voi header.png',
                  width: 260.w, height: 260.h, fit: BoxFit.contain),
              )),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 60.h),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 68.w, height: 68.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5.w)),
                      child: ClipOval(
                        child: _avatarUrl.isNotEmpty
                            ? (_avatarUrl.startsWith('http')
                                ? Image.network(
                                    _avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                                  )
                                : Image.file(
                                    File(_avatarUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                                  ))
                            : Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Name + Level
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_username,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26.sp, fontWeight: FontWeight.w900, color: Colors.white,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF1E1B4B).withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            )),
                          SizedBox(height: 6.h),
                          Row(children: [
                            Image.asset(
                              'image/Cấp ${_level.clamp(1, 5)}.png',
                              width: 22.sp,
                              height: 22.sp,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 1.w),
                            Text('Cấp $_level: ${_getLevelTitle(_level)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp, fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9))),
                          ]),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ]),
        ),

        // ═══ STATS CARD (nền trắng, đè lên header) ═══
        Positioned(
          left: 20.w,
          right: 20.w,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16.r, offset: Offset(0, 4.h))]),
            child: Row(children: [
              // Streak
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('image/Lửa chuổi.png', width: 20.w, height: 20.h),
                  SizedBox(width: 5.w),
                  Text('$_streak ngày', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, fontWeight: FontWeight.w800,
                    color: AppColors.onBackground)),
                ]),
                SizedBox(height: 3.h),
                Text('Chuỗi ngày', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp, fontWeight: FontWeight.w500,
                  color: AppColors.textHint)),
              ])),
              // Divider
              Container(width: 1.w, height: 40.h, color: AppColors.surfaceContainerLow),
              // Stars
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('image/sao.png', width: 20.w, height: 20.h),
                  SizedBox(width: 5.w),
                  Text('$_totalStars sao', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, fontWeight: FontWeight.w800,
                    color: AppColors.onBackground)),
                ]),
                SizedBox(height: 3.h),
                Text('Điểm thưởng', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp, fontWeight: FontWeight.w500,
                  color: AppColors.textHint)),
              ])),
              // Divider
              Container(width: 1.w, height: 40.h, color: AppColors.surfaceContainerLow),
              // Level
              Expanded(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Lv.$_level', style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp, fontWeight: FontWeight.w800,
                      color: AppColors.onBackground)),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 40.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: _score?.levelProgress ?? 0,
                          minHeight: 6.h,
                          backgroundColor: AppColors.surfaceContainerLow,
                          valueColor: const AlwaysStoppedAnimation(AppColors.headerMid)))),
                  ]),
                  SizedBox(height: 3.h),
                  Text('Cấp độ hiện tại', style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp, fontWeight: FontWeight.w500,
                    color: AppColors.textHint)),
                ],
              )),
            ]),
          ),
        ),
      ],
    );
  }
}
