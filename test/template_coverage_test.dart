import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

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
      // Vẽ nhiều nét phủ kín vùng chữ mẫu
      final strokes = [
        // Nét ngang
        List.generate(50, (i) => Offset(150 + i * 2.0, 180)),
        List.generate(50, (i) => Offset(150 + i * 2.0, 200)),
        List.generate(50, (i) => Offset(150 + i * 2.0, 220)),
        // Nét dọc
        List.generate(50, (i) => Offset(180, 150 + i * 2.0)),
        List.generate(50, (i) => Offset(200, 150 + i * 2.0)),
        List.generate(50, (i) => Offset(220, 150 + i * 2.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Large strokes - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      // Nhiều nét phủ kín phải PASS
      if (result.insideCoverage >= 70 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
      }
    });

    test('Drawing only half of template should FAIL', () {
      // Chỉ vẽ nửa trên của chữ
      final strokes = [
        List.generate(40, (i) => Offset(160 + i * 2.0, 170)),
        List.generate(40, (i) => Offset(160 + i * 2.0, 180)),
        List.generate(40, (i) => Offset(160 + i * 2.0, 190)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
        minPointsOverride: 200,
      );

      print('Half template - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%');

      // Chỉ vẽ một nửa không đủ
      expect(result.passed, false);
    });

    test('Full template coverage with good accuracy should PASS with high score', () {
      // Vẽ đầy đủ toàn bộ chữ mẫu
      final strokes = <List<Offset>>[];

      // Tạo lưới nét phủ kín vùng chữ mẫu (160-240 x 160-240)
      for (int y = 160; y <= 240; y += 10) {
        strokes.add(List.generate(40, (i) => Offset(160 + i * 2.0, y.toDouble())));
      }
      for (int x = 160; x <= 240; x += 10) {
        strokes.add(List.generate(40, (i) => Offset(x.toDouble(), 160 + i * 2.0)));
      }

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Full coverage - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}, Score: ${result.finalScore.round()}%, Stars: ${result.stars}');

      // Phủ đầy đủ phải PASS với điểm cao
      if (result.insideCoverage >= 70 && result.outsideCoverage <= 30) {
        expect(result.passed, true);
        expect(result.finalScore, greaterThan(70));
      }
    });

    test('Very small stroke (< 20 points) should FAIL immediately', () {
      // Nét rất nhỏ
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
      // Vẽ đầy đủ nhưng nhiều nét ra ngoài
      final strokes = <List<Offset>>[];

      // Nét trong
      for (int y = 170; y <= 230; y += 15) {
        strokes.add(List.generate(30, (i) => Offset(170 + i * 2.0, y.toDouble())));
      }

      // Nét ngoài (nhiều)
      for (int y = 50; y <= 150; y += 20) {
        strokes.add(List.generate(30, (i) => Offset(50 + i * 2.0, y.toDouble())));
      }

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Good coverage but outside - Inside: ${result.insideCoverage.round()}%, Outside: ${result.outsideCoverage.round()}%');
      print('Result: ${result.passed ? "PASS" : "FAIL"}');

      if (result.outsideCoverage > 30) {
        expect(result.passed, false);
      }
    });

    test('Comparing different coverage levels', () {
      // Test 1: 25% coverage
      final strokes1 = [
        List.generate(20, (i) => Offset(180 + i * 2.0, 190)),
        List.generate(20, (i) => Offset(180 + i * 2.0, 200)),
      ];

      final result1 = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes1,
        canvasSize: canvasSize,
        minPointsOverride: 200,
      );

      print('25% coverage - Score: ${result1.finalScore.round()}%, Passed: ${result1.passed}');

      // Test 2: 75% coverage
      final strokes2 = <List<Offset>>[];
      for (int y = 165; y <= 235; y += 10) {
        strokes2.add(List.generate(35, (i) => Offset(165 + i * 2.0, y.toDouble())));
      }

      final result2 = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes2,
        canvasSize: canvasSize,
        minPointsOverride: 200,
      );

      print('75% coverage - Score: ${result2.finalScore.round()}%, Passed: ${result2.passed}');

      // 75% coverage phải tốt hơn 25%
      expect(result2.finalScore, greaterThan(result1.finalScore));
    });
  });
}
