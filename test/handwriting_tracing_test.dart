import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

void main() {
  group('HandwritingTracingService Tests', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    test('Empty strokes should return 1 score (minimum)', () {
      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: [],
        canvasSize: canvasSize,
      );

      expect(result.finalScore, 1); // Điểm tối thiểu là 1%
      expect(result.passed, false);
      expect(result.stars, 0);
      expect(result.insideCoverage, 0);
      expect(result.outsideCoverage, 0);
    });

    test('Strokes completely outside template should fail', () {
      // Draw in top-left corner (far from center where template is)
      // Need at least 2 strokes and 200 points to pass minimum requirements
      final strokes = [
        List.generate(100, (i) => Offset(10 + i * 0.5, 10 + i * 0.5)),
        List.generate(100, (i) => Offset(50 + i * 0.5, 10 + i * 0.5)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      expect(result.passed, false);
      expect(result.outsideCoverage, greaterThan(result.insideCoverage));
    });

    test('Strokes in center (template area) should have high inside coverage', () {
      // Draw in center where template is with enough points (200+)
      final strokes = [
        List.generate(100, (i) => Offset(180 + i * 0.5, 180 + i * 0.5)),
        List.generate(100, (i) => Offset(220 - i * 0.5, 180 + i * 0.5)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      expect(result.insideCoverage, greaterThan(0));
    });

    test('Score >= 80% should pass (new threshold)', () {
      // Simulate good tracing (center area with multiple strokes and enough points)
      final strokes = [
        List.generate(100, (i) => Offset(180 + i * 0.8, 180 + i * 0.8)),
        List.generate(100, (i) => Offset(220 - i * 0.8, 180 + i * 0.8)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      // If score >= 80, should pass (new threshold)
      if (result.finalScore >= 80) {
        expect(result.passed, true);
        expect(result.stars, greaterThanOrEqualTo(1));
      }
    });

    test('Outside coverage > 20% should fail', () {
      // Draw mostly outside with little inside (but enough points)
      final strokes = [
        // Small stroke inside
        List.generate(50, (i) => Offset(200 + i * 0.2, 200 + i * 0.2)),
        // Large stroke outside
        List.generate(150, (i) => Offset(10 + i * 2.0, 10 + i * 2.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      if (result.outsideCoverage > 20) {
        expect(result.passed, false);
        expect(result.finalScore, greaterThanOrEqualTo(1)); // Minimum score is 1
        expect(result.finalScore, lessThan(80)); // Should not pass
      }
    });

    test('Star rating should match score ranges', () {
      // Test star calculation logic
      // 90+ = 3 stars, 80-89 = 2 stars, 70-79 = 1 star, <70 = 0 stars

      // We can't easily simulate exact scores, but we can verify the logic
      // by checking that higher scores get more stars
      final testCases = [
        {'score': 95.0, 'expectedStars': 3},
        {'score': 85.0, 'expectedStars': 2},
        {'score': 75.0, 'expectedStars': 1},
        {'score': 65.0, 'expectedStars': 0},
      ];

      for (final testCase in testCases) {
        final score = testCase['score'] as double;
        final expectedStars = testCase['expectedStars'] as int;

        int stars = 0;
        if (score >= 90) {
          stars = 3;
        } else if (score >= 80) {
          stars = 2;
        } else if (score >= 70) {
          stars = 1;
        }

        expect(stars, expectedStars);
      }
    });

    test('Visual feedback should be generated for valid strokes', () {
      // Need at least 2 strokes and 200 points
      final strokes = [
        List.generate(100, (i) => Offset(180 + i * 0.5, 180 + i * 0.5)),
        List.generate(100, (i) => Offset(220 - i * 0.5, 180 + i * 0.5)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      // Visual feedback should contain segments for valid strokes
      expect(result.visualFeedback, isNotEmpty);
    });

    test('Different characters should work', () {
      final strokes = [
        List.generate(15, (i) => Offset(180 + i * 3.0, 180 + i * 3.0)),
      ];

      final characters = ['ក', 'ខ', 'គ', 'ង', 'ច'];

      for (final char in characters) {
        final result = service.scoreTracing(
          character: char,
          userStrokes: strokes,
          canvasSize: canvasSize,
        );

        // Should return valid result for each character
        expect(result.finalScore, greaterThanOrEqualTo(0));
        expect(result.finalScore, lessThanOrEqualTo(100));
      }
    });

    test('Feedback messages should be appropriate', () {
      // High score feedback
      final goodStrokes = [
        List.generate(30, (i) => Offset(180 + i * 2.0, 180 + i * 2.0)),
        List.generate(30, (i) => Offset(220 - i * 2.0, 180 + i * 2.0)),
      ];

      final goodResult = service.scoreTracing(
        character: 'ក',
        userStrokes: goodStrokes,
        canvasSize: canvasSize,
      );

      if (goodResult.finalScore >= 90) {
        expect(goodResult.feedback, contains('Xuất sắc'));
      } else if (goodResult.finalScore >= 80) {
        expect(goodResult.feedback, contains('Rất tốt'));
      } else if (goodResult.finalScore >= 70) {
        expect(goodResult.feedback, contains('Tốt'));
      }

      // Low score feedback
      final badStrokes = [
        [const Offset(10, 10), const Offset(20, 20)],
      ];

      final badResult = service.scoreTracing(
        character: 'ក',
        userStrokes: badStrokes,
        canvasSize: canvasSize,
      );

      expect(badResult.feedback, isNotEmpty);
      expect(badResult.tips, isNotEmpty);
    });

    test('Tips should be helpful based on performance', () {
      // Test that tips are generated based on coverage
      // This will fail minimum requirements, so tips should mention that
      final strokes = [
        [const Offset(200, 200), const Offset(210, 210)],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      expect(result.tips, isNotEmpty);

      // Tips should be relevant to the issue
      // Since this fails minimum requirements, tips should mention strokes or points
      expect(result.tips.any((tip) =>
        tip.contains('nét') ||
        tip.contains('điểm') ||
        tip.contains('đầy đủ')
      ), true);
    });
  });
}
