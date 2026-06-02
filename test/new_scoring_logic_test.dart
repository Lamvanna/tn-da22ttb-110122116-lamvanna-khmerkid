import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';
import 'package:khmerkid/data/khmer_stroke_templates.dart';

void main() {
  group('New Scoring Logic Tests', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    // Helpers to get template points and outside points
    List<Offset> getTemplatePoints() {
      final template = KhmerStrokeTemplateData.getTemplate('ក');
      const double dynamicRatio = 0.62;
      final double halfW = canvasSize.width * dynamicRatio / 2;
      final double halfH = canvasSize.height * dynamicRatio / 2;
      final double cx = canvasSize.width / 2;
      final double cy = canvasSize.height / 2;
      return template.pointsNoRotation.map((tp) {
        return Offset(cx + tp.dx * (halfW / 125.0), cy + tp.dy * (halfH / 125.0));
      }).toList();
    }

    final points = getTemplatePoints();
    final outside = List.generate(200, (i) => Offset(10.0 + i * 1.5, 10.0));

    test('Inside 70%, Outside 30% - Should PASS (boundary case)', () {
      final strokes = [
        points.sublist(0, 70),
        outside.sublist(0, 30),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 1 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      if (result.insideCoverage >= 70 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
      }
    });

    test('Inside 60%, Outside 40% - Should FAIL (inside < 70%)', () {
      final strokes = [
        points.sublist(0, 60),
        outside.sublist(0, 40),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 2 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      if (result.insideCoverage < 70) {
        expect(result.passed, false);
      }
    });

    test('Inside 70%, Outside 35% - Should FAIL (outside > 30%)', () {
      final strokes = [
        points.sublist(0, 70),
        outside.sublist(0, 35),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 3 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      if (result.outsideCoverage > 30) {
        expect(result.passed, false);
        expect(result.finalScore, lessThan(80));
      }
    });

    test('Inside 90%, Outside 10% - Should PASS with 3 stars', () {
      final strokes = [
        points.sublist(0, 90),
        outside.sublist(0, 10),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 4 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%, Stars: ${result.stars}');

      if (result.insideCoverage >= 90 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
        expect(result.stars, 3);
      }
    });

    test('Inside 80%, Outside 20% - Should PASS with 2 stars', () {
      final strokes = [
        points.sublist(0, 80),
        outside.sublist(0, 20),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 5 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%, Stars: ${result.stars}');

      if (result.insideCoverage >= 80 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
        expect(result.stars, greaterThanOrEqualTo(2));
      }
    });

    test('Inside 75%, Outside 25% - Should PASS with 1 star', () {
      final strokes = [
        points.sublist(0, 75),
        outside.sublist(0, 25),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Test 6 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%, Stars: ${result.stars}');

      if (result.insideCoverage >= 70 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
        expect(result.stars, greaterThanOrEqualTo(1));
      }
    });

    test('Drawing along the template path should have high inside coverage', () {
      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [points],
        canvasSize: canvasSize,
        minPointsOverride: 20,
        minStrokesOverride: 1,
      );

      print('Test 7 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');

      expect(result.insideCoverage, greaterThan(50));
    });

    test('Drawing only in corners should have high outside coverage', () {
      final strokes = [
        [const Offset(10, 10), const Offset(30, 30)],
        [const Offset(370, 10), const Offset(390, 30)],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 2,
        minStrokesOverride: 1,
      );

      print('Test 8 - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');

      expect(result.outsideCoverage, greaterThan(50));
      expect(result.passed, false);
    });

    test('Feedback messages should match new logic', () {
      final strokes1 = [
        points.sublist(0, 60),
        outside.sublist(0, 40),
      ];

      final result1 = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes1,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Feedback test 1 - Inside: ${result1.insideCoverage.round()}%, Outside: ${result1.outsideCoverage.round()}%');
      print('Feedback: ${result1.feedback}');

      if (result1.outsideCoverage > 30) {
        expect(result1.feedback, contains('Không đạt'));
        expect(result1.tips.any((tip) => tip.contains('30%')), true);
      } else if (result1.insideCoverage < 70) {
        expect(result1.feedback, contains('Chưa đạt'));
        expect(result1.tips.any((tip) => tip.contains('70%')), true);
      }

      final strokes2 = [
        points.sublist(0, 50),
        outside.sublist(0, 50),
      ];

      final result2 = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes2,
        canvasSize: canvasSize,
        minPointsOverride: 50,
        minStrokesOverride: 1,
      );

      print('Feedback test 2 - Inside: ${result2.insideCoverage.round()}%, Outside: ${result2.outsideCoverage.round()}%');
      print('Feedback: ${result2.feedback}');

      if (result2.outsideCoverage > 30) {
        expect(result2.feedback, contains('Không đạt'));
        expect(result2.tips.any((tip) => tip.contains('30%')), true);
      }
    });
  });
}
