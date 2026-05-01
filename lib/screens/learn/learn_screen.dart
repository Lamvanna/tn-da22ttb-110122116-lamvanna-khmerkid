import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/adventure_map_bg.dart';
import 'letter_map_screen.dart';
import 'spelling_screen.dart';
import 'reading_screen.dart';
import 'vowel_detail_screen.dart';
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
    return _buildOverview(context);
  }

  Widget _buildOverview(BuildContext context) {
    final letterProg = (_score?.lettersLearned ?? 0) / 33;
    final vowelProg = (_score?.vowelsLearned ?? 0) / 18;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTopCard(),
                    const SizedBox(height: 20),

                    // Đích đến ở trên cùng
                    _buildFinishBadge(),
                    const SizedBox(height: 8),

                    // Zone 6: Từ vựng (trên cùng)
                    _buildZoneCard(
                      align: Alignment.centerRight,
                      padLeft: 50, padRight: 20,
                      zone: _Zone(
                        number: 6,
                        title: 'Từ vựng',
                        subtitle: 'Học từ vựng theo chủ đề',
                        icon: Icons.translate_rounded,
                        progress: (_score?.vocabLearned ?? 0) / 38,
                        lessons: '${_score?.vocabLearned ?? 0}/38 từ',
                        color: const Color(0xFF00897B),
                        borderColor: const Color(0xFF80CBC4),
                        buttonText: 'Học từ vựng',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const VocabularyScreen())),
                      ),
                    ),
                    _buildConnector(leftToRight: false),

                    // Zone 5: Tập đọc
                    _buildZoneCard(
                      align: Alignment.centerLeft,
                      padLeft: 20, padRight: 50,
                      zone: _Zone(
                        number: 5,
                        title: 'Tập đọc',
                        subtitle: 'Đọc từ và câu đơn giản',
                        icon: Icons.auto_stories_rounded,
                        progress: 0.3,
                        lessons: '6/20 bài',
                        color: const Color(0xFF1976D2),
                        borderColor: const Color(0xFF90CAF9),
                        buttonText: 'Tập đọc',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ReadingScreen())),
                      ),
                    ),
                    _buildConnector(leftToRight: true),

                    // Zone 4: Tập viết
                    _buildZoneCard(
                      align: Alignment.centerRight,
                      padLeft: 50, padRight: 20,
                      zone: _Zone(
                        number: 4,
                        title: 'Tập viết',
                        subtitle: 'Viết đúng nét chữ Khmer',
                        icon: Icons.draw_rounded,
                        progress: 0.8,
                        lessons: '16/20 bài',
                        color: const Color(0xFF7B1FA2),
                        borderColor: const Color(0xFFCE93D8),
                        buttonText: 'Tập viết',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SpellingScreen(
                            character: 'ក', romanized: 'Ka'))),
                      ),
                    ),
                    _buildConnector(leftToRight: false),

                    // Zone 3: Đánh vần
                    _buildZoneCard(
                      align: Alignment.centerLeft,
                      padLeft: 20, padRight: 50,
                      zone: _Zone(
                        number: 3,
                        title: 'Đánh vần',
                        subtitle: 'Ghép phụ âm + nguyên âm',
                        icon: Icons.spellcheck_rounded,
                        progress: 0.45,
                        lessons: '9/20 bài',
                        color: const Color(0xFFFF9800),
                        borderColor: const Color(0xFFFFCC80),
                        buttonText: 'Tiếp tục học',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SpellingScreen())),
                      ),
                    ),
                    _buildConnector(leftToRight: true),

                    // Zone 2: Nguyên âm
                    _buildZoneCard(
                      align: Alignment.centerRight,
                      padLeft: 50, padRight: 20,
                      zone: _Zone(
                        number: 2,
                        title: 'Nguyên âm',
                        subtitle: 'Học 18 nguyên âm Khmer',
                        icon: Icons.record_voice_over_rounded,
                        progress: vowelProg,
                        lessons: '${_score?.vowelsLearned ?? 0}/18 bài',
                        color: const Color(0xFFE91E63),
                        borderColor: const Color(0xFFF48FB1),
                        buttonText: 'Học nguyên âm',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const VowelDetailScreen())),
                      ),
                    ),
                    _buildConnector(leftToRight: false),

                    // Zone 1: Học chữ cái (dưới cùng — bắt đầu ở đây)
                    _buildZoneCard(
                      align: Alignment.centerLeft,
                      padLeft: 20, padRight: 50,
                      zone: _Zone(
                        number: 1,
                        title: 'Học chữ cái',
                        subtitle: 'Nhận biết 33 phụ âm Khmer',
                        icon: Icons.abc_rounded,
                        progress: letterProg,
                        lessons: '${_score?.lettersLearned ?? 0}/33 bài',
                        color: const Color(0xFF4CAF50),
                        borderColor: const Color(0xFFA5D6A7),
                        buttonText: 'Bắt đầu học',
                        onTap: () => setState(() => _showLetterMap = true),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildStartBadge(),
                    const SizedBox(height: 30),
          ],
        ),
      ),
    ),
    );
  }

  // ── Top card — 1 hàng gọn ──
  Widget _buildTopCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Color(0xFF0D9488),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lộ trình học tập',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                  color: Color(0xFFF9A825), size: 16),
                const SizedBox(width: 3),
                Text(
                  '${_score?.totalStars ?? 0}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF9A825),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE9E7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF5722), size: 16),
                const SizedBox(width: 3),
                Text(
                  '${_score?.streak ?? 0}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF5722),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone card ──
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
          width: 210,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: zone.borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: zone.color.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: zone.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${zone.number}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      zone.title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                zone.subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: zone.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(zone.icon, color: zone.color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 65, height: 65,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 65, height: 65,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 5,
                            color: zone.color.withValues(alpha: 0.12),
                          ),
                        ),
                        SizedBox(
                          width: 65, height: 65,
                          child: CircularProgressIndicator(
                            value: zone.progress.clamp(0, 1),
                            strokeWidth: 5,
                            color: zone.color,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(zone.progress.clamp(0, 1) * 100).toInt()}%',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: zone.color,
                              ),
                            ),
                            Text(
                              zone.lessons,
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: zone.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zone.color,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: zone.color.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    zone.buttonText,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Path connector ──
  Widget _buildConnector({required bool leftToRight}) {
    return SizedBox(
      height: 50,
      child: CustomPaint(
        painter: _PathConnectorPainter(isLeftToRight: leftToRight),
        size: const Size(double.infinity, 50),
      ),
    );
  }

  // ── Finish badge ──
  Widget _buildFinishBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
            color: Color(0xFF5D4037), size: 26),
          const SizedBox(width: 10),
          Text(
            'Hoàn thành tất cả!',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5D4037),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.workspace_premium_rounded,
            color: Color(0xFF5D4037), size: 24),
        ],
      ),
    );
  }

  // ── Start badge ──
  Widget _buildStartBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded,
            color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'Bắt đầu từ đây!',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_upward_rounded,
            color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

// ── Zone data ──
class _Zone {
  final int number;
  final String title, subtitle, lessons, buttonText;
  final IconData icon;
  final double progress;
  final Color color, borderColor;
  final VoidCallback? onTap;

  _Zone({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.lessons,
    required this.color,
    required this.borderColor,
    required this.buttonText,
    this.onTap,
  });
}

// ── Path connector painter ──
class _PathConnectorPainter extends CustomPainter {
  final bool isLeftToRight;
  _PathConnectorPainter({required this.isLeftToRight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final startX = isLeftToRight ? w * 0.35 : w * 0.65;
    final endX = isLeftToRight ? w * 0.65 : w * 0.35;

    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      canvas.drawCircle(
        Offset(startX + (endX - startX) * t, h * 0.2 + (h * 0.6) * t),
        3, paint,
      );
    }

    final midX = (startX + endX) / 2;
    canvas.drawCircle(Offset(midX, h / 2), 8,
      Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(Offset(midX, h / 2), 8,
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
