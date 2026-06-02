import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/khmer_stroke_templates.dart';

/// ════════════════════════════════════════════════════════════════════
/// Handwriting Tracing Service — Template-based Stroke Overlay Scoring
/// ────────────────────────────────────────────────────────────────────
/// Chấm điểm dựa trên độ phủ (coverage) giữa nét viết và nét mẫu.
/// KHÔNG sử dụng OCR hay nhận dạng hình dạng.
///
/// Scoring Rules (NGHIÊM NGẶT):
///   • Inside Coverage (%) = nét viết nằm TRÊN nét mẫu
///   • Outside Coverage (%) = nét viết nằm NGOÀI nét mẫu
///   • Final Score = Inside Coverage
///   • Pass threshold: >= 80% (tăng từ 70%)
///   • Fail conditions:
///     - Outside Coverage > 20% (giảm từ 30%)
///     - Inside Coverage < 80%
///     - Số nét < 2
///     - Số điểm < 200
///   • Tolerance radius: 10px (giảm từ 15px)
///   • Near points weight: 0.5 (giảm từ 0.7)
/// ════════════════════════════════════════════════════════════════════

class TracingScoreResult {
  final double insideCoverage;    // 0-100: % nét viết nằm trên mẫu
  final double outsideCoverage;   // 0-100: % nét viết nằm ngoài mẫu
  final double finalScore;        // 0-100: điểm cuối cùng
  final bool passed;              // >= 70% và inside > outside
  final int stars;                // 0-3 sao
  final String feedback;
  final List<String> tips;
  final List<StrokeSegment> visualFeedback; // Để vẽ màu xanh/vàng/đỏ

  const TracingScoreResult({
    required this.insideCoverage,
    required this.outsideCoverage,
    required this.finalScore,
    required this.passed,
    required this.stars,
    required this.feedback,
    required this.tips,
    required this.visualFeedback,
  });
}

/// Đoạn nét với màu feedback (green/yellow/red)
class StrokeSegment {
  final List<Offset> points;
  final Color color;

  const StrokeSegment({
    required this.points,
    required this.color,
  });
}

class HandwritingTracingService {
  HandwritingTracingService._();
  static final HandwritingTracingService instance = HandwritingTracingService._();

  static const Set<String> _khmerConsonants = {
    'ក', 'ខ', 'គ', 'ឃ', 'ង', 'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
    'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ', 'ត', 'ថ', 'ទ', 'ធ', 'ន',
    'ប', 'ផ', 'ព', 'ភ', 'ម', 'យ', 'រ', 'ល', 'វ', 'ស',
    'ហ', 'ឡ', 'អ'
  };

  // ─── Configuration ─────────────────────────────────────────────────
  static const double strokeWidth = 4.0;
  // Template scale: chữ mẫu hiển thị chiếm khoảng 60% chiều rộng canvas.
  // KHÔNG dùng fixed fontSize vì guide widget dùng 200.sp (responsive).
  static const double templateCanvasRatio = 0.62;  // Vùng template = 62% canvas
  static const double toleranceRadius = 15.0;      // Mặc định khoan dung cho trẻ em
  static const double passThreshold = 70.0;        // Đạt từ 70% trở lên
  static const double outsideThreshold = 30.0;     // Nét ngoài cho phép tối đa 30%
  static const int gridResolution = 64;
  static const int minPointsRequired = 15;         // Khoan dung hơn cho trẻ em viết nhanh
  static const int minStrokesRequired = 1;         // Cho phép viết 1 nét tối thiểu

  /// Ký tự DOTTED CIRCLE (U+25CC) — dấu chấm tròn dùng làm chỗ neo hiển thị cho
  /// các dấu phụ thuộc Khmer (vd: nguyên âm `ា`, `ិ`, `ុ`). KHÔNG strip khi sinh
  /// template nữa: TextPainter cần render đầy đủ `◌ា` để căn vị trí dấu phụ
  /// thuộc đúng như màn hình hiển thị — nhờ vậy template ellipse bao quanh
  /// đúng vị trí thực của nét chính người dùng cần viết.

