import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'package:string_similarity/string_similarity.dart';
import '../data/stroke_guide_data.dart';
import 'dollar_one_recognizer.dart';
import '../data/khmer_stroke_templates.dart';
import 'handwriting_tracing_service.dart';

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
  static const int defaultPassThreshold = 75; // Tăng từ 70% lên 75% - NGHIÊM NGẶT HƠN

  // ─── Multiple Accepted Pronunciations Map ──────────────────────────
  // CHỈ GIỮ PHÁT ÂM CHUẨN - Loại bỏ các biến thể quá khoan dung
  // Mỗi chữ chỉ có 2-3 cách phát âm được chấp nhận (chuẩn + biến thể gần)
  static const Map<String, List<String>> acceptedPronunciations = {
    // Phụ âm Series 1 (A-series)
    'ក': ['ka', 'ko'],           // Chỉ 2 cách: ka (chuẩn), ko (biến thể)
    'ខ': ['kha', 'kho'],         // Loại bỏ: khor, khaa, khaw, ka, ko
    'គ': ['ko', 'kor'],          // Loại bỏ: koo, kou, go, gor, goo
    'ឃ': ['kho', 'khor'],        // Loại bỏ: khoo, khou, ko, kor
    'ង': ['ngo', 'ngor'],        // Loại bỏ: ngoo, no, nor

    // Phụ âm Series 2 (O-series) - QUAN TRỌNG
    'ច': ['cho', 'chor'],        // Loại bỏ: choo, chou, co, cor, jo, jor
    'ឆ': ['chhor', 'chor'],      // Loại bỏ: chho, cho, choo, chhoo
    'ជ': ['cho', 'chor'],        // Loại bỏ: choo, jo, jor, joo
    'ឈ': ['chhor', 'chor'],      // Loại bỏ: chho, cho, jo
    'ញ': ['nhor', 'nho'],        // Loại bỏ: nhoo, nyo, nyor, no

    // Phụ âm Series 3
    'ដ': ['da', 'do'],           // Loại bỏ: dor, daa, daw, doo, ta, to
    'ឋ': ['tha', 'tho'],         // Loại bỏ: thor, thaa, thaw, thoo, ta, to
    'ឌ': ['do', 'dor'],          // Loại bỏ: doo, dou, to, tor
    'ឍ': ['tho', 'thor'],        // Loại bỏ: thoo, thou, to, tor
    'ណ': ['na', 'no'],           // Loại bỏ: nor, naa, naw, noo

    // Phụ âm Series 4
    'ត': ['ta', 'to'],           // Loại bỏ: tor, taa, taw, too, da, do
    'ថ': ['tha', 'tho'],         // Loại bỏ: thor, thaa, thaw, thoo, ta, to
    'ទ': ['to', 'tor'],          // Loại bỏ: too, tou, do, dor
    'ធ': ['tho', 'thor'],        // Loại bỏ: thoo, thou, to, tor
    'ន': ['no', 'nor'],          // Loại bỏ: noo, nou, na, naa

    // Phụ âm Series 5
    'ប': ['ba', 'bo'],           // Loại bỏ: bor, baa, baw, boo, pa, po
    'ផ': ['pha', 'pho'],         // Loại bỏ: phor, phaa, phaw, phoo, pa, po
    'ព': ['po', 'por'],          // Loại bỏ: poo, pou, bo, bor
    'ភ': ['pho', 'phor'],        // Loại bỏ: phoo, phou, po, por
    'ម': ['mo', 'mor'],          // Loại bỏ: moo, mou, ma, maa

    // Phụ âm Series 6
    'យ': ['yo', 'yor'],          // Loại bỏ: yoo, you, ya, yaa, jo
    'រ': ['ro', 'ror'],          // Loại bỏ: roo, rou, ra, raa, lo
    'ល': ['lo', 'lor'],          // Loại bỏ: loo, lou, la, laa
    'វ': ['vo', 'vor'],          // Loại bỏ: voo, vou, va, vaa, wo, wor

    // Phụ âm Series 7
    'ស': ['sa', 'so'],           // Loại bỏ: sor, saa, saw, soo, sha, sho
    'ហ': ['ha', 'ho'],           // Loại bỏ: hor, haa, haw, hoo
    'ឡ': ['la', 'lo'],           // Loại bỏ: lor, laa, law, loo
    'អ': ['a', 'o'],             // Loại bỏ: or, aa, aw, oo, ou
  };

  // ─── Multiple Accepted Vowel Pronunciations Map ────────────────────
  // Bản đồ phát âm chấp nhận cho 24 nguyên âm Khmer.
  // Mỗi nguyên âm có 3-6 cách đọc hợp lệ: phiên âm Latin, tiếng Việt có dấu,
  // tiếng Việt không dấu, và biến thể STT thường nhận.
  static const Map<String, List<String>> acceptedVowelPronunciations = {
    // ══ Nguyên âm cơ bản ══
    'អា': ['aa', 'a', 'à', 'á', 'ah'],                      // a dài
    'អិ': ['e', 'i', 'ì', 'í', 'ê'],                        // i ngắn
    'អី': ['ei', 'ây', 'ay', 'âi', 'ey'],                   // ây
    'អឹ': ['ə', 'ơ', 'ớ', 'ờ', 'er'],                       // ơ ngắn
    'អឺ': ['əə', 'ơ', 'ớ', 'ờ', 'ơơ', 'er'],               // ơ dài
    'អុ': ['o', 'ô', 'ố', 'ồ', 'u'],                        // ô ngắn
    'អូ': ['oo', 'u', 'ú', 'ù', 'uu'],                      // u dài
    'អួ': ['uə', 'ua', 'uà', 'uá', 'ùa'],                  // ua
    'អើ': ['əə', 'ơ', 'ớ', 'ờ', 'ơi', 'er'],               // ơ
    'អឿ': ['ɨə', 'ưa', 'ừa', 'ứa', 'ưà'],                  // ưa
    'អៀ': ['iə', 'ia', 'ìa', 'ía', 'ie'],                   // ia
    'អេ': ['ee', 'ê', 'ế', 'ề', 'e'],                       // ê
    'អែ': ['ae', 'e', 'è', 'é', 'ê', 'eh'],                 // e
    'អៃ': ['aj', 'ai', 'ài', 'ái', 'ay'],                   // ai
    'អោ': ['ao', 'ao', 'ào', 'áo', 'aw'],                   // ao
    'អៅ': ['aw', 'au', 'àu', 'áu', 'ao'],                   // au
    'អំ': ['ɑm', 'ăm', 'am', 'àm', 'ám', 'um'],             // ăm
    'អុំ': ['om', 'ôm', 'ồm', 'ốm', 'um'],                  // ôm
    'អះ': ['ah', 'ăh', 'ăc', 'ac', 'ak'],                   // ăh
    'អាំ': ['am', 'am', 'àm', 'ám', 'ăm'],                  // am
    'អិះ': ['eh', 'ih', 'ic', 'ik', 'ít'],                   // ih
    'អុះ': ['oh', 'ôh', 'ôc', 'ốc', 'ốt'],                  // ôh
    'អេះ': ['eh', 'êh', 'êt', 'ết', 'ếc'],                  // êh
    'អោះ': ['oah', 'oăh', 'oăc', 'oac', 'oát'],             // oăh
  };

  // ─── Device Matrix Dynamic Calibration ────────────────────────────
  static double calibrateConfidence(double rawConfidence) {
    // GIẢM BOOST - Không nên boost quá nhiều
    double factor = 0.0;
    try {
      if (Platform.isAndroid) {
        final versionStr = Platform.operatingSystemVersion.toLowerCase();
        if (versionStr.contains('sdk') || versionStr.contains('google') || versionStr.contains('emulator')) {
          factor = 0.10; // Giảm từ 0.25 xuống 0.10
        } else {
          factor = 0.08; // Giảm từ 0.18 xuống 0.08
        }
      } else if (Platform.isIOS) {
        factor = 0.08; // Giảm từ 0.15 xuống 0.08
      }
    } catch (_) {
      factor = 0.08; // Giảm từ 0.15 xuống 0.08
    }
    return (rawConfidence + factor).clamp(0.0, 1.0);
  }

  // ─── Pronunciation Scoring ──────────────────────────────────────

  /// Chấm điểm trên NHIỀU bản chép thay thế (alternates) và chọn bản tốt nhất.
  /// Engine STT thường trả bản đoán đầu tiên sai (đặc biệt tiếng Khmer / giọng
  /// trẻ em) nhưng một alternate khác lại đúng — nên ta thử khớp tất cả.
  /// Trả về cặp (kết quả tốt nhất, văn bản đã chọn) để UI hiển thị đúng bản khớp.
  ({PronunciationScoreResult result, String matchedText}) scoreBestAlternate({
    required String targetCharacter,
    required List<String> alternates,
    required double confidence,
    String romanized = '',
    String pronunciation = '',
    List<String> acceptedAnswers = const [],
    int passThreshold = defaultPassThreshold,
  }) {
    // Lọc rỗng & loại trùng, luôn đảm bảo có ít nhất 1 phần tử để chấm
    final candidates = <String>[];
    for (final a in alternates) {
      final t = a.trim();
      if (t.isNotEmpty && !candidates.contains(t)) candidates.add(t);
    }
    if (candidates.isEmpty) candidates.add('');

    PronunciationScoreResult? best;
    String bestText = candidates.first;
    for (final cand in candidates) {
      final r = scorePronunciationSeparated(
        targetCharacter: targetCharacter,
        recognizedText: cand,
        confidence: confidence,
        romanized: romanized,
        pronunciation: pronunciation,
        acceptedAnswers: acceptedAnswers,
        passThreshold: passThreshold,
      );
      // Ưu tiên điểm thô cao hơn; nếu bằng nhau, ưu tiên bản đã pass
      if (best == null ||
          r.rawScore > best.rawScore ||
          (r.rawScore == best.rawScore && r.passed && !best.passed)) {
        best = r;
        bestText = cand;
      }
      // Khớp tuyệt đối thì dừng sớm
      if (r.rawScore >= 100.0) break;
    }
    return (result: best!, matchedText: bestText);
  }

  /// Chấm điểm phát âm biệt lập được thiết kế đặc thù cho việc kiểm thử độc lập (Phase 2).
  PronunciationScoreResult scorePronunciationSeparated({
    required String targetCharacter,
    required String recognizedText,
    required double confidence,
    String romanized = '',
    String pronunciation = '',
    List<String> acceptedAnswers = const [],
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

    // Tập hợp các dạng phát âm Latin được chấp nhận cho chữ cái này:
    //   • Bản đồ phát âm cứng (acceptedPronunciations) cho phụ âm
    //   • Bản đồ phát âm cứng (acceptedVowelPronunciations) cho nguyên âm
    //   • romanized + pronunciation của CHÍNH chữ cái (lấy từ dữ liệu bài học)
    // Nhờ vậy mọi bài (kể cả bài 6 trở đi) đều có mục tiêu so khớp, không còn
    // phụ thuộc vào việc chữ cái có nằm trong bản đồ cứng hay không.
    final Set<String> latinForms = {};
    if (acceptedPronunciations.containsKey(targetCharacter)) {
      latinForms.addAll(acceptedPronunciations[targetCharacter]!);
    }
    // Tự động bổ sung bản đồ nguyên âm khi target là nguyên âm Khmer
    if (acceptedVowelPronunciations.containsKey(targetCharacter)) {
      latinForms.addAll(acceptedVowelPronunciations[targetCharacter]!);
    }
    for (final extra in [romanized, pronunciation, ...acceptedAnswers]) {
      final n = _normalize(extra);
      if (n.isNotEmpty) latinForms.add(n);
    }

    // Phiên bản "bỏ dấu thanh tiếng Việt" của các dạng chấp nhận (à/á/ả/ã/ạ → a...).
    // Dùng cho bước so khớp nương tay: bé đọc "à" vẫn khớp mục tiêu "a".
    final Set<String> latinFormsLoose = latinForms.map(_normalizeLatin).toSet()
      ..removeWhere((e) => e.isEmpty);
    final String spokenLoose = _normalizeLatin(recognizedText);

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
    else if (latinForms.contains(spokenNorm)) {
      rawScore = 90.0; // Giảm từ 95.0 xuống 90.0 - không phải exact match
      matchMethod = 'accepted_pronunciation';
    }
    // 2b. Khớp NƯƠNG TAY (hợp trẻ em): bỏ dấu thanh tiếng Việt, hoặc lệch nhẹ phần
    //     đuôi với ÂM NGẮN (≤3 ký tự). KHÔNG cho thay ký tự (a↔e, ka↔ta) để tránh
    //     nhận nhầm nguyên âm/phụ âm khác — chỉ chấp nhận thêm/bớt ký tự ở đuôi (a↔aa).
    else if (spokenLoose.isNotEmpty &&
        (latinFormsLoose.contains(spokenLoose) ||
            (spokenLoose.length <= 3 &&
                latinFormsLoose.any((f) => _lenientShortMatch(spokenLoose, f))))) {
      rawScore = 80.0;
      matchMethod = 'lenient';
    }
    // 3. Đối sánh âm vị học đã chuẩn hóa (Phonetic Matching)
    else if (() {
      final normRec = _normalizePhonetic(recognizedText);
      if (normRec.isEmpty) return false;

      final normTarget = _normalizePhonetic(targetCharacter);
      if (normTarget.isNotEmpty && normRec == normTarget) return true;

      if (latinForms.any((p) {
        final normP = _normalizePhonetic(p);
        return normP.isNotEmpty && normRec == normP;
      })) {
        return true;
      }

      return false;
    }()) {
      rawScore = 85.0; // Giảm từ 90.0 xuống 85.0
      matchMethod = 'phonetic';
    }
    // 4. Đo lường tỷ lệ tương đồng Dice Coefficient
    else {
      double best = StringSimilarity.compareTwoStrings(spokenNorm, targetNorm);
      final recPhonetic = _normalizePhonetic(recognizedText);

      // So sánh với tất cả các dạng phát âm được chấp nhận
      for (final p in latinForms) {
        best = math.max(best, StringSimilarity.compareTwoStrings(spokenNorm, p));
        if (recPhonetic.isNotEmpty) {
          final pPhon = _normalizePhonetic(p);
          if (pPhon.isNotEmpty) {
            best = math.max(
                best, StringSimilarity.compareTwoStrings(recPhonetic, pPhon));
          }
        }
      }

      rawScore = best * 100.0;
      matchMethod = 'dice';

      // THÊM: Nếu Dice score quá thấp (<50%), coi như sai hoàn toàn
      if (rawScore < 50.0) {
        rawScore = rawScore * 0.5; // Penalty nặng cho điểm thấp
      }
    }

    // Tính điểm Weighted (Confidence Weighting).
    // QUAN TRỌNG: khi đã KHỚP VĂN BẢN rõ ràng (exact/accepted/phonetic/lenient) thì
    // chính nội dung nhận diện là bằng chứng — KHÔNG hạ điểm theo confidence của máy,
    // vì rất nhiều thiết bị Android trả confidence = 0 dù nghe đúng. Việc chống nhận
    // bừa dựa vào CHẤT LƯỢNG so khớp (đã siết), không dựa vào confidence.
    // Chỉ khớp mờ (dice) mới chịu trọng số confidence.
    double weightedScore;
    if (matchMethod == 'dice') {
      // Khớp mờ: cân theo confidence nhưng vẫn nương tay tối thiểu 85% điểm thô
      weightedScore = math.max(rawScore * 0.85, rawScore * calibratedConfidence);
    } else {
      // Khớp văn bản dứt khoát: tin nội dung, giữ nguyên điểm thô
      weightedScore = rawScore;
    }

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
      romanized: romanized,
      pronunciation: pronunciation,
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

  /// Chấm điểm viết chữ dựa trên template tracing (pixel coverage).
  /// Scoring dựa trên độ phủ giữa nét viết và nét mẫu.
  /// KHÔNG sử dụng OCR hay shape recognition.
  RecognitionResult recognizeWriting({
    required String character,
    required List<List<Offset>> strokes,
    required Size canvasSize,
    int? minPointsOverride,
    int? minStrokesOverride,
    double? passThresholdOverride,
    double? outsideThresholdOverride,
    double? toleranceRadiusOverride,
  }) {
    // Sử dụng HandwritingTracingService mới
    final tracingResult = HandwritingTracingService.instance.scoreTracing(
      character: character,
      userStrokes: strokes,
      canvasSize: canvasSize,
      minPointsOverride: minPointsOverride,
      minStrokesOverride: minStrokesOverride,
      passThresholdOverride: passThresholdOverride,
      outsideThresholdOverride: outsideThresholdOverride,
      toleranceRadiusOverride: toleranceRadiusOverride,
    );

    // Chuyển đổi TracingScoreResult sang RecognitionResult để tương thích
    return RecognitionResult(
      finalScore: tracingResult.finalScore,
      passed: tracingResult.passed,
      shapeScore: tracingResult.insideCoverage,
      strokeScore: 100.0 - tracingResult.outsideCoverage,
      directionScore: tracingResult.insideCoverage > tracingResult.outsideCoverage ? 100.0 : 0.0,
      feedback: tracingResult.feedback,
      tips: tracingResult.tips,
      stars: tracingResult.stars,
    );
  }

  /// Chấm điểm viết chữ dựa trên stroke analysis + shape guide coordinates (LEGACY).
  /// Kiểm tra: số nét, kích thước, tỉ lệ, coverage và độ khớp hình dáng chữ mẫu.
  /// Nhận diện chữ viết tay sử dụng thuật toán $1 Unistroke Recognizer kết hợp
  /// Phân tích nét viết (Stroke Analysis), Hướng nét viết (Stroke Direction), và Grid Bitmap 16x16.
  RecognitionResult recognizeWritingLegacy({
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

    // 3. Anti-Scribble / Anti-Cheat Detection (CHỈ PHÁT HIỆN VẼ BẬY RÕ RÀNG)
    bool isScribble = false;
    List<String> cheatFeedback = [];

    // Chỉ phát hiện số nét QUÁ NHIỀU (> 10 nét)
    if (strokes.length > 10) {
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

    // Chỉ phát hiện tô KÍN màn hình (> 70%)
    if (occupancyRatio > 0.70) {
      isScribble = true;
      cheatFeedback.add('Hình vẽ tô kín cả màn hình.');
    }

    // KHÔNG kiểm tra nét ngắn nữa - gây false positive

    // KHÔNG kiểm tra vẽ sọc nữa - gây false positive

    // KHÔNG kiểm tra độ dài nữa - gây false positive

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

    // Kiểm tra IoU quá thấp = viết bậy
    if (iou < 0.12) { // Giảm từ 0.15 xuống 0.12
      return RecognitionResult(
        finalScore: (iou * 100).roundToDouble().clamp(0, 30),
        passed: false,
        shapeScore: iou * 100,
        strokeScore: 20,
        directionScore: 10,
        feedback: 'Hình vẽ không giống chữ cái. Hãy viết theo mẫu nhé! ✍️',
        tips: [
          'Nhìn kỹ chữ mẫu màu xanh.',
          'Vẽ chậm rãi và cẩn thận.',
          'Tham khảo gợi ý để biết cách viết đúng.',
        ],
        stars: 0,
      );
    }

    // Map IoU using a balanced curve (KHOAN DUNG HƠN cho trẻ em):
    // - Under 0.20 (garbage drawings): penalized to cap shapeScore below 35%.
    // - 0.20 to 0.50 (valid drawings): scaled smoothly from 35% to 100%.
    double gridShapeScore = 0.0;
    if (iou < 0.20) {
      gridShapeScore = (iou / 0.20) * 35.0;
    } else {
      gridShapeScore = 35.0 + ((iou - 0.20) / (0.50 - 0.20)) * 65.0;
    }
    gridShapeScore = gridShapeScore.clamp(0.0, 100.0);

    // Combine shape scores: TĂNG trọng số Dollar One để nhạy hơn với hình dạng nét
    // - dollarOneShapeScore: 60% - nhạy với hình dạng, thứ tự nét, hướng vẽ (QUAN TRỌNG)
    // - gridShapeScore (IoU): 40% - đo độ phủ tổng thể
    double shapeScore = (dollarOneShapeScore * 0.6) + (gridShapeScore * 0.4);
    shapeScore = shapeScore.clamp(0.0, 100.0);

    // Kiểm tra Dollar One quá thấp = hình dạng nét hoàn toàn sai
    if (dollarOneShapeScore < 20.0) { // Giảm từ 30% xuống 20%
      return RecognitionResult(
        finalScore: (shapeScore * 0.9).roundToDouble().clamp(0, 35),
        passed: false,
        shapeScore: shapeScore,
        strokeScore: 25,
        directionScore: 15,
        feedback: 'Hình dạng nét vẽ không giống chữ mẫu. Hãy vẽ theo đúng hình! ✍️',
        tips: [
          'Quan sát kỹ hình dạng từng nét trong chữ mẫu.',
          'Vẽ chậm rãi, theo đúng hướng mũi tên.',
          'Tránh vẽ sọc thẳng đơn giản.',
        ],
        stars: 0,
      );
    }

    // Fail early only if shape is completely unrelated (less than 35% boosted shapeScore)
    if (shapeScore < 35.0) {
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

    // 5. Stroke Analysis (15% weight - giảm từ 25%)
    double strokeCountScore = 100.0;
    final guides = StrokeGuideData.getStrokes(character);
    if (guides.isNotEmpty) {
      int expectedCount = guides.length;
      int actualCount = strokes.length;
      int diff = (actualCount - expectedCount).abs();
      if (diff == 0) {
        strokeCountScore = 100.0;
      } else if (diff == 1) {
        strokeCountScore = 90.0; // Rất khoan dung (tăng từ 80.0)
      } else if (diff == 2) {
        strokeCountScore = 75.0; // Rất khoan dung (tăng từ 60.0)
      } else if (diff == 3) {
        strokeCountScore = 60.0; // Thêm mức mới
      } else {
        strokeCountScore = 50.0; // Khoan dung (tăng từ 40.0)
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
          if (angleDiff < (60.0 * math.pi / 180.0)) { // Rất khoan dung (tăng từ 45°)
            dirS = 100.0;
          } else if (angleDiff < (120.0 * math.pi / 180.0)) { // Rất khoan dung (tăng từ 90°)
            dirS = 80.0; // Khoan dung (tăng từ 70.0)
            badDirectionIndices.add(i);
          } else {
            dirS = 60.0; // Khoan dung (tăng từ 40.0)
            badDirectionIndices.add(i);
          }
          totalDirScore += dirS;
        } else {
          totalDirScore += 70.0; // Khoan dung (tăng từ 50.0)
        }
      }

      if (strokes.length != guides.length) {
        int diff = (strokes.length - guides.length).abs();
        totalDirScore = (totalDirScore / math.max(strokes.length, guides.length)) * (1.0 - (diff * 0.05)).clamp(0.5, 1.0) * 100.0; // Giảm penalty (từ 0.08 xuống 0.05, từ 0.3 lên 0.5)
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

    // 8. Compute final weighted score (tăng trọng số shape, giảm stroke và direction)
    double finalScore = shapeScore * 0.75 + strokeScore * 0.15 + directionScore * 0.10;
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

    // Encouraging passing criteria: 50% or above passes for kids (giảm từ 58%)
    bool passed = roundedFinal >= 50;
    int stars = 0;
    if (roundedFinal >= 80) {
      stars = 3;
    } else if (roundedFinal >= 65) {
      stars = 2;
    } else if (roundedFinal >= 50) {
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

    // Loại '◌' (DOTTED CIRCLE) khỏi chữ mẫu — đây là dấu hướng dẫn vị trí dấu
    // phụ thuộc trong nguyên âm Khmer, KHÔNG phải ký tự OCR cần nhận diện.
    final expectedStripped = expected.replaceAll('◌', '').trim();
    final expectedClean = expectedStripped.isEmpty ? expected : expectedStripped;

    final accuracy = quickScore(recognized, expectedClean);
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

    // ═══ BƯỚC 1: Bảo tồn nguyên âm tiếng Việt quan trọng TRƯỚC khi xóa dấu ═══
    // Các nguyên âm đặc biệt phải được mã hóa riêng để không bị gộp nhầm:
    //   ơ/ớ/ờ/ợ/ở/ỡ → "ow"  (phân biệt với "o")
    //   ô/ố/ồ/ộ/ổ/ỗ → "oh"  (phân biệt với "o")
    //   ê/ế/ề/ệ/ể/ễ → "eh"  (phân biệt với "e")
    //   ư/ứ/ừ/ự/ử/ữ → "uw"  (phân biệt với "u")
    //   â/ấ/ầ/ậ/ẩ/ẫ → "aw"  (phân biệt với "a")
    //   ă/ắ/ằ/ặ/ẳ/ẵ → "ax"  (phân biệt với "a")
    str = str.replaceAll(RegExp(r'[ơờớợởỡ]'), 'ow');
    str = str.replaceAll(RegExp(r'[ôồốộổỗ]'), 'oh');
    str = str.replaceAll(RegExp(r'[êềếệểễ]'), 'eh');
    str = str.replaceAll(RegExp(r'[ưừứựửữ]'), 'uw');
    str = str.replaceAll(RegExp(r'[âầấậẩẫ]'), 'aw');
    str = str.replaceAll(RegExp(r'[ăằắặẳẵ]'), 'ax');

    // ═══ BƯỚC 2: Xóa dấu thanh cho các nguyên âm ĐƠN còn lại ═══
    var withDiacritics = 'àáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹđ';
    var withoutDiacritics = 'aaaaaeeeeeiiiiiooooouuuuuyyyyyd';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }

    // Giữ lại chữ cái thường và số
    str = str.replaceAll(RegExp(r'[^a-z0-9]'), '');

    // y ≡ i: trong tiếng Việt, 'y' và 'i' phát âm GIỐNG NHAU (vd "mỹ"/"mĩ",
    // "kỹ"/"kĩ"). STT Google thường viết âm "i" thành "y" với dấu thanh (ý, ỳ,
    // ỹ). Sau khi xoá dấu, gộp 'y' → 'i' để khớp đúng các target nguyên âm
    // như 'i', 'ii', 'ei'.
    str = str.replaceAll('y', 'i');

    // Các từ đồng âm gần âm phổ biến (đặc biệt khi fallback tiếng Việt)
    if (str.startsWith('c')) str = 'k${str.substring(1)}';
    if (str.startsWith('q')) str = 'k${str.substring(1)}';
    if (str.startsWith('gi')) str = 'd${str.substring(2)}';
    if (str.startsWith('v')) str = 'd${str.substring(1)}';
    if (str.startsWith('tr')) str = 'ch${str.substring(2)}';
    if (str.startsWith('ph')) str = 'f${str.substring(2)}';

    // Chuẩn hóa các phụ âm kép
    str = str.replaceAll('kh', 'k');
    str = str.replaceAll('ch', 'j');
    str = str.replaceAll('th', 't');
    str = str.replaceAll('ng', 'n');
    str = str.replaceAll('nh', 'n');

    return str;
  }

  String _normalizePhonetic(String s) {
    if (_isKhmerText(s)) {
      return _normalizeKhmer(s);
    } else {
      return _normalizeLatin(s);
    }
  }

  /// Fuzzy matching: cho phép sai lệch 1 ký tự (thêm, bớt, hoặc thay thế)
  /// Ví dụ: "ko" khớp với "koh", "kor", "k", "koo"
  bool _isFuzzyMatch(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;

    // Độ dài chênh lệch quá nhiều thì không khớp
    if ((a.length - b.length).abs() > 1) return false;

    // Kiểm tra nếu một chuỗi là substring của chuỗi kia
    if (a.contains(b) || b.contains(a)) return true;

    // Kiểm tra Levenshtein distance = 1
    return _levenshteinDistance(a, b) <= 1;
  }

  /// Khớp nương tay cho âm NGẮN: chấp nhận giống hệt, hoặc lệch đúng 1 ký tự thừa ở
  /// ĐẦU/ĐUÔI NHƯNG ký tự thừa đó phải là:
  ///   • kéo dài nguyên âm (trùng ký tự liền kề): "a"↔"aa", "ka"↔"kaa", hoặc
  ///   • đuôi "r"/"h" (hay gặp trong phiên âm Khmer / STT tự thêm): "ko"↔"kor".
  /// KHÔNG chấp nhận thêm ký tự KHÁC (a↔ae, ka↔kae) để tránh nhận nhầm âm khác.
  bool _lenientShortMatch(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;
    if ((a.length - b.length).abs() != 1) return false;
    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    final isPrefix = longer.startsWith(shorter);
    final isSuffix = longer.endsWith(shorter);
    if (!isPrefix && !isSuffix) return false;
    // Ký tự thừa: ở cuối nếu shorter là tiền tố; ở đầu nếu shorter là hậu tố.
    final extra = isPrefix ? longer[longer.length - 1] : longer[0];
    final neighbor = isPrefix
        ? longer[longer.length - 2]
        : longer[1];
    if (extra == neighbor) return true; // kéo dài nguyên âm (aa, kaa)
    if (isPrefix && (extra == 'r' || extra == 'h')) return true; // đuôi r/h
    return false;
  }

  /// Tính khoảng cách Levenshtein (edit distance)
  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List.filled(b.length + 1, 0);
    List<int> v1 = List.filled(b.length + 1, 0);

    for (int i = 0; i <= b.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          math.min(v1[j] + 1, v0[j + 1] + 1),
          v0[j] + cost,
        );
      }

      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[b.length];
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
