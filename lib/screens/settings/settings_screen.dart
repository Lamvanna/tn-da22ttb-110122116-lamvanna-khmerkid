import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_header.dart';

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

  // Kết nối máy chủ
  final _serverCtrl = TextEditingController();
  String _currentServer = '';
  bool _detecting = false;

  static const _langKeys = {'km': 'khmer', 'vi': 'vietnam', 'en': 'english'};
  static const _langStore = {'khmer': 'km', 'vietnam': 'vi', 'english': 'en'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    final manual = await AuthService.getManualServerUrl();
    setState(() {
      _storage = s;
      _soundEnabled = s.getSoundEnabled();
      _hapticsEnabled = s.getHapticsEnabled();
      _offlineEnabled = s.getOfflineEnabled();
      _selectedLanguage = _langKeys[s.getLanguage()] ?? 'vietnam';
      _speed = TtsSpeed.values[s.getTtsSpeed().clamp(0, 2)];
      _currentServer = AuthService.currentServerUrl;
      if (manual != null) _serverCtrl.text = _displayHost(manual);
      _loading = false;
    });
  }

  /// Rút gọn URL "http://192.168.1.50:5000/api" → "192.168.1.50" để hiển thị.
  String _displayHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
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
            title: '⚙️ ${AppStrings.settingsTitle}',
            subtitle: AppStrings.settingsSubtitle,
            onBack: () => Navigator.pop(context),
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
                          _buildResetTile(),
                        ]),
                        const SizedBox(height: 22),
                        _sectionHeader(AppStrings.sectionServer,
                            Icons.dns_rounded, AppColors.secondary),
                        _card([_buildServerSection()]),
                        const SizedBox(height: 22),
                        _sectionHeader(AppStrings.sectionAbout,
                            Icons.info_outline_rounded, AppColors.violet),
                        _card([_buildAboutTile()]),
                        const SizedBox(height: 8),
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
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Divider(height: 1, color: AppColors.outlineVariant),
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
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
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

  // === sections appended below ===

  // ─── Âm thanh ─────────────────────────────────────────────────────
  Widget _buildSoundToggle() {
    return _tile(
      icon: _soundEnabled
          ? Icons.volume_up_rounded
          : Icons.volume_off_rounded,
      color: AppColors.coral,
      title: AppStrings.sound,
      desc: AppStrings.soundDesc,
      trailing: Switch(
        value: _soundEnabled,
        activeThumbColor: AppColors.tertiary,
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.speed_rounded,
                        color: AppColors.coral, size: 24),
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
              Row(
                children: [
                  _speedChip(TtsSpeed.slow, AppStrings.speedSlow,
                      Icons.directions_walk_rounded),
                  const SizedBox(width: 8),
                  _speedChip(TtsSpeed.normal, AppStrings.speedNormal,
                      Icons.directions_run_rounded),
                  const SizedBox(width: 8),
                  _speedChip(TtsSpeed.fast, AppStrings.speedFast,
                      Icons.bolt_rounded),
                ],
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.coral : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
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
      trailing: Switch(
        value: _hapticsEnabled,
        activeThumbColor: AppColors.tertiary,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: AppColors.primary, size: 24),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: selected
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
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
      trailing: Switch(
        value: _offlineEnabled,
        activeThumbColor: AppColors.tertiary,
        onChanged: (v) async {
          _tap();
          setState(() => _offlineEnabled = v);
          await _storage?.setOfflineEnabled(v);
        },
      ),
    );
  }

  // ─── Đặt lại tiến độ ──────────────────────────────────────────────
  Widget _buildResetTile() {
    return _tile(
      icon: Icons.restart_alt_rounded,
      color: AppColors.errorRed,
      title: AppStrings.resetProgress,
      desc: AppStrings.resetProgressDesc,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textHint),
      onTap: _confirmReset,
    );
  }

  Future<void> _confirmReset() async {
    _tap();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.errorRed, size: 40),
        title: Text(AppStrings.resetConfirmTitle,
            style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
        content: Text(AppStrings.resetConfirmMsg,
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
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
                backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.confirmReset,
                style: AppTextStyles.buttonTextSmall),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage?.clearProgress();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.resetDone),
          backgroundColor: AppColors.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Kết nối máy chủ ──────────────────────────────────────────────
  Widget _buildServerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dns_rounded,
                    color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.serverAddress,
                        style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      _detecting
                          ? AppStrings.serverDetecting
                          : _displayHost(_currentServer),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _detecting
                            ? AppColors.secondary
                            : AppColors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_detecting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _serverCtrl,
            keyboardType: TextInputType.url,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: AppStrings.serverManualHint,
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
              prefixIcon:
                  const Icon(Icons.lan_rounded, color: AppColors.secondary),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.secondary, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _detecting ? null : _redetectServer,
                  icon: const Icon(Icons.radar_rounded, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  label: Text(AppStrings.serverRedetect,
                      style: AppTextStyles.buttonTextSmall
                          .copyWith(color: AppColors.secondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _detecting ? null : _saveManualServer,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  label: Text(AppStrings.serverSaveManual,
                      style: AppTextStyles.buttonTextSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppStrings.serverHelp,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _redetectServer() async {
    _tap();
    setState(() => _detecting = true);
    // Xóa IP thủ công để buộc dò tự động (nếu ô trống)
    if (_serverCtrl.text.trim().isEmpty) {
      await AuthService.setManualServerUrl(null);
    }
    await AuthService.detectActiveServer();
    if (!mounted) return;
    setState(() {
      _currentServer = AuthService.currentServerUrl;
      _detecting = false;
    });
    _snack(AppStrings.serverFound, AppColors.tertiary);
  }

  Future<void> _saveManualServer() async {
    _tap();
    final input = _serverCtrl.text.trim();
    if (input.isEmpty) {
      await AuthService.setManualServerUrl(null);
      await _redetectServer();
      return;
    }
    setState(() => _detecting = true);
    await AuthService.setManualServerUrl(input);
    await AuthService.detectActiveServer();
    if (!mounted) return;
    setState(() {
      _currentServer = AuthService.currentServerUrl;
      _detecting = false;
    });
    _snack(AppStrings.serverManualSaved, AppColors.tertiary);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
