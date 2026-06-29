import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';
import '../../services/local_notification_service.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_header.dart';
import '../auth/login_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_manager.dart';

/// Màn hình Cài đặt — Settings Screen
/// Nhóm theo chức năng: Âm thanh & Giọng đọc · Chung · Dữ liệu · Giới thiệu.
/// Mọi tùy chọn được lưu vào [StorageService] và áp dụng ngay.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  StorageService? _storage;
  bool _loading = true;

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _offlineEnabled = false;
  String _selectedLanguage = 'vi';
  TtsSpeed _speed = TtsSpeed.normal;

  AnimationController? _animCtrl;
  Animation<double>? _fadeIn;

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animCtrl = ctrl;
    _fadeIn = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await StorageService.getInstance();
    setState(() {
      _storage = s;
      _soundEnabled = s.getSoundEnabled();
      _hapticsEnabled = s.getHapticsEnabled();
      _offlineEnabled = s.getOfflineEnabled();
      _selectedLanguage = LanguageManager.instance.currentLocale.languageCode;
      _speed = TtsSpeed.values[s.getTtsSpeed().clamp(0, 2)];
      _loading = false;
    });
    _animCtrl?.forward();
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
          // Header đồng bộ với các trang khác
          AppHeader(
            title: context.translate('settings.title'),
            subtitle: context.translate('settings.subtitle'),
            onBack: () => Navigator.pop(context),
            bottomPadding: 24.h,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : FadeTransition(
                    opacity: _fadeIn ?? const AlwaysStoppedAnimation(1.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Âm thanh & Giọng đọc ──
                          _buildSectionLabel(context.translate('settings.section_audio')),
                          SizedBox(height: 10.h),
                          _buildAudioCard(),

                          SizedBox(height: 24.h),

                          // ── Ngôn ngữ hiển thị ──
                          _buildSectionLabel(context.translate('settings.section_lang')),
                          SizedBox(height: 10.h),
                          _buildLanguageCard(),

                          SizedBox(height: 24.h),

                          // ── Dữ liệu & Tài khoản ──
                          _buildSectionLabel(context.translate('settings.section_data')),
                          SizedBox(height: 10.h),
                          _buildDataCard(),

                          SizedBox(height: 24.h),

                          // ── Giới thiệu ──
                          _buildSectionLabel(context.translate('settings.section_about')),
                          SizedBox(height: 10.h),
                          _buildAboutCard(),

                          if (kDebugMode) ...[
                            SizedBox(height: 24.h),
                            _buildSectionLabel('Kiểm thử & Phát triển'),
                            SizedBox(height: 10.h),
                            _buildDebugCard(),
                          ],

                          SizedBox(height: 20.h),
                          _buildVersionFooter(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Section label
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Card wrapper
  // ═══════════════════════════════════════════════════════════════════════
  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF304060).withValues(alpha: 0.05),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: const Color(0xFF304060).withValues(alpha: 0.02),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(children: children),
      ),
    );
  }

  Widget _thinDivider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════
  //  Tile helper
  // ═══════════════════════════════════════════════════════════════════════
  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.sp),
              ),
              SizedBox(width: 14.w),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: 8.w), trailing],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Premium switch
  // ═══════════════════════════════════════════════════════════════════════
  Widget _premiumSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = AppColors.primary,
  }) {
    return Transform.scale(
      scale: 0.85,
      child: Switch.adaptive(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: activeColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFE0E0E0),
        trackOutlineColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
        onChanged: onChanged,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  🔊 Âm thanh card
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAudioCard() {
    return _settingsCard(children: [
      // Sound toggle
      _settingsTile(
        icon:
            _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        iconColor: AppColors.primary,
        title: context.translate('settings.sound'),
        subtitle: context.translate('settings.sound_desc'),
        trailing: _premiumSwitch(
          value: _soundEnabled,
          activeColor: AppColors.primary,
          onChanged: (v) async {
            _tap();
            setState(() => _soundEnabled = v);
            TtsService.instance.soundEnabled = v;
            await _storage?.setSoundEnabled(v);
          },
        ),
      ),
      _thinDivider(),

      // Speed selector
      _buildSpeedSection(),
      _thinDivider(),

      // Haptics toggle
      _settingsTile(
        icon: Icons.vibration_rounded,
        iconColor: AppColors.tertiary,
        title: context.translate('settings.haptics'),
        subtitle: context.translate('settings.haptics_desc'),
        trailing: _premiumSwitch(
          value: _hapticsEnabled,
          activeColor: AppColors.tertiary,
          onChanged: (v) async {
            if (v) HapticFeedback.lightImpact();
            setState(() => _hapticsEnabled = v);
            await _storage?.setHapticsEnabled(v);
          },
        ),
      ),
    ]);
  }

  // ─── Tốc độ đọc ──────────────────────────────────────────────────────
  Widget _buildSpeedSection() {
    final opacity = _soundEnabled ? 1.0 : 0.35;
    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !_soundEnabled,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.speed_rounded,
                        color: AppColors.secondary, size: 20.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('settings.speech_speed'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.translate('settings.speech_speed_desc'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              // Speed chips
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    _speedChip(TtsSpeed.slow, context.translate('settings.speed_slow'),
                        Icons.directions_walk_rounded),
                    _speedChip(TtsSpeed.normal, context.translate('settings.speed_normal'),
                        Icons.directions_run_rounded),
                    _speedChip(TtsSpeed.fast, context.translate('settings.speed_fast'),
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
          TtsService.instance.speak('ក', fallbackText: 'co');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15.sp,
                color: selected ? AppColors.primary : AppColors.textHint,
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  🌐 Ngôn ngữ card — Dropdown dynamic selection
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLanguageCard() {
    final manager = LanguageManager.instance;
    final currentLang = manager.currentLanguage;

    return _settingsCard(children: [
      _settingsTile(
        icon: Icons.language_rounded,
        iconColor: const Color(0xFF1E6DEB),
        title: context.translate('settings.section_lang'),
        subtitle: '${currentLang.flag} ${currentLang.nativeName} · ${currentLang.name}',
        trailing: Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint, size: 22.sp),
        onTap: _showLanguageDropdown,
      ),
    ]);
  }

  Future<void> _showLanguageDropdown() async {
    _tap();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _LanguageBottomSheet(),
    );
    // Reload state after language changes
    setState(() {
      _selectedLanguage = LanguageManager.instance.currentLocale.languageCode;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  📦 Dữ liệu & Tài khoản card
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDataCard() {
    return _settingsCard(children: [
      _settingsTile(
        icon: Icons.cloud_download_rounded,
        iconColor: AppColors.violet,
        title: context.translate('settings.offline_mode'),
        subtitle: context.translate('settings.offline_mode_desc'),
        trailing: _premiumSwitch(
          value: _offlineEnabled,
          activeColor: AppColors.violet,
          onChanged: (v) async {
            _tap();
            setState(() => _offlineEnabled = v);
            await _storage?.setOfflineEnabled(v);
          },
        ),
      ),
      _thinDivider(),
      
      // Đặt lại tiến độ học
      _settingsTile(
        icon: Icons.refresh_rounded,
        iconColor: AppColors.secondary,
        title: context.translate('settings.reset_progress'),
        subtitle: context.translate('settings.reset_progress_desc'),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 20.sp),
        onTap: _confirmResetProgress,
      ),
      _thinDivider(),

      _settingsTile(
        icon: Icons.logout_rounded,
        iconColor: AppColors.errorRed,
        title: context.translate('settings.logout'),
        subtitle: context.translate('settings.logout_desc'),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 20.sp),
        onTap: _confirmLogout,
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ℹ️ Giới thiệu card
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAboutCard() {
    return _settingsCard(children: [
      _settingsTile(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
        title: context.translate('settings.about_app'),
        subtitle: context.translate('settings.about_app_desc'),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'v1.0.0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDebugCard() {
    return _settingsCard(children: [
      _settingsTile(
        icon: Icons.notification_important_rounded,
        iconColor: Colors.orange,
        title: 'Gửi thông báo test tức thì',
        subtitle: 'Yêu cầu server đẩy thông báo socket',
        onTap: () async {
          _tap();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
          
          final res = await NotificationService().sendTestReminder();
          
          if (mounted) {
            Navigator.pop(context); // Dismiss spinner
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['success'] == true ? 'Đã yêu cầu server gửi thông báo!' : 'Lỗi: ${res['message']}'),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
      _thinDivider(),
      _settingsTile(
        icon: Icons.timer_rounded,
        iconColor: Colors.blue,
        title: 'Giả lập thông báo sau 5 giây',
        subtitle: 'Lên lịch offline và thoát app để test',
        onTap: () async {
          _tap();
          await LocalNotificationService().scheduleNotification(
            id: 9999,
            title: '🐘 Voi con nhớ bé quá!',
            body: 'Bé ơi, quay lại học chữ Khmer cùng Voi con nhé! 🌟',
            scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã lên lịch 5 giây! Hãy bấm Home thoát app ngay để test.'),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Footer
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildVersionFooter() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Text(
          '${context.translate('common.app_name')} · ${context.translate('settings.version')} 1.0.0',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Đặt lại tiến độ học dialog
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _confirmResetProgress() async {
    _tap();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        icon: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.refresh_rounded,
              color: AppColors.secondary, size: 28.sp),
        ),
        title: Text(context.translate('settings.reset_confirm_title'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        content: Text(
            context.translate('settings.reset_confirm_desc'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(context.translate('common.cancel'),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.translate('settings.reset_confirm_btn'),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      await _storage?.clearProgress();

      if (!mounted) return;
      Navigator.pop(context); // Dismiss spinner

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('settings.reset_success')),
          backgroundColor: AppColors.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Đăng xuất dialog
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _confirmLogout() async {
    _tap();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        icon: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: AppColors.errorRed.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.logout_rounded,
              color: AppColors.errorRed, size: 28.sp),
        ),
        title: Text(context.translate('settings.logout_confirm_title'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        content: Text(
            context.translate('settings.logout_confirm_desc'),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(context.translate('common.cancel'),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.translate('settings.logout'),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
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
}

// ═══════════════════════════════════════════════════════════════════════
//  🌐 Language Bottom Sheet — Combobox Dropdown with Search
// ═══════════════════════════════════════════════════════════════════════
class _LanguageBottomSheet extends StatefulWidget {
  const _LanguageBottomSheet();

  @override
  State<_LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<_LanguageBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _currentCode;

  @override
  void initState() {
    super.initState();
    _currentCode = LanguageManager.instance.currentLocale.languageCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = LanguageManager.instance;
    
    // Filter languages based on search query dynamically
    final filteredLanguages = manager.supportedLanguages.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.code.toLowerCase().contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3F0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6DEB).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: const Color(0xFF1E6DEB), size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  context.translate('settings.select_lang'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          
          // Search Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.textHint, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.translate('settings.search_lang'),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 18.sp),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          
          // Dynamic language selector listing supporting full Unicode
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: filteredLanguages.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Text(
                      'No matching languages found',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: filteredLanguages.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Divider(
                        height: 1,
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final lang = filteredLanguages[index];
                      final isSelected = _currentCode == lang.code;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            setState(() => _currentCode = lang.code);
                            // Call manager to apply locale globally and trigger rebuilds
                            await LanguageManager.instance.changeLanguage(lang.code);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 14.h),
                            color: isSelected
                                ? const Color(0xFF1E6DEB).withValues(alpha: 0.05)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                // Flag
                                Text(
                                  lang.flag,
                                  style: TextStyle(fontSize: 28.sp),
                                ),
                                SizedBox(width: 14.w),
                                // Name + nativeName with correct fonts
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.nativeName,
                                        style: GoogleFonts.getFont(
                                          lang.fontFamily,
                                          fontSize: 15.sp,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF1E6DEB)
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        lang.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Checkmark
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: const Color(0xFF1E6DEB),
                                    size: 22.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12.h),
        ],
      ),
    );
  }
}
