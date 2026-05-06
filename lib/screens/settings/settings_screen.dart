import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/app_header.dart';

/// Màn hình Cài đặt - Settings Screen
/// Bao gồm: Âm thanh, Ngôn ngữ (Khmer/Việt/English), Học offline
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _offlineEnabled = false;
  String _selectedLanguage = 'khmer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context),

          // ── Nội dung ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Âm thanh ──
                  _buildSoundToggle(),

                  const SizedBox(height: 16),

                  // ── Ngôn ngữ ──
                  _buildLanguageSection(),

                  const SizedBox(height: 16),

                  // ── Học offline ──
                  _buildOfflineToggle(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: '⚙️ Cài đặt',
      onBack: () => Navigator.pop(context),
    );
  }

  /// Toggle âm thanh
  Widget _buildSoundToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: AppColors.primaryPurple,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.sound, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(AppStrings.soundDesc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
            activeThumbColor: AppColors.accentGreen,
          ),
        ],
      ),
    );
  }

  /// Phần chọn ngôn ngữ
  Widget _buildLanguageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.accentTeal,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.language, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 2),
                  Text(AppStrings.languageDesc, style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 nút ngôn ngữ
          _buildLanguageOption(
            flag: '🇰🇭',
            title: AppStrings.khmer,
            subtitle: AppStrings.khmerLang,
            value: 'khmer',
            isSelected: _selectedLanguage == 'khmer',
          ),
          const SizedBox(height: 10),
          _buildLanguageOption(
            flag: '🇻🇳',
            title: AppStrings.vietnamese,
            subtitle: AppStrings.vietnameseLang,
            value: 'vietnam',
            isSelected: _selectedLanguage == 'vietnam',
          ),
          const SizedBox(height: 10),
          _buildLanguageOption(
            flag: '🇺🇸',
            title: AppStrings.english,
            subtitle: AppStrings.englishLang,
            value: 'english',
            isSelected: _selectedLanguage == 'english',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.textHint.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle học offline
  Widget _buildOfflineToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: AppColors.accentGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.offlineMode, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(AppStrings.offlineModeDesc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: _offlineEnabled,
            onChanged: (v) => setState(() => _offlineEnabled = v),
            activeThumbColor: AppColors.accentGreen,
          ),
        ],
      ),
    );
  }
}
