import 'dart:math' as math;
import 'package:string_similarity/string_similarity.dart';
import '../data/stroke_guide_data.dart';


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

  // ─── Pronunciation Scoring ──────────────────────────────────────

  /// Chấm điểm phát âm bằng Dice coefficient (string_similarity).
  /// So sánh [spoken] với nhiều target: character, romanized, pronunciation.
  /// Trả về PronunciationResult với accuracy 0-100, passed, stars 0-3.
  PronunciationResult scorePronunciation({
    required String spoken,
    required String character,
    String romanized = '',
    String pronunciation = '',
    int passThreshold = defaultPassThreshold,
  }) {
    final spokenNorm = _normalize(spoken);
    final spokenPhonetic = _normalizePhonetic(spoken);
    
    if (spokenNorm.isEmpty) {
      return const PronunciationResult(
        accuracy: 0,
        passed: false,
        stars: 0,
      );
    }

    // Targets theo cách chuẩn hóa thông thường
    final targetsNorm = <String>[
      character,
      if (romanized.isNotEmpty) romanized,
      if (pronunciation.isNotEmpty) pronunciation,
    ].map(_normalize).where((t) => t.isNotEmpty).toList();

    // Targets theo cách chuẩn hóa âm học (phonetic)
    final targetsPhonetic = <String>[
      character,
      if (romanized.isNotEmpty) romanized,
      if (pronunciation.isNotEmpty) pronunciation,
    ].map(_normalizePhonetic).where((t) => t.isNotEmpty).toList();

    // 1. Kiểm tra khớp tuyệt đối theo bất kỳ cách nào
    bool exactMatch = false;
    String matchedTarget = character;

    // Check khớp chuẩn
    for (int i = 0; i < targetsNorm.length; i++) {
      final tNorm = targetsNorm[i];
      if (spokenNorm.contains(tNorm) || tNorm.contains(spokenNorm)) {
        exactMatch = true;
        matchedTarget = targetsNorm[i];
        break;
      }
    }

    // Check khớp gần âm
    if (!exactMatch) {
      for (int i = 0; i < targetsPhonetic.length; i++) {
        final tPhonetic = targetsPhonetic[i];
        if (spokenPhonetic.isNotEmpty && tPhonetic.isNotEmpty &&
            (spokenPhonetic.contains(tPhonetic) || tPhonetic.contains(spokenPhonetic) || spokenPhonetic == tPhonetic)) {
          exactMatch = true;
          // Ánh xạ lại target nguyên bản tương ứng
          final rawTargets = <String>[
            character,
            if (romanized.isNotEmpty) romanized,
            if (pronunciation.isNotEmpty) pronunciation,
          ].where((t) => t.isNotEmpty).toList();
          matchedTarget = rawTargets[i];
          break;
        }
      }
    }

    if (exactMatch) {
      return PronunciationResult(
        accuracy: 100,
        passed: true,
        stars: 3,
        matchedTarget: matchedTarget,
        highlights: _buildHighlights(spoken, matchedTarget, true),
      );
    }

    // 2. So sánh độ tương tự (Dice coefficient) cho cả 2 cách và lấy điểm lớn nhất
    double bestScore = 0;
    String bestTarget = character;
    
    final rawTargets = <String>[
      character,
      if (romanized.isNotEmpty) romanized,
      if (pronunciation.isNotEmpty) pronunciation,
    ].where((t) => t.isNotEmpty).toList();

    for (int i = 0; i < rawTargets.length; i++) {
      final tNorm = targetsNorm[i];
      final tPhonetic = targetsPhonetic[i];

      // Điểm chuẩn
      final scoreNorm = StringSimilarity.compareTwoStrings(spokenNorm, tNorm);
      // Điểm âm học gần đúng
      final scorePhonetic = StringSimilarity.compareTwoStrings(spokenPhonetic, tPhonetic);

      final score = scoreNorm > scorePhonetic ? scoreNorm : scorePhonetic;
      if (score > bestScore) {
        bestScore = score;
        bestTarget = rawTargets[i];
      }
    }

    // Boost 10% nếu ký tự đầu khớp theo âm học
    final bestTargetPhonetic = _normalizePhonetic(bestTarget);
    if (bestTargetPhonetic.isNotEmpty && spokenPhonetic.isNotEmpty && 
        bestTargetPhonetic[0] == spokenPhonetic[0]) {
      bestScore = (bestScore + 0.1).clamp(0.0, 1.0);
    }

    final accuracy = (bestScore * 100).round().clamp(0, 100);
    final passed = accuracy >= passThreshold;
    final stars = _accuracyToStars(accuracy);

    return PronunciationResult(
      accuracy: accuracy,
      passed: passed,
      stars: stars,
      matchedTarget: bestTarget,
      highlights: _buildHighlights(spoken, bestTarget, passed),
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
  WritingResult scoreWriting({
    required List<List<dynamic>> strokes,
    required double canvasWidth,
    required double canvasHeight,
    int minStrokes = 1,
    int minPoints = 20,
    double minSizeRatio = 0.15,
    String? expectedCharacter,
  }) {
    if (strokes.isEmpty) {
      return const WritingResult(
        score: 0,
        passed: false,
        stars: 0,
        feedback: 'Hãy viết chữ trước nhé!',
      );
    }

    // Check minimum strokes
    if (strokes.length < minStrokes) {
      return WritingResult(
        score: 10,
        passed: false,
        stars: 0,
        feedback: 'Cần ít nhất $minStrokes nét vẽ! (hiện có ${strokes.length} nét)',
      );
    }

    // Count total points
    int totalPoints = 0;
    for (final s in strokes) {
      totalPoints += s.length;
    }

    if (totalPoints < minPoints) {
      return const WritingResult(
        score: 20,
        passed: false,
        stars: 0,
        feedback: 'Nét viết quá ngắn! Hãy viết rõ ràng hơn.',
      );
    }

    // Check bounds (size of written area)
    double minX = double.infinity, maxX = 0;
    double minY = double.infinity, maxY = 0;
    for (final s in strokes) {
      for (final p in s) {
        final dx = (p as dynamic).dx as double;
        final dy = (p as dynamic).dy as double;
        if (dx < minX) minX = dx;
        if (dx > maxX) maxX = dx;
        if (dy < minY) minY = dy;
        if (dy > maxY) maxY = dy;
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;

    if (width < canvasWidth * minSizeRatio ||
        height < canvasHeight * minSizeRatio) {
      return const WritingResult(
        score: 25,
        passed: false,
        stars: 0,
        feedback: 'Chữ quá nhỏ! Hãy viết lớn hơn.',
      );
    }

    // Detect obvious scribbles stretching to margins (e.g. lines crossing the screen)
    final coverageX = width / canvasWidth;
    final coverageY = height / canvasHeight;
    final coverage = (coverageX + coverageY) / 2;

    if (coverageX > 0.82 || coverageY > 0.82) {
      return const WritingResult(
        score: 30,
        passed: false,
        stars: 0,
        feedback: 'Hãy viết gói gọn trong ô vuông nhé!',
      );
    }

    // Calculate center of drawing relative to canvas center
    final centerX = minX + width / 2;
    final centerY = minY + height / 2;
    final offsetX = (centerX - canvasWidth / 2).abs() / canvasWidth;
    final offsetY = (centerY - canvasHeight / 2).abs() / canvasHeight;

    // If writing is too off-center (e.g. drawn near the very bottom/top/left/right), penalize heavily
    if (offsetX > 0.25 || offsetY > 0.25) {
      return const WritingResult(
        score: 35,
        passed: false,
        stars: 0,
        feedback: 'Hãy viết ở chính giữa ô vuông nhé!',
      );
    }

    // Shape matching heuristic based on guide coordinates
    double guideMatchRatio = 1.0;
    if (expectedCharacter != null) {
      final guides = StrokeGuideData.getStrokes(expectedCharacter);
      if (guides.isNotEmpty) {
        int matchedGuides = 0;
        final double maxDim = canvasWidth > canvasHeight ? canvasWidth : canvasHeight;
        // Strict threshold: 14% of the canvas size (42 pixels on a 300px canvas)
        final double threshold = maxDim * 0.14;

        for (final g in guides) {
          final double gX = g[1] * canvasWidth;
          final double gY = g[2] * canvasHeight;

          double minDistance = double.infinity;
          for (final s in strokes) {
            for (final p in s) {
              final double dx = (p as dynamic).dx as double;
              final double dy = (p as dynamic).dy as double;
              final double dist = math.sqrt((dx - gX) * (dx - gX) + (dy - gY) * (dy - gY));
              if (dist < minDistance) {
                minDistance = dist;
              }
            }
          }

          if (minDistance <= threshold) {
            matchedGuides++;
          }
        }

        guideMatchRatio = matchedGuides / guides.length;

        // Detect extraneous strokes (strokes drawn away from all guide points)
        int extraneousStrokes = 0;
        final double extraneousThreshold = maxDim * 0.18; // slightly more lenient for identifying active guides
        for (final s in strokes) {
          if (s.isEmpty) continue;
          double closestGuideDist = double.infinity;
          for (final g in guides) {
            final double gX = g[1] * canvasWidth;
            final double gY = g[2] * canvasHeight;
            for (final p in s) {
              final double dx = (p as dynamic).dx as double;
              final double dy = (p as dynamic).dy as double;
              final double dist = math.sqrt((dx - gX) * (dx - gX) + (dy - gY) * (dy - gY));
              if (dist < closestGuideDist) {
                closestGuideDist = dist;
              }
            }
          }
          if (closestGuideDist > extraneousThreshold) {
            extraneousStrokes++;
          }
        }

        // Apply penalty factors for extraneous/excess strokes (scribbles)
        if (extraneousStrokes > 0 || strokes.length > guides.length + 1) {
          final double penaltyFactor = math.max(0.1, 1.0 - (extraneousStrokes * 0.25) - ((strokes.length - guides.length).clamp(0, 5) * 0.12));
          guideMatchRatio *= penaltyFactor;
        }

        // Require a higher match ratio for multiple guide points (strictness)
        final double minRequiredRatio = guides.length <= 2 ? 0.5 : 0.72;

        // If the user missed too many guide points or drew scribbles
        if (guideMatchRatio < minRequiredRatio) {
          final int penalizedScore = (35 * guideMatchRatio).round().clamp(0, 45);
          return WritingResult(
            score: penalizedScore,
            passed: false,
            stars: 0,
            feedback: 'Hãy vẽ nắn nót theo hình mẫu nhé!',
          );
        }
      }
    }

    // Score based on complexity, proportion, and alignment
    int score = 30; // Base score lowered to 30 for strictness

    // Bonus for reasonable number of strokes (max +15)
    // Real letters have 1-4 strokes. Excessive strokes are likely scribbles.
    if (strokes.length <= 4) {
      score += strokes.length * 3;
    } else {
      score += 5; 
    }

    // Bonus for total points (smoothness) (max +15)
    score += (totalPoints ~/ 10).clamp(0, 15);

    // Bonus for balanced coverage ratio (max +15)
    // Best coverage is between 0.3 and 0.68 (well-proportioned character in center)
    if (coverage >= 0.3 && coverage <= 0.68) {
      score += 15;
    } else if (coverage > 0.68 && coverage <= 0.8) {
      score += 8;
    } else {
      score += 2;
    }

    // Bonus for aspect ratio being reasonable (max +15)
    final aspect = width / height;
    if (aspect > 0.55 && aspect < 1.8) {
      score += 15;
    } else if (aspect >= 0.4 && aspect <= 2.2) {
      score += 5;
    }

    // Centering bonus (max +10)
    final distanceToCenter = offsetX + offsetY; // 0.0 is perfect center
    score += ((1.0 - distanceToCenter.clamp(0.0, 1.0)) * 10).round();

    // Apply shape guide multiplier to score
    score = (score * guideMatchRatio).round().clamp(0, 100);
    final passed = score >= 60;
    final stars = _accuracyToStars(score);

    return WritingResult(
      score: score,
      passed: passed,
      stars: stars,
      feedback: passed ? 'Viết rất đẹp!' : 'Hãy viết rõ ràng và nắn nót hơn nhé!',
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

  String _normalizePhonetic(String s) {
    // 1. Chuyển thành chữ thường và xóa khoảng trắng
    var str = s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    
    // 2. Loại bỏ dấu tiếng Việt
    var withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    
    // 3. Giữ lại chữ cái thường và số
    str = str.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // 4. Các từ đồng âm gần âm phổ biến (đặc biệt khi fallback tiếng Việt)
    if (str.startsWith('c')) str = 'k' + str.substring(1);
    if (str.startsWith('q')) str = 'k' + str.substring(1);
    if (str.startsWith('gi')) str = 'd' + str.substring(2);
    if (str.startsWith('v')) str = 'd' + str.substring(1);
    if (str.startsWith('tr')) str = 'ch' + str.substring(2);
    if (str.startsWith('ph')) str = 'f' + str.substring(2);
    
    return str;
  }

  int _accuracyToStars(int accuracy) {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy >= 50) return 1;
    return 0;
  }

  List<HighlightedWord> _buildHighlights(
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
