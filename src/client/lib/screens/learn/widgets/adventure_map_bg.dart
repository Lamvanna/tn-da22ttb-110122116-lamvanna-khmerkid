import 'dart:math';
import 'package:flutter/material.dart';

/// Vẽ nền bản đồ cartoon phiêu lưu
/// Gồm: đồi cỏ uốn lượn, núi xa, lâu đài, cây dừa, tháp Khmer, mây,
///       nước, đảo nhỏ, cờ
class AdventureMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Lớp 1: Núi xa (nhạt) ──
    _drawDistantMountains(canvas, w, h);

    // ── Lớp 2: Đồi cỏ uốn lượn ──
    _drawRollingHills(canvas, w, h);

    // ── Lớp 3: Tháp Khmer ──
    _drawKhmerTemple(canvas, w * 0.06, h * 0.08, 0.55);
    _drawKhmerTemple(canvas, w * 0.88, h * 0.05, 0.5);
    _drawKhmerTemple(canvas, w * 0.92, h * 0.45, 0.4);
    _drawKhmerTemple(canvas, w * 0.04, h * 0.52, 0.38);

    // ── Lớp 4: Cây dừa ──
    _drawPalmTree(canvas, w * 0.18, h * 0.12, 0.7);
    _drawPalmTree(canvas, w * 0.82, h * 0.15, 0.65);
    _drawPalmTree(canvas, w * 0.1, h * 0.38, 0.55);
    _drawPalmTree(canvas, w * 0.92, h * 0.35, 0.5);
    _drawPalmTree(canvas, w * 0.15, h * 0.6, 0.6);
    _drawPalmTree(canvas, w * 0.85, h * 0.65, 0.55);
    _drawPalmTree(canvas, w * 0.08, h * 0.82, 0.5);
    _drawPalmTree(canvas, w * 0.93, h * 0.8, 0.45);

    // ── Lớp 5: Cây xanh lá ──
    _drawBushyTree(canvas, w * 0.05, h * 0.25, 0.5);
    _drawBushyTree(canvas, w * 0.95, h * 0.28, 0.45);
    _drawBushyTree(canvas, w * 0.03, h * 0.7, 0.55);
    _drawBushyTree(canvas, w * 0.97, h * 0.72, 0.4);

    // ── Lớp 6: Mây ──
    _drawCloud(canvas, w * 0.15, h * 0.02, 0.7);
    _drawCloud(canvas, w * 0.65, h * 0.01, 0.6);
    _drawCloud(canvas, w * 0.4, h * 0.04, 0.5);

    // ── Lớp 7: Hòn đảo nhỏ ──
    _drawSmallIsland(canvas, w * 0.12, h * 0.92);
    _drawSmallIsland(canvas, w * 0.88, h * 0.95);

    // ── Lớp 8: Lâu đài chính ──
    _drawCastle(canvas, w * 0.84, h * 0.1, 0.7);
    _drawCastle(canvas, w * 0.08, h * 0.45, 0.5);
  }

  void _drawDistantMountains(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF81D4FA).withValues(alpha: 0.25);
    final snowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);

    final path = Path();
    path.moveTo(0, h * 0.12);
    path.lineTo(w * 0.08, h * 0.05);
    path.lineTo(w * 0.15, h * 0.1);
    path.lineTo(w * 0.25, h * 0.03);
    path.lineTo(w * 0.35, h * 0.09);
    path.lineTo(w * 0.45, h * 0.02);
    path.lineTo(w * 0.55, h * 0.08);
    path.lineTo(w * 0.65, h * 0.04);
    path.lineTo(w * 0.75, h * 0.1);
    path.lineTo(w * 0.85, h * 0.03);
    path.lineTo(w * 0.95, h * 0.08);
    path.lineTo(w, h * 0.05);
    path.lineTo(w, h * 0.15);
    path.lineTo(0, h * 0.15);
    path.close();
    canvas.drawPath(path, paint);

    // Snow caps
    canvas.drawCircle(Offset(w * 0.25, h * 0.035), 5, snowPaint);
    canvas.drawCircle(Offset(w * 0.45, h * 0.025), 6, snowPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.035), 5, snowPaint);
  }

  void _drawRollingHills(Canvas canvas, double w, double h) {
    // Multiple layers of gentle hills
    final colors = [
      const Color(0xFF81C784).withValues(alpha: 0.12),
      const Color(0xFF66BB6A).withValues(alpha: 0.10),
      const Color(0xFF4CAF50).withValues(alpha: 0.08),
    ];

    for (int i = 0; i < 3; i++) {
      final yOffset = h * 0.15 + i * h * 0.25;
      final path = Path();
      path.moveTo(0, yOffset + 30);

      for (double x = 0; x <= w; x += w / 5) {
        final y = yOffset + sin(x * 0.015 + i * 1.5) * 15;
        path.lineTo(x, y);
      }

      path.lineTo(w, yOffset + 40);
      path.lineTo(0, yOffset + 40);
      path.close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }

  void _drawKhmerTemple(Canvas canvas, double x, double y, double s) {
    final paint = Paint()
      ..color = const Color(0xFFD4A76A).withValues(alpha: 0.35);

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 10 * s, y + 10 * s, 20 * s, 25 * s),
        Radius.circular(2 * s),
      ),
      paint,
    );

    // Tiers (3 levels tapering)
    for (int i = 0; i < 3; i++) {
      final tierW = (18 - i * 4) * s;
      final tierH = 8 * s;
      final tierY = y + (8 - i * 8) * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, tierY),
            width: tierW,
            height: tierH,
          ),
          Radius.circular(1.5 * s),
        ),
        paint,
      );
    }

    // Spire
    final spire = Path();
    spire.moveTo(x - 3 * s, y - 12 * s);
    spire.lineTo(x, y - 22 * s);
    spire.lineTo(x + 3 * s, y - 12 * s);
    spire.close();
    canvas.drawPath(spire, paint);
  }

  void _drawPalmTree(Canvas canvas, double x, double y, double s) {
    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.35)
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trunkPath = Path();
    trunkPath.moveTo(x, y + 35 * s);
    trunkPath.quadraticBezierTo(x - 3 * s, y + 15 * s, x + 2 * s, y);
    canvas.drawPath(trunkPath, trunkPaint);

    // Leaves (5 fronds)
    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.4)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angles = [-2.5, -1.8, -1.2, -0.5, 0.2];
    for (final angle in angles) {
      final endX = x + 2 * s + cos(angle) * 20 * s;
      final endY = y + sin(angle) * 18 * s;
      final leafPath = Path();
      leafPath.moveTo(x + 2 * s, y);
      leafPath.quadraticBezierTo(
        x + 2 * s + cos(angle) * 12 * s,
        y + sin(angle) * 10 * s - 3 * s,
        endX,
        endY,
      );
      canvas.drawPath(leafPath, leafPaint);
    }

    // Coconuts
    final coconutPaint = Paint()
      ..color = const Color(0xFF795548).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x + 1 * s, y + 3 * s), 2.5 * s, coconutPaint);
    canvas.drawCircle(Offset(x + 4 * s, y + 2 * s), 2 * s, coconutPaint);
  }

  void _drawBushyTree(Canvas canvas, double x, double y, double s) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF6D4C41).withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 2 * s, y, 4 * s, 18 * s),
        Radius.circular(2 * s),
      ),
      trunkPaint,
    );

    final crownPaint = Paint()
      ..color = const Color(0xFF43A047).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x, y - 4 * s), 12 * s, crownPaint);
    canvas.drawCircle(Offset(x - 7 * s, y + 1 * s), 9 * s, crownPaint);
    canvas.drawCircle(Offset(x + 7 * s, y + 1 * s), 9 * s, crownPaint);
  }

  void _drawCloud(Canvas canvas, double x, double y, double s) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 50 * s, height: 18 * s),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x - 15 * s, y + 3 * s),
        width: 30 * s,
        height: 14 * s,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + 15 * s, y + 2 * s),
        width: 35 * s,
        height: 16 * s,
      ),
      paint,
    );
  }

  void _drawSmallIsland(Canvas canvas, double x, double y) {
    final waterPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 5), width: 55, height: 18),
      waterPaint,
    );

    final islandPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 40, height: 12),
      islandPaint,
    );

    // Small flag
    canvas.drawLine(
      Offset(x, y - 2),
      Offset(x, y - 16),
      Paint()
        ..color = const Color(0xFF795548).withValues(alpha: 0.3)
        ..strokeWidth = 1.2,
    );
    final flag = Path();
    flag.moveTo(x, y - 16);
    flag.lineTo(x + 8, y - 14);
    flag.lineTo(x, y - 12);
    flag.close();
    canvas.drawPath(
      flag,
      Paint()..color = const Color(0xFFEF5350).withValues(alpha: 0.35),
    );
  }

  void _drawCastle(Canvas canvas, double x, double y, double s) {
    final wallPaint = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.3);
    final roofPaint = Paint()
      ..color = const Color(0xFFE57373).withValues(alpha: 0.25);

    // Main wall
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 14 * s, y, 28 * s, 35 * s),
        Radius.circular(2 * s),
      ),
      wallPaint,
    );

    // Towers
    canvas.drawRect(
      Rect.fromLTWH(x - 18 * s, y - 5 * s, 10 * s, 40 * s),
      wallPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 8 * s, y - 5 * s, 10 * s, 40 * s),
      wallPaint,
    );

    // Tower roofs
    for (final tx in [x - 13 * s, x + 13 * s]) {
      final roof = Path();
      roof.moveTo(tx - 7 * s, y - 5 * s);
      roof.lineTo(tx, y - 18 * s);
      roof.lineTo(tx + 7 * s, y - 5 * s);
      roof.close();
      canvas.drawPath(roof, roofPaint);
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 4 * s, y + 20 * s, 8 * s, 15 * s),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.2),
    );

    // Windows
    final windowPaint = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromLTWH(x - 9 * s, y + 8 * s, 5 * s, 6 * s),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 4 * s, y + 8 * s, 5 * s, 6 * s),
      windowPaint,
    );

    // Flag on top
    canvas.drawLine(
      Offset(x - 13 * s, y - 18 * s),
      Offset(x - 13 * s, y - 25 * s),
      Paint()
        ..color = const Color(0xFF795548).withValues(alpha: 0.3)
        ..strokeWidth = 1.2,
    );
    final flag = Path();
    flag.moveTo(x - 13 * s, y - 25 * s);
    flag.lineTo(x - 6 * s, y - 23 * s);
    flag.lineTo(x - 13 * s, y - 21 * s);
    flag.close();
    canvas.drawPath(
      flag,
      Paint()..color = const Color(0xFFEF5350).withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
