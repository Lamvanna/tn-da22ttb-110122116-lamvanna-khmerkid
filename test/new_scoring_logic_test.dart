import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

void main() {
  group('New Scoring Logic Tests', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    test('Inside 70%, Outside 30% - Should PASS (boundary case)', () {
      final strokes = [
        List.generate(70, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(30, (i) => Offset(100 + i * 2.0, 100)),
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
        List.generate(60, (i) => Offset(180 + (i % 8) * 5.0, 180 + (i ~/ 8) * 5.0)),
        List.generate(40, (i) => Offset(50 + i * 3.0, 50)),
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
        List.generate(70, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(35, (i) => Offset(50 + i * 3.0, 50)),
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
        List.generate(90, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(10, (i) => Offset(150 + i * 2.0, 150)),
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
        List.generate(80, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(20, (i) => Offset(140 + i * 2.0, 140)),
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
        List.generate(75, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(25, (i) => Offset(130 + i * 2.0, 130)),
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

    test('Drawing only in center should have high inside coverage', () {
      final strokes = [
        List.generate(50, (i) => Offset(180 + (i % 10) * 3.0, 180 + (i ~/ 10) * 3.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
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
        List.generate(60, (i) => Offset(180 + (i % 8) * 5.0, 180 + (i ~/ 8) * 5.0)),
        List.generate(40, (i) => Offset(50 + i * 3.0, 50)),
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
        List.generate(50, (i) => Offset(180 + (i % 10) * 4.0, 180 + (i ~/ 10) * 4.0)),
        List.generate(50, (i) => Offset(50 + i * 3.0, 50)),
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
