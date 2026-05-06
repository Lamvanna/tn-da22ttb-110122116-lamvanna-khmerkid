import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/score_service.dart';
import '../../widgets/app_header.dart';

/// Màn hình Xếp hạng - Bảng xếp hạng học sinh
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  ScoreService? _score;
  bool _loading = true;

  // Dữ liệu mẫu bảng xếp hạng
  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Bé Minh', 'stars': 256, 'level': 12, 'avatar': '🦁'},
    {'name': 'Bé Lan', 'stars': 230, 'level': 11, 'avatar': '🐰'},
    {'name': 'Bé Hùng', 'stars': 198, 'level': 10, 'avatar': '🐻'},
    {'name': 'Bé Mai', 'stars': 175, 'level': 9, 'avatar': '🦊'},
    {'name': 'Bé Đức', 'stars': 152, 'level': 8, 'avatar': '🐼'},
    {'name': 'Bé Thảo', 'stars': 140, 'level': 7, 'avatar': '🐨'},
    {'name': 'Bé Nam', 'stars': 128, 'level': 7, 'avatar': '🐯'},
    {'name': 'Bé Hoa', 'stars': 115, 'level': 6, 'avatar': '🐸'},
    {'name': 'Bé Tuấn', 'stars': 98, 'level': 5, 'avatar': '🦉'},
    {'name': 'Bé Vy', 'stars': 85, 'level': 4, 'avatar': '🐱'},
  ];

  int _myRank = 0;
  int _myStars = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _score = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _myStars = _score?.totalStars ?? 0;
        // Tính rank dựa trên số sao
        _myRank = _leaderboard.where((e) => (e['stars'] as int) > _myStars).length + 1;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: Column(children: [
        _buildHeader(context),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: '🏅 Bảng xếp hạng',
      subtitle: 'Hạng của bạn: #$_myRank',
      onBack: () => Navigator.pop(context),
      gradientColors: const [Color(0xFFFFA726), Color(0xFFFF7043)],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Text('#$_myRank', style: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFFFF7043)))),
    );
  }

  Widget _buildContent() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) => _buildRankItem(index),
    );
  }

  Widget _buildRankItem(int index) {
    final item = _leaderboard[index];
    final rank = index + 1;
    final isTop3 = rank <= 3;

    // Màu medal cho top 3
    Color? medalColor;
    String medalEmoji = '';
    if (rank == 1) { medalColor = const Color(0xFFFFD54F); medalEmoji = '🥇'; }
    else if (rank == 2) { medalColor = const Color(0xFFB0BEC5); medalEmoji = '🥈'; }
    else if (rank == 3) { medalColor = const Color(0xFFFFCC80); medalEmoji = '🥉'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isTop3 ? Border.all(color: medalColor!, width: 2) : null,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Rank number or medal
        SizedBox(
          width: 36,
          child: isTop3
            ? Text(medalEmoji, style: const TextStyle(fontSize: 24))
            : Text('$rank', textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: const Color(0xFFBDBDBD))),
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: isTop3 ? Border.all(color: medalColor!, width: 2) : null),
          child: Center(child: Text(
            item['avatar'] as String,
            style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        // Name + Level
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['name'] as String, style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2D2D))),
            Text('Cấp ${item['level']}', style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9E9E))),
          ],
        )),
        // Stars
        Row(children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('${item['stars']}', style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: const Color(0xFFFFA726))),
        ]),
      ]),
    );
  }
}
