import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'package:string_similarity/string_similarity.dart';

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
/// Scoring Service — Chấm điểm phát âm & viết chữ Khmer (Stubbed)
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
    'ម': ['mo', 'mor'],          // Loại bỏ: moo, kou, ma, maa

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
    double factor = 0.0;
    try {
      if (Platform.isAndroid) {
        final versionStr = Platform.operatingSystemVersion.toLowerCase();
        if (versionStr.contains('sdk') || versionStr.contains('google') || versionStr.contains('emulator')) {
          factor = 0.10;
        } else {
          factor = 0.08;
        }
      } else if (Platform.isIOS) {
        factor = 0.08;
      }
    } catch (_) {
      factor = 0.08;
    }
    return (rawConfidence + factor).clamp(0.0, 1.0);
  }

  // ─── Pronunciation Scoring ──────────────────────────────────────
  ({PronunciationScoreResult result, String matchedText}) scoreBestAlternate({
    required String targetCharacter,
    required List<String> alternates,
    required double confidence,
    String romanized = '',
    String pronunciation = '',
    List<String> acceptedAnswers = const [],
    int passThreshold = defaultPassThreshold,
  }) {
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
      if (best == null ||
          r.rawScore > best.rawScore ||
          (r.rawScore == best.rawScore && r.passed && !best.passed)) {
        best = r;
        bestText = cand;
      }
      if (r.rawScore >= 100.0) break;
    }
    return (result: best!, matchedText: bestText);
  }

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

    final Set<String> latinForms = {};
    if (acceptedPronunciations.containsKey(targetCharacter)) {
      latinForms.addAll(acceptedPronunciations[targetCharacter]!);
    }
    if (acceptedVowelPronunciations.containsKey(targetCharacter)) {
      latinForms.addAll(acceptedVowelPronunciations[targetCharacter]!);
    }
    for (final extra in [romanized, pronunciation, ...acceptedAnswers]) {
      final n = _normalize(extra);
      if (n.isNotEmpty) latinForms.add(n);
    }

    final Set<String> latinFormsLoose = latinForms.map(_normalizeLatin).toSet()
      ..removeWhere((e) => e.isEmpty);
    final String spokenLoose = _normalizeLatin(recognizedText);

    final calibratedConfidence = calibrateConfidence(confidence);

    double rawScore = 0.0;
    String matchMethod = 'dice';

    if (spokenNorm == targetNorm || recognizedText == targetCharacter) {
      rawScore = 100.0;
      matchMethod = 'exact';
    }
    else if (latinForms.contains(spokenNorm)) {
      rawScore = 90.0;
      matchMethod = 'accepted_pronunciation';
    }
    else if (spokenLoose.isNotEmpty &&
        (latinFormsLoose.contains(spokenLoose) ||
            (spokenLoose.length <= 3 &&
                latinFormsLoose.any((f) => _lenientShortMatch(spokenLoose, f))))) {
      rawScore = 80.0;
      matchMethod = 'lenient';
    }
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
      rawScore = 85.0;
      matchMethod = 'phonetic';
    }
    else {
      double best = StringSimilarity.compareTwoStrings(spokenNorm, targetNorm);
      final recPhonetic = _normalizePhonetic(recognizedText);

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

      if (rawScore < 50.0) {
        rawScore = rawScore * 0.5;
      }
    }

    double weightedScore;
    if (matchMethod == 'dice') {
      weightedScore = math.max(rawScore * 0.85, rawScore * calibratedConfidence);
    } else {
      weightedScore = rawScore;
    }

    final finalWeighted = weightedScore.clamp(0.0, 100.0);
    final passed = finalWeighted >= passThreshold;

    return PronunciationScoreResult(
      rawScore: rawScore,
      weightedScore: finalWeighted,
      passed: passed,
      matchMethod: matchMethod,
    );
  }

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
      confidence: 1.0,
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

  int quickScore(String spoken, String target) {
    final a = _normalize(spoken);
    final b = _normalize(target);
    if (a.isEmpty || b.isEmpty) return 0;

    if (a.contains(b) || b.contains(a)) return 100;

    final score = StringSimilarity.compareTwoStrings(a, b);
    return (score * 100).round().clamp(0, 100);
  }

  // ─── Writing Scoring (Stubbed) ──────────────────────────────────
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
    return const RecognitionResult(
      finalScore: 100.0,
      passed: true,
      shapeScore: 100.0,
      strokeScore: 100.0,
      directionScore: 100.0,
      feedback: 'Viết rất tốt! 🌟',
      tips: ['Chữ viết của bạn rất tốt, hãy tiếp tục phát huy nhé!'],
      stars: 3,
    );
  }

  RecognitionResult recognizeWritingLegacy({
    required String character,
    required List<List<Offset>> strokes,
    required Size canvasSize,
  }) {
    return const RecognitionResult(
      finalScore: 100.0,
      passed: true,
      shapeScore: 100.0,
      strokeScore: 100.0,
      directionScore: 100.0,
      feedback: 'Viết rất tốt! 🌟',
      tips: ['Chữ viết của bạn rất tốt, hãy tiếp tục phát huy nhé!'],
      stars: 3,
    );
  }

  WritingResult scoreWriting({
    required List<List<dynamic>> strokes,
    required double canvasWidth,
    required double canvasHeight,
    int minStrokes = 1,
    int minPoints = 6,
    double minSizeRatio = 0.15,
    String? expectedCharacter,
  }) {
    return const WritingResult(
      score: 100,
      passed: true,
      stars: 3,
      feedback: 'Viết rất đẹp! 🌟',
    );
  }

  WritingResult scoreWritingOcr({
    required String recognized,
    required String expected,
  }) {
    return const WritingResult(
      score: 100,
      passed: true,
      stars: 3,
      feedback: 'Viết rất đẹp! 🌟',
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
    str = str.replaceAll(RegExp(r'[^\u1780-\u17a2]'), '');
    
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

    str = str.replaceAll(RegExp(r'[ơờớợởỡ]'), 'ow');
    str = str.replaceAll(RegExp(r'[ôồốộổỗ]'), 'oh');
    str = str.replaceAll(RegExp(r'[êềếệểễ]'), 'eh');
    str = str.replaceAll(RegExp(r'[ưừứựửữ]'), 'uw');
    str = str.replaceAll(RegExp(r'[âầấậẩẫ]'), 'aw');
    str = str.replaceAll(RegExp(r'[ăằắặẳẵ]'), 'ax');

    var withDiacritics = 'àáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹđ';
    var withoutDiacritics = 'aaaaaeeeeeiiiiiooooouuuuuyyyyyd';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }

    str = str.replaceAll(RegExp(r'[^a-z0-9]'), '');
    str = str.replaceAll('y', 'i');

    if (str.startsWith('c')) str = 'k${str.substring(1)}';
    if (str.startsWith('q')) str = 'k${str.substring(1)}';
    if (str.startsWith('gi')) str = 'd${str.substring(2)}';
    if (str.startsWith('v')) str = 'd${str.substring(1)}';
    if (str.startsWith('tr')) str = 'ch${str.substring(2)}';
    if (str.startsWith('ph')) str = 'f${str.substring(2)}';

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

  bool _isFuzzyMatch(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;

    if ((a.length - b.length).abs() > 1) return false;

    if (a.contains(b) || b.contains(a)) return true;

    return _levenshteinDistance(a, b) <= 1;
  }

  bool _lenientShortMatch(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;
    if ((a.length - b.length).abs() != 1) return false;
    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    final isPrefix = longer.startsWith(shorter);
    final isSuffix = longer.endsWith(shorter);
    if (!isPrefix && !isSuffix) return false;
    final extra = isPrefix ? longer[longer.length - 1] : longer[0];
    final neighbor = isPrefix
        ? longer[longer.length - 2]
        : longer[1];
    if (extra == neighbor) return true;
    if (isPrefix && (extra == 'r' || extra == 'h')) return true;
    return false;
  }

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
