import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/score_service.dart';
import '../../widgets/app_header.dart';

/// Màn hình Thành tích — Hiển thị huy chương, badge, cột mốc
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  ScoreService? _score;
  bool _loading = true;

  static final List<_Achievement> _achievements = [
    _Achievement(
      title: 'Bước đầu tiên',
      desc: 'Hoàn thành bài học đầu tiên',
      emoji: '🎓',
      done: true,
      progress: 1.0,
      current: 1, total: 1,
      color: const Color(0xFF4CAF50),
    ),
    _Achievement(
      title: 'Người chơi giỏi',
      desc: 'Hoàn thành 10 trò chơi',
      emoji: '🎮',
      done: false,
      progress: 0.7,
      current: 7, total: 10,
      color: const Color(0xFFE91E63),
    ),
    _Achievement(
      title: '5 ngày liên tiếp',
      desc: 'Học 5 ngày liên tiếp',
      emoji: '🔥',
      done: true,
      progress: 1.0,
      current: 5, total: 5,
      color: const Color(0xFFFF9800),
    ),
    _Achievement(
      title: 'Bạn đọc chăm chỉ',
      desc: 'Hoàn thành 20 bài tập đọc',
      emoji: '📖',
      done: false,
      progress: 0.35,
      current: 7, total: 20,
      color: const Color(0xFF5B9CF5),
    ),
    _Achievement(
      title: 'Nhà vô địch',
      desc: 'Đạt 100% trong bài kiểm tra',
      emoji: '🏆',
      done: false,
      progress: 0.0,
      current: 0, total: 1,
      color: const Color(0xFFFFCA28),
    ),
    _Achievement(
      title: 'Tốc độ ánh sáng',
      desc: 'Trả lời đúng trong 3 giây',
      emoji: '⚡',
      done: false,
      progress: 0.4,
      current: 4, total: 10,
      color: const Color(0xFFAB47BC),
    ),
    _Achievement(
      title: 'Bộ sưu tập đầy đủ',
      desc: 'Học hết 33 phụ âm',
      emoji: '🔤',
      done: false,
      progress: 0.24,
      current: 8, total: 33,
      color: const Color(0xFF7E57C2),
    ),
    _Achievement(
      title: 'Viết đẹp',
      desc: 'Hoàn thành 15 bài tập viết',
      emoji: '✍️',
      done: false,
      progress: 0.53,
      current: 8, total: 15,
      color: const Color(0xFF00897B),
    ),
    _Achievement(
      title: 'Nuôi thú vui',
      desc: 'Cho thú cưng ăn 30 lần',
      emoji: '🐱',
      done: false,
      progress: 0.2,
      current: 6, total: 30,
      color: const Color(0xFFEF5350),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _score = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        // Update with real data
        _achievements[0] = _achievements[0].copyWith(
          done: _score!.lettersLearned >= 1,
          progress: _score!.lettersLearned >= 1 ? 1.0 : 0.0,
          current: _score!.lettersLearned >= 1 ? 1 : 0,
        );
        _achievements[2] = _achievements[2].copyWith(
          done: _score!.streak >= 5,
          progress: (_score!.streak / 5).clamp(0.0, 1.0),
          current: _score!.streak.clamp(0, 5),
        );
        _achievements[6] = _achievements[6].copyWith(
          done: _score!.lettersLearned >= 33,
          progress: (_score!.lettersLearned / 33).clamp(0.0, 1.0),
          current: _score!.lettersLearned.clamp(0, 33),
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final done = _achievements.where((a) => a.done).length;
    final total = _achievements.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          _buildHeader(context, done, total),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildCard(_achievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int done, int total) {
    return AppHeader(
      title: '🏆 Thành tích',
      subtitle: '$done/$total hoàn thành',
      onBack: () => Navigator.pop(context),
      gradientColors: const [Color(0xFFF5A623), Color(0xFFFF8F00)],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12)),
        child: Text('$done/$total', style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
    );
  }

  Widget _buildCard(_Achievement a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: a.done
            ? Border.all(color: a.color.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Emoji badge
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: a.done
                  ? a.color.withValues(alpha: 0.15)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: a.done
                  ? Text(a.emoji, style: const TextStyle(fontSize: 28))
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Color(0xFFBDBDBD), BlendMode.srcATop),
                      child: Text(a.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: a.done
                                  ? const Color(0xFF37474F)
                                  : const Color(0xFF9E9E9E))),
                    ),
                    if (a.done)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50), size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(a.desc,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9E9E9E))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: a.progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: AlwaysStoppedAnimation(
                              a.done ? a.color : a.color.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${a.current}/${a.total}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title, desc, emoji;
  final bool done;
  final double progress;
  final int current, total;
  final Color color;

  const _Achievement({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.done,
    required this.progress,
    required this.current,
    required this.total,
    required this.color,
  });

  _Achievement copyWith({bool? done, double? progress, int? current}) {
    return _Achievement(
      title: title, desc: desc, emoji: emoji, color: color, total: total,
      done: done ?? this.done,
      progress: progress ?? this.progress,
      current: current ?? this.current,
    );
  }
}
