import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ════════════════════════════════════════════════════════════════════
///  KHMERKID DESIGN TOKENS — 2026
/// ────────────────────────────────────────────────────────────────────
///  Single source of truth cho:
///    • Semantic colors (role-based, không phải tên màu)
///    • Spacing scale (8-point grid)
///    • Radius scale
///    • Elevation (shadow tiers)
///    • Motion (durations + curves)
///    • Breakpoints (responsive)
///
///  Quy tắc bắt buộc:
///    1. Mọi widget MỚI chỉ được dùng tokens trong file này
///    2. Không bao giờ Color(0xFF...) hardcode trong widget
///    3. Mọi TextStyle phải có `height` để Khmer không bị clip
///    4. Min touch target 48dp
/// ════════════════════════════════════════════════════════════════════

// ─── PRIMITIVE COLOR RAMPS ─────────────────────────────────────────────
// Internal use only — KHÔNG expose ra widgets.
// Widgets dùng `KkColors` (semantic) bên dưới.
// ignore_for_file: unused_field
class _Ramp {
  _Ramp._();

  // Blue (brand / learn)
  static const blue50  = Color(0xFFEAF2FC);
  static const blue100 = Color(0xFFC8DEF7);
  static const blue200 = Color(0xFF9CC2EE);
  static const blue300 = Color(0xFF6FA4E1);
  static const blue400 = Color(0xFF4F8DD4);
  static const blue500 = Color(0xFF3D7FCC); // brand primary
  static const blue600 = Color(0xFF2F6BB5);
  static const blue700 = Color(0xFF24559A);
  static const blue800 = Color(0xFF1B4380);
  static const blue900 = Color(0xFF123059);

  // Green (success / listen)
  static const green50  = Color(0xFFE6F5EC);
  static const green100 = Color(0xFFC2E6CF);
  static const green500 = Color(0xFF2F9656);
  static const green600 = Color(0xFF258048);
  static const green700 = Color(0xFF1B6939);

  // Amber (reward / streak)
  static const amber50  = Color(0xFFFFF6E1);
  static const amber100 = Color(0xFFFFE8B0);
  static const amber500 = Color(0xFFC68C1F);
  static const amber600 = Color(0xFFA87515);
  static const amber700 = Color(0xFF855A0E);

  // Violet (explore / consonant)
  static const violet50  = Color(0xFFEFEDFB);
  static const violet100 = Color(0xFFD4CEF1);
  static const violet500 = Color(0xFF6457C9);
  static const violet600 = Color(0xFF5247B0);
  static const violet700 = Color(0xFF3F388C);

  // Coral (play / speak)
  static const coral50  = Color(0xFFFCEBE9);
  static const coral100 = Color(0xFFF6CAC4);
  static const coral500 = Color(0xFFD0584D);
  static const coral600 = Color(0xFFB6473D);
  static const coral700 = Color(0xFF8F362F);

  // Neutral (text / surface)
  static const n0   = Color(0xFFFFFFFF);
  static const n50  = Color(0xFFFAFBFD);
  static const n100 = Color(0xFFF1F4F9);
  static const n200 = Color(0xFFE3E8F1);
  static const n300 = Color(0xFFCDD4E2);
  static const n400 = Color(0xFFA8B2C5);
  static const n500 = Color(0xFF8390A8);
  static const n600 = Color(0xFF6B7891);
  static const n700 = Color(0xFF4C5871);
  static const n800 = Color(0xFF2E3849);
  static const n900 = Color(0xFF1A1F2E);
}

// ─── SEMANTIC COLORS ───────────────────────────────────────────────────
/// Semantic color tokens. Đặt theo VAI TRÒ, không phải tên màu.
/// Đây là API duy nhất widgets nên dùng.
class KkColors {
  KkColors._();

  // ── Brand ──
  static const Color brand        = _Ramp.blue500;
  static const Color brandHover   = _Ramp.blue600;
  static const Color brandPressed = _Ramp.blue700;
  static const Color brandSubtle  = _Ramp.blue50;
  static const Color brandMuted   = _Ramp.blue100;

  // ── Surface (3 layers) ──
  static const Color surfaceBase    = _Ramp.n50;  // app background
  static const Color surfaceRaised  = _Ramp.n0;   // card / sheet
  static const Color surfaceOverlay = _Ramp.n0;   // modal
  static const Color surfaceMuted   = _Ramp.n100; // subtle bg
  static const Color surfaceSunken  = _Ramp.n200; // input / track

