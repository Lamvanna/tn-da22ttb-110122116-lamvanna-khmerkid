import 'package:flutter/material.dart';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.5, -1),
            end: Alignment(0.5, 1),
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24)),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          // Decorative stars
          Positioned(right: 20, top: 45,
            child: Icon(Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.15), size: 20)),
          Positioned(right: 55, top: 35,
            child: Icon(Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.1), size: 14)),
          Positioned(left: 30, top: 55,
            child: Icon(Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.08), size: 12)),
          // Elephant mascot — bên phải, to rõ
          Positioned(right: -42, bottom: -80,
            child: Image.asset('image/Voi header.png',
              width: 260, height: 260, fit: BoxFit.contain)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5)),
                    child: ClipOval(
                      child: Image.asset('image/Đại diện.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 14),
                  // Name + Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(_getLevelIcon(_level),
                            color: const Color(0xFF66BB6A), size: 16),
                          const SizedBox(width: 5),
                          Text('Cấp $_level: ${_getLevelTitle(_level)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
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
        offset: const Offset(0, -28),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: [
            // Streak
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('image/Lửa chuổi.png', width: 20, height: 20),
                const SizedBox(width: 5),
                Text('$_streak ngày', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C3345))),
              ]),
              const SizedBox(height: 3),
              Text('Chuỗi ngày', style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
            ])),
            // Divider
            Container(width: 1, height: 40, color: const Color(0xFFEEF1F8)),
            // Stars
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('image/sao.png', width: 20, height: 20),
                const SizedBox(width: 5),
                Text('$_totalStars sao', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C3345))),
              ]),
              const SizedBox(height: 3),
              Text('Điểm thưởng', style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
            ])),
            // Divider
            Container(width: 1, height: 40, color: const Color(0xFFEEF1F8)),
            // Level
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Lv.$_level', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C3345))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _score?.levelProgress ?? 0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEEF1F8),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF1976D2))))),
                ]),
                const SizedBox(height: 3),
                Text('Cấp độ hiện tại', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
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
