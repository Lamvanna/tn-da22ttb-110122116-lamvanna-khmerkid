import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'matching_game_screen.dart';
import 'sorting_game_screen.dart';
import 'letter_find_game_screen.dart';
import 'quiz_game_screen.dart';

/// Màn hình Chơi - Play Screen
/// Hiển thị các trò chơi mini: Ghép hình, Xếp hình, Trò chơi chữ, Đố vui
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Text(
                    'Chơi',
                    style: AppTextStyles.screenTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // ── Game cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Trò chơi',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 16),

                  // Game grid - 2 columns
                  Row(
                    children: [
                      Expanded(
                        child: _buildGameCard(
                          title: 'Ghép hình',
                          description: 'Ghép chữ với phiên âm',
                          icon: Icons.extension_rounded,
                          color: const Color(0xFFFF6B6B),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const MatchingGameScreen(),
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGameCard(
                          title: 'Xếp hình',
                          description: 'Sắp xếp chữ cái',
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF42A5F5),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const SortingGameScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildGameCard(
                          title: 'Trò chơi chữ',
                          description: 'Tìm chữ cái đúng',
                          icon: Icons.abc_rounded,
                          color: const Color(0xFF66BB6A),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const LetterFindGameScreen(),
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGameCard(
                          title: 'Đố vui',
                          description: 'Câu đố về chữ Khmer',
                          icon: Icons.quiz_rounded,
                          color: const Color(0xFFFFCA28),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const QuizGameScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Thành tích ──
                  Text(
                    'Thành tích',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),

                  _buildAchievementCard(
                    title: 'Người chơi giỏi',
                    description: 'Hoàn thành 10 trò chơi',
                    icon: Icons.emoji_events_rounded,
                    progress: 0.7,
                    current: 7,
                    total: 10,
                  ),
                  const SizedBox(height: 10),
                  _buildAchievementCard(
                    title: 'Tốc độ ánh sáng',
                    description: 'Hoàn thành trong 30 giây',
                    icon: Icons.bolt_rounded,
                    progress: 0.4,
                    current: 4,
                    total: 10,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: AppColors.cardShadow.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required IconData icon,
    required double progress,
    required int current,
    required int total,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentYellow, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.progressBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentYellow,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$current/$total',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
