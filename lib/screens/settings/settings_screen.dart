import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  StorageService? _storage;
  bool _loading = true;

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _offlineEnabled = false;
  String _selectedLanguage = 'vietnam';
  TtsSpeed _speed = TtsSpeed.normal;

  AnimationController? _animCtrl;
  Animation<double>? _fadeIn;

  static const _langKeys = {'km': 'khmer', 'vi': 'vietnam', 'en': 'english'};
  static const _langStore = {'khmer': 'km', 'vietnam': 'vi', 'english': 'en'};

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
      _selectedLanguage = _langKeys[s.getLanguage()] ?? 'vietnam';
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
          // Header đồng bộ với các trang khác (default blue gradient, chiều cao nhỏ)
          AppHeader(
            title: AppStrings.settingsTitle,
            subtitle: AppStrings.settingsSubtitle,
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
                          _buildSectionLabel('Âm thanh & Giọng đọc'),
                          SizedBox(height: 10.h),
                          _buildAudioCard(),

                          SizedBox(height: 24.h),

                          // ── Ngôn ngữ hiển thị ──
                          _buildSectionLabel('Ngôn ngữ hiển thị'),
                          SizedBox(height: 10.h),
                          _buildLanguageCard(),

                          SizedBox(height: 24.h),

                          // ── Dữ liệu & Tài khoản ──
                          _buildSectionLabel('Dữ liệu & Tài khoản'),
                          SizedBox(height: 10.h),
                          _buildDataCard(),

                          SizedBox(height: 24.h),

                          // ── Giới thiệu ──
                          _buildSectionLabel('Giới thiệu'),
                          SizedBox(height: 10.h),
                          _buildAboutCard(),

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
        title: AppStrings.sound,
        subtitle: AppStrings.soundDesc,
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
        title: AppStrings.haptics,
        subtitle: AppStrings.hapticsDesc,
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
                          AppStrings.speechSpeed,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          AppStrings.speechSpeedDesc,
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
  //  🌐 Ngôn ngữ card
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLanguageCard() {
    return _settingsCard(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        child: Column(
          children: [
            _languageOption('🇰🇭', AppStrings.khmer, AppStrings.khmerLang, 'khmer'),
            SizedBox(height: 8.h),
            _languageOption(
                '🇻🇳', AppStrings.vietnamese, AppStrings.vietnameseLang, 'vietnam'),
            SizedBox(height: 8.h),
            _languageOption(
                '🇺🇸', AppStrings.english, AppStrings.englishLang, 'english'),
          ],
        ),
      ),
    ]);
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 24.sp)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('check'),
                      color: AppColors.primary,
                      size: 22.sp)
                  : Container(
                      key: const ValueKey('empty'),
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textHint.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  📦 Dữ liệu & Tài khoản card
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDataCard() {
    return _settingsCard(children: [
      _settingsTile(
        icon: Icons.cloud_download_rounded,
        iconColor: AppColors.violet,
        title: AppStrings.offlineMode,
        subtitle: AppStrings.offlineModeDesc,
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
      _settingsTile(
        icon: Icons.logout_rounded,
        iconColor: AppColors.errorRed,
        title: 'Đăng xuất',
        subtitle: 'Đăng xuất tài khoản khỏi thiết bị',
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
        title: AppStrings.aboutApp,
        subtitle: AppStrings.aboutAppDesc,
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

  // ═══════════════════════════════════════════════════════════════════════
  //  Footer
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildVersionFooter() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Text(
          '${AppStrings.appName} · ${AppStrings.appVersion} 1.0.0',
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
        title: Text('Đăng xuất?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        content: Text(
            'Bạn có chắc chắn muốn đăng xuất tài khoản hiện tại không?',
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
                  child: Text(AppStrings.cancel,
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
                  child: Text('Đăng xuất',
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