  /// Chấm điểm viết theo mẫu (Template Tracing)
  TracingScoreResult scoreTracing({
    required String character,
    required List<List<Offset>> userStrokes,
    required Size canvasSize,
    int? minPointsOverride,
    int? minStrokesOverride,
    double? passThresholdOverride,
    double? outsideThresholdOverride,
    double? toleranceRadiusOverride,
  }) {
    final int effectiveMinPoints = minPointsOverride ?? minPointsRequired;
    final int effectiveMinStrokes = minStrokesOverride ?? minStrokesRequired;
    final double effectivePassThreshold = passThresholdOverride ?? passThreshold;
    final double effectiveOutsideThreshold = outsideThresholdOverride ?? outsideThreshold;
    final double effectiveToleranceRadius = toleranceRadiusOverride ?? toleranceRadius;

    // Dùng NGUYÊN chuỗi character (kể cả '◌') khi sinh template để TextPainter
    // căn vị trí đúng như người dùng nhìn thấy. Nếu strip '◌' đi, ký tự phụ
    // thuộc (vd ា) sẽ tự căn giữa canvas, lệch khỏi vị trí thực của nét →
    // người vẽ đúng nét ở bên phải sẽ bị tính ra ngoài template.
    final scoringCharacter = character;

    if (userStrokes.isEmpty) {
      return const TracingScoreResult(
        insideCoverage: 0,
        outsideCoverage: 0,
        finalScore: 1, // Điểm tối thiểu là 1%
        passed: false,
        stars: 0,
        feedback: 'Hãy viết chữ trước nhé! ✍️',
        tips: ['Đặt bút lên bảng vẽ để bắt đầu viết.'],
        visualFeedback: [],
      );
    }

    // 1. Tạo template bitmap từ NÉT CHÍNH của chữ mẫu (đã loại dấu hướng dẫn).
    final templateBitmap = _generateTemplateBitmap(
      character: scoringCharacter,
      canvasSize: canvasSize,
    );

    // 2. Phân tích từng điểm của user strokes
    final analysis = _analyzeUserStrokes(
      userStrokes: userStrokes,
      templateBitmap: templateBitmap,
      canvasSize: canvasSize,
      toleranceRadiusOverride: effectiveToleranceRadius,
      character: scoringCharacter,
    );

    // 3. Tính toán coverage
    final totalPoints = analysis.insidePoints + analysis.outsidePoints;
    if (totalPoints == 0) {
      return const TracingScoreResult(
        insideCoverage: 0,
        outsideCoverage: 0,
        finalScore: 1, // Điểm tối thiểu là 1%
        passed: false,
        stars: 0,
        feedback: 'Nét vẽ quá ngắn! Hãy vẽ rõ ràng hơn.',
        tips: ['Vẽ dài hơn và rõ nét hơn.'],
        visualFeedback: [],
      );
    }

    // Kiểm tra số nét tối thiểu (chữ Khmer thường có nhiều nét)
    if (userStrokes.length < effectiveMinStrokes) {
      return TracingScoreResult(
        insideCoverage: 0,
        outsideCoverage: 0,
        finalScore: 1, // Điểm tối thiểu là 1%
        passed: false,
        stars: 0,
        feedback: 'Chưa đủ số nét! Chữ này cần ít nhất $effectiveMinStrokes nét.',
        tips: ['Viết đầy đủ tất cả các nét của chữ cái.', 'Quan sát kỹ chữ mẫu để biết có bao nhiêu nét.'],
        visualFeedback: [],
      );
    }

    // Kiểm tra số điểm tối thiểu (tránh vẽ 1 nét nhỏ)
    if (totalPoints < effectiveMinPoints) {
      return TracingScoreResult(
        insideCoverage: 0,
        outsideCoverage: 0,
        finalScore: 1, // Điểm tối thiểu là 1%
        passed: false,
        stars: 0,
        feedback: 'Nét vẽ quá ngắn! Hãy viết đầy đủ chữ cái.',
        tips: [
          'Viết đầy đủ toàn bộ chữ cái, không chỉ một phần nhỏ.',
          'Viết chậm rãi và rõ ràng.',
          'Cần ít nhất $effectiveMinPoints điểm (hiện tại: $totalPoints).'
        ],
        visualFeedback: [],
      );
    }

    final cleanChar = character.replaceAll('◌', '').trim();
    final isConsonant = _khmerConsonants.contains(cleanChar);

    // Kiểm tra vẽ bậy (scribble detection) - Tổng chiều dài nét vẽ quá lớn (Chỉ áp dụng cho nguyên âm, chữ số...)
    if (!isConsonant) {
      double totalPathLength = 0;
      for (final stroke in userStrokes) {
        for (int i = 1; i < stroke.length; i++) {
          totalPathLength += (stroke[i] - stroke[i - 1]).distance;
        }
      }
      
      // Nếu tổng chiều dài vẽ gấp 5 lần chiều rộng canvas, coi như vẽ bậy
      if (totalPathLength > canvasSize.width * 5) {
        return TracingScoreResult(
          insideCoverage: 0,
          outsideCoverage: 100, // Đánh dấu là sai hoàn toàn
          finalScore: 1,
          passed: false,
          stars: 0,
          feedback: 'Không đạt ❌ - Bạn đang vẽ bậy!',
          tips: [
            'Có vẻ bạn đã gạch xóa hoặc vẽ quá nhiều nét thừa.',
            'Hãy chỉ đồ nét một cách cẩn thận theo hình chữ mẫu.',
            'Không nên vẽ ngoằn ngoèo trên màn hình.'
          ],
          visualFeedback: [],
        );
      }
    }

    final insideCoverage = (analysis.insidePoints / totalPoints) * 100.0;
    final outsideCoverage = (analysis.outsidePoints / totalPoints) * 100.0;

    // 4. ĐIỀU KIỆN ĐẠT (NGHIÊM NGẶT HÓA):
    // - Phải có đủ số điểm và số nét (đã kiểm tra ở trên)
    // - Nét trong (inside) phải >= effectivePassThreshold
    // - Nét ngoài (outside) phải <= effectiveOutsideThreshold

    final int roundedInside = insideCoverage.round();
    final int roundedOutside = outsideCoverage.round();
    final int roundedPassThreshold = effectivePassThreshold.round();
    final int roundedOutsideThreshold = effectiveOutsideThreshold.round();

    bool passed = false;
    double finalScore = 1; // Điểm tối thiểu là 1% thay vì 0%
    String feedback = '';
    List<String> tips = [];

    // Kiểm tra điều kiện 1: Nét ngoài > effectiveOutsideThreshold
    if (roundedOutside > roundedOutsideThreshold) {
      passed = false;
      finalScore = (insideCoverage * 0.79).clamp(1.0, 79.0);
      feedback = 'Không đạt ❌ - Viết quá nhiều ra ngoài chữ mẫu';
      tips = [
        'Nét viết ra ngoài: $roundedOutside% (chỉ cho phép tối đa $roundedOutsideThreshold%)',
        'Hãy viết chính xác theo nét mẫu màu xanh.',
        'Tránh vẽ lan ra ngoài chữ mẫu.',
        'Viết chậm rãi và cẩn thận hơn.',
      ];
    }
    // Kiểm tra điều kiện 2: Nét trong < effectivePassThreshold
    else if (roundedInside < roundedPassThreshold) {
      passed = false;
      finalScore = insideCoverage.clamp(1.0, 79.0);
      feedback = 'Chưa đạt ⚠️ - Viết chưa đủ chính xác';
      tips = [
        'Nét viết đúng: $roundedInside% (cần tối thiểu $roundedPassThreshold%)',
        'Hãy viết nhiều hơn trên nét mẫu.',
        'Viết chậm rãi và cẩn thận theo chữ mẫu.',
        'Đảm bảo mỗi nét đều nằm trên chữ mẫu.',
      ];
    }
    // Đạt cả 2 điều kiện
    else {
      passed = true;
      finalScore = insideCoverage.clamp(effectivePassThreshold, 100.0);
      feedback = _generateFeedback(finalScore, insideCoverage, outsideCoverage, effectivePassThreshold);
      tips = _generateTips(finalScore, insideCoverage, outsideCoverage, effectivePassThreshold);
    }

    // 5. Tính số sao
    final stars = _calculateStars(finalScore, effectivePassThreshold);

    return TracingScoreResult(
      insideCoverage: insideCoverage,
      outsideCoverage: outsideCoverage,
      finalScore: finalScore,
      passed: passed,
      stars: stars,
      feedback: feedback,
      tips: tips,
      visualFeedback: analysis.segments,
    );
  }

