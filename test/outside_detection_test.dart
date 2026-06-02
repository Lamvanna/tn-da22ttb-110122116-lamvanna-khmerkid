import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

void main() {
  group('Handwriting Outside Template Detection Tests', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    test('Drawing in corners (far from center) should have high outside coverage', () {
      // Vẽ ở 4 góc canvas (xa tâm)
      final strokes = [
        // Góc trên trái
        [const Offset(10, 10), const Offset(30, 30)],
        // Góc trên phải
        [const Offset(370, 10), const Offset(390, 30)],
        // Góc dưới trái
        [const Offset(10, 370), const Offset(30, 390)],
        // Góc dưới phải
        [const Offset(370, 370), const Offset(390, 390)],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Corner drawing - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Vẽ ở góc phải có outside coverage cao
      expect(result.outsideCoverage, greaterThan(50));
      expect(result.passed, false);
    });

    test('Drawing around template (not on it) should have high outside coverage', () {
      // Vẽ vòng tròn xung quanh chữ mẫu nhưng không chạm vào
      final strokes = [
        // Vòng tròn bên ngoài (radius lớn)
        List.generate(40, (i) {
          final angle = (i / 40) * 2 * 3.14159;
          return Offset(
            200 + 150 * math.cos(angle),
            200 + 150 * math.sin(angle),
          );
        }),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Around template - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Vẽ xung quanh phải có outside coverage cao
      expect(result.outsideCoverage, greaterThan(30));
    });

    test('Drawing exactly on center should have high inside coverage', () {
      // Vẽ chính giữa canvas (nơi có chữ mẫu)
      final strokes = [
        // Nét ngang qua tâm
        List.generate(20, (i) => Offset(180 + i * 2.0, 200)),
        // Nét dọc qua tâm
        List.generate(20, (i) => Offset(200, 180 + i * 2.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Center drawing - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Vẽ ở tâm phải có inside coverage cao
      expect(result.insideCoverage, greaterThan(result.outsideCoverage));
    });

    test('Drawing half inside, half outside should be detected correctly', () {
      // Vẽ một nửa trong, một nửa ngoài
      final strokes = [
        // Nét từ tâm ra ngoài
        List.generate(30, (i) => Offset(200, 200 + i * 5.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Half-half drawing - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Cả inside và outside đều phải có giá trị
      expect(result.insideCoverage, greaterThan(0));
      expect(result.outsideCoverage, greaterThan(0));
    });

    test('Scribbling everywhere should fail with high outside coverage', () {
      // Vẽ bậy khắp canvas
      final strokes = [
        List.generate(20, (i) => Offset(i * 20.0, 50)),
        List.generate(20, (i) => Offset(i * 20.0, 150)),
        List.generate(20, (i) => Offset(i * 20.0, 250)),
        List.generate(20, (i) => Offset(i * 20.0, 350)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Scribbling - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Vẽ bậy phải có outside coverage rất cao
      expect(result.outsideCoverage, greaterThan(40));
      expect(result.passed, false);
    });

    test('Drawing in top-left quadrant only should have high outside coverage', () {
      // Chỉ vẽ ở góc phần tư trên trái
      final strokes = [
        List.generate(30, (i) => Offset(50 + i * 2.0, 50 + i * 2.0)),
        List.generate(30, (i) => Offset(50 + i * 2.0, 100 - i * 1.0)),
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Top-left quadrant - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      expect(result.outsideCoverage, greaterThan(50));
      expect(result.passed, false);
    });

    test('Small stroke far from template should be 100% outside', () {
      // Nét nhỏ xa chữ mẫu
      final strokes = [
        [const Offset(10, 10), const Offset(15, 15), const Offset(20, 20)],
      ];

      final result = service.scoreTracing(
        character: 'ក',
        userStrokes: strokes,
        canvasSize: canvasSize,
      );

      print('Far stroke - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

      // Nét xa hoàn toàn phải là 100% outside
      expect(result.outsideCoverage, greaterThan(80));
      expect(result.insideCoverage, lessThan(20));
      expect(result.passed, false);
    });

    test('Comparing different characters - same stroke position', () {
      // Cùng một nét vẽ nhưng với các chữ khác nhau
      final strokes = [
        List.generate(20, (i) => Offset(180 + i * 2.0, 180 + i * 2.0)),
      ];

      final characters = ['ក', 'ខ', 'គ'];

      for (final char in characters) {
        final result = service.scoreTracing(
          character: char,
          userStrokes: strokes,
          canvasSize: canvasSize,
        );

        print('Character $char - Outside: ${result.outsideCoverage}%, Inside: ${result.insideCoverage}%');

        // Mỗi chữ có thể có kết quả khác nhau
        expect(result.finalScore, greaterThanOrEqualTo(0));
        expect(result.finalScore, lessThanOrEqualTo(100));
      }
    });
  });
}
