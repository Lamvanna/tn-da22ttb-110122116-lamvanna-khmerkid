import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../screens/settings/settings_screen.dart';
import '../../../services/storage_service.dart';
import '../../../services/score_service.dart';

/// Header trang chủ — Gradient sáng sang trọng + thông tin user
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF4580C4), Color(0xFF6A9DD6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Row: Avatar + Name + Settings ===
              Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.face_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  // Name + Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(_getLevelIcon(_level),
                            color: AppColors.secondaryContainer, size: 16),
                          const SizedBox(width: 5),
                          Text('Cấp $_level: ${_getLevelTitle(_level)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92))),
                        ]),
                      ],
                    ),
                  ),
                  // Settings
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                      child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // === Stats bar ===
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                child: Row(children: [
                  // Streak
                  const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.secondaryLight, size: 19),
                  const SizedBox(width: 5),
                  Text('$_streak ngày',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  Container(
                    width: 1, height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.white.withValues(alpha: 0.3)),
                  // Stars
                  const Icon(Icons.star_rounded,
                    color: AppColors.secondaryLight, size: 19),
                  const SizedBox(width: 5),
                  Text('$_totalStars sao',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  // Level progress
                  SizedBox(
                    width: 55,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _score?.levelProgress ?? 0,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(AppColors.secondaryLight)))),
                  const SizedBox(width: 8),
                  Text('Lv.$_level',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