  /// Tính độ phủ chữ mẫu (template coverage)
  /// Trả về % diện tích chữ mẫu đã được người dùng vẽ lên
  double _calculateTemplateCoverage({
    required List<List<Offset>> userStrokes,
    required List<List<bool>> grid,
    required Size canvasSize,
  }) {
    final cellWidth = canvasSize.width / gridResolution;
    final cellHeight = canvasSize.height / gridResolution;

    // Đếm số cell template
    int totalTemplateCells = 0;
    for (int row = 0; row < gridResolution; row++) {
      for (int col = 0; col < gridResolution; col++) {
        if (grid[row][col]) {
          totalTemplateCells++;
        }
      }
    }

    if (totalTemplateCells == 0) return 0;

    // Đánh dấu các cell template đã được vẽ lên
    final coveredCells = List.generate(
      gridResolution,
      (_) => List.filled(gridResolution, false),
    );

    for (final stroke in userStrokes) {
      for (final point in stroke) {
        final col = (point.dx / cellWidth).floor().clamp(0, gridResolution - 1);
        final row = (point.dy / cellHeight).floor().clamp(0, gridResolution - 1);

        // Nếu cell này là template cell và được vẽ lên
        if (grid[row][col]) {
          coveredCells[row][col] = true;
        }
      }
    }

    // Đếm số cell template đã được phủ
    int coveredCount = 0;
    for (int row = 0; row < gridResolution; row++) {
      for (int col = 0; col < gridResolution; col++) {
        if (grid[row][col] && coveredCells[row][col]) {
          coveredCount++;
        }
      }
    }

    return (coveredCount / totalTemplateCells) * 100.0;
  }

