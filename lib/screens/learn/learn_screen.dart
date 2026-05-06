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

/// Màn hình Học - Lộ trình học tập Khmer
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
      return LetterMapView(
        onBack: () => setState(() => _showLetterMap = false),
      );
    }
    if (_showVowels) {
      return VowelScreen(
        onBack: () => setState(() => _showVowels = false),
      );
    }
    return _buildOverview(context);
  }

  Widget _buildOverview(BuildContext context) {
    final letterProg = (_score?.lettersLearned ?? 0) / 33;
    final vowelProg = (_score?.vowelsLearned ?? 0) / 18;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(children: [
                  // Title row with stats
                  Row(children: [
                    // Stars
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, color: AppColors.secondaryLight, size: 18),
                        const SizedBox(width: 4),
                        Text('${_score?.totalStars ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      ]),
                    ),
                    const Spacer(),
                    Text('Lộ trình học',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    // Streak
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.local_fire_department_rounded, color: AppColors.coral, size: 18),
                        const SizedBox(width: 4),
                        Text('${_score?.streak ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
              const SizedBox(height: 16),
              _buildFinishBadge(),
              const SizedBox(height: 8),

              _buildZoneCard(
                align: Alignment.centerRight, padLeft: 50, padRight: 20,
                zone: _Zone(number: 6, title: 'Từ vựng', subtitle: 'Học từ vựng theo chủ đề',
                  icon: Icons.translate_rounded,
                  progress: (_score?.vocabLearned ?? 0) / 38,
                  lessons: '${_score?.vocabLearned ?? 0}/38 từ',
                  color: AppColors.violet,
                  buttonText: 'Học từ vựng',
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VocabularyScreen())))),
              _buildConnector(leftToRight: false),

              _buildZoneCard(
                align: Alignment.centerLeft, padLeft: 20, padRight: 50,
                zone: _Zone(number: 5, title: 'Tập đọc', subtitle: 'Đọc từ và câu đơn giản',
                  icon: Icons.auto_stories_rounded, progress: 0.3, lessons: '6/20 bài',
                  color: AppColors.primary,
                  buttonText: 'Tập đọc',
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReadingScreen())))),
              _buildConnector(leftToRight: true),

              _buildZoneCard(
                align: Alignment.centerRight, padLeft: 50, padRight: 20,
                zone: _Zone(number: 4, title: 'Tập viết', subtitle: 'Viết đúng nét chữ Khmer',
                  icon: Icons.draw_rounded, progress: 0.8, lessons: '16/20 bài',
                  color: AppColors.tertiary,
                  buttonText: 'Tập viết',
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WritingMapScreen())))),
              _buildConnector(leftToRight: false),

              _buildZoneCard(
                align: Alignment.centerLeft, padLeft: 20, padRight: 50,
                zone: _Zone(number: 3, title: 'Đánh vần', subtitle: 'Ghép phụ âm + nguyên âm',
                  icon: Icons.spellcheck_rounded, progress: 0.45, lessons: '9/20 bài',
                  color: AppColors.secondary,
                  buttonText: 'Tiếp tục học',
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SpellingMapScreen())))),
              _buildConnector(leftToRight: true),

              _buildZoneCard(
                align: Alignment.centerRight, padLeft: 50, padRight: 20,
                zone: _Zone(number: 2, title: 'Nguyên âm', subtitle: 'Học 18 nguyên âm Khmer',
                  icon: Icons.record_voice_over_rounded, progress: vowelProg,
                  lessons: '${_score?.vowelsLearned ?? 0}/18 bài',
                  color: AppColors.coral,
                  buttonText: 'Học nguyên âm',
                  onTap: () => setState(() => _showVowels = true))),
              _buildConnector(leftToRight: false),

              _buildZoneCard(
                align: Alignment.centerLeft, padLeft: 20, padRight: 50,
                zone: _Zone(number: 1, title: 'Học chữ cái', subtitle: 'Nhận biết 33 phụ âm Khmer',
                  icon: Icons.abc_rounded, progress: letterProg,
                  lessons: '${_score?.lettersLearned ?? 0}/33 bài',
                  color: AppColors.primary,
                  buttonText: 'Bắt đầu học',
                  onTap: () => setState(() => _showLetterMap = true))),

              const SizedBox(height: 16),
              _buildStartBadge(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      ],
      ),
    );
  }

  Widget _buildZoneCard({
    required Alignment align,
    required double padLeft,
    required double padRight,
    required _Zone zone,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: padLeft, right: padRight),
      child: Align(
        alignment: align,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: zone.color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6)),
              BoxShadow(
                color: const Color(0xFF304060).withValues(alpha: 0.04),
                blurRadius: 40,
                offset: const Offset(0, 16)),
            ],
            border: Border.all(color: zone.color.withValues(alpha: 0.12), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                // Number badge
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [zone.color, zone.color.withValues(alpha: 0.8)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: zone.color.withValues(alpha: 0.25),
                      blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Center(child: Text('${zone.number}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800,
                      color: Colors.white))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.onBackground)),
                    const SizedBox(height: 1),
                    Text(zone.subtitle, style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: zone.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14)),
                    child: Icon(zone.icon, color: zone.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Progress ring
                  SizedBox(
                    width: 52, height: 52,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 52, height: 52,
                        child: CircularProgressIndicator(
                          value: 1.0, strokeWidth: 4,
                          color: zone.color.withValues(alpha: 0.12))),
                      SizedBox(width: 52, height: 52,
                        child: CircularProgressIndicator(
                          value: zone.progress.clamp(0, 1), strokeWidth: 4,
                          color: zone.color, strokeCap: StrokeCap.round)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${(zone.progress.clamp(0, 1) * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800,
                            color: zone.color)),
                        Text(zone.lessons, style: GoogleFonts.plusJakartaSans(
                          fontSize: 8, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                      ]),
                    ]),
                  ),
                  const Spacer(),
                  // Stars reward
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: AppColors.secondary, size: 14),
                      const SizedBox(width: 3),
                      Text('+${zone.number * 5}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: zone.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zone.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                  child: Text(zone.buttonText,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnector({required bool leftToRight}) {
    return SizedBox(
      height: 50,
      child: CustomPaint(
        painter: _PathConnectorPainter(isLeftToRight: leftToRight),
        size: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildFinishBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryLight, AppColors.secondary]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.18),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
        const SizedBox(width: 10),
        Text('Hoàn thành tất cả!',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(width: 8),
        const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
      ]),
    );
  }

  Widget _buildStartBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        Text('Bắt đầu từ đây!',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ]),
    );
  }
}

class _Zone {
  final int number;
  final String title, subtitle, lessons, buttonText;
  final IconData icon;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  _Zone({
    required this.number, required this.title, required this.subtitle,
    required this.icon, required this.progress, required this.lessons,
    required this.color, required this.buttonText, this.onTap,
  });
}

class _PathConnectorPainter extends CustomPainter {
  final bool isLeftToRight;
  _PathConnectorPainter({required this.isLeftToRight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = AppColors.textHint.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final startX = isLeftToRight ? w * 0.35 : w * 0.65;
    final endX = isLeftToRight ? w * 0.65 : w * 0.35;

    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      canvas.drawCircle(
        Offset(startX + (endX - startX) * t, h * 0.2 + (h * 0.6) * t),
        2.5, paint);
    }

    final midX = (startX + endX) / 2;
    canvas.drawCircle(Offset(midX, h / 2), 7,
      Paint()..color = AppColors.secondaryLight);
    canvas.drawCircle(Offset(midX, h / 2), 7,
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
