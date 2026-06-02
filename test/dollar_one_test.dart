import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmerkid/services/dollar_one_recognizer.dart';
import 'package:khmerkid/services/scoring_service.dart';
import 'package:khmerkid/data/khmer_stroke_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('DollarOneRecognizer Tests', () {
    test('Resample produces exactly 128 points', () {
      List<Offset> points = [
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
        const Offset(40, 40),
        const Offset(50, 50),
      ];

      List<Offset> resampled = DollarOneRecognizer.resample(points, 128);
      expect(resampled.length, equals(128));
      expect((resampled.first - const Offset(10, 10)).distance, lessThan(0.001));
      expect((resampled.last - const Offset(50, 50)).distance, lessThan(0.001));
    });

    test('Preprocessing scales and centers points', () {
      List<Offset> points = [
        const Offset(10, 10),
        const Offset(10, 110),
        const Offset(110, 110),
        const Offset(110, 10),
      ];

      List<Offset> preprocessed = DollarOneRecognizer.preprocess(points);
      expect(preprocessed.length, equals(128));

      // Centroid should be zero
      Offset c = DollarOneRecognizer.centroid(preprocessed);
      expect(c.dx.abs(), lessThan(0.001));
      expect(c.dy.abs(), lessThan(0.001));

      // Bounding box should fit into 250x250
      Rect bounds = DollarOneRecognizer.boundingBox(preprocessed);
      expect(bounds.width, closeTo(250.0, 0.001));
      expect(bounds.height, closeTo(250.0, 0.001));
    });

    test('Recognize match is 1.0 for identical templates', () {
      // Create a template path (circle/square contour)
      List<Offset> circle = [];
      for (int i = 0; i < 360; i += 10) {
        double rad = i * pi / 180.0;
        circle.add(Offset(100 + 50 * cos(rad), 100 + 50 * sin(rad)));
      }

      List<Offset> square = [];
      square.add(const Offset(50, 50));
      square.add(const Offset(150, 50));
      square.add(const Offset(150, 150));
      square.add(const Offset(50, 150));
      square.add(const Offset(50, 50));

      Map<String, List<Offset>> templates = {
        'circle': DollarOneRecognizer.preprocess(circle),
        'square': DollarOneRecognizer.preprocess(square),
      };

      // Test recognition of the circle vs both circle and square templates
      RecognitionMatch circleMatch = DollarOneRecognizer.recognize(circle, templates);
      expect(circleMatch.character, equals('circle'));
      expect(circleMatch.score, greaterThan(0.95));

      // Test recognition of the square vs templates
      RecognitionMatch squareMatch = DollarOneRecognizer.recognize(square, templates);
      expect(squareMatch.character, equals('square'));
      expect(squareMatch.score, greaterThan(0.95));
    });

    test('KhmerStrokeTemplateData loads valid templates and grid occupancy', () {
      importData();
    });

    test('KhmerStrokeTemplateData fallback applies Catmull-Rom spline smoothing', () {
      final template = KhmerStrokeTemplateData.getTemplate('គ');
      expect(template.character, equals('គ'));
      expect(template.points.length, equals(128));
      
      // The spline points should be well-centered and distributed
      final bounds = DollarOneRecognizer.boundingBox(template.points);
      expect(bounds.width, closeTo(250.0, 1.0));
      expect(bounds.height, closeTo(250.0, 1.0));
      
      int occupied = template.gridOccupancy.where((c) => c == 1).length;
      expect(occupied, greaterThan(0));
    });

    test('KhmerStrokeTemplateData preloads consonants using spline template directly', () async {
      await KhmerStrokeTemplateData.loadDynamicFontTemplate('គ');
      final template = KhmerStrokeTemplateData.getTemplate('គ');
      expect(template.character, equals('គ'));
      expect(template.points.length, equals(128));
    });

    test('recognizeWriting with garbage strokes gets low/failing score due to capped Jaccard IoU', () {
      final scoringService = ScoringService.instance;
      // Draw 4 completely parallel diagonal strokes (garbage drawing)
      // that do not overlap well with the letter 'ក'
      final List<List<Offset>> garbageStrokes = [
        [const Offset(10, 10), const Offset(240, 60)],
        [const Offset(10, 80), const Offset(240, 130)],
        [const Offset(10, 150), const Offset(240, 200)],
        [const Offset(10, 220), const Offset(240, 270)],
      ];

      final result = scoringService.recognizeWriting(
        character: 'ក',
        strokes: garbageStrokes,
        canvasSize: const Size(300, 300),
      );

      // The shape score must be capped and fail early (< 42.0)
      expect(result.shapeScore, lessThan(42.0));
      expect(result.passed, isFalse);
      expect(result.finalScore, lessThan(49.0));
    });
  });
}

void importData() {
  final template = KhmerStrokeTemplateData.getTemplate('ក');
  expect(template.character, equals('ក'));
  expect(template.points.length, equals(128));
  expect(template.gridOccupancy.length, equals(256));
  
  // Make sure at least some cells are occupied
  int occupiedCount = template.gridOccupancy.where((cell) => cell == 1).length;
  expect(occupiedCount, greaterThan(0));
  expect(occupiedCount, lessThan(256));
}

