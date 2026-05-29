import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'package:string_similarity/string_similarity.dart';
import '../data/stroke_guide_data.dart';
import 'dollar_one_recognizer.dart';
import '../data/khmer_stroke_templates.dart';

class PronunciationScoreResult {
  final double rawScore;
  final double weightedScore;
  final bool passed;
  final String matchMethod; // 'exact' | 'accepted_pronunciation' | 'phonetic' | 'dice'

  const PronunciationScoreResult({
    required this.rawScore,
    required this.weightedScore,
    required this.passed,
    required this.matchMethod,
  });
}

class RecognitionResult {
  final double finalScore;    // 0-100
  final bool passed;          // >= 70
  final double shapeScore;    // 0-100 ($1 similarity)
  final double strokeScore;   // 0-100 (count + length + position)
  final double directionScore; // 0-100 (hướng vẽ)
  final String feedback;
  final List<String> tips;
  final int stars;            // 0-3

  const RecognitionResult({
    required this.finalScore,
    required this.passed,
    required this.shapeScore,
    required this.strokeScore,
    required this.directionScore,
    required this.feedback,
    required this.tips,
    required this.stars,
  });
}



/// ════════════════════════════════════════════════════════════════════
/// Scoring Service — Chấm điểm phát âm & viết chữ Khmer
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Pronunciation scoring dùng string_similarity (Dice coefficient)
///   • Multi-target comparison (character, romanized, pronunciation)
///   • Normalize: lowercase, trim, remove spaces
///   • Score 0-100%, pass threshold configurable (default 70%)
///   • Writing scoring: stroke analysis + bounds check
///   • Star rating: 0-3 sao
/// ════════════════════════════════════════════════════════════════════

class PronunciationResult {
  final int accuracy; // 0-100
  final bool passed;
  final int stars; // 0-3
  final String matchedTarget; // Target mà user match tốt nhất
  final List<HighlightedWord> highlights;

  const PronunciationResult({
    required this.accuracy,
    required this.passed,
    required this.stars,
    this.matchedTarget = '',
    this.highlights = const [],
  });
}

class HighlightedWord {
  final String text;
  final bool isCorrect;

  const HighlightedWord({required this.text, required this.isCorrect});
}

class WritingResult {
  final int score; // 0-100
  final bool passed;
  final int stars; // 0-3
  final String feedback;

  const WritingResult({
    required this.score,
    required this.passed,
    required this.stars,
    this.feedback = '',
  });
}

class ScoringService {
  ScoringService._();
  static final ScoringService instance = ScoringService._();

  // ─── Config ─────────────────────────────────────────────────────
  static const int defaultPassThreshold = 70; // 70%

  // ─── Multiple Accepted Pronunciations Map ──────────────────────────
  static const Map<String, List<String>> acceptedPronunciations = {
    'ក': ['ko', 'kor', 'koh', 'k'],
    'ខ': ['kho', 'khor', 'khoh', 'kh'],
    'គ': ['ko', 'kor', 'koh', 'k', 'co', 'cor'],
    'ឃ': ['kho', 'khor', 'khoh', 'kh', 'cho', 'chor'],
    'ង': ['ngo', 'ngor', 'ngoh', 'ng'],
    'ច': ['co', 'cor', 'coh', 'ch', 'jo', 'jor'],
    'ឆ': ['cho', 'chor', 'choh', 'ch'],
    'ជ': ['co', 'cor', 'coh', 'ch', 'jo', 'jor'],
    'ឈ': ['cho', 'chor', 'choh', 'ch'],
    'ញ': ['nho', 'nhor', 'nhoh', 'nh', 'ny', 'nyo'],
    'ដ': ['do', 'dor', 'doh', 'd'],
    'ឋ': ['tho', 'thor', 'thoh', 'th'],
    'ឌ': ['do', 'dor', 'doh', 'd'],
    'ឍ': ['tho', 'thor', 'thoh', 'th'],
    'ណ': ['no', 'nor', 'noh', 'n'],
    'ត': ['to', 'tor', 'toh', 't'],
    'ថ': ['tho', 'thor', 'thoh', 'th'],
    'ទ': ['to', 'tor', 'toh', 't'],
    'ធ': ['tho', 'thor', 'thoh', 'th'],
    'ន': ['no', 'nor', 'noh', 'n'],
    'ប': ['bo', 'bor', 'boh', 'b'],
    'ផ': ['pho', 'phor', 'phoh', 'ph'],
    'ព': ['po', 'por', 'poh', 'p'],
    'ភ': ['pho', 'phor', 'phoh', 'ph'],
    'ម': ['mo', 'mor', 'moh', 'm'],
    'យ': ['yo', 'yor', 'yoh', 'y'],
    'រ': ['ro', 'ror', 'roh', 'r'],
    'ល': ['lo', 'lor', 'loh', 'l'],
    'វ': ['vo', 'vor', 'voh', 'v', 'wo', 'wor'],
    'ស': ['so', 'sor', 'soh', 's'],
    'ហ': ['ho', 'hor', 'hoh', 'h'],
    'ឡ': ['lo', 'lor', 'loh', 'l'],
    'អ': ['o', 'or', 'oh'],
  };

