import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dollar_one_recognizer.dart';
import 'stroke_guide_data.dart';

class KhmerStrokeTemplate {
  final String character;
  final List<Offset> points; // Preprocessed 128 points
  final List<int> gridOccupancy; // 16x16 grid occupancy (256 elements of 0/1)

  KhmerStrokeTemplate({
    required this.character,
    required this.points,
    required this.gridOccupancy,
  });
}

class KhmerStrokeTemplateData {
  static final Map<String, KhmerStrokeTemplate> _templates = {};

  /// Synchronously get or construct template for a character
  static KhmerStrokeTemplate getTemplate(String character) {
    if (_templates.containsKey(character)) {
      return _templates[character]!;
    }
    
    // Fallback/Default: Generate from StrokeGuideData if available
    final guideStrokes = StrokeGuideData.getStrokes(character);
    List<Offset> rawPoints = [];
    
    if (guideStrokes.isNotEmpty) {
      // Reconstruct path by connecting guide coordinates scaled to 250x250
      for (var s in guideStrokes) {
        double px = s[1] * 250.0;
        double py = s[2] * 250.0;
        rawPoints.add(Offset(px, py));
      }
      // Apply Catmull-Rom spline smoothing to avoid jagged zigzag templates
      rawPoints = _generateCatmullRomSpline(rawPoints);
    } else {
      // If no guide coordinates, construct a fallback simple shape or circle/square
      // Vowels and numbers will fall back here if not dynamically loaded.
      rawPoints = _getDefaultPointsForVowelsAndNumbers(character);
    }

    final preprocessedPoints = DollarOneRecognizer.preprocess(rawPoints);
    final gridOccupancy = computeGrid16x16(preprocessedPoints);

    final template = KhmerStrokeTemplate(
      character: character,
      points: preprocessedPoints,
      gridOccupancy: gridOccupancy,
    );
    
    _templates[character] = template;
    return template;
  }

  /// Check if template has pre-defined guides
  static bool hasGuide(String character) {
    return StrokeGuideData.getStrokes(character).isNotEmpty;
  }

  /// Fallback keypoints for vowels & numbers to ensure 100% offline-first reliability
  static List<Offset> _getDefaultPointsForVowelsAndNumbers(String char) {
    List<Offset> pts = [];
    if (char == 'ា') { // Vowel Aa
      pts = [const Offset(30, 30), const Offset(220, 30), const Offset(220, 220)];
    } else if (char == 'ិ') { // Vowel I
      pts = [const Offset(30, 180), const Offset(125, 40), const Offset(220, 180)];
    } else if (char == 'ី') { // Vowel Ii
      pts = [const Offset(30, 180), const Offset(125, 40), const Offset(220, 180), const Offset(220, 100)];
    } else if (char == '១') { // Number 1
      pts = [const Offset(125, 30), const Offset(125, 220)];
    } else if (char == '២') { // Number 2
      pts = [const Offset(30, 50), const Offset(220, 50), const Offset(30, 180), const Offset(220, 180)];
    } else {
      // Generic beautiful spiral/circle fallback
      for (int i = 0; i < 360; i += 20) {
        double rad = i * math.pi / 180.0;
        pts.add(Offset(125 + 85 * math.cos(rad), 125 + 85 * math.sin(rad)));
      }
    }
    return pts;
  }