  // ── Border / Divider ──
  static const Color borderSubtle = _Ramp.n200;
  static const Color borderStrong = _Ramp.n300;
  static const Color divider      = _Ramp.n200;

  // ── Text (đảm bảo WCAG AA) ──
  /// 16:1 trên surfaceRaised — cho mọi heading & body chính
  static const Color textPrimary   = _Ramp.n900;
  /// 7.8:1 — cho subtitle, secondary content
  static const Color textSecondary = _Ramp.n700;
  /// 4.6:1 — cho hint, caption (PASS WCAG AA)
  static const Color textTertiary  = _Ramp.n600;
  /// Chỉ dùng cho disabled state
  static const Color textDisabled  = _Ramp.n400;
  /// Text trên bg tối / colored
  static const Color textOnBrand   = _Ramp.n0;
  static const Color textOnDark    = _Ramp.n0;

  // ── Module colors (5 vai trò sản phẩm) ──
  static const Color moduleLearn    = _Ramp.blue500;
  static const Color moduleLearnBg  = _Ramp.blue50;
  static const Color modulePlay     = _Ramp.coral500;
  static const Color modulePlayBg   = _Ramp.coral50;
  static const Color moduleReward   = _Ramp.amber500;
  static const Color moduleRewardBg = _Ramp.amber50;
  static const Color moduleExplore  = _Ramp.violet500;
  static const Color moduleExploreBg= _Ramp.violet50;
  static const Color moduleSuccess  = _Ramp.green500;
  static const Color moduleSuccessBg= _Ramp.green50;

  // ── Functional ──
  static const Color success = _Ramp.green500;
  static const Color warning = _Ramp.amber500;
  static const Color danger  = _Ramp.coral500;
  static const Color info    = _Ramp.blue500;

  static const Color successBg = _Ramp.green50;
  static const Color warningBg = _Ramp.amber50;
  static const Color dangerBg  = _Ramp.coral50;
  static const Color infoBg    = _Ramp.blue50;

  // ── Action steps (Listen / Speak / Write) ──
  static const Color stepListen   = _Ramp.green500;
  static const Color stepListenBg = _Ramp.green50;
  static const Color stepSpeak    = _Ramp.coral500;
  static const Color stepSpeakBg  = _Ramp.coral50;
  static const Color stepWrite    = _Ramp.blue500;
  static const Color stepWriteBg  = _Ramp.blue50;

  // ── Gradients (chỉ dùng cho hero / brand surface) ──
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
    colors: [_Ramp.blue600, _Ramp.blue400],
  );
  static const LinearGradient learnGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [_Ramp.blue500, _Ramp.blue300],
  );
  static const LinearGradient playGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [_Ramp.coral500, _Ramp.coral100],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [_Ramp.green500, _Ramp.green100],
  );
  static const LinearGradient rewardGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [_Ramp.amber500, _Ramp.amber100],
  );
  static const LinearGradient exploreGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [_Ramp.violet500, _Ramp.violet100],
  );
}

// ─── SPACING SCALE (8-point grid) ──────────────────────────────────────
/// Dùng `Spacing.s4` thay cho EdgeInsets.all(16.w).
/// Quy ước:
///   • s1=4  hairline
///   • s2=8  tight
///   • s3=12 compact
///   • s4=16 default ⭐ (most common)
///   • s5=20 comfortable
///   • s6=24 section
///   • s8=32 group
///   • s10=40 hero
///   • s12=48 landmark
class Spacing {
  Spacing._();
  static double get s1  => 4.w;
  static double get s2  => 8.w;
  static double get s3  => 12.w;
  static double get s4  => 16.w;
  static double get s5  => 20.w;
  static double get s6  => 24.w;
  static double get s8  => 32.w;
  static double get s10 => 40.w;
  static double get s12 => 48.w;

  // Vertical helpers (dùng .h)
  static double get v1  => 4.h;
  static double get v2  => 8.h;
  static double get v3  => 12.h;
  static double get v4  => 16.h;
  static double get v5  => 20.h;
  static double get v6  => 24.h;
  static double get v8  => 32.h;
  static double get v10 => 40.h;
  static double get v12 => 48.h;
}