  // ─── Device Matrix Dynamic Calibration ────────────────────────────
  static double calibrateConfidence(double rawConfidence) {
    double factor = 0.0;
    try {
      if (Platform.isAndroid) {
        final versionStr = Platform.operatingSystemVersion.toLowerCase();
        if (versionStr.contains('sdk') || versionStr.contains('google') || versionStr.contains('emulator')) {
          factor = 0.20; // Emulator / Low-end boost
        } else {
          factor = 0.12; // Samsung / Mid-end boost
        }
      }
    } catch (_) {
      factor = 0.10; // Fallback
    }
    return (rawConfidence + factor).clamp(0.0, 1.0);
  }

  // ─── Pronunciation Scoring ──────────────────────────────────────

  /// Chấm điểm phát âm biệt lập được thiết kế đặc thù cho việc kiểm thử độc lập (Phase 2).
  PronunciationScoreResult scorePronunciationSeparated({
    required String targetCharacter,
    required String recognizedText,
    required double confidence,
    int passThreshold = defaultPassThreshold,
  }) {
    final spokenNorm = _normalize(recognizedText);
    final targetNorm = _normalize(targetCharacter);

    if (spokenNorm.isEmpty) {
      return const PronunciationScoreResult(
        rawScore: 0.0,
        weightedScore: 0.0,
        passed: false,
        matchMethod: 'dice',
      );
    }

    // Cân chuẩn độ tin cậy thông qua Ma trận Thiết bị
    final calibratedConfidence = calibrateConfidence(confidence);

    double rawScore = 0.0;
    String matchMethod = 'dice';

    // 1. So khớp chính xác tuyệt đối (Exact Match)
    if (spokenNorm == targetNorm || recognizedText == targetCharacter) {
      rawScore = 100.0;
      matchMethod = 'exact';
    } 
    // 2. Tra cứu phát âm đồng nghĩa được chấp nhận (Multiple Accepted Pronunciations)
    else if (acceptedPronunciations.containsKey(targetCharacter) &&
        acceptedPronunciations[targetCharacter]!.contains(spokenNorm)) {
      rawScore = 95.0;
      matchMethod = 'accepted_pronunciation';
    }
    // 3. Đối sánh âm vị học đã chuẩn hóa (Phonetic Matching)
    else if (() {
      final normRec = _normalizePhonetic(recognizedText);
      final normTarget = _normalizePhonetic(targetCharacter);
      if (normRec.isEmpty) return false;
      
      if (normTarget.isNotEmpty && normRec == normTarget) return true;
      
      if (acceptedPronunciations.containsKey(targetCharacter)) {
        return acceptedPronunciations[targetCharacter]!.any((p) {
          final normP = _normalizePhonetic(p);
          return normP.isNotEmpty && normRec == normP;
        });
      }
      return false;
    }()) {
      rawScore = 90.0;
      matchMethod = 'phonetic';
    }
    // 4. Đo lường tỷ lệ tương đồng Dice Coefficient
    else {
      final similarity = StringSimilarity.compareTwoStrings(spokenNorm, targetNorm);
      rawScore = similarity * 100.0;
      matchMethod = 'dice';
    }

    // Tính điểm Weighted theo độ tin cậy đã cân chuẩn (Confidence Weighting)
    // Chặn dưới bằng 60% raw_score để không phạt quá nặng giọng nói trẻ em khi gate đạt
    double weightedScore = rawScore * calibratedConfidence;
    weightedScore = math.max(rawScore * 0.60, weightedScore);

    // Rounding & Threshold Check
    final finalWeighted = weightedScore.clamp(0.0, 100.0);
    final passed = finalWeighted >= passThreshold;

    return PronunciationScoreResult(
      rawScore: rawScore,
      weightedScore: finalWeighted,
      passed: passed,
      matchMethod: matchMethod,
    );
  }

