import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'letter_map_screen.dart';
import 'spelling_map_screen.dart';
import 'writing_map_screen.dart';
import 'reading_screen.dart';
import 'vowel_screen.dart';
import 'vocabulary_screen.dart';
import '../../services/score_service.dart';

/// Màn hình Học - Lộ trình học tập Khmer (dạng danh sách)
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _showLetterMap = false;
  bool _showVowels = false;
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_showLetterMap) {
      return LetterMapView(onBack: () => setState(() => _showLetterMap = false));
    }
    if (_showVowels) {
      return VowelScreen(onBack: () => setState(() => _showVowels = false));
    }
    return _buildOverview(context);
  }

  List<_Zone> _getZones() {
    final lp = (_score?.lettersLearned ?? 0) / 33;
    final vp = (_score?.vowelsLearned ?? 0) / 18;
    return [
      _Zone(n: 1, title: 'Học phụ âm', sub: 'Nhận biết 33 phụ âm Khmer',
        icon: Icons.abc_rounded, prog: lp, total: 33, done: _score?.lettersLearned ?? 0,
        color: const Color(0xFF4A90D9), stars: 10, btn: 'Bắt đầu học',
        onTap: () => setState(() => _showLetterMap = true)),
      _Zone(n: 2, title: 'Học nguyên âm', sub: 'Học 18 nguyên âm Khmer',
        icon: Icons.record_voice_over_rounded, prog: vp, total: 18, done: _score?.vowelsLearned ?? 0,
        color: const Color(0xFFFF7043), stars: 10, btn: 'Bắt đầu học',
        onTap: () => setState(() => _showVowels = true)),
      _Zone(n: 3, title: 'Đánh vần', sub: 'Ghép âm thành tiếng và từ',
        icon: Icons.spellcheck_rounded, prog: 0, total: 30, done: 0,
        color: const Color(0xFF7E57C2), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpellingMapScreen()))),
      _Zone(n: 4, title: 'Tập đọc', sub: 'Làm quen và đọc câu đơn giản',
        icon: Icons.auto_stories_rounded, prog: 0, total: 28, done: 0,
        color: const Color(0xFF42A5F5), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingScreen()))),
      _Zone(n: 5, title: 'Luyện viết', sub: 'Tập viết chữ Khmer đúng nét',
        icon: Icons.draw_rounded, prog: 0, total: 30, done: 0,
        color: const Color(0xFFFFA726), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WritingMapScreen()))),
      _Zone(n: 6, title: 'Đọc hiểu', sub: 'Hiểu nội dung và trả lời câu hỏi',
        icon: Icons.menu_book_rounded, prog: 0, total: 25, done: 0,
        color: const Color(0xFFEC407A), stars: 20, btn: 'Bắt đầu học',
        onTap: () {}),
      _Zone(n: 7, title: 'Khám phá văn hóa', sub: 'Tìm hiểu văn hóa Khmer',
        icon: Icons.temple_buddhist_rounded, prog: 0, total: 20, done: 0,
        color: const Color(0xFF5C6BC0), stars: 20, btn: 'Bắt đầu học',
        onTap: () {}),
    ];
  }

  Widget _buildOverview(BuildContext context) {
    final zones = _getZones();
    final cont = zones.firstWhere((z) => z.prog < 1.0, orElse: () => zones.first);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            const SizedBox(height: 16),
            _buildContinueCard(cont),
            const SizedBox(height: 20),
            ...zones.map((z) => _buildZoneRow(z, isLast: z.n == zones.length)),
            const SizedBox(height: 8),
            _buildStartBanner(),
            const SizedBox(height: 100),
          ]),
        )),
      ]),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(children: [
          // Stars badge - white card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('image/sao.png', width: 18, height: 18),
                const SizedBox(width: 5),
                Text('${_score?.totalStars ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2C3345))),
              ]),
              const SizedBox(height: 2),
              Text('Điểm của bạn', style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF616161))),
            ]),
          ),
          const Spacer(),
          Text('Lộ trình học', style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const Spacer(),
          // Streak badge - white card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('image/Lửa chuổi.png', width: 18, height: 18),
                const SizedBox(width: 5),
                Text('${_score?.streak ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2C3345))),
              ]),
              const SizedBox(height: 2),
              Text('Chuỗi ngày', style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF616161))),
            ]),
          ),
        ]),
      )),
    );
  }

  // ── Continue Learning Card ──
  Widget _buildContinueCard(_Zone zone) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(width: 150, height: 150,
              child: Image.asset('image/Sách.png', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 12),
          // RIGHT: title + progress + reward
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiếp tục học', style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(children: [
                SizedBox(width: 65, height: 65,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 65, height: 65, child: CircularProgressIndicator(
                      value: 1.0, strokeWidth: 5,
                      color: const Color(0xFFFFA726).withValues(alpha: 0.15))),
                    SizedBox(width: 65, height: 65, child: CircularProgressIndicator(
                      value: zone.prog.clamp(0, 1), strokeWidth: 5,
                      color: const Color(0xFFFFA726), strokeCap: StrokeCap.round)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${(zone.prog.clamp(0, 1) * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF2C3345))),
                      Text('${zone.done}/${zone.total} bài', style: GoogleFonts.plusJakartaSans(
                        fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ]),
                  ]),
                ),
                const Spacer(),
                Container(
                  width: 65, height: 65,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('image/sao.png', width: 18, height: 18),
                    const SizedBox(height: 2),
                    Text('+${zone.stars}', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFF0A030))),
                    Text('Điểm', style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: zone.onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB340), Color(0xFFF0A030)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFF0A030).withValues(alpha: 0.30),
                      blurRadius: 6, offset: const Offset(0, 2))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Tiếp tục học', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ]),
                ),
              ),
            ],
          )),
        ]),
      ]),
    );
  }

  Widget _buildZoneRow(_Zone zone, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Timeline: circle + dotted line
          SizedBox(width: 36, child: Column(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: zone.color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: zone.color.withValues(alpha: 0.3),
                  blurRadius: 6, offset: const Offset(0, 2))]),
              child: Center(child: Text('${zone.n}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            if (!isLast)
              Expanded(child: CustomPaint(
                painter: _DottedLinePainter(color: zone.color.withValues(alpha: 0.3)))),
          ])),
          const SizedBox(width: 10),
          // Card
          Expanded(child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: zone.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(zone.icon, color: zone.color, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.title, style: GoogleFonts.plusJakartaSans(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(zone.sub, style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('image/sao.png', width: 14, height: 14),
                    const SizedBox(width: 3),
                    Text('+${zone.stars}', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFF0A030))),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Text('${(zone.prog * 100).toInt()}%', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: zone.color)),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: zone.prog.clamp(0, 1), minHeight: 6,
                    backgroundColor: zone.color.withValues(alpha: 0.12), color: zone.color),
                )),
                const SizedBox(width: 8),
                Text('${zone.done}/${zone.total} bài', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: zone.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(zone.btn, style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ]),
          )),
        ])),
    );
  }

  // ── Start Banner ──
  Widget _buildStartBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1976D2).withValues(alpha: 0.25),
          blurRadius: 16, offset: const Offset(0, 6))]),
      child: Row(children: [
        const Text('🚀', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bắt đầu từ đây!', style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Học mỗi ngày – Tiến bộ mỗi ngày', style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85))),
          ],
        )),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ),
      ]),
    );
  }
}

class _Zone {
  final int n, total, done, stars;
  final String title, sub, btn;
  final IconData icon;
  final double prog;
  final Color color;
  final VoidCallback? onTap;

  _Zone({
    required this.n, required this.title, required this.sub,
    required this.icon, required this.prog,
    required this.total, required this.done,
    required this.color, required this.btn, required this.stars,
    this.onTap,
  });
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    double y = 6;
    while (y < size.height) {
      canvas.drawCircle(Offset(cx, y), 1.5, paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
