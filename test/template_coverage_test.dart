import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';
import 'package:khmerkid/data/khmer_stroke_templates.dart';

void main() {
  group('Template Coverage Tests', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    test('Small stroke in center should FAIL (template coverage < 50%)', () {
      // Chỉ vẽ 1 nét nhỏ ở tâm
      final strokes = [
        [
          const Offset(195, 195),
          const Offset(200, 200),
          const Offset(205, 205),
        ],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Small stroke - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');
      print('Feedback: ${result.feedback}');

      // Nét nhỏ phải FAIL vì không đủ phủ hoặc thiếu nét/ngắn
      expect(result.passed, false);
      expect(result.feedback, anyOf(contains('Chưa đạt'), contains('nét'), contains('ngắn')));
    });

    test('Large strokes covering template should PASS', () {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;

      final points = template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [points],
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Large strokes - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      expect(result.passed, true);
    });

    test('Drawing only half of template should FAIL', () {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;

      final points = template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();

      // Only draw the first 30% of the character template points
      final partialPoints = points.sublist(0, (points.length * 0.3).toInt());

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [partialPoints],
        canvasSize: canvasSize,
        minPointsOverride: 100, // Override high to fail partial drawing
        minStrokesOverride: 1,
      );

      print('Half template - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      expect(result.passed, false);
    });

    test('Full template coverage with good accuracy should PASS with high score', () {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;

      final points = template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [points],
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Full coverage - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%, Stars: ${result.stars}');

      expect(result.passed, true);
      expect(result.finalScore, greaterThan(80));
    });

    test('Very small stroke (< 20 points) should FAIL immediately', () {
      final strokes = [
        [
          const Offset(200, 200),
          const Offset(201, 201),
          const Offset(202, 202),
        ],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Very small - Total points: ${strokes[0].length}');
      print('Feedback: ${result.feedback}');

      expect(result.passed, false);
      expect(result.feedback, anyOf(contains('quá ngắn'), contains('nét'), contains('Chưa đạt')));
    });

    test('Drawing with good coverage but too much outside should FAIL', () {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;

      final points = template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();

      // Outside stroke: 100 points far away
      final outsideStroke = List.generate(100, (i) => Offset(10.0 + i * 2.0, 10.0));

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [points, outsideStroke],
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Good coverage but outside - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}');

      expect(result.passed, false);
    });

    test('Comparing different coverage levels', () {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;

      final points = template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();

      // Test 1: 25% coverage with outside points
      final partial25 = points.sublist(0, (points.length * 0.25).toInt());
      final outside1 = List.generate(100, (i) => Offset(10.0 + i * 2.0, 10.0));
      final result1 = service.scoreTracing(
        character: 'ក',
        userStrokes: [partial25, outside1],
        canvasSize: canvasSize,
        minPointsOverride: 10,
        minStrokesOverride: 1,
      );

      print('25% coverage - Score: ${result1.finalScore.round()}%, Passed: ${result1.passed}');

      // Test 2: 75% coverage with same outside points
      final partial75 = points.sublist(0, (points.length * 0.75).toInt());
      final outside2 = List.generate(100, (i) => Offset(10.0 + i * 2.0, 10.0));
      final result2 = service.scoreTracing(
        character: 'ក',
        userStrokes: [partial75, outside2],
        canvasSize: canvasSize,
        minPointsOverride: 10,
        minStrokesOverride: 1,
      );

      print('75% coverage - Score: ${result2.finalScore.round()}%, Passed: ${result2.passed}');

      expect(result2.finalScore, greaterThan(result1.finalScore));
    });
  });
}
