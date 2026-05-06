import 'package:flutter/material.dart';

/// Bảng màu ứng dụng KhmerKid
/// Design System: 5 màu hài hòa + Neutral
/// 🔵 Primary    — Header, điều hướng, học tập
/// 🟢 Green      — Thành công, hoàn thành
/// 🟡 Gold       — Phần thưởng, sao, xếp hạng
/// 🟣 Violet     — Khám phá, thành tích
/// 🩷 Coral      — Chơi, tương tác
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════
  // 🔵 PRIMARY — Xanh dương (Header, Học, Navigation)
  // ═══════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF4580C4);
  static const Color primaryLight = Color(0xFF6A9DD6);
  static const Color primaryDark = Color(0xFF3468A8);
  static const Color primarySurface = Color(0xFFEDF3FB);

  // ═══════════════════════════════════════════════════════════════════
  // 🟢 GREEN — Xanh lá (Thành công, Listen, Nhiệm vụ)
  // ═══════════════════════════════════════════════════════════════════
  static const Color tertiary = Color(0xFF3DA06A);
  static const Color tertiaryLight = Color(0xFF6BBF8E);
  static const Color tertiaryDark = Color(0xFF2D8054);
  static const Color tertiarySurface = Color(0xFFEDF8F2);

  // ═══════════════════════════════════════════════════════════════════
  // 🟡 GOLD — Vàng ấm (Phần thưởng, Sao, Xếp hạng)
  // ═══════════════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFFD4A430);
  static const Color secondaryLight = Color(0xFFE8BE55);
  static const Color secondaryDark = Color(0xFFB88A20);
  static const Color secondarySurface = Color(0xFFFFF8E8);

  // ═══════════════════════════════════════════════════════════════════
  // 🟣 VIOLET — Tím thanh (Thành tích, Khám phá, Module phụ âm)
  // ═══════════════════════════════════════════════════════════════════
  static const Color violet = Color(0xFF7367D6);
  static const Color violetLight = Color(0xFF9089E0);
  static const Color violetDark = Color(0xFF5F54C0);
  static const Color violetSurface = Color(0xFFF2F0FF);

  // ═══════════════════════════════════════════════════════════════════
  // 🩷 CORAL — Hồng cam (Chơi, Tương tác, Speak)
  // ═══════════════════════════════════════════════════════════════════
  static const Color coral = Color(0xFFE07065);
  static const Color coralLight = Color(0xFFEA9590);
  static const Color coralDark = Color(0xFFC85A50);
  static const Color coralSurface = Color(0xFFFFF0EF);

  // ═══════════════════════════════════════════════════════════════════
  // ⚪ NEUTRAL
  // ═══════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFF6F7FB);
  static const Color surfaceContainerLow = Color(0xFFEDF0F7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFDDE2EE);

  static const Color textPrimary = Color(0xFF2C3345);
  static const Color onBackground = Color(0xFF2C3345);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFADB5BD);

  static const Color cardWhite = surfaceContainerLowest;
  static const Color cardShadow = Color(0x10304060);
  static const Color outlineVariant = Color(0x1A2C3345);

  // ═══════════════════════════════════════════════════════════════════
  // LEGACY ALIASES — backward compatibility
  // ═══════════════════════════════════════════════════════════════════
  static const Color primaryContainer = primaryLight;
  static const Color primaryPurple = primary;
  static const Color primaryPurpleLight = primaryLight;
  static const Color primaryPurpleDark = primaryDark;
  static const Color secondaryContainer = secondaryLight;
  static const Color tertiaryContainer = tertiaryLight;

  // Consonant module → Violet
  static const Color consonantAccent = violet;
  static const Color consonantAccentLight = violetLight;
  static const Color consonantAccentDark = violetDark;
  static const Color consonantBg = violetSurface;

  // Accent aliases
  static const Color accentOrange = secondary;
  static const Color accentYellow = secondaryLight;
  static const Color accentPink = coral;
  static const Color accentRed = coral;
  static const Color accentGreen = tertiary;
  static const Color accentTeal = primaryLight;

  // Background legacy
  static const Color backgroundLight = background;
  static const Color backgroundWhite = surfaceContainerLowest;
  static const Color backgroundMint = secondarySurface;

  // Semantic
  static const Color testSpeaking = coral;
  static const Color testListening = primary;
  static const Color testWriting = secondary;
  static const Color testComprehensive = tertiary;

  static const Color starFilled = secondary;
  static const Color starEmpty = surfaceContainerLow;
  static const Color progressGreen = tertiary;
  static const Color progressBackground = surfaceContainerLow;

  static const Color statHealth = coral;
  static const Color statHunger = secondary;
  static const Color statEnergy = primary;
  static const Color statHappiness = tertiaryLight;

  static const Color shopFood = coral;
  static const Color shopItems = surfaceContainerLowest;
  static const Color shopDecor = surfaceContainerLowest;

  static const Color navActive = primary;
  static const Color navInactive = textHint;

  static const Color difficultyEasy = tertiary;
  static const Color difficultyMedium = secondary;
  static const Color difficultyHard = coral;

  // ═══════════════════════════════════════════════════════════════════
  // 🌈 GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  static const LinearGradient primaryGradient = headerGradient;
  static const LinearGradient consonantGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [violet, violetLight],
  );
  static const LinearGradient purpleGradient = consonantGradient;

  static const LinearGradient listenGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [tertiary, tertiaryLight],
  );
  static const LinearGradient speakGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [coral, coralLight],
  );
  static const LinearGradient writeGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // ═══════════════════════════════════════════════════════════════════
  // 🔲 SHADOWS
  // ═══════════════════════════════════════════════════════════════════
  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: const Color(0xFF304060).withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadowList = [
    BoxShadow(
      color: const Color(0xFF304060).withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF304060).withValues(alpha: 0.03),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