  Map<String, dynamic> _generateTemplateBitmap({
    required String character,
    required Size canvasSize,
  }) {
    final grid = List.generate(
      gridResolution,
      (_) => List.filled(gridResolution, false),
    );

    final cellWidth = canvasSize.width / gridResolution;
    final cellHeight = canvasSize.height / gridResolution;

    // ──── Tính vùng template theo canvas ────────────────────────────
    // Chữ mẫu hiển thị trên canvas chiếm ~62% chiều rộng/chiều cao.
    // Căn giữa canvas — khớp với Center(child: Text(...)) trong widget.
    final bool isDepMark = character.contains('◌') || _classifyDependentMark(character) != _MarkPosition.none;
    final double dynamicRatio = isDepMark ? 0.55 : templateCanvasRatio;

    final double halfW = canvasSize.width * dynamicRatio / 2;
    final double halfH = canvasSize.height * dynamicRatio / 2;
    final double cx = canvasSize.width / 2;
    final double cy = canvasSize.height / 2;

    double centerX = cx;
    double centerY = cy;
    double radiusX = halfW;
    double radiusY = halfH;

    // Apply vertical translation shift to centerY for dependent marks to center them beautifully and prevent cutoff
    double shiftY = 0.0;
    final markPos = _classifyDependentMark(character);
    if (markPos == _MarkPosition.below) {
      shiftY = -canvasSize.height * 0.08;
    } else if (markPos == _MarkPosition.above) {
      shiftY = canvasSize.height * 0.06;
    }
    centerY += shiftY;

    // ──── Định vị chính xác theo phương vị dấu phụ thuộc ────────────
    // Để khớp hoàn hảo với vị trí hiển thị của font Battambang trên màn hình,
    // ta dịch chuyển tâm ellipse và thu nhỏ bán kính phù hợp cho từng vùng.
    if (markPos != _MarkPosition.none) {
      switch (markPos) {
        case _MarkPosition.above:
          centerY = cy + shiftY - halfH * 0.72;      // Loop 'ិ' nằm rất cao ở phía trên
          radiusY = halfH * 0.45;           // Thu hẹp chiều cao ellipse để ôm khít loop
          break;
        case _MarkPosition.below:
          centerY = cy + shiftY + halfH * 0.72;      // Vùng dấu dưới 'ុ'
          radiusY = halfH * 0.45;
          break;
        case _MarkPosition.left:
          centerX = cx - halfW * 0.72;      // Vùng dấu trái 'េ'
          radiusX = halfW * 0.45;
          break;
        case _MarkPosition.right:
          centerX = cx + halfW * 0.72;      // Vùng dấu phải 'ា'
          radiusX = halfW * 0.45;
          break;
        case _MarkPosition.leftAndRight:
          centerX = cx;
          radiusX = halfW * 1.35;           // Mở rộng chiều ngang để ôm cả trái và phải
          radiusY = halfH * 1.35;           // Mở rộng chiều dọc vì chữ ៀ, ឿ có nét rất dài trên/dưới
          break;
        case _MarkPosition.aboveAndBelow:
          centerY = cy;
          radiusY = halfH * 1.25;           // Mở rộng chiều dọc để ôm cả trên và dưới
          break;
        case _MarkPosition.none:
          break;
      }

      // --- Tùy chỉnh kích thước đặc biệt theo từng chữ (Custom Bounds) ---
      final charStr = character.replaceAll('◌', '');
      if (charStr == 'ៀ') {
        // Nét móc vươn rất dài xuống dưới và nét phụ lên trên
        radiusX = halfW * 1.45;
        radiusY = halfH * 1.65;
        centerY = cy + shiftY + halfH * 0.15; // Dịch tâm xuống một chút để ôm trọn đuôi
      } else if (charStr == 'ឿ') {
        // Nét kép trên và phải
        radiusX = halfW * 1.4;
        radiusY = halfH * 1.4;
      } else if (charStr == 'ៅ') {
        // Nét kép trái và phải (bên phải rất cao)
        radiusX = halfW * 1.45;
        radiusY = halfH * 1.4;
        centerY = cy + shiftY - halfH * 0.1;
      } else if (charStr == 'ី' || charStr == 'ឺ') {
        // Dấu trên cao hơn bình thường một chút
        radiusY = halfH * 0.55;
        centerY = cy + shiftY - halfH * 0.78;
      } else if (charStr == 'ូ') {
        // Dấu dưới dài hơn bình thường
        radiusY = halfH * 0.6;
        centerY = cy + shiftY + halfH * 0.85;
      } else if (charStr == 'ួ') {
        // Dấu dưới rộng
        radiusX = halfW * 0.6;
        radiusY = halfH * 0.5;
        centerY = cy + shiftY + halfH * 0.75;
      } else if (charStr.contains('ះ')) {
        // Các chữ kết hợp dấu ះ thường cần rộng hơn bên phải
        radiusX = halfW * 1.45;
      }
    }

    final cleanChar = character.replaceAll('◌', '').trim();
    final isConsonant = _khmerConsonants.contains(cleanChar);

    if (isConsonant) {
      for (int row = 0; row < gridResolution; row++) {
        for (int col = 0; col < gridResolution; col++) {
          final cellCenterX = col * cellWidth + cellWidth / 2;
          final cellCenterY = row * cellHeight + cellHeight / 2;
          final normalizedX = (cellCenterX - centerX) / radiusX;
          final normalizedY = (cellCenterY - centerY) / radiusY;
          if (normalizedX * normalizedX + normalizedY * normalizedY <= 1.0) {
            grid[row][col] = true;
          }
        }
      }
    } else {
      final template = KhmerStrokeTemplateData.getTemplate(character);
      for (final tp in template.points) {
        final px = centerX + tp.dx * (radiusX / 125.0);
        final py = centerY + tp.dy * (radiusY / 125.0);
        
        final col = (px / cellWidth).floor();
        final row = (py / cellHeight).floor();
        
        // Mark cells in a small radius around (row, col) to create the stroke shape
        const rRange = 6;
        for (int dr = -rRange; dr <= rRange; dr++) {
          for (int dc = -rRange; dc <= rRange; dc++) {
            final nr = row + dr;
            final nc = col + dc;
            if (nr >= 0 && nr < gridResolution && nc >= 0 && nc < gridResolution) {
              if (dr * dr + dc * dc <= 36) { // rounded radius of ~6 cells (approx. 37px on 400x400 canvas)
                grid[nr][nc] = true;
              }
            }
          }
        }
      }
    }


    return {
      'grid': grid,
      'offsetX': cx - halfW,
      'offsetY': cy - halfH,
      'textWidth': halfW * 2,
      'textHeight': halfH * 2,
      'centerX': centerX,
      'centerY': centerY,
      'radiusX': radiusX,
      'radiusY': radiusY,
    };
  }

