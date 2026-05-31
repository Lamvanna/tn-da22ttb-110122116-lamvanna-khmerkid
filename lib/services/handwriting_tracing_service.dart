import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

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

  // ─── Configuration ─────────────────────────────────────────────────
  static const double strokeWidth = 4.0;           // Độ dày nét vẽ
  static const double templateStrokeWidth = 180.0; // Độ dày nét mẫu (font size)
  static const double toleranceRadius = 10.0;      // Bán kính chấp nhận "gần đúng" (giảm từ 15.0 để nghiêm ngặt hơn)
  static const double passThreshold = 80.0;        // Ngưỡng đạt (tăng từ 70.0)
  static const int gridResolution = 64;            // Độ phân giải grid để tính coverage
  static const int minPointsRequired = 200;        // Số điểm tối thiểu (tăng từ 100)
  static const int minStrokesRequired = 2;         // Số nét tối thiểu

  /// Chấm điểm viết theo mẫu (Template Tracing)
  TracingScoreResult scoreTracing({
    required String character,
    required List<List<Offset>> userStrokes,
    required Size canvasSize,
  }) {
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

    // 1. Tạo template bitmap từ chữ mẫu
    final templateBitmap = _generateTemplateBitmap(
      character: character,
      canvasSize: canvasSize,
    );

    // 2. Phân tích từng điểm của user strokes
    final analysis = _analyzeUserStrokes(
      userStrokes: userStrokes,
      templateBitmap: templateBitmap,
      canvasSize: canvasSize,
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
    if (userStrokes.length < minStrokesRequired) {
      return TracingScoreResult(
        insideCoverage: 0,
        outsideCoverage: 0,
        finalScore: 1, // Điểm tối thiểu là 1%
        passed: false,
        stars: 0,
        feedback: 'Chưa đủ số nét! Chữ này cần ít nhất $minStrokesRequired nét.',
        tips: ['Viết đầy đủ tất cả các nét của chữ cái.', 'Quan sát kỹ chữ mẫu để biết có bao nhiêu nét.'],
        visualFeedback: [],
      );
    }

    // Kiểm tra số điểm tối thiểu (tránh vẽ 1 nét nhỏ)
    // Yêu cầu tối thiểu 200 điểm để đảm bảo viết đầy đủ
    if (totalPoints < minPointsRequired) {
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
          'Cần ít nhất $minPointsRequired điểm (hiện tại: $totalPoints).'
        ],
        visualFeedback: [],
      );
    }

    final insideCoverage = (analysis.insidePoints / totalPoints) * 100.0;
    final outsideCoverage = (analysis.outsidePoints / totalPoints) * 100.0;

    // 4. ĐIỀU KIỆN ĐẠT (NGHIÊM NGẶT HÓA):
    // - Phải có đủ số điểm và số nét (đã kiểm tra ở trên)
    // - Nét trong (inside) phải >= 80% (tăng từ 70%)
    // - Nét ngoài (outside) phải <= 20% (giảm từ 30%)

    bool passed = false;
    double finalScore = 1; // Điểm tối thiểu là 1% thay vì 0%
    String feedback = '';
    List<String> tips = [];

    // Kiểm tra điều kiện 1: Nét ngoài > 20%
    if (outsideCoverage > 20.0) {
      passed = false;
      // Điểm từ 1-79 dựa trên tỷ lệ nét đúng, nhưng tối đa 79% vì fail
      finalScore = (insideCoverage * 0.79).clamp(1.0, 79.0);
      feedback = 'Không đạt ❌ - Viết quá nhiều ra ngoài chữ mẫu';
      tips = [
        'Nét viết ra ngoài: ${outsideCoverage.round()}% (chỉ cho phép tối đa 20%)',
        'Hãy viết chính xác theo nét mẫu màu xanh.',
        'Tránh vẽ lan ra ngoài chữ mẫu.',
        'Viết chậm rãi và cẩn thận hơn.',
      ];
    }
    // Kiểm tra điều kiện 2: Nét trong < 80%
    else if (insideCoverage < 80.0) {
      passed = false;
      // Điểm từ 1-79 dựa trên % nét trong
      finalScore = insideCoverage.clamp(1.0, 79.0);
      feedback = 'Chưa đạt ⚠️ - Viết chưa đủ chính xác';
      tips = [
        'Nét viết đúng: ${insideCoverage.round()}% (cần tối thiểu 80%)',
        'Hãy viết nhiều hơn trên nét mẫu.',
        'Viết chậm rãi và cẩn thận theo chữ mẫu.',
        'Đảm bảo mỗi nét đều nằm trên chữ mẫu.',
      ];
    }
    // Đạt cả 2 điều kiện
    else {
      passed = true;
      // Điểm = % nét trong (80-100)
      finalScore = insideCoverage.clamp(80.0, 100.0);
      feedback = _generateFeedback(finalScore, insideCoverage, outsideCoverage);
      tips = _generateTips(finalScore, insideCoverage, outsideCoverage);
    }

    // 5. Tính số sao
    final stars = _calculateStars(finalScore);

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

  /// Tạo bitmap của chữ mẫu (template) bằng cách render chữ lên canvas ảo
  /// và phát hiện chính xác vùng có pixel của chữ
  Map<String, dynamic> _generateTemplateBitmap({
    required String character,
    required Size canvasSize,
  }) {
    // Tạo grid bitmap để đánh dấu vùng chữ mẫu
    final grid = List.generate(
      gridResolution,
      (_) => List.filled(gridResolution, false),
    );

    // Tạo TextPainter để render chữ
    final textSpan = TextSpan(
      text: character,
      style: const TextStyle(
        fontSize: templateStrokeWidth,
        fontWeight: FontWeight.w700,
        fontFamily: 'Battambang',
        color: Color(0xFF000000),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Tính offset để căn giữa
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    final offsetX = (canvasSize.width - textWidth) / 2;
    final offsetY = (canvasSize.height - textHeight) / 2;

    // Tạo PictureRecorder để render chữ lên canvas ảo
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Vẽ chữ lên canvas với stroke để tạo vùng dày hơn
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    // Vẽ chữ nhiều lần với offset nhỏ để tạo vùng dày (simulate stroke)
    for (double dx = -2; dx <= 2; dx += 0.5) {
      for (double dy = -2; dy <= 2; dy += 0.5) {
        textPainter.paint(canvas, Offset(offsetX + dx, offsetY + dy));
      }
    }

    // Kết thúc recording
    final picture = recorder.endRecording();

    // Đánh dấu các ô grid dựa trên vị trí chữ thực tế
    final cellWidth = canvasSize.width / gridResolution;
    final cellHeight = canvasSize.height / gridResolution;

    // Tính bounding box chữ mẫu
    final templateLeft = offsetX;
    final templateRight = offsetX + textWidth;
    final templateTop = offsetY;
    final templateBottom = offsetY + textHeight;
    final centerX = offsetX + textWidth / 2;
    final centerY = offsetY + textHeight / 2;

    // Đánh dấu các cell nằm trong vùng chữ mẫu
    // Sử dụng phương pháp ellipse để xấp xỉ hình dạng chữ
    // Thu nhỏ ellipse để nghiêm ngặt hơn
    final radiusX = textWidth / 2.2;  // Giảm từ 2.0 để nghiêm ngặt hơn
    final radiusY = textHeight / 2.2; // Giảm từ 2.0 để nghiêm ngặt hơn

    for (int row = 0; row < gridResolution; row++) {
      for (int col = 0; col < gridResolution; col++) {
        final cellCenterX = col * cellWidth + cellWidth / 2;
        final cellCenterY = row * cellHeight + cellHeight / 2;

        // Kiểm tra cell có nằm trong ellipse bao quanh chữ không
        final normalizedX = (cellCenterX - centerX) / radiusX;
        final normalizedY = (cellCenterY - centerY) / radiusY;
        final distanceSquared = normalizedX * normalizedX + normalizedY * normalizedY;

        // Cell nằm trong ellipse nếu distance <= 1
        if (distanceSquared <= 1.0) {
          grid[row][col] = true;
        }
      }
    }

    picture.dispose();

    return {
      'grid': grid,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'textWidth': textWidth,
      'textHeight': textHeight,
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
  }) {
    final grid = templateBitmap['grid'] as List<List<bool>>;
    final cellWidth = canvasSize.width / gridResolution;
    final cellHeight = canvasSize.height / gridResolution;

    int insidePoints = 0;
    int outsidePoints = 0;
    int nearPoints = 0;

    final List<StrokeSegment> segments = [];

    for (final stroke in userStrokes) {
      final List<Offset> greenPoints = [];
      final List<Offset> yellowPoints = [];
      final List<Offset> redPoints = [];

      for (final point in stroke) {
        // Tìm ô grid tương ứng
        final col = (point.dx / cellWidth).floor().clamp(0, gridResolution - 1);
        final row = (point.dy / cellHeight).floor().clamp(0, gridResolution - 1);

        // Kiểm tra điểm này nằm trong/gần/ngoài template
        final isInside = grid[row][col];
        final isNear = !isInside && _isNearTemplate(
          point: point,
          grid: grid,
          col: col,
          row: row,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );

        if (isInside) {
          insidePoints++;
          greenPoints.add(point);
        } else if (isNear) {
          nearPoints++;
          yellowPoints.add(point);
        } else {
          outsidePoints++;
          redPoints.add(point);
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

    return _StrokeAnalysis(
      insidePoints: adjustedInside,
      outsidePoints: outsidePoints,
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
  int _calculateStars(double score) {
    if (score >= 95) return 3;  // Tăng từ 90
    if (score >= 87) return 2;  // Tăng từ 80
    if (score >= 80) return 1;  // Tăng từ 70
    return 0;
  }

  /// Tạo feedback message
  String _generateFeedback(double finalScore, double inside, double outside) {
    if (finalScore >= 95) {
      return 'Xuất sắc! ⭐⭐⭐';
    } else if (finalScore >= 87) {
      return 'Rất tốt! ⭐⭐';
    } else if (finalScore >= 80) {
      return 'Tốt! ⭐';
    } else {
      return 'Chưa đạt - Cần luyện tập thêm';
    }
  }

  /// Tạo tips dựa trên kết quả
  List<String> _generateTips(double finalScore, double inside, double outside) {
    final tips = <String>[];

    if (finalScore >= 95) {
      tips.add('Chữ viết của bạn rất đẹp! Hãy tiếp tục phát huy nhé!');
    } else if (finalScore >= 80) {
      tips.add('Bạn đã viết khá tốt!');
      if (outside > 10) {
        tips.add('Cố gắng viết sát hơn với nét mẫu để giảm nét ra ngoài.');
      }
      if (inside < 90) {
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
