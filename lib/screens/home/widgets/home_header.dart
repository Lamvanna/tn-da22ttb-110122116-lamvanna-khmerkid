import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/storage_service.dart';
import '../../../services/score_service.dart';

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
  int _level = 1;
  int _streak = 0;
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    _score = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _username = _storage!.getUsername();
        _level = _score!.level;
        _streak = _score!.streak;
        _totalStars = _score!.totalStars;
      });
    }
  }

  String _getLevelTitle(int level) {
    if (level >= 20) return 'Kim Cương';
    if (level >= 15) return 'Bạch Kim';
    if (level >= 10) return 'Sao Vàng';
    if (level >= 5) return 'Sao Bạc';
    return 'Mới bắt đầu';
  }

  IconData _getLevelIcon(int level) {
    if (level >= 20) return Icons.diamond_rounded;
    if (level >= 15) return Icons.workspace_premium_rounded;
    if (level >= 10) return Icons.star_rounded;
    if (level >= 5) return Icons.star_half_rounded;
    return Icons.eco_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ═══ HEADER GRADIENT ═══
      Container(
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -1),
            end: Alignment(0.5, 1),
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
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
          Positioned(right: -42.w, bottom: -80.h,
            child: Image.asset('image/Voi header.png',
              width: 260.w, height: 260.h, fit: BoxFit.contain)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 52.h),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 56.w, height: 56.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5.w)),
                    child: ClipOval(
                      child: Image.asset('image/Đại diện.png', fit: BoxFit.cover)),
                  ),
                  SizedBox(width: 14.w),
                  // Name + Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                        SizedBox(height: 3.h),
                        Row(children: [
                          Icon(_getLevelIcon(_level),
                            color: const Color(0xFF66BB6A), size: 16.sp),
                          SizedBox(width: 5.w),
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
      Transform.translate(
        offset: Offset(0, -28.h),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
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
                  color: const Color(0xFF2C3345))),
              ]),
              SizedBox(height: 3.h),
              Text('Chuỗi ngày', style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp, fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
            ])),
            // Divider
            Container(width: 1.w, height: 40.h, color: const Color(0xFFEEF1F8)),
            // Stars
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('image/sao.png', width: 20.w, height: 20.h),
                SizedBox(width: 5.w),
                Text('$_totalStars sao', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp, fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C3345))),
              ]),
              SizedBox(height: 3.h),
              Text('Điểm thưởng', style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp, fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
            ])),
            // Divider
            Container(width: 1.w, height: 40.h, color: const Color(0xFFEEF1F8)),
            // Level
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Lv.$_level', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C3345))),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 40.w,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: _score?.levelProgress ?? 0,
                        minHeight: 6.h,
                        backgroundColor: const Color(0xFFEEF1F8),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF1976D2))))),
                ]),
                SizedBox(height: 3.h),
                Text('Cấp độ hiện tại', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp, fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF))),
              ],
            )),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 5),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w800,
          color: const Color(0xFF2C3345))),
      ]),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: const Color(0xFF9CA3AF))),
    ]);
  }
}
