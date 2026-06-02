import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

void main() {
  group('Consonant Handwriting Tracing Tests (Commit 27 behavior)', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    test('Consonant (e.g. ក) should use ellipse-based tracing (lenient)', () {
      // Draw a simple horizontal line in the middle of the canvas.
      // In template-based tracing (commit 32), this would cover very few template pixels,
      // resulting in extremely low inside coverage.
      // But in ellipse-based tracing (commit 27), the entire center ellipse is the template,
      // so any point in the center counts as 100% inside.
      final strokes = [
        List.generate(50, (i) => Offset(150.0 + i * 2.0, 200.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 10,
        minStrokesOverride: 1,
      );

      print('Consonant ក - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      
      // Since all points in the line (150 to 250) fall within the central ellipse:
      expect(result.insideCoverage, 100.0);
      expect(result.outsideCoverage, 0.0);
      expect(result.passed, true);
    });

    test('Consonant (e.g. ក) should bypass scribble detection', () {
      // Draw an extremely long path (e.g. 500 points moving back and forth, length > 400 * 5 = 2000)
      final List<Offset> longStroke = [];
      for (int i = 0; i < 500; i++) {
        longStroke.add(Offset(150.0 + (i % 100) * 1.0, 200.0 + (i ~/ 100) * 2.0));
      }
      final strokes = [longStroke];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 10,
        minStrokesOverride: 1,
      );

      print('Consonant ក with scribble - Passed: ${result.passed}, Feedback: ${result.feedback}');
      // It should NOT be flagged as scribble. It should pass and be calculated.
      expect(result.feedback.contains('vẽ bậy'), false);
      expect(result.insideCoverage, 100.0);
    });

    test('Non-consonant (e.g. vowel ា) should NOT bypass scribble detection', () {
      // Draw an extremely long path (e.g. 500 points, length > 400 * 5 = 2000)
      final List<Offset> longStroke = [];
      for (int i = 0; i < 500; i++) {
        longStroke.add(Offset(150.0 + (i % 100) * 10.0, 200.0 + (i ~/ 100) * 20.0));
      }
      final strokes = [longStroke];

      final result = service.scoreTracing(
        character: 'ា',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 10,
        minStrokesOverride: 1,
      );

      print('Vowel ា with scribble - Passed: ${result.passed}, Feedback: ${result.feedback}');
      // It SHOULD be flagged as scribble.
      expect(result.feedback.contains('vẽ bậy'), true);
      expect(result.passed, false);
      expect(result.finalScore, 1.0);
    });
  });
}
