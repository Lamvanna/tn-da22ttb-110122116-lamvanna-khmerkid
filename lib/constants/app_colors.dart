import 'package:flutter/material.dart';

/// Bảng màu ứng dụng - Trích xuất từ Figma design
/// App color palette - Extracted from the Figma design
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── Primary Colors ───────────────────────────────────────────────
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryPurpleLight = Color(0xFF9B8FFF);
  static const Color primaryPurpleDark = Color(0xFF5A52D5);

  // ─── Header Gradient ──────────────────────────────────────────────
  static const Color headerGradientStart = Color(0xFF7B6CF6);
  static const Color headerGradientEnd = Color(0xFF9B8FFF);

  // ─── Accent Colors ────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentRed = Color(0xFFF44336);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentTeal = Color(0xFF26C6DA);

  // ─── Background Colors ────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F2FF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundMint = Color(0xFFE0F7FA); // Pet screen bg

  // ─── Card Colors ──────────────────────────────────────────────────
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // ─── Text Colors ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFBDBDBD);

  // ─── Test Category Colors ─────────────────────────────────────────
  /// Kiểm tra nói - Speaking test (Coral/Red)
  static const Color testSpeaking = Color(0xFFEF5350);
  /// Kiểm tra nghe - Listening test (Blue)
  static const Color testListening = Color(0xFF5C6BC0);
  /// Kiểm tra viết - Writing test (Pink)
  static const Color testWriting = Color(0xFFEC407A);
  /// Kiểm tra tổng hợp - Comprehensive test (Green)
  static const Color testComprehensive = Color(0xFF66BB6A);

  // ─── Star Rating Colors ───────────────────────────────────────────
  static const Color starFilled = Color(0xFFFFD600);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // ─── Progress Bar Colors ──────────────────────────────────────────
  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color progressBackground = Color(0xFFE8E8E8);

  // ─── Pet Stats Colors ─────────────────────────────────────────────
  static const Color statHealth = Color(0xFFEF5350);    // ❤️ Heart
  static const Color statHunger = Color(0xFFFF7043);     // 🍗 Hunger
  static const Color statEnergy = Color(0xFF42A5F5);     // ⚡ Energy
  static const Color statHappiness = Color(0xFFFFCA28);  // 😊 Happiness

  // ─── Shop Tab Colors ──────────────────────────────────────────────
  static const Color shopFood = Color(0xFFF44336);       // Đồ ăn
  static const Color shopItems = Color(0xFFFFFFFF);       // Vật phẩm
  static const Color shopDecor = Color(0xFFFFFFFF);       // Trang trí

  // ─── Navigation Colors ────────────────────────────────────────────
  static const Color navActive = Color(0xFF6C63FF);
  static const Color navInactive = Color(0xFF9E9E9E);

  // ─── Gradient Definitions ─────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7B6CF6), Color(0xFF6C63FF)],
  );

  // ─── Difficulty Badge Colors ──────────────────────────────────────
  static const Color difficultyEasy = Color(0xFF4CAF50);
  static const Color difficultyMedium = Color(0xFFFF9800);
  static const Color difficultyHard = Color(0xFFF44336);
}
