import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Màn hình Nhiệm vụ hàng ngày
class DailyQuestScreen extends StatefulWidget {
  const DailyQuestScreen({super.key});
  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chestCtrl;
  late Animation<double> _chestBounce;

  final List<_Quest> _quests = [
    _Quest(
      icon: Icons.abc_rounded, title: 'Học 2 chữ cái mới',
      current: 1, total: 2, reward: 50,
      cardColor: Color(0xFFE8F4FD), accentColor: Color(0xFF1976D2), done: false,
    ),
    _Quest(
      icon: Icons.sports_esports_rounded, title: 'Hoàn thành 1 trò chơi',
      current: 1, total: 1, reward: 100,
      cardColor: Color(0xFFE8F5E9), accentColor: Color(0xFF388E3C), done: true,
    ),
    _Quest(
      icon: Icons.auto_stories_rounded, title: 'Đọc 1 câu chuyện',
      current: 0, total: 1, reward: 75,
      cardColor: Color(0xFFFFF3E0), accentColor: Color(0xFFE65100), done: false,
    ),
  ];

  int get _doneCount => _quests.where((q) => q.done).length;

  @override
  void initState() {
    super.initState();
    _chestCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _chestBounce = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _chestCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _chestCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.ambientShadow),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.onBackground, size: 20),
          ),
        ),
        title: Text('Nhiệm vụ hàng ngày',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.ambientShadow),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                const SizedBox(width: 4),
                Text('350', style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildChestCard(),
            const SizedBox(height: 28),
            // Section header
            Row(children: [
              Text('Nhiệm vụ', style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('$_doneCount/${_quests.length} xong',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tertiary)),
              ),
            ]),
            const SizedBox(height: 14),
            ...List.generate(_quests.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildQuestCard(_quests[i]),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.ambientShadow),
      child: Column(children: [
        AnimatedBuilder(
          animation: _chestBounce,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _chestBounce.value), child: child),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFFB74D), Color(0xFFFF8F00)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.25),
                blurRadius: 16, offset: const Offset(0, 6))]),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 18),
        Text('Phần thưởng lớn!', style: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
        const SizedBox(height: 6),
        Text('Mở khóa khi hoàn thành tất cả nhiệm vụ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _doneCount / _quests.length, minHeight: 10,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF43A047)))),
        const SizedBox(height: 8),
        Text('$_doneCount / ${_quests.length} nhiệm vụ hoàn thành',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildQuestCard(_Quest quest) {
    final progress = quest.total > 0 ? quest.current / quest.total : 0.0;
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: quest.cardColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: quest.accentColor.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(children: [
            // Icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: quest.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16)),
              child: Icon(quest.icon, color: quest.accentColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Title + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title, style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.onBackground)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress, minHeight: 8,
                          backgroundColor: quest.accentColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(quest.accentColor))),
                    ),
                    const SizedBox(width: 8),
                    Text('${quest.current}/${quest.total}', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: quest.accentColor)),
                    const SizedBox(width: 6),
                    Text('$pct%', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Star reward
            Column(children: [
              Icon(quest.done ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFB300), size: 26),
              const SizedBox(height: 2),
              Text('+${quest.reward} Sao', style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: quest.done ? AppColors.tertiary : AppColors.textSecondary)),
            ]),
          ]),

          // Completed badge — below, not overlay
          if (quest.done) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 20),
                const SizedBox(width: 6),
                Text('Đã hoàn thành!', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
                const SizedBox(width: 12),
                Text('Đã nhận', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Quest {
  final IconData icon; final String title;
  final int current, total, reward;
  final Color cardColor, accentColor;
  final bool done;
  _Quest({required this.icon, required this.title, required this.current,
    required this.total, required this.reward, required this.cardColor,
    required this.accentColor, required this.done});
}