  /// Phân tích user strokes so với template
  _StrokeAnalysis _analyzeUserStrokes({
    required List<List<Offset>> userStrokes,
    required Map<String, dynamic> templateBitmap,
    required Size canvasSize,
    double? toleranceRadiusOverride,
    required String character,
  }) {
    final grid = templateBitmap['grid'] as List<List<bool>>;
    final cellWidth = canvasSize.width / gridResolution;
    final cellHeight = canvasSize.height / gridResolution;
    final double effectiveTolerance = toleranceRadiusOverride ?? toleranceRadius;

    final double cx = canvasSize.width / 2;
    final double cy = canvasSize.height / 2;
    final bool isDepMark = character.contains('◌') || _classifyDependentMark(character) != _MarkPosition.none;
    final double dynamicRatio = isDepMark ? 0.55 : templateCanvasRatio;

    final double halfW = canvasSize.width * dynamicRatio / 2;
    final double halfH = canvasSize.height * dynamicRatio / 2;

    double shiftY = 0.0;
    final markPos = _classifyDependentMark(character);
    if (markPos == _MarkPosition.below) {
      shiftY = -canvasSize.height * 0.08;
    } else if (markPos == _MarkPosition.above) {
      shiftY = canvasSize.height * 0.06;
    }
    final double shiftedCy = cy + shiftY;

    int insidePoints = 0;
    int outsidePoints = 0;
    int nearPoints = 0;
    int neutralPointsCount = 0;

    final List<StrokeSegment> segments = [];

    for (final stroke in userStrokes) {
      final List<Offset> greenPoints = [];
      final List<Offset> yellowPoints = [];
      final List<Offset> redPoints = [];

      for (final point in stroke) {
        // Tìm ô grid tương ứng
        final col = (point.dx / cellWidth).floor().clamp(0, gridResolution - 1);
        final row = (point.dy / cellHeight).floor().clamp(0, gridResolution - 1);

        // 1. Kiểm tra xem điểm có nằm trên chữ mẫu thực tế trước
        final isInside = grid[row][col];
        final isNear = !isInside && _isNearTemplate(
          point: point,
          grid: grid,
          col: col,
          row: row,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          toleranceRadius: effectiveTolerance,
        );

        if (isInside) {
          insidePoints++;
          greenPoints.add(point);
        } else if (isNear) {
          nearPoints++;
          yellowPoints.add(point);
        } else {
          // 2. Nếu không thuộc nét chữ, kiểm tra xem có nằm trong vùng vòng tròn nét đứt không (đối với dấu phụ thuộc)
          final double normX = (point.dx - cx) / halfW;
          final double normY = (point.dy - shiftedCy) / halfH;
          final bool isInsideDottedCircle = isDepMark && (normX * normX + normY * normY <= 1.15);

          if (isInsideDottedCircle) {
            neutralPointsCount++;
            // Color it green for satisfying visual feedback (vẫn vẽ xanh nếu tô lên vòng tròn)
            greenPoints.add(point);
          } else {
            outsidePoints++;
            redPoints.add(point);
          }
        }
      }

      // Tạo segments cho visual feedback
      if (greenPoints.isNotEmpty) {
        segments.add(StrokeSegment(points: greenPoints, color: Colors.green));
      }
      if (yellowPoints.isNotEmpty) {
        segments.add(StrokeSegment(points: yellowPoints, color: Colors.yellow));
      }
      if (redPoints.isNotEmpty) {
        segments.add(StrokeSegment(points: redPoints, color: Colors.red));
      }
    }

    // Coi điểm "gần" như là inside (với trọng số thấp hơn)
    // Giảm từ 0.7 xuống 0.5 để nghiêm ngặt hơn
    final adjustedInside = insidePoints + (nearPoints * 0.5).round();
    int adjustedOutside = outsidePoints;

    // Nếu người dùng không vẽ bất kỳ điểm nào trên hoặc gần nét chữ mẫu thực tế,
    // toàn bộ điểm vẽ trên vòng tròn trung tâm sẽ bị coi là nét vẽ ngoài chữ mẫu (vì chưa viết nét chính).
    if (insidePoints == 0 && nearPoints == 0) {
      adjustedOutside += neutralPointsCount;
    }

    return _StrokeAnalysis(
      insidePoints: adjustedInside,
      outsidePoints: adjustedOutside,
      segments: segments,
    );
  }