  /// Generate a smooth Catmull-Rom Spline curve passing through the control points
  static List<Offset> _generateCatmullRomSpline(List<Offset> controlPoints, {int pointsPerSegment = 24}) {
    if (controlPoints.isEmpty) return [];
    if (controlPoints.length == 1) return [controlPoints[0]];
    if (controlPoints.length == 2) {
      List<Offset> pts = [];
      for (int i = 0; i <= pointsPerSegment; i++) {
        double t = i / pointsPerSegment;
        pts.add(Offset.lerp(controlPoints[0], controlPoints[1], t)!);
      }
      return pts;
    }

    List<Offset> splinePoints = [];
    int n = controlPoints.length;

    for (int i = 0; i < n - 1; i++) {
      Offset p0 = i == 0 ? controlPoints[0] : controlPoints[i - 1];
      Offset p1 = controlPoints[i];
      Offset p2 = controlPoints[i + 1];
      Offset p3 = i == n - 2 ? controlPoints[n - 1] : controlPoints[i + 2];

      for (int j = 0; j <= pointsPerSegment; j++) {
        double t = j / pointsPerSegment;
        double t2 = t * t;
        double t3 = t2 * t;

        double x = 0.5 * (
          (2 * p1.dx) +
          (-p0.dx + p2.dx) * t +
          (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
          (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3
        );

        double y = 0.5 * (
          (2 * p1.dy) +
          (-p0.dy + p2.dy) * t +
          (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
          (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3
        );

        splinePoints.add(Offset(x, y));
      }
    }
    return splinePoints;
  }

  /// Compute grid occupancy bitmap (16x16 grid)
  static List<int> computeGrid16x16(List<Offset> points) {
    final List<int> grid = List.filled(256, 0);
    if (points.isEmpty) return grid;

    // The points are already preprocessed: scaled to 250x250 and centered at (0, 0).
    // Bounding box in this centered space:
    double minX = -125.0, maxX = 125.0;
    double minY = -125.0, maxY = 125.0;

    for (var p in points) {
      // Map x from [-125, 125] to [0, 15]
      int col = (((p.dx - minX) / (maxX - minX)) * 15).clamp(0, 15).toInt();
      // Map y from [-125, 125] to [0, 15]
      int row = (((p.dy - minY) / (maxY - minY)) * 15).clamp(0, 15).toInt();
      
      grid[row * 16 + col] = 1;
    }
    return grid;
  }

  /// Dynamic asynchronous font-traced template loader (Phase 2 & 6 advanced feature)
  static Future<void> loadDynamicFontTemplate(String character) async {
    try {
      // In a headless unit test environment, bypass offscreen rendering to prevent HTTP/Asset Exceptions
      bool isTesting = false;
      try {
        isTesting = Platform.environment.containsKey('FLUTTER_TEST');
      } catch (_) {}
      
      if (isTesting) {
        final template = getTemplate(character);
        _templates[character] = template;
        return;
      }

      final points = await FontTemplateGenerator.generateTemplate(character);
      if (points.isNotEmpty) {
        final preprocessed = DollarOneRecognizer.preprocess(points);
        final grid = computeGrid16x16(preprocessed);
        _templates[character] = KhmerStrokeTemplate(
          character: character,
          points: preprocessed,
          gridOccupancy: grid,
        );
      }
    } catch (e) {
      debugPrint('[KhmerStrokeTemplateData] Error loading dynamic font template: $e');
    }
  }
}

class FontTemplateGenerator {
  static Future<List<Offset>> generateTemplate(String char) async {
    try {
      // Ensure the Google Font is fully loaded in memory before drawing
      try {
        await GoogleFonts.pendingFonts([
          GoogleFonts.battambang(fontWeight: FontWeight.w700),
        ]);
      } catch (e) {
        debugPrint('[FontTemplateGenerator] Failed to preload Google Font Battambang: $e');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));

      final bgPaint = Paint()..color = Colors.black;
      canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), bgPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: GoogleFonts.battambang(
            fontSize: 140,
            fontWeight: FontWeight.w700,
          ).copyWith(
            foreground: Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final x = (200 - textPainter.width) / 2;
      final y = (200 - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(x, y));

      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return [];

      final List<Offset> whitePixels = [];
      final bytes = byteData.buffer.asUint8List();
      
      for (int yGrid = 0; yGrid < 200; yGrid += 3) {
        for (int xGrid = 0; xGrid < 200; xGrid += 3) {
          int index = (yGrid * 200 + xGrid) * 4;
          int r = bytes[index];
          int g = bytes[index + 1];
          int b = bytes[index + 2];
          
          if (r > 150 && g > 150 && b > 150) {
            whitePixels.add(Offset(xGrid.toDouble(), yGrid.toDouble()));
          }
        }
      }

      if (whitePixels.isEmpty) return [];

      final List<Offset> tracedPath = [];
      final List<bool> visited = List.filled(whitePixels.length, false);

      int currentIndex = 0;
      double minVal = double.infinity;
      for (int i = 0; i < whitePixels.length; i++) {
        double val = whitePixels[i].dy * 2 + whitePixels[i].dx;
        if (val < minVal) {
          minVal = val;
          currentIndex = i;
        }
      }

      tracedPath.add(whitePixels[currentIndex]);
      visited[currentIndex] = true;

      for (int step = 1; step < whitePixels.length; step++) {
        int nextIndex = -1;
        double minDistance = double.infinity;
        Offset currentPt = whitePixels[currentIndex];

        for (int i = 0; i < whitePixels.length; i++) {
          if (!visited[i]) {
            double dist = (whitePixels[i] - currentPt).distanceSquared;
            if (dist < minDistance) {
              minDistance = dist;
              nextIndex = i;
            }
          }
        }

        if (nextIndex != -1) {
          tracedPath.add(whitePixels[nextIndex]);
          visited[nextIndex] = true;
          currentIndex = nextIndex;
        } else {
          break;
        }
      }

      return tracedPath;
    } catch (e) {
      debugPrint('[FontTemplateGenerator] Error generating template: $e');
      return [];
    }
  }
}
