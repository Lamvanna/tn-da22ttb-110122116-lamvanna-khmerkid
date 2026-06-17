import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_header.dart';
import '../auth/login_screen.dart';

/// Màn hình Cài đặt — Settings Screen
/// Nhóm theo chức năng: Âm thanh & Giọng đọc · Chung · Dữ liệu · Giới thiệu.
/// Mọi tùy chọn được lưu vào [StorageService] và áp dụng ngay.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StorageService? _storage;
  bool _loading = true;

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _offlineEnabled = false;
  String _selectedLanguage = 'vietnam';
  TtsSpeed _speed = TtsSpeed.normal;

  static const _langKeys = {'km': 'khmer', 'vi': 'vietnam', 'en': 'english'};
  static const _langStore = {'khmer': 'km', 'vietnam': 'vi', 'english': 'en'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    setState(() {
      _storage = s;
      _soundEnabled = s.getSoundEnabled();
      _hapticsEnabled = s.getHapticsEnabled();
      _offlineEnabled = s.getOfflineEnabled();
      _selectedLanguage = _langKeys[s.getLanguage()] ?? 'vietnam';
      _speed = TtsSpeed.values[s.getTtsSpeed().clamp(0, 2)];
      _loading = false;
    });
  }

  void _tap() {
    if (_hapticsEnabled) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: AppStrings.settingsTitle,
            subtitle: AppStrings.settingsSubtitle,
            onBack: () => Navigator.pop(context),
            gradientColors: const [AppColors.primary, AppColors.violet],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                            AppStrings.sectionAudio, Icons.graphic_eq_rounded,
                            AppColors.coral),
                        _card([
                          _buildSoundToggle(),
                          _divider(),
                          _buildSpeedSelector(),
                          _divider(),
                          _buildHapticsToggle(),
                        ]),
                        const SizedBox(height: 22),
                        _sectionHeader(AppStrings.sectionGeneral,
                            Icons.tune_rounded, AppColors.primary),
                        _card([_buildLanguageSection()]),
                        const SizedBox(height: 22),
                        _sectionHeader(AppStrings.sectionData,
                            Icons.storage_rounded, AppColors.tertiary),
                        _card([
                          _buildOfflineToggle(),
                          _divider(),
                          _buildLogoutTile(),
                        ]),
                        const SizedBox(height: 22),
                        _sectionHeader(AppStrings.sectionAbout,
                            Icons.info_outline_rounded, AppColors.violet),
                        _card([_buildAboutTile()]),
                        const SizedBox(height: 16),
                        _buildVersionFooter(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable building blocks ─────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF304060).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      );

  /// Hàng cài đặt chuẩn: icon + tiêu đề + mô tả + widget bên phải.
  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(desc, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Âm thanh ─────────────────────────────────────────────────────
  Widget _buildSoundToggle() {
    return _tile(
      icon: _soundEnabled
          ? Icons.volume_up_rounded
          : Icons.volume_off_rounded,
      color: AppColors.coral,
      title: AppStrings.sound,
      desc: AppStrings.soundDesc,
      trailing: Switch.adaptive(
        value: _soundEnabled,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.tertiary,
        onChanged: (v) async {
          _tap();
          setState(() => _soundEnabled = v);
          TtsService.instance.soundEnabled = v;
          await _storage?.setSoundEnabled(v);
        },
      ),
    );
  }

  // ─── Tốc độ đọc ───────────────────────────────────────────────────
  Widget _buildSpeedSelector() {
    final opacity = _soundEnabled ? 1.0 : 0.4;
    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !_soundEnabled,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.speed_rounded,
                        color: AppColors.coral, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.speechSpeed,
                            style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 2),
                        Text(AppStrings.speechSpeedDesc,
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.03),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _speedChip(TtsSpeed.slow, AppStrings.speedSlow,
                        Icons.directions_walk_rounded),
                    _speedChip(TtsSpeed.normal, AppStrings.speedNormal,
                        Icons.directions_run_rounded),
                    _speedChip(TtsSpeed.fast, AppStrings.speedFast,
                        Icons.bolt_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedChip(TtsSpeed speed, String label, IconData icon) {
    final selected = _speed == speed;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          _tap();
          setState(() => _speed = speed);
          await TtsService.instance.setSpeed(speed);
          // Đọc thử để người dùng nghe ngay tốc độ mới
          TtsService.instance.speak('ក', fallbackText: 'co');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.coral : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.coral : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rung phản hồi ────────────────────────────────────────────────
  Widget _buildHapticsToggle() {
    return _tile(
      icon: Icons.vibration_rounded,
      color: AppColors.secondary,
      title: AppStrings.haptics,
      desc: AppStrings.hapticsDesc,
      trailing: Switch.adaptive(
        value: _hapticsEnabled,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.tertiary,
        onChanged: (v) async {
          if (v) HapticFeedback.lightImpact();
          setState(() => _hapticsEnabled = v);
          await _storage?.setHapticsEnabled(v);
        },
      ),
    );
  }

  // ─── Ngôn ngữ ─────────────────────────────────────────────────────
  Widget _buildLanguageSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.language, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(AppStrings.languageDesc,
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _languageOption('🇰🇭', AppStrings.khmer, AppStrings.khmerLang, 'khmer'),
          const SizedBox(height: 8),
          _languageOption('🇻🇳', AppStrings.vietnamese, AppStrings.vietnameseLang,
              'vietnam'),
          const SizedBox(height: 8),
          _languageOption('🇺🇸', AppStrings.english, AppStrings.englishLang,
              'english'),
        ],
      ),
    );
  }

  Widget _languageOption(
      String flag, String title, String subtitle, String value) {
    final selected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () async {
        _tap();
        setState(() => _selectedLanguage = value);
        await _storage?.setLanguage(_langStore[value] ?? 'vi');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(flag, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textHint.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Học offline ──────────────────────────────────────────────────
  Widget _buildOfflineToggle() {
    return _tile(
      icon: Icons.cloud_download_rounded,
      color: AppColors.tertiary,
      title: AppStrings.offlineMode,
      desc: AppStrings.offlineModeDesc,
      trailing: Switch.adaptive(
        value: _offlineEnabled,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.tertiary,
        onChanged: (v) async {
          _tap();
          setState(() => _offlineEnabled = v);
          await _storage?.setOfflineEnabled(v);
        },
      ),
    );
  }

  // ─── Đăng xuất ────────────────────────────────────────────────────
  Widget _buildLogoutTile() {
    return _tile(
      icon: Icons.logout_rounded,
      color: AppColors.errorRed,
      title: 'Đăng xuất',
      desc: 'Đăng xuất tài khoản hiện tại khỏi thiết bị',
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.errorRed),
      onTap: _confirmLogout,
    );
  }

  Future<void> _confirmLogout() async {
    _tap();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.logout_rounded,
            color: AppColors.errorRed, size: 40),
        title: const Text('Đăng xuất?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản hiện tại không?',
            style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      // Show loading spinner dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
      
      await AuthService().logout();
      
      if (!mounted) return;
      // Dismiss spinner
      Navigator.pop(context);
      
      // Navigate to Login Screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ─── Giới thiệu ───────────────────────────────────────────────────
  Widget _buildAboutTile() {
    return _tile(
      icon: Icons.favorite_rounded,
      color: AppColors.violet,
      title: AppStrings.aboutApp,
      desc: AppStrings.aboutAppDesc,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('v1.0.0',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.violet, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          '${AppStrings.appName} · ${AppStrings.appVersion} 1.0.0',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ),
    );
  }
}
