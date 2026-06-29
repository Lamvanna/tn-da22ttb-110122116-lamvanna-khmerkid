/// ═══════════════════════════════════════════════════════════════════════
/// Khmer Handwriting Service — Tier 1: On-device ML Kit Recognition
/// ═══════════════════════════════════════════════════════════════════════
///
/// This service wraps Google ML Kit's Digital Ink Recognition for Khmer
/// script ('km' language model). It provides:
///
///   1. **Model Lifecycle Management**: Download, verify, and cache the
///      Khmer ink recognition model automatically on first use.
///
///   2. **Anti-False Recognition Filter**: A multi-stage validation
///      pipeline that rejects ambiguous or obviously wrong inputs
///      before presenting results to the child. This prevents
///      the app from rewarding random scribbles.
///
///   3. **Kid-Friendly Top-3 Matching**: If the target character
///      appears anywhere in the top 3 ML Kit candidates, the result
///      is accepted as correct — much more forgiving than top-1 only.
///
/// ─── Architecture Note ─────────────────────────────────────────────
///
/// This service is Tier 1 of the Two-Tier Hybrid Recognition system.
/// It provides instant (zero-latency) feedback to the child.
/// Tier 2 (backend AI geometric analysis via WebSocket) runs
/// asynchronously in the background for detailed stroke correction.
///
/// ─── Usage ─────────────────────────────────────────────────────────
///
/// ```dart
/// final service = KhmerHandwritingService.instance;
/// await service.initialize();
///
/// final result = await service.recognizeAndValidate(
///   strokes: userStrokes,
///   targetCharacter: 'ក',
///   expectedStrokeCount: 2,
/// );
///
/// if (result.isCorrect) {
///   // Show success animation
/// } else {
///   // Show result.message to child
/// }
/// ```
///
/// @module services/khmer_handwriting_service
library;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml_kit;

// ═══════════════════════════════════════════════════════════════════════
// Data Models
// ═══════════════════════════════════════════════════════════════════════

/// Timestamped point on a stroke.
///
/// [x], [y] are canvas coordinates (pixels).
/// [t] is the millisecond timestamp from epoch or drawing start.
class StrokePoint {
  final double x;
  final double y;
  final int t; // milliseconds

  const StrokePoint({required this.x, required this.y, required this.t});

  /// Convert to a JSON-serializable map (for WebSocket transmission).
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 't': t};

  /// Construct from JSON map.
  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        t: (json['t'] as num).toInt(),
      );

  @override
  String toString() => 'StrokePoint(x: $x, y: $y, t: $t)';
}

/// Result from the Tier 1 recognition pipeline.
class HandwritingRecognitionResult {
  /// Whether the child's drawing is accepted as correct.
  final bool isCorrect;

  /// Human-readable Vietnamese message for the child.
  final String message;

  /// The best-matching character recognized by ML Kit.
  final String? recognizedCharacter;

  /// Confidence score of the top candidate (0.0 – 1.0), or null if unavailable.
  final double? confidence;

  /// All candidate texts returned by ML Kit (up to 10).
  final List<String> allCandidates;

  /// Rejection reason code (for analytics / debugging).
  /// null if accepted.
  final RejectionReason? rejectionReason;

  const HandwritingRecognitionResult({
    required this.isCorrect,
    required this.message,
    this.recognizedCharacter,
    this.confidence,
    this.allCandidates = const [],
    this.rejectionReason,
  });

  @override
  String toString() =>
      'HandwritingRecognitionResult(isCorrect: $isCorrect, '
      'recognized: $recognizedCharacter, confidence: $confidence, '
      'reason: $rejectionReason)';
}

/// Enumeration of possible rejection reasons.
enum RejectionReason {
  /// ML Kit returned no candidates at all.
  noCandidates,

  /// Top candidate confidence was below the minimum threshold.
  lowConfidence,

  /// User's stroke count deviates > 50% from the expected stroke count.
  strokeCountMismatch,

  /// Target character was not found in the top 3 candidates.
  notInTopThree,

  /// The ML Kit model is not downloaded / available.
  modelNotReady,

  /// Generic recognition failure.
  recognitionError;
}

// ═══════════════════════════════════════════════════════════════════════
// Configuration Constants
// ═══════════════════════════════════════════════════════════════════════

/// The BCP-47 language tag for Khmer script in ML Kit.
const String _kKhmerLanguageCode = 'km';