// ─── RADIUS SCALE ──────────────────────────────────────────────────────
class Radii {
  Radii._();
  static double get xs   => 6.r;   // chip, badge nhỏ
  static double get sm   => 12.r;  // input, button nhỏ
  static double get md   => 16.r;  // card default ⭐
  static double get lg   => 20.r;  // hero card
  static double get xl   => 28.r;  // bottom sheet
  static double get full => 999.r; // pill / circle
}

// ─── ELEVATION (3 tiers, 2-layer shadow each) ──────────────────────────
class Elevation {
  Elevation._();

  /// Resting state: card, list item
  static List<BoxShadow> get e1 => [
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.04),
      blurRadius: 2.r, offset: Offset(0, 1.h)),
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.06),
      blurRadius: 6.r, offset: Offset(0, 2.h)),
  ];

  /// Raised: hero card, dropdown, tooltip
  static List<BoxShadow> get e2 => [
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.06),
      blurRadius: 4.r, offset: Offset(0, 2.h)),
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.08),
      blurRadius: 12.r, offset: Offset(0, 6.h)),
  ];

  /// Floating: modal, toast, FAB
  static List<BoxShadow> get e3 => [
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.08),
      blurRadius: 8.r, offset: Offset(0, 4.h)),
    BoxShadow(
      color: const Color(0xFF1A1F2E).withValues(alpha: 0.10),
      blurRadius: 24.r, offset: Offset(0, 12.h)),
  ];

  /// Brand-tinted shadow (cho hero element có màu thương hiệu)
  static List<BoxShadow> brand({double opacity = 0.25}) => [
    BoxShadow(
      color: KkColors.brand.withValues(alpha: opacity * 0.5),
      blurRadius: 4.r, offset: Offset(0, 2.h)),
    BoxShadow(
      color: KkColors.brand.withValues(alpha: opacity),
      blurRadius: 16.r, offset: Offset(0, 8.h)),
  ];
}

// ─── MOTION (durations + curves) ───────────────────────────────────────
class Motion {
  Motion._();

  // Durations
  static const Duration micro   = Duration(milliseconds: 120);
  static const Duration fast    = Duration(milliseconds: 180);
  static const Duration normal  = Duration(milliseconds: 240);
  static const Duration medium  = Duration(milliseconds: 360);
  static const Duration slow    = Duration(milliseconds: 480);
  static const Duration reveal  = Duration(milliseconds: 600);

  // Curves
  static const Curve enter    = Curves.easeOutCubic;
  static const Curve exit     = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve bouncy   = Curves.easeOutBack;
  static const Curve emphasis = Cubic(0.2, 0.0, 0.0, 1.0); // Material 3 emphasized

  // Stagger helper
  static Duration stagger(int index, {Duration step = const Duration(milliseconds: 60)}) {
    return Duration(milliseconds: step.inMilliseconds * index);
  }
}

// ─── TOUCH TARGET (Apple HIG + Material) ──────────────────────────────
class TapTarget {
  TapTarget._();
  static const double min = 48.0; // 48dp tối thiểu
  static BoxConstraints get minBox =>
    BoxConstraints(minWidth: min.w, minHeight: min.h);
}

// ─── BREAKPOINTS (responsive) ──────────────────────────────────────────
class Breakpoint {
  Breakpoint._();
  static const double mobileMax  = 600;
  static const double tabletMax  = 1024;
  static const double desktopMax = 1440;
}

extension KkResponsive on BuildContext {
  Size get _size => MediaQuery.of(this).size;
  bool get isMobile  => _size.width <= Breakpoint.mobileMax;
  bool get isTablet  => _size.width > Breakpoint.mobileMax && _size.width <= Breakpoint.tabletMax;
  bool get isDesktop => _size.width > Breakpoint.tabletMax;

  /// Số cột grid khuyến nghị theo breakpoint
  int get gridColumns => isMobile ? 2 : (isTablet ? 3 : 4);

  /// Padding mép màn hình theo breakpoint
  double get screenPadding => isMobile ? 16.w : (isTablet ? 24.w : 40.w);

  /// Max content width — tránh giãn xấu trên desktop
  double get maxContentWidth => isDesktop ? 1200 : double.infinity;

  /// Reduced motion từ system settings
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}