  /// Chấm điểm phát âm bằng Dice coefficient (string_similarity) tương thích ngược.
  PronunciationResult scorePronunciation({
    required String spoken,
    required String character,
    String romanized = '',
    String pronunciation = '',
    int passThreshold = defaultPassThreshold,
  }) {
    final result = scorePronunciationSeparated(
      targetCharacter: character,
      recognizedText: spoken,
      confidence: 1.0, // Mặc định tin cậy tối đa cho các lệnh gọi cũ
      passThreshold: passThreshold,
    );

    return PronunciationResult(
      accuracy: result.weightedScore.round(),
      passed: result.passed,
      stars: _accuracyToStars(result.weightedScore.round()),
      matchedTarget: character,
      highlights: buildHighlights(spoken, character, result.passed),
    );
  }

  /// Chấm điểm nhanh — chỉ trả về accuracy %
  int quickScore(String spoken, String target) {
    final a = _normalize(spoken);
    final b = _normalize(target);
    if (a.isEmpty || b.isEmpty) return 0;

    // Exact match
    if (a.contains(b) || b.contains(a)) return 100;

    final score = StringSimilarity.compareTwoStrings(a, b);
    return (score * 100).round().clamp(0, 100);
  }

  // ─── Writing Scoring ────────────────────────────────────────────

