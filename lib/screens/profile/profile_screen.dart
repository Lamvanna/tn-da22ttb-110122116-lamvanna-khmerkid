import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_strings.dart';
import '../pet/pet_screen.dart';
import '../shop/shop_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../report/report_screen.dart';

/// Màn hình Hồ sơ - Profile Screen
/// Hiển thị thông tin cá nhân, thú vui, cửa hàng, cài đặt
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  child: Column(
                    children: [
                      Text(
                        AppStrings.navProfile,
                        style: AppTextStyles.screenTitle,
                      ),
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 40,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bé học giỏi',
                        style: AppTextStyles.cardTitleWhite,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cấp độ: 5',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Menu items ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Stats card
                  _buildStatsCard(),
                  const SizedBox(height: 16),

                  // Menu list
                  _buildMenuItem(
                    icon: Icons.pets_rounded,
                    title: AppStrings.petTitle,
                    subtitle: 'Chăm sóc thú cưng của bạn',
                    color: AppColors.accentPink,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const PetScreen(),
                      ));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.shopping_bag_rounded,
                    title: AppStrings.shopTitle,
                    subtitle: 'Mua đồ cho thú cưng',
                    color: AppColors.accentOrange,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ShopScreen(),
                      ));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.library_books_rounded,
                    title: AppStrings.libraryTitle,
                    subtitle: 'Đọc truyện và bài học',
                    color: AppColors.primaryPurple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const LibraryScreen(),
                      ));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Báo cáo học tập',
                    subtitle: 'Thống kê tiến độ cho phụ huynh',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ReportScreen(),
                      ));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: AppStrings.settingsTitle,
                    subtitle: 'Âm thanh, ngôn ngữ, học offline',
                    color: AppColors.textSecondary,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ));
                    },
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

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('🔥', '7', 'Ngày streak'),
          _buildStatDivider(),
          _buildStatItem('⭐', '1500', 'Tổng sao'),
          _buildStatDivider(),
          _buildStatItem('🏆', '12', 'Huy chương'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.cardTitle),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.progressBackground,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
