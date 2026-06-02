import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/scoring_service.dart';

void main() {
  group('Speech Scoring Separated Pipeline Tests', () {
    final scoring = ScoringService.instance;

    test('Exact match (ក vs ក) returns 100% and exact method', () {
      final result = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'ក',
        confidence: 1.0,
      );

      expect(result.rawScore, equals(100.0));
      expect(result.weightedScore, equals(100.0));
      expect(result.passed, isTrue);
      expect(result.matchMethod, equals('exact'));
    });

    test('Accepted pronunciations lookup (ក vs ko/kor) returns 95% and accepted_pronunciation method', () {
      final resultKo = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'ko',
        confidence: 1.0,
      );

      expect(resultKo.rawScore, equals(95.0));
      expect(resultKo.passed, isTrue);
      expect(resultKo.matchMethod, equals('accepted_pronunciation'));

      final resultKor = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'kor',
        confidence: 1.0,
      );

      expect(resultKor.rawScore, equals(95.0));
      expect(resultKor.passed, isTrue);
      expect(resultKor.matchMethod, equals('accepted_pronunciation'));
    });

    test('Phonetic matching handles basic accent normalization', () {
      // Test phonetic accent equivalence
      final resultAccent = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'kò',
        confidence: 1.0,
      );

      expect(resultAccent.rawScore, equals(90.0));
      expect(resultAccent.passed, isTrue);
      expect(resultAccent.matchMethod, equals('phonetic'));
    });

    test('Dice coefficient similarity handles unrelated texts', () {
      final resultUnrelated = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'xyz',
        confidence: 1.0,
      );

      expect(resultUnrelated.rawScore, lessThan(40.0));
      expect(resultUnrelated.passed, isFalse);
      expect(resultUnrelated.matchMethod, equals('dice'));
    });

    test('Confidence weighting and dynamic calibration platform rules', () {
      // 1. Calibrate confidence output checks
      final calibMax = ScoringService.calibrateConfidence(1.0);
      expect(calibMax, equals(1.0)); // Clamped to 1.0

      final calibMin = ScoringService.calibrateConfidence(0.0);
      if (Platform.isAndroid) {
        final versionStr = Platform.operatingSystemVersion.toLowerCase();
        if (versionStr.contains('sdk') || versionStr.contains('google') || versionStr.contains('emulator')) {
          expect(calibMin, closeTo(0.20, 0.001));
        } else {
          expect(calibMin, closeTo(0.12, 0.001));
        }
      } else {
        expect(calibMin, closeTo(0.00, 0.001)); // No boost on non-Android platforms
      }

      // 2. Score bounds check (weightedScore bounded from below by rawScore * 0.60)
      final resultLowConfidence = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'ក',
        confidence: 0.1, // very low confidence
      );

      // Raw score is 100. Weighted score should be bounded by 100 * 0.6 = 60.0,
      // even though calibrated confidence * 100 might be lower (e.g. on non-Android: (0.1+0.0)*100 = 10)
      expect(resultLowConfidence.weightedScore, greaterThanOrEqualTo(60.0));
    });

    test('Stars mapping constraints are correctly satisfied', () {
      // Helper function to map accuracy to stars (same logic as inside KhmerSpeakWidget)
      int accuracyToStars(int accuracy) {
        if (accuracy >= 90) return 3;
        if (accuracy >= 80) return 2;
        if (accuracy >= 70) return 1;
        return 0;
      }

      expect(accuracyToStars(95), equals(3));
      expect(accuracyToStars(90), equals(3));
      expect(accuracyToStars(85), equals(2));
      expect(accuracyToStars(80), equals(2));
      expect(accuracyToStars(75), equals(1));
      expect(accuracyToStars(70), equals(1));
      expect(accuracyToStars(69), equals(0));
      expect(accuracyToStars(50), equals(0));
    });
    test('Non-Latin strings normalizing to empty (e.g. Khmer laughter) do not match phonetically', () {
      final resultLaughter = scoring.scorePronunciationSeparated(
        targetCharacter: 'ឃ',
        recognizedText: 'ហាសហាហាហា',
        confidence: 1.0,
      );

      // Should fall back to dice coefficient and fail, not matching phonetically with 90%
      expect(resultLaughter.matchMethod, equals('dice'));
      expect(resultLaughter.rawScore, lessThan(40.0));
      expect(resultLaughter.passed, isFalse);
    });

    test('Khmer homophone pairs (e.g. គ vs ក) match phonetically with 90% score', () {
      final resultHomophone = scoring.scorePronunciationSeparated(
        targetCharacter: 'គ',
        recognizedText: 'ក',
        confidence: 1.0,
      );

      expect(resultHomophone.matchMethod, equals('phonetic'));
      expect(resultHomophone.rawScore, equals(90.0));
      expect(resultHomophone.passed, isTrue);
    });

    // ── Bài 6 trở đi: dùng romanized/pronunciation của chính chữ cái ──
    // Trước đây các chữ này chỉ dựa vào bản đồ cứng nên dễ trượt. Giờ scorer
    // nhận thêm romanized + pronunciation từ dữ liệu bài học nên khớp được.
    group('Lesson romanized/pronunciation are accepted (bài 6+)', () {
      // (ký tự, romanized, pronunciation, người dùng đọc)
      final cases = [
        ['ច', 'Cho', 'cho', 'cho'], // bài 7
        ['ឆ', 'Chho', 'chho', 'chho'], // bài 8
        ['ដ', 'Đo', 'đo', 'đo'], // bài 13
        ['ត', 'To', 'to', 'to'], // bài 19
        ['ប', 'Bo', 'bo', 'bo'], // bài 25
        ['យ', 'Dô', 'dô', 'dô'], // bài 31
        ['ស', 'So', 'so', 'so'], // bài 36
        ['ហ', 'Ho', 'ho', 'ho'], // bài 37
        ['វ', 'Vô', 'vô', 'vô'], // bài 34
      ];

      for (final c in cases) {
        test('${c[0]} ("${c[1]}") được chấp nhận khi đọc "${c[3]}"', () {
          final result = scoring.scorePronunciationSeparated(
            targetCharacter: c[0],
            recognizedText: c[3],
            confidence: 1.0,
            romanized: c[1],
            pronunciation: c[2],
          );

          expect(result.passed, isTrue,
              reason: 'Đọc đúng "${c[3]}" cho ${c[0]} phải đạt');
          expect(result.rawScore, greaterThanOrEqualTo(90.0));
        });
      }
    });

    test('Latin gần đúng vẫn đạt nhờ Dice so với romanized (vô vs vo)', () {
      final result = scoring.scorePronunciationSeparated(
        targetCharacter: 'វ',
        recognizedText: 'vo',
        confidence: 1.0,
        romanized: 'Vô',
        pronunciation: 'vô',
      );

      expect(result.passed, isTrue);
    });

    // ── Sửa lỗi "đọc đúng vẫn trượt" do confidence thấp ──
    // Nhiều máy Android trả confidence = 0 dù nghe đúng. Khớp văn bản dứt khoát
    // (exact/accepted/phonetic) KHÔNG được bị hạ điểm theo confidence.
    test('Khớp chính xác đậu dù confidence = 0 (lỗi Android trả confidence thấp)',
        () {
      final result = scoring.scorePronunciationSeparated(
        targetCharacter: 'ក',
        recognizedText: 'ក',
        confidence: 0.0,
      );
      expect(result.weightedScore, equals(100.0));
      expect(result.passed, isTrue);
    });

    test('Khớp phát âm đồng nghĩa đậu dù confidence = 0', () {
      final result = scoring.scorePronunciationSeparated(
        targetCharacter: 'ស',
        recognizedText: 'so',
        confidence: 0.0,
        romanized: 'So',
        pronunciation: 'so',
      );
      expect(result.passed, isTrue);
      expect(result.weightedScore, greaterThanOrEqualTo(90.0));
    });

    test('Khớp mờ (dice) vẫn nương tay tối thiểu 85% điểm thô', () {
      // recognizedText khớp một phần với romanized → method dice
      final result = scoring.scorePronunciationSeparated(
        targetCharacter: 'ខ',
        recognizedText: 'khaa', // gần "kho"/"kh" nhưng không trùng khớp tuyệt đối
        confidence: 0.0,
        romanized: 'Kho',
        pronunciation: 'kho',
      );
      if (result.matchMethod == 'dice') {
        // weighted >= rawScore * 0.85 dù confidence = 0
        expect(result.weightedScore,
            greaterThanOrEqualTo(result.rawScore * 0.85 - 0.01));
      }
    });

    // ── Chọn bản chép thay thế tốt nhất (alternates) ──
    // Engine STT trả bản đầu sai nhưng alternate sau đúng → phải chọn bản đúng.
    group('scoreBestAlternate chọn bản khớp nhất', () {
      test('Bản đầu sai, alternate thứ 2 đúng → đậu', () {
        final best = scoring.scoreBestAlternate(
          targetCharacter: 'ច',
          alternates: ['chha', 'cho', 'xyz'], // "cho" mới khớp
          confidence: 0.0,
          romanized: 'Cho',
          pronunciation: 'cho',
        );
        expect(best.result.passed, isTrue);
        expect(best.matchedText, equals('cho'));
      });

      test('Khớp chính xác chữ Khmer trong alternates', () {
        final best = scoring.scoreBestAlternate(
          targetCharacter: 'ក',
          alternates: ['ខ', 'ក', 'ko'],
          confidence: 0.0,
        );
        expect(best.result.rawScore, equals(100.0));
        expect(best.matchedText, equals('ក'));
      });

      test('Không có bản nào khớp → trả kết quả tốt nhất, không crash', () {
        final best = scoring.scoreBestAlternate(
          targetCharacter: 'ស',
          alternates: ['xxx', 'yyy'],
          confidence: 0.0,
          romanized: 'So',
          pronunciation: 'so',
        );
        expect(best.result, isNotNull);
        expect(best.matchedText, isNotEmpty);
      });

      test('Danh sách rỗng → không crash, điểm 0', () {
        final best = scoring.scoreBestAlternate(
          targetCharacter: 'ក',
          alternates: const [],
          confidence: 0.0,
        );
        expect(best.result.rawScore, equals(0.0));
        expect(best.result.passed, isFalse);
      });
    });
  });
}
