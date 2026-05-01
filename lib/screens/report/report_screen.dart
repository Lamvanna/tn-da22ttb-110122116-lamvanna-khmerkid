import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/storage_service.dart';
import '../../services/score_service.dart';

/// Màn hình Báo cáo — Thống kê tiến độ học tập cho phụ huynh/giáo viên
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  StorageService? _storage;
  ScoreService? _score;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.getInstance();
    _score = await ScoreService.getInstance();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(children: [
        _buildHeader(context),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent()),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 22),
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded), color: Colors.white),
            Expanded(child: Text('📊 Báo cáo học tập', textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
            child: Text('Dành cho phụ huynh & giáo viên',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
      )),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildOverviewCard(),
        const SizedBox(height: 14),
        _buildProgressCard(),
        const SizedBox(height: 14),
        _buildTestHistoryCard(),
        const SizedBox(height: 14),
        _buildStreakCard(),
        const SizedBox(height: 14),
        _buildRecommendations(),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tổng quan', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF37474F))),
        const SizedBox(height: 16),
        Row(children: [
          _statBox('⭐', '${_score?.totalStars ?? 0}', 'Tổng sao', const Color(0xFFFFB300)),
          const SizedBox(width: 10),
          _statBox('🏆', '${_score?.level ?? 1}', 'Cấp độ', const Color(0xFF7E57C2)),
          const SizedBox(width: 10),
          _statBox('🔥', '${_score?.streak ?? 0}', 'Ngày streak', const Color(0xFFEF5350)),
          const SizedBox(width: 10),
          _statBox('🎖️', '${_score?.totalMedals ?? 0}', 'Huy chương', const Color(0xFF4CAF50)),
        ]),
        const SizedBox(height: 16),
        // Level progress
        Row(children: [
          Text('Tiến trình cấp ${_score?.level ?? 1}:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF757575))),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _score?.levelProgress ?? 0, minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7E57C2))),
          )),
          const SizedBox(width: 8),
          Text('${((_score?.levelProgress ?? 0) * 100).toInt()}%',
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF7E57C2))),
        ]),
      ]),
    );
  }

  Widget _statBox(String emoji, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E))),
      ]),
    ));
  }

  Widget _buildProgressCard() {
    final letterProg = _score?.lettersLearned ?? 0;
    final vowelProg = _score?.vowelsLearned ?? 0;
    final vocabProg = _score?.vocabLearned ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📚 Tiến độ học tập', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF37474F))),
        const SizedBox(height: 16),
        _progressBar('Phụ âm', letterProg, 33, const Color(0xFF5B9CF5)),
        const SizedBox(height: 12),
        _progressBar('Nguyên âm', vowelProg, 18, const Color(0xFFE91E63)),
        const SizedBox(height: 12),
        _progressBar('Từ vựng', vocabProg, 38, const Color(0xFF7E57C2)),
        const SizedBox(height: 12),
        _progressBar('Số Khmer', 10, 10, const Color(0xFF4CAF50)),
      ]),
    );
  }

  Widget _progressBar(String label, int current, int total, Color color) {
    final pct = total > 0 ? current / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF616161))),
        Text('$current/$total (${(pct * 100).toInt()}%)',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct, minHeight: 8,
          backgroundColor: const Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation(color)),
      ),
    ]);
  }

  Widget _buildTestHistoryCard() {
    final history = _storage?.getTestHistory() ?? [];
    final avg = _score?.avgTestScore ?? 0;
    final totalTests = _score?.totalTests ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📝 Kết quả kiểm tra', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF37474F))),
        const SizedBox(height: 14),
        Row(children: [
          _miniStat('Tổng bài', '$totalTests', const Color(0xFF5B9CF5)),
          const SizedBox(width: 10),
          _miniStat('Điểm TB', '${avg.toInt()}%', avg >= 70 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
        ]),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Lịch sử gần đây:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E))),
          const SizedBox(height: 8),
          ...history.reversed.take(5).map((t) {
            final pct = ((t['correct'] as int) / (t['total'] as int) * 100).toInt();
            final diff = ['Dễ', 'TB', 'Khó'][t['difficulty'] as int];
            final date = DateTime.tryParse(t['date'] as String);
            final dateStr = date != null ? '${date.day}/${date.month}' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(pct >= 70 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 16, color: pct >= 70 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
                const SizedBox(width: 8),
                Text('$dateStr — $diff — ${t['correct']}/${t['total']} ($pct%)',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF616161))),
                const Spacer(),
                Row(children: List.generate(3, (i) => Icon(Icons.star_rounded, size: 14,
                    color: i < (t['stars'] as int) ? const Color(0xFFFFD54F) : const Color(0xFFE0E0E0)))),
              ]),
            );
          }),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Chưa có bài kiểm tra nào.', style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF9E9E9E))),
          ),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E))),
      ]),
    ));
  }

  Widget _buildStreakCard() {
    final streak = _score?.streak ?? 0;
    final studyMinutes = _storage?.getTotalStudyMinutes() ?? 0;
    final dailyMinutes = _storage?.getDailyStudyMinutes() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('⏱️ Thời gian học', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF37474F))),
        const SizedBox(height: 14),
        Row(children: [
          _miniStat('Streak', '$streak ngày', const Color(0xFFEF5350)),
          const SizedBox(width: 10),
          _miniStat('Hôm nay', '$dailyMinutes phút', const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          _miniStat('Tổng', '$studyMinutes phút', const Color(0xFF5B9CF5)),
        ]),
      ]),
    );
  }

  Widget _buildRecommendations() {
    final letterProg = _score?.lettersLearned ?? 0;
    final avgScore = _score?.avgTestScore ?? 0;

    final tips = <String>[];
    if (letterProg < 10) tips.add('💡 Nên học thêm phụ âm cơ bản mỗi ngày');
    if (avgScore < 70 && avgScore > 0) tips.add('📝 Cần ôn tập lại — điểm TB dưới 70%');
    if ((_score?.streak ?? 0) < 3) tips.add('🔥 Khuyến khích học liên tục mỗi ngày');
    if ((_score?.vocabLearned ?? 0) < 5) tips.add('📚 Nên bắt đầu học từ vựng theo chủ đề');
    if (tips.isEmpty) tips.add('🎉 Bé đang học rất tốt! Tiếp tục phát huy!');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE082))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💡 Khuyến nghị', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFF57F17))),
        const SizedBox(height: 10),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF616161))),
        )),
      ]),
    );
  }
}