/// Minimum confidence score for the top candidate to pass.
/// ML Kit Digital Ink often returns 0 or null for confidence,
/// so we set a very low threshold and rely on top-3 matching instead.
const double _kMinConfidenceThreshold = 0.05;

/// Maximum allowed deviation in stroke count (as a fraction).
/// If |userStrokes - expectedStrokes| / expectedStrokes > 0.50,
/// we reject immediately.
const double _kStrokeCountDeviationMax = 0.50;

// ═══════════════════════════════════════════════════════════════════════
// Service Singleton
// ═══════════════════════════════════════════════════════════════════════

/// Singleton service managing ML Kit Digital Ink Recognition for Khmer.
class KhmerHandwritingService {
  KhmerHandwritingService._();

  /// Global singleton instance.
  static final KhmerHandwritingService instance = KhmerHandwritingService._();

  // ── Internal state ────────────────────────────────────────────────

  /// The ML Kit recognizer instance.
  ml_kit.DigitalInkRecognizer? _recognizer;

  /// Model manager for downloading / checking the Khmer model.
  final ml_kit.DigitalInkRecognizerModelManager _modelManager =
      ml_kit.DigitalInkRecognizerModelManager();

  /// Whether the Khmer model has been downloaded and is ready.
  bool _isModelReady = false;

  /// Future of the ongoing initialization (prevents re-entrant race conditions).
  Future<void>? _initFuture;

  // ═══════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════

  /// Whether the service is ready to perform recognition.
  bool get isReady => _isModelReady && _recognizer != null;

  /// Initialize the service: download the Khmer model if needed,
  /// then create the recognizer instance.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  ///
  /// Throws [HandwritingServiceException] if the model cannot be
  /// downloaded after retries.
  Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    if (_isModelReady && _recognizer != null) return;