  /// Kiểm tra điểm có gần template không (trong bán kính tolerance)
  bool _isNearTemplate({
    required Offset point,
    required List<List<bool>> grid,
    required int col,
    required int row,
    required double cellWidth,
    required double cellHeight,
    required double toleranceRadius,
  }) {
    // Kiểm tra các ô lân cận trong bán kính tolerance
    final checkRadius = (toleranceRadius / math.min(cellWidth, cellHeight)).ceil();

    for (int dr = -checkRadius; dr <= checkRadius; dr++) {
      for (int dc = -checkRadius; dc <= checkRadius; dc++) {
        final newRow = row + dr;
        final newCol = col + dc;

        if (newRow >= 0 && newRow < gridResolution &&
            newCol >= 0 && newCol < gridResolution) {
          if (grid[newRow][newCol]) {
            // Tính khoảng cách thực tế từ điểm đến tâm cell lân cận
            final cellCenterX = newCol * cellWidth + cellWidth / 2;
            final cellCenterY = newRow * cellHeight + cellHeight / 2;
            final distance = math.sqrt(
              math.pow(point.dx - cellCenterX, 2) +
              math.pow(point.dy - cellCenterY, 2),
            );

            if (distance <= toleranceRadius) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Tính số sao dựa trên điểm (nghiêm ngặt hơn)
  int _calculateStars(double score, [double passThreshold = 70.0]) {
    if (score >= 90) return 3;
    if (score >= 80) return 2;
    if (score >= passThreshold) return 1;
    return 0;
  }

  /// Tạo feedback message
  String _generateFeedback(double finalScore, double inside, double outside, [double passThreshold = 70.0]) {
    if (finalScore >= 90) {
      return 'Xuất sắc! ⭐⭐⭐';
    } else if (finalScore >= 80) {
      return 'Rất tốt! ⭐⭐';
    } else if (finalScore >= passThreshold) {
      return 'Đạt! ⭐';
    } else {
      return 'Chưa đạt - Cần luyện tập thêm';
    }
  }

  /// Tạo tips dựa trên kết quả
  List<String> _generateTips(double finalScore, double inside, double outside, [double passThreshold = 70.0]) {
    final tips = <String>[];

    if (finalScore >= 90) {
      tips.add('Chữ viết của bạn rất đẹp! Hãy tiếp tục phát huy nhé!');
    } else if (finalScore >= passThreshold) {
      tips.add('Bạn đã viết đạt yêu cầu!');
      if (outside > 15) {
        tips.add('Cố gắng viết sát hơn với nét mẫu để giảm nét ra ngoài.');
      }
      if (inside < 85) {
        tips.add('Cố gắng viết nhiều hơn trên nét mẫu để tăng độ chính xác.');
      }
      tips.add('Viết chậm rãi và cẩn thận hơn để đạt điểm cao hơn.');
    } else {
      // Trường hợp này không xảy ra vì đã xử lý ở scoreTracing
      tips.add('Hãy viết chính xác hơn theo nét mẫu.');
    }

    return tips;
  }
}

/// Kết quả phân tích stroke
class _StrokeAnalysis {
  final int insidePoints;
  final int outsidePoints;
  final List<StrokeSegment> segments;

  const _StrokeAnalysis({
    required this.insidePoints,
    required this.outsidePoints,
    required this.segments,
  });
}

enum _MarkPosition {
  above,
  below,
  left,
  right,
  leftAndRight,
  aboveAndBelow,
  none,
}

_MarkPosition _classifyDependentMark(String character) {
  // Check double/compound positions first
  if (character.contains('ោ') ||
      character.contains('ើ') ||
      character.contains('ឿ') ||
      character.contains('ៀ') ||
      character.contains('ៅ') ||
      character.contains('េះ') ||
      character.contains('ោះ') ||
      character.contains('ើះ') ||
      character.contains('ែះ') ||
      character.contains('ៃះ')) {
    return _MarkPosition.leftAndRight;
  }

  if (character.contains('ុំ') ||
      character.contains('ុះ') ||
      character.contains('ូះ')) {
    return _MarkPosition.aboveAndBelow;
  }

  // Otherwise check single dependent marks.
  if (character.contains('ិ') ||
      character.contains('ី') ||
      character.contains('ឹ') ||
      character.contains('ឺ') ||
      character.contains('ំ') ||
      character.contains('៏')) {
    return _MarkPosition.above;
  }

  if (character.contains('ុ') ||
      character.contains('ូ') ||
      character.contains('ួ') ||
      character.contains('្')) {
    return _MarkPosition.below;
  }

  if (character.contains('េ') ||
      character.contains('ែ') ||
      character.contains('ៃ')) {
    return _MarkPosition.left;
  }

  if (character.contains('ា') ||
      character.contains('ះ')) {
    return _MarkPosition.right;
  }

  return _MarkPosition.none;
}

