import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/handwriting_tracing_service.dart';

/// Kiểm tra vùng template chấm điểm bám đúng vị trí dấu phụ thuộc Khmer
/// (trên / dưới / trái / phải) so với chỗ neo '◌'.
void main() {
  group('Vowel scoring template position by mark type', () {
    final service = HandwritingTracingService.instance;
    const canvasSize = Size(400, 400);

    List<List<Offset>> strokeAt({required double x, required double y}) {
      // 220 điểm > minPointsRequired (200), tập trung quanh (x, y).
      return [
        List<Offset>.generate(
          220,
          (i) => Offset(x + (i % 20).toDouble(), y + (i ~/ 20) * 4.0),
        ),
      ];
    }

    test('◌ា (dấu PHẢI): vẽ bên phải đậu, vẽ bên trái trượt', () {
      final right = service.scoreTracing(
        character: '◌ា',
        userStrokes: strokeAt(x: 240, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final left = service.scoreTracing(
        character: '◌ា',
        userStrokes: strokeAt(x: 60, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(right.insideCoverage, greaterThanOrEqualTo(right.outsideCoverage));
      expect(left.outsideCoverage, greaterThan(left.insideCoverage));
    });

    test('◌ិ (dấu TRÊN): vẽ phía trên đậu, vẽ phía dưới trượt', () {
      // Vùng dấu phụ thuộc trên = phần trên 65% canvas/glyph.
      // y=130 nằm chắc trong vùng cả khi font load được lẫn không.
      final top = service.scoreTracing(
        character: '◌ិ',
        userStrokes: strokeAt(x: 150, y: 130),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final bottom = service.scoreTracing(
        character: '◌ិ',
        userStrokes: strokeAt(x: 150, y: 340),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(top.insideCoverage, greaterThanOrEqualTo(top.outsideCoverage));
      expect(bottom.outsideCoverage, greaterThan(bottom.insideCoverage));
    });

    test('◌ី (dấu TRÊN — nguyên âm "ây"): vẽ phía trên đậu', () {
      final top = service.scoreTracing(
        character: '◌ី',
        userStrokes: strokeAt(x: 150, y: 130),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(top.insideCoverage, greaterThanOrEqualTo(top.outsideCoverage));
    });

    test('◌ុ (dấu DƯỚI): vẽ phía dưới đậu, vẽ phía trên trượt', () {
      final bottom = service.scoreTracing(
        character: '◌ុ',
        userStrokes: strokeAt(x: 150, y: 260),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final top = service.scoreTracing(
        character: '◌ុ',
        userStrokes: strokeAt(x: 150, y: 30),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(bottom.insideCoverage, greaterThanOrEqualTo(bottom.outsideCoverage));
      expect(top.outsideCoverage, greaterThan(top.insideCoverage));
    });

    test('◌េ (dấu TRÁI): vẽ bên trái đậu, vẽ bên phải trượt', () {
      final left = service.scoreTracing(
        character: '◌េ',
        userStrokes: strokeAt(x: 120, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final right = service.scoreTracing(
        character: '◌េ',
        userStrokes: strokeAt(x: 280, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(left.insideCoverage, greaterThanOrEqualTo(left.outsideCoverage));
      expect(right.outsideCoverage, greaterThan(right.insideCoverage));
    });

    test('◌ោ (dấu GHÉP trái+phải): vẽ cả bên trái lẫn bên phải đều đậu (không bị phạt)', () {
      final left = service.scoreTracing(
        character: '◌ោ',
        userStrokes: strokeAt(x: 120, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final right = service.scoreTracing(
        character: '◌ោ',
        userStrokes: strokeAt(x: 280, y: 150),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(left.insideCoverage, greaterThanOrEqualTo(left.outsideCoverage));
      expect(right.insideCoverage, greaterThanOrEqualTo(right.outsideCoverage));
    });

    test('◌ុំ (dấu GHÉP trên+dưới): vẽ cả phía trên lẫn phía dưới đều đậu (không bị phạt)', () {
      final top = service.scoreTracing(
        character: '◌ុំ',
        userStrokes: strokeAt(x: 150, y: 100),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      final bottom = service.scoreTracing(
        character: '◌ុំ',
        userStrokes: strokeAt(x: 150, y: 300),
        canvasSize: canvasSize,
        minStrokesOverride: 1,
        minPointsOverride: 80,
      );
      expect(top.insideCoverage, greaterThanOrEqualTo(top.outsideCoverage));
      expect(bottom.insideCoverage, greaterThanOrEqualTo(bottom.outsideCoverage));
    });
  });
}