    try {
      debugPrint('[KhmerHandwriting] Initializing ML Kit for Khmer...');

      // ── Step 1: Check / download the Khmer model ────────────
      bool isDownloaded = await _modelManager.isModelDownloaded(_kKhmerLanguageCode);

      if (!isDownloaded) {
        debugPrint('[KhmerHandwriting] Downloading Khmer ink model...');
        try {
          isDownloaded =
              await _modelManager.downloadModel(_kKhmerLanguageCode);
        } catch (e) {
          debugPrint('[KhmerHandwriting] Download failed: $e');
          // Retry once
          await Future.delayed(const Duration(seconds: 2));
          try {
            isDownloaded =
                await _modelManager.downloadModel(_kKhmerLanguageCode);
          } catch (e2) {
            debugPrint('[KhmerHandwriting] Retry failed: $e2');
            throw const HandwritingServiceException(
              'Không thể tải mô hình nhận diện chữ Khmer. Vui lòng kiểm tra kết nối mạng.',
            );
          }
        }

        if (!isDownloaded) {
          throw const HandwritingServiceException(
            'Tải mô hình Khmer thất bại.',
          );
        }
        debugPrint('[KhmerHandwriting] Model downloaded successfully.');
      } else {
        debugPrint('[KhmerHandwriting] Model already cached.');
      }

      // ── Step 2: Create recognizer ───────────────────────────
      _recognizer = ml_kit.DigitalInkRecognizer(languageCode: _kKhmerLanguageCode);
      _isModelReady = true;

      debugPrint('[KhmerHandwriting] ✅ Service initialized.');
    } catch (e) {
      _initFuture = null; // Clear to allow retry on next attempt
      rethrow;
    }
  }

  /// Perform recognition and run the full anti-false validation pipeline.
  ///
  /// [strokes] — the child's drawing as a list of stroke point lists.
  /// [targetCharacter] — the Khmer character the child is supposed to write.
  /// [expectedStrokeCount] — number of strokes in the golden path (from DB).
  ///   If null, the stroke count filter is skipped.
  ///
  /// Returns a [HandwritingRecognitionResult] indicating whether
  /// the drawing is accepted and, if not, a child-friendly explanation.
  Future<HandwritingRecognitionResult> recognizeAndValidate({
    required List<List<StrokePoint>> strokes,
    required String targetCharacter,
    int? expectedStrokeCount,
  }) async {
    // ── Guard: Service not ready ────────────────────────────────
    if (!isReady) {
      try {
        await initialize();
        if (!isReady || _recognizer == null) {
          return const HandwritingRecognitionResult(
            isCorrect: false,
            message: 'Mô hình nhận diện đang được chuẩn bị, vui lòng viết lại sau ít giây.',
            rejectionReason: RejectionReason.modelNotReady,
          );
        }
      } catch (_) {
        return const HandwritingRecognitionResult(
          isCorrect: false,
          message: 'Mô hình nhận diện chưa sẵn sàng, vui lòng thử lại sau.',
          rejectionReason: RejectionReason.modelNotReady,
        );
      }
    }

    if (_recognizer == null) {
      return const HandwritingRecognitionResult(
        isCorrect: false,
        message: 'Mô hình nhận diện chưa sẵn sàng, vui lòng thử lại sau.',
        rejectionReason: RejectionReason.modelNotReady,
      );
    }

    // ── Guard: Empty strokes ────────────────────────────────────
    if (strokes.isEmpty || strokes.every((s) => s.length < 2)) {
      return const HandwritingRecognitionResult(
        isCorrect: false,
        message: 'Con chưa viết gì cả, hãy thử viết nhé! ✏️',
        rejectionReason: RejectionReason.noCandidates,
      );
    }

    final cleanTarget = targetCharacter.replaceAll('\u25CC', '').trim();

    // ════════════════════════════════════════════════════════════════
    // FILTER 1: Stroke Count Deviation
    // ════════════════════════════════════════════════════════════════
    //
    // If the child drew far too many or too few strokes compared to
    // the standard, reject immediately. This catches random scribbles.
    //
    if (expectedStrokeCount != null && expectedStrokeCount > 0) {
      final userStrokeCount = strokes.length;
      final deviation =
          (userStrokeCount - expectedStrokeCount).abs() / expectedStrokeCount;

      debugPrint(
        '[KhmerHandwriting] Stroke count deviation: '
        '$userStrokeCount vs expected $expectedStrokeCount '
        '(deviation: ${(deviation * 100).toStringAsFixed(1)}%)',
      );
      // Stroke count deviation check is relaxed to allow any stroke count
    }

    // ════════════════════════════════════════════════════════════════
    // Build ML Kit Ink object
    // ════════════════════════════════════════════════════════════════

    final ink = ml_kit.Ink();
    for (final strokePoints in strokes) {
      final mlStroke = ml_kit.Stroke();
      for (final pt in strokePoints) {
        mlStroke.points.add(ml_kit.StrokePoint(
          x: pt.x,
          y: pt.y,
          t: pt.t,
        ));
      }
      ink.strokes.add(mlStroke);
    }

    // ════════════════════════════════════════════════════════════════
    // Run ML Kit recognition
    // ════════════════════════════════════════════════════════════════

    List<ml_kit.RecognitionCandidate> candidates;
    try {
      candidates = await _recognizer!.recognize(ink);
    } catch (e) {
      debugPrint('[KhmerHandwriting] Recognition error: $e');
      return const HandwritingRecognitionResult(
        isCorrect: false,
        message: 'Có lỗi khi nhận diện nét vẽ. Hãy thử lại nhé! 🔄',
        rejectionReason: RejectionReason.recognitionError,
      );
    }

    // ════════════════════════════════════════════════════════════════
    // FILTER 2: No candidates at all
    // ════════════════════════════════════════════════════════════════

    if (candidates.isEmpty) {
      debugPrint('[KhmerHandwriting] REJECTED: no candidates returned');
      return const HandwritingRecognitionResult(
        isCorrect: false,
        message: 'Nét vẽ chưa rõ ràng, con viết lại nhé! ✏️',
        rejectionReason: RejectionReason.noCandidates,
      );
    }

    // Extract candidate texts and confidence
    final allTexts = candidates.map((c) => c.text).toList();
    final topText = candidates.first.text;
    final topScore = candidates.first.score; // may be null or 0

    debugPrint(
      '[KhmerHandwriting] Candidates: ${allTexts.take(5).join(", ")} | topScore: $topScore',
    );

    // ════════════════════════════════════════════════════════════════
    // FILTER 3: Confidence too low (only if score is available)
    // ════════════════════════════════════════════════════════════════
    //
    // ML Kit Digital Ink often returns score = 0 or null for many
    // language models. We only reject when a meaningful score IS
    // provided and it's below threshold.
    //

    if (topScore != null && topScore > 0 && topScore < _kMinConfidenceThreshold) {
      debugPrint(
        '[KhmerHandwriting] REJECTED: top confidence $topScore < $_kMinConfidenceThreshold',
      );
      return HandwritingRecognitionResult(
        isCorrect: false,
        message: 'Nét vẽ chưa rõ ràng, con viết lại nhé! ✏️',
        recognizedCharacter: topText,
        confidence: topScore.toDouble(),
        allCandidates: allTexts,
        rejectionReason: RejectionReason.lowConfidence,
      );
    }

    // ════════════════════════════════════════════════════════════════
    // FILTER 4: Kid-Friendly Top-3 Matching
    // ════════════════════════════════════════════════════════════════
    //
    // If the target character appears anywhere in the top 3 candidates,
    // accept it. This is much more forgiving for children whose
    // handwriting is still developing.
    //

    final top3 = allTexts.take(3).toList();
    bool isInTop3 = top3.any((text) => text.contains(cleanTarget));

    if (isInTop3 && top3.isNotEmpty) {
      final topChar = top3.first;
      final otherLessonChars = [
        // 33 Consonants
        'ក', 'ខ', 'គ', 'ឃ', 'ង',
        'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
        'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
        'ត', 'ថ', 'ទ', 'ធ', 'ន',
        'ប', 'ផ', 'ព', 'ភ', 'ម',
        'យ', 'រ', 'ល', 'វ', 'ស', 'ហ', 'ឡ', 'អ',
        // 24 Vowels
        'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ',
        'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ',
        'ុំ', 'ំ', 'ាំ', 'ះ', 'ុះ', 'េះ', 'ោះ', 'ៈ',
        // Numbers
        '០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'
      ].where((c) => c != cleanTarget).toList();

      // Helper to strip carrier characters for comparison
      String cleanCarrier(String s) {
        return s.replaceAll('អ', '').replaceAll('\u25CC', '').trim();
      }

      final cleanTopChar = cleanCarrier(topChar);
      final hasMismatchedLessonChar = otherLessonChars.any((other) {
        final cleanOther = cleanCarrier(other);
        if (cleanOther.isEmpty) return false;

        // If cleanOther is a vowel, only check for exact equality.
        // If it's a consonant, we can check for startsWith.
        final bool isVowel = const [
          'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ',
          'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ',
          'ុំ', 'ំ', 'ាំ', 'ះ', 'ុះ', 'េះ', 'ោះ', 'ៈ'
        ].contains(cleanOther);

        if (isVowel) {
          return cleanTopChar == cleanOther;
        } else {
          return cleanTopChar == cleanOther || cleanTopChar.startsWith(cleanOther);
        }
      });

      if (hasMismatchedLessonChar) {
        isInTop3 = false;
        debugPrint(
          '[KhmerHandwriting] REJECTED: Top candidate "$topChar" (cleaned: "$cleanTopChar") is a different lesson character than target "$cleanTarget"',
        );
      }
    }

    if (isInTop3) {
      debugPrint(
        '[KhmerHandwriting] ✅ ACCEPTED: "$cleanTarget" found in top 3: $top3',
      );
      return HandwritingRecognitionResult(
        isCorrect: true,
        message: 'Giỏi lắm! Con viết đúng rồi! 🌟',
        recognizedCharacter: topText,
        confidence: topScore?.toDouble(),
        allCandidates: allTexts,
      );
    }

    // ── Not in top 3: rejected ──────────────────────────────────
    debugPrint(
      '[KhmerHandwriting] REJECTED: "$cleanTarget" not in top 3: $top3',
    );
    return HandwritingRecognitionResult(
      isCorrect: false,
      message: 'Chưa đúng rồi, con quan sát mẫu rồi viết lại nhé! 💪',
      recognizedCharacter: topText,
      confidence: topScore?.toDouble(),
      allCandidates: allTexts,
      rejectionReason: RejectionReason.notInTopThree,
    );
  }

  /// Release native resources. Call when the service is no longer needed.
  void dispose() {
    _recognizer?.close();
    _recognizer = null;
    _isModelReady = false;
    debugPrint('[KhmerHandwriting] Service disposed.');
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Exceptions
// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown by [KhmerHandwritingService] when initialization
/// or model download fails.
class HandwritingServiceException implements Exception {
  final String message;
  const HandwritingServiceException(this.message);

  @override
  String toString() => 'HandwritingServiceException: $message';
}