  /// Chấm điểm viết chữ dựa trên stroke analysis + shape guide coordinates.
  /// Kiểm tra: số nét, kích thước, tỉ lệ, coverage và độ khớp hình dáng chữ mẫu.
  /// Nhận diện chữ viết tay sử dụng thuật toán $1 Unistroke Recognizer kết hợp
  /// Phân tích nét viết (Stroke Analysis), Hướng nét viết (Stroke Direction), và Grid Bitmap 16x16.
  RecognitionResult recognizeWriting({
    required String character,
    required List<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    if (strokes.isEmpty) {
      return const RecognitionResult(
        finalScore: 0,
        passed: false,
        shapeScore: 0,
        strokeScore: 0,
        directionScore: 0,
        feedback: 'Hãy viết chữ trước nhé! ✍️',
        tips: ['Đặt bút lên bảng vẽ để bắt đầu viết nhé.'],
        stars: 0,
      );
    }

    // 1. Sanity filters & size check
    int totalPoints = strokes.fold<int>(0, (sum, stroke) => sum + stroke.length);
    if (totalPoints < 6) {
      return const RecognitionResult(
        finalScore: 10,
        passed: false,
        shapeScore: 0,
        strokeScore: 10,
        directionScore: 0,
        feedback: 'Nét vẽ ngắn quá! Hãy vẽ rõ ràng hơn nhé.',
        tips: ['Vẽ dài hơn và rõ nét hơn.', 'Tránh chỉ chạm nhẹ/chấm điểm lên bảng vẽ.'],
        stars: 0,
      );
    }

    // Find bounding box in raw canvas coordinates
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (var s in strokes) {
      for (var p in s) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    double drawnW = maxX - minX;
    double drawnH = maxY - minY;

    // Minimum size ratio check
    double sizeRatio = 0.12; // allow slightly smaller drawings
    if (drawnW < canvasSize.width * sizeRatio || drawnH < canvasSize.height * sizeRatio) {
      return const RecognitionResult(
        finalScore: 15,
        passed: false,
        shapeScore: 0,
        strokeScore: 15,
        directionScore: 0,
        feedback: 'Chữ nhỏ quá! Hãy viết lớn và rõ ràng hơn nhé.',
        tips: ['Viết chữ to hơn chiếm khoảng 50-80% ô vuông.', 'Tránh viết quá sát ở góc.'],
        stars: 0,
      );
    }

    // Centering check
    double centerX = minX + drawnW / 2;
    double centerY = minY + drawnH / 2;
    double offsetX = (centerX - canvasSize.width / 2).abs() / canvasSize.width;
    double offsetY = (centerY - canvasSize.height / 2).abs() / canvasSize.height;
    if (offsetX > 0.42 || offsetY > 0.42) {
      return const RecognitionResult(
        finalScore: 20,
        passed: false,
        shapeScore: 0,
        strokeScore: 20,
        directionScore: 0,
        feedback: 'Hãy viết ở chính giữa ô vuông nhé!',
        tips: ['Viết cân đối ở chính giữa bảng vẽ.', 'Tránh vẽ quá lệch về một bên.'],
        stars: 0,
      );
    }

    // 2. Fetch template data
    final template = KhmerStrokeTemplateData.getTemplate(character);

    // 3. Anti-Scribble / Anti-Cheat Detection
    bool isScribble = false;
    List<String> cheatFeedback = [];
    if (strokes.length > 9) {
      isScribble = true;
      cheatFeedback.add('Số nét vẽ quá nhiều (hiện có ${strokes.length} nét).');
    }

    // Compute grid occupancy ratio for user
    final userMergedPath = DollarOneRecognizer.mergeStrokes(strokes);
    final userPreprocessed = DollarOneRecognizer.preprocess(userMergedPath);
    
    // Compute 16x16 grid occupancy for user
    final userGrid = KhmerStrokeTemplateData.computeGrid16x16(userPreprocessed);
    int userFilledCells = userGrid.where((cell) => cell == 1).length;
    double occupancyRatio = userFilledCells / 256.0;

    if (occupancyRatio > 0.70) {
      isScribble = true;
      cheatFeedback.add('Hình vẽ tô kín cả màn hình.');
    }

    if (isScribble) {
      return RecognitionResult(
        finalScore: 10,
        passed: false,
        shapeScore: 5,
        strokeScore: 10,
        directionScore: 5,
        feedback: 'Hãy viết nắn nót chữ cái, tránh vẽ bậy lên khung nhé! 🙅',
        tips: [
          'Tránh tô đi tô lại quá nhiều nét.',
          'Chỉ vẽ đúng hình dạng chữ cái.',
          ...cheatFeedback
        ],
        stars: 0,
      );
    }

    // 4. Shape Similarity (65% weight)
    // a) Dollar-One Unistroke shape score (stroke-order and direction sensitive)
    double dollarOneShapeScore = 0.0;
    Map<String, List<Offset>> templateMap = {
      character: template.points
    };
    final match = DollarOneRecognizer.recognize(userMergedPath, templateMap);
    dollarOneShapeScore = (math.sqrt(match.score) * 100.0).clamp(0.0, 100.0);

    // b) Grid-based Intersection over Union (IoU) score (completely robust against stroke-order, number of strokes and scrambled template paths)
    int intersection = 0;
    int union = 0;
    for (int i = 0; i < 256; i++) {
      if (userGrid[i] == 1 && template.gridOccupancy[i] == 1) {
        intersection++;
      }
      if (userGrid[i] == 1 || template.gridOccupancy[i] == 1) {
        union++;
      }
    }
    double iou = union > 0 ? (intersection / union) : 0.0;
    // Map IoU using a robust piece-wise curve:
    // - Under 0.28 (garbage drawings): heavily penalized to cap shapeScore below 42% so it fails early.
    // - 0.28 to 0.60 (valid drawings): scaled smoothly and generously from 38% to 100% for child-friendliness.
    double gridShapeScore = 0.0;
    if (iou < 0.28) {
      gridShapeScore = (iou / 0.28) * 38.0;
    } else {
      gridShapeScore = 38.0 + ((iou - 0.28) / (0.60 - 0.28)) * 62.0;
    }
    gridShapeScore = gridShapeScore.clamp(0.0, 100.0);

    // Combine shape scores: take the maximum of both to handle stroke-order variations,
    // but cap by gridShapeScore * 1.4 to prevent garbage drawings from cheating the system
    // due to accidental alignment with scrambled outline templates.
    double shapeScore = math.max(dollarOneShapeScore, gridShapeScore);
    shapeScore = math.min(shapeScore, gridShapeScore * 1.4).clamp(0.0, 100.0);

    // Fail early only if shape is completely unrelated (less than 42% boosted shapeScore)
    if (shapeScore < 42.0) {
      return RecognitionResult(
        finalScore: (shapeScore * 0.95).roundToDouble().clamp(0, 49),
        passed: false,
        shapeScore: shapeScore,
        strokeScore: 30,
        directionScore: 20,
        feedback: 'Hãy viết nắn nót theo hình mẫu nhé! ✍️',
        tips: ['Tham khảo hướng dẫn và vẽ nắn nót từng nét.', 'Tránh viết sai hình dạng chữ cái.'],
        stars: 0,
      );
    }

    // 5. Stroke Analysis (25% weight)
    double strokeCountScore = 100.0;
    final guides = StrokeGuideData.getStrokes(character);
    if (guides.isNotEmpty) {
      int expectedCount = guides.length;
      int actualCount = strokes.length;
      int diff = (actualCount - expectedCount).abs();
      if (diff == 0) {
        strokeCountScore = 100.0;
      } else if (diff == 1) {
        strokeCountScore = 80.0; // Generous: was 65.0
      } else if (diff == 2) {
        strokeCountScore = 60.0; // Generous: was 40.0
      } else {
        strokeCountScore = 40.0; // Generous: was 20.0
      }
    }

    // Stroke length comparison
    double templateLength = DollarOneRecognizer.pathLength(template.points);
    double userNormalizedLength = DollarOneRecognizer.pathLength(userPreprocessed);
    double lengthRatio = (userNormalizedLength / templateLength);
    double lengthScore = 100.0;
    if (lengthRatio < 0.4 || lengthRatio > 2.2) {
      lengthScore = 50.0;
    } else if (lengthRatio < 0.6 || lengthRatio > 1.7) {
      lengthScore = 85.0;
    }

    double strokeScore = (strokeCountScore * 0.7 + lengthScore * 0.3);

    // 6. Stroke Direction (10% weight)
    double directionScore = 100.0;
    List<int> badDirectionIndices = [];
    if (guides.isNotEmpty) {
      double totalDirScore = 0.0;
      int matchCount = math.min(guides.length, strokes.length);
      for (int i = 0; i < matchCount; i++) {
        final g = guides[i];
        final expectedAngleRad = g[3] * math.pi / 180.0;
        final stroke = strokes[i];
        
        if (stroke.length >= 2) {
          final double dx = stroke.last.dx - stroke.first.dx;
          final double dy = stroke.last.dy - stroke.first.dy;
          final double drawnAngle = math.atan2(dy, dx);
          double angleDiff = (drawnAngle - expectedAngleRad).abs();
          if (angleDiff > math.pi) angleDiff = 2 * math.pi - angleDiff;
          
          double dirS = 0.0;
          if (angleDiff < (45.0 * math.pi / 180.0)) { // Generous angle tolerance
            dirS = 100.0;
          } else if (angleDiff < (90.0 * math.pi / 180.0)) { // Generous angle tolerance
            dirS = 70.0; // Generous: was 60.0
            badDirectionIndices.add(i);
          } else {
            dirS = 40.0; // Generous: was 10.0
            badDirectionIndices.add(i);
          }
          totalDirScore += dirS;
        } else {
          totalDirScore += 50.0;
        }
      }
      
      if (strokes.length != guides.length) {
        int diff = (strokes.length - guides.length).abs();
        totalDirScore = (totalDirScore / math.max(strokes.length, guides.length)) * (1.0 - (diff * 0.08)).clamp(0.3, 1.0) * 100.0;
      } else {
        totalDirScore = totalDirScore / guides.length;
      }
      directionScore = totalDirScore;
    }

    // 7. Grid Overlap Boost/Refinement
    int gridMatches = 0;
    for (int i = 0; i < 256; i++) {
      if (userGrid[i] == template.gridOccupancy[i]) {
        gridMatches++;
      }
    }
    double gridSim = gridMatches / 256.0;
    
    if (shapeScore >= 45.0 && shapeScore <= 75.0) {
      if (gridSim > 0.90) {
        shapeScore = math.min(100.0, shapeScore + 8.0);
      } else if (gridSim < 0.80) {
        shapeScore = math.max(0.0, shapeScore - 8.0);
      }
    }

    // 8. Compute final weighted score
    double finalScore = shapeScore * 0.65 + strokeScore * 0.25 + directionScore * 0.10;
    int roundedFinal = finalScore.round().clamp(0, 100);
    
    // Smart Feedback & Tips
    final lines = <String>[];
    final tips = <String>[];
    
    if (shapeScore >= 78) {
      lines.add('✓ Hình dạng rất tốt!');
    } else if (shapeScore >= 55) {
      lines.add('△ Hình dạng khá khớp nhưng cần nắn nót hơn.');
      tips.add('Cố gắng vẽ cong mượt và đều tay theo nét mờ.');
    } else {
      lines.add('✗ Hình dạng nét viết chưa chuẩn.');
      tips.add('Nhìn kỹ chữ mẫu và tập vẽ chậm rãi hơn.');
    }

    if (guides.isNotEmpty) {
      if (strokes.length == guides.length) {
        lines.add('✓ Đúng số nét (${guides.length} nét).');
      } else {
        lines.add('✗ Chưa đúng số nét (cần vẽ ${guides.length} nét, bạn vẽ ${strokes.length} nét).');
        tips.add('Khmer viết theo đúng quy trình: nhấc bút đúng ${guides.length} lần.');
      }
    }

    if (directionScore >= 75) {
      lines.add('✓ Hướng vẽ chính xác.');
    } else {
      lines.add('△ Một số nét vẽ chưa đúng hướng.');
      for (var idx in badDirectionIndices) {
        tips.add('Nét thứ ${idx + 1}: vẽ theo chiều mũi tên hướng dẫn.');
      }
    }

    // Encouraging passing criteria: 58% or above passes for kids
    bool passed = roundedFinal >= 58;
    int stars = 0;
    if (roundedFinal >= 85) {
      stars = 3;
    } else if (roundedFinal >= 72) {
      stars = 2;
    } else if (roundedFinal >= 58) {
      stars = 1;
    }

    String feedback = lines.join('\n');

    return RecognitionResult(
      finalScore: roundedFinal.toDouble(),
      passed: passed,
      shapeScore: shapeScore,
      strokeScore: strokeScore,
      directionScore: directionScore,
      feedback: feedback,
      tips: tips.isEmpty ? ['Chữ viết của bạn rất tốt, hãy tiếp tục phát huy nhé!'] : tips,
      stars: stars,
    );
  }

  /// Chấm điểm viết chữ dựa trên $1 Unistroke Recognizer (tương thích ngược với legacy code).
  WritingResult scoreWriting({
    required List<List<dynamic>> strokes,
    required double canvasWidth,
    required double canvasHeight,
    int minStrokes = 1,
    int minPoints = 6,
    double minSizeRatio = 0.15,
    String? expectedCharacter,
  }) {
    final List<List<Offset>> offsetStrokes = [];
    for (final s in strokes) {
      final List<Offset> offsetStroke = [];
      for (final p in s) {
        offsetStroke.add(p as Offset);
      }
      offsetStrokes.add(offsetStroke);
    }

    final recognition = recognizeWriting(
      character: expectedCharacter ?? 'ក',
      strokes: offsetStrokes,
      canvasSize: Size(canvasWidth, canvasHeight),
    );

    return WritingResult(
      score: recognition.finalScore.round(),
      passed: recognition.passed,
      stars: recognition.stars,
      feedback: recognition.feedback,
    );
  }

  /// Chấm điểm viết OCR (so sánh text nhận dạng với mẫu)
  WritingResult scoreWritingOcr({
    required String recognized,
    required String expected,
  }) {
    if (recognized.isEmpty) {
      return const WritingResult(
        score: 0,
        passed: false,
        stars: 0,
        feedback: 'Không nhận diện được chữ viết.',
      );
    }

    final accuracy = quickScore(recognized, expected);
    final passed = accuracy >= 60;
    final stars = _accuracyToStars(accuracy);

    return WritingResult(
      score: accuracy,
      passed: passed,
      stars: stars,
      feedback: passed
          ? 'Viết rất đẹp!'
          : 'Hãy viết rõ ràng hơn nhé!',
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _normalize(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isKhmerText(String s) {
    return s.runes.any((r) => r >= 0x1780 && r <= 0x17FF);
  }

  String _normalizeKhmer(String s) {
    var str = s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    // Giữ lại phụ âm Khmer cốt lõi
    str = str.replaceAll(RegExp(r'[^\u1780-\u17a2]'), '');
    
    // Đồng nhất các cặp phụ âm đồng âm (Series 1 & Series 2)
    str = str.replaceAll('គ', 'ក');
    str = str.replaceAll('ឃ', 'ខ');
    str = str.replaceAll('ជ', 'ច');
    str = str.replaceAll('ឈ', 'ឆ');
    str = str.replaceAll('ឌ', 'ដ');
    str = str.replaceAll('ឍ', 'ឋ');
    str = str.replaceAll('ន', 'ណ');
    str = str.replaceAll('ទ', 'ត');
    str = str.replaceAll('ធ', 'ថ');
    str = str.replaceAll('ព', 'ប');
    str = str.replaceAll('ភ', 'ផ');
    str = str.replaceAll('ឡ', 'ល');
    
    return str;
  }

  String _normalizeLatin(String s) {
    var str = s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    
    // Loại bỏ dấu tiếng Việt
    var withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    
    // Giữ lại chữ cái thường và số
    str = str.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Các từ đồng âm gần âm phổ biến (đặc biệt khi fallback tiếng Việt)
    if (str.startsWith('c')) str = 'k' + str.substring(1);
    if (str.startsWith('q')) str = 'k' + str.substring(1);
    if (str.startsWith('gi')) str = 'd' + str.substring(2);
    if (str.startsWith('v')) str = 'd' + str.substring(1);
    if (str.startsWith('tr')) str = 'ch' + str.substring(2);
    if (str.startsWith('ph')) str = 'f' + str.substring(2);
    
    return str;
  }

  String _normalizePhonetic(String s) {
    if (_isKhmerText(s)) {
      return _normalizeKhmer(s);
    } else {
      return _normalizeLatin(s);
    }
  }

  int _accuracyToStars(int accuracy) {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy >= 50) return 1;
    return 0;
  }

  List<HighlightedWord> buildHighlights(
    String spoken,
    String target,
    bool allCorrect,
  ) {
    if (allCorrect || target.isEmpty) {
      return [HighlightedWord(text: spoken, isCorrect: true)];
    }

    // Tách từ để highlight từng từ
    final spokenWords = spoken.split(RegExp(r'\s+'));
    final targetNorm = _normalize(target);
    final targetPhonetic = _normalizePhonetic(target);
    
    return spokenWords.map((word) {
      final wordNorm = _normalize(word);
      final wordPhonetic = _normalizePhonetic(word);
      
      final simNorm = wordNorm.isNotEmpty && targetNorm.isNotEmpty
          ? StringSimilarity.compareTwoStrings(wordNorm, targetNorm)
          : 0.0;
          
      final simPhonetic = wordPhonetic.isNotEmpty && targetPhonetic.isNotEmpty
          ? StringSimilarity.compareTwoStrings(wordPhonetic, targetPhonetic)
          : 0.0;
          
      final isCorrect = simNorm > 0.3 || simPhonetic > 0.4 || wordPhonetic == targetPhonetic;
      return HighlightedWord(text: word, isCorrect: isCorrect);
    }).toList();
  }
}

extension PronunciationResultX on PronunciationResult {
  String get feedback {
    if (accuracy >= 90) return 'Xuất sắc! 🌟';
    if (accuracy >= 70) return 'Tuyệt vời! 🎉';
    if (accuracy >= 50) return 'Khá tốt! 👍';
    if (accuracy >= 30) return 'Cần cố gắng thêm!';
    return 'Thử lại nhé! 💪';
  }

  String get emoji {
    if (accuracy >= 90) return '🌟';
    if (accuracy >= 70) return '🎉';
    if (accuracy >= 50) return '👍';
    if (accuracy >= 30) return '😅';
    return '💪';
  }
}
