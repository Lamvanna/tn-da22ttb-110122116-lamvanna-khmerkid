import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'audio_preprocessing_service.dart';

/// ════════════════════════════════════════════════════════════════════
/// Speech Service — Singleton quản lý Speech-to-Text
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Auto-detect locale: vi-VN (ưu tiên) → km-KH (fallback)
///   • partialResults: true (realtime transcript)
///   • listenFor: 7 giây
///   • pauseFor: 3 giây
///   • Permission handling tự động
///   • Clean error handling
///   • Sử dụng vi-VN để tăng độ chính xác với người Việt học Khmer
/// ════════════════════════════════════════════════════════════════════

enum SpeechPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

class SpeechService {
  SpeechService._();
  static SpeechService? _instance;
  static SpeechService get instance {
    _instance ??= SpeechService._();
    return _instance!;
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPreprocessingService _audioPreprocessing = AudioPreprocessingService.instance;
  bool _initialized = false;
  bool _isListening = false;
  String _selectedLocaleId = 'vi-VN'; // Ưu tiên tiếng Việt cho độ chính xác cao hơn
  String? _fallbackLocaleId; // Locale hệ thống dùng khi máy không có gói Việt
  bool _khmerAvailable = false;
  DateTime? _startTime;
  AudioAnalysisResult? _lastAudioAnalysis; // Lưu kết quả phân tích audio gần nhất

  // ─── Config ─────────────────────────────────────────────────────
  static const Duration defaultListenFor = Duration(seconds: 12); // Tăng từ 10s lên 12s
  static const Duration defaultPauseFor = Duration(seconds: 3);   // Giảm từ 4s xuống 3s
  static const int maxAlternates = 10; // Tăng số alternates để có nhiều lựa chọn hơn

  // ─── Callbacks ──────────────────────────────────────────────────
  /// [alternates] là tất cả bản chép engine đề xuất (đã sắp theo độ tin cậy).
  /// Lớp chấm điểm nên thử KHỚP từng bản và lấy bản tốt nhất, vì bản đầu tiên
  /// (recognizedWords) thường sai với tiếng Khmer / giọng trẻ em.
  void Function(
      String text, double confidence, bool isFinal, List<String> alternates)? onResult;
  void Function(String status)? onStatus;
  void Function(String error)? onError;
  void Function(double level)? onAudioLevel; // Callback cho audio level realtime
  void Function(AudioAnalysisResult analysis)? onAudioQualityAnalysis; // Callback cho phân tích chất lượng

  // ─── Getters ────────────────────────────────────────────────────
  bool get isInitialized => _initialized;
  bool get isListening => _isListening;
  bool get isKhmerAvailable => _khmerAvailable;
  String get activeLocale => _selectedLocaleId;
  AudioAnalysisResult? get lastAudioAnalysis => _lastAudioAnalysis;

  // ─── Permission ─────────────────────────────────────────────────
  Future<SpeechPermissionStatus> checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return SpeechPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return SpeechPermissionStatus.permanentlyDenied;
    }
    return SpeechPermissionStatus.denied;
  }

  Future<SpeechPermissionStatus> requestPermission() async {
    final current = await Permission.microphone.status;
    if (current.isPermanentlyDenied) {
      return SpeechPermissionStatus.permanentlyDenied;
    }
    final result = await Permission.microphone.request();
    if (result.isGranted) return SpeechPermissionStatus.granted;
    if (result.isPermanentlyDenied) {
      return SpeechPermissionStatus.permanentlyDenied;
    }
    return SpeechPermissionStatus.denied;
  }

  /// Mở Settings app (khi bị permanentlyDenied)
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // ─── Initialization ─────────────────────────────────────────────
  Future<bool> init() async {
    if (_initialized) return true;

    final permStatus = await requestPermission();
    if (permStatus != SpeechPermissionStatus.granted) {
      debugPrint(
          '[SpeechService] ❌ Mic permission: $permStatus');
      return false;
    }

    try {
      _initialized = await _speech.initialize(
        onError: (err) {
          debugPrint('[SpeechService] Error: ${err.errorMsg}');
          if (_isListening) {
            _isListening = false;
            onError?.call(err.errorMsg);
          }
        },
        onStatus: (status) {
          debugPrint('[SpeechService] Status: $status');
          onStatus?.call(status);
          if (status == 'done' && _isListening) {
            _isListening = false;
          }
        },
      );

      if (_initialized) {
        await _detectBestLocale();
      }

      debugPrint(
        '[SpeechService] ✅ Initialized. Locale=$_selectedLocaleId, '
        'Khmer=$_khmerAvailable',
      );
    } catch (e) {
      debugPrint('[SpeechService] ❌ Init error: $e');
      _initialized = false;
    }

    return _initialized;
  }

  Future<void> _detectBestLocale() async {
    try {
      // Ghi nhớ locale hệ thống để fallback
      final systemLocale = await _speech.systemLocale();
      _fallbackLocaleId = systemLocale?.localeId;

      // Ưu tiên tiếng Việt cho người Việt học Khmer (độ chính xác cao hơn)
      final locales = await _speech.locales();

      // Tìm tiếng Việt trước
      for (final l in locales) {
        if (l.localeId.toLowerCase().contains('vi')) {
          _selectedLocaleId = l.localeId;
          _khmerAvailable = false;
          debugPrint('[SpeechService] ✅ Using Vietnamese (vi-VN) for better accuracy with Vietnamese learners');
          return;
        }
      }

      // Nếu không có tiếng Việt, kiểm tra Khmer
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('km')) {
          _selectedLocaleId = l.localeId;
          _khmerAvailable = true;
          debugPrint('[SpeechService] ⚠️ Using Khmer (km-KH) - may have lower accuracy for Vietnamese learners');
          return;
        }
      }

      // Không có cả Việt và Khmer: dùng vi-VN qua mạng
      _khmerAvailable = false;
      _selectedLocaleId = 'vi-VN';
      debugPrint('[SpeechService] ⚠️ No Vietnamese or Khmer offline pack found, using online recognition with vi-VN');
    } catch (e) {
      debugPrint('[SpeechService] Locale detection error: $e');
      _khmerAvailable = false;
      _selectedLocaleId = 'vi-VN';
    }
  }

  // ─── Listen ─────────────────────────────────────────────────────
  Future<bool> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    int retryCount = 0,
  }) async {
    if (!_initialized) {
      final ok = await init();
      if (!ok) return false;
    }

    // Đảm bảo stop hoàn toàn trước khi start mới
    if (_isListening) {
      await cancel();
      // Tăng delay lên 500ms để audio hardware reset hoàn toàn
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      // Luôn stop trước khi start để đảm bảo clean state
      await cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Kiểm tra xem speech engine có sẵn sàng không
    if (!_speech.isAvailable) {
      debugPrint('[SpeechService] ⚠️ Speech not available, reinitializing...');
      _initialized = false;
      final ok = await init();
      if (!ok) return false;
    }

    try {
      _isListening = true;
      _startTime = DateTime.now();

      await _speech.listen(
        onResult: (result) {
          // Trích xuất TẤT CẢ bản chép thay thế (alternates) để lớp chấm điểm
          // có thể chọn bản khớp nhất, không chỉ bản đoán đầu tiên.
          // TĂNG SỐ ALTERNATES để có nhiều lựa chọn hơn
          final alts = result.alternates
              .take(maxAlternates) // Lấy tối đa 10 alternates
              .map((a) => a.recognizedWords)
              .where((w) => w.trim().isNotEmpty)
              .toList();

          // Thêm recognized words vào đầu nếu chưa có
          if (!alts.contains(result.recognizedWords) && result.recognizedWords.trim().isNotEmpty) {
            alts.insert(0, result.recognizedWords);
          }

          onResult?.call(
            result.recognizedWords,
            result.confidence,
            result.finalResult,
            alts,
          );
          if (result.finalResult) {
            _isListening = false;
            final durationMs = DateTime.now().difference(_startTime!).inMilliseconds;
            _logSTTResult(result.recognizedWords, result.confidence, durationMs, alts);
          }
        },
        onSoundLevelChange: (level) {
          // Callback cho audio level realtime (0.0 - 1.0)
          // Normalize level từ -2.0 đến 10.0 về 0.0 - 1.0
          final normalizedLevel = ((level + 2.0) / 12.0).clamp(0.0, 1.0);
          onAudioLevel?.call(normalizedLevel);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          // Dùng cả nhận diện trên máy lẫn qua mạng để tăng độ chính xác
          onDevice: false,
          listenMode: stt.ListenMode.confirmation,
          localeId: localeId ?? _selectedLocaleId,
          listenFor: listenFor ?? defaultListenFor,
          pauseFor: pauseFor ?? defaultPauseFor,
          // Tăng độ nhạy để bắt giọng nói tốt hơn
          sampleRate: 16000, // 16kHz - chuẩn cho speech recognition
        ),
      );

      // Đợi một chút để đảm bảo listener đã start
      await Future.delayed(const Duration(milliseconds: 100));

      // Kiểm tra xem có thực sự đang listening không
      if (!_speech.isListening && _isListening) {
        debugPrint('[SpeechService] ⚠️ Listen failed to start, retrying...');
        _isListening = false;

        // Retry với exponential backoff (tối đa 2 lần)
        if (retryCount < 2) {
          await Future.delayed(Duration(milliseconds: 300 * (retryCount + 1)));
          return startListening(
            listenFor: listenFor,
            pauseFor: pauseFor,
            localeId: localeId,
            retryCount: retryCount + 1,
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[SpeechService] ❌ Listen error: $e');
      _isListening = false;

      // Retry nếu chưa vượt quá số lần thử
      if (retryCount < 2) {
        debugPrint('[SpeechService] 🔄 Retrying... (attempt ${retryCount + 1})');
        await Future.delayed(Duration(milliseconds: 300 * (retryCount + 1)));
        return startListening(
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
          retryCount: retryCount + 1,
        );
      }

      onError?.call(e.toString());
      return false;
    }
  }

  void _logSTTResult(String text, double confidence, int durationMs,
      [List<String> alternates = const []]) {
    try {
      final osName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);
      final deviceInfo = '$osName ${Platform.operatingSystemVersion}';

      final logMap = {
        'locale': _selectedLocaleId,
        'recognizedText': text,
        'alternates': alternates,
        'confidence': double.parse(confidence.toStringAsFixed(2)),
        'listenDuration': durationMs,
        'deviceInfo': deviceInfo,
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('[SpeechService] 🎤 STT Log:\n${jsonEncode(logMap)}');
    } catch (e) {
      debugPrint('[SpeechService] Log STT error: $e');
    }
  }

  // ─── Stop ───────────────────────────────────────────────────────
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
  }

  // ─── Cancel ─────────────────────────────────────────────────────
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _isListening = false;
  }

  // ─── Dispose ────────────────────────────────────────────────────
  void dispose() {
    _speech.stop();
    _isListening = false;
    onResult = null;
    onStatus = null;
    onError = null;
    onAudioLevel = null;
    onAudioQualityAnalysis = null;
  }

  // ─── Language Selection ─────────────────────────────────────────
  /// Cho phép user chọn ngôn ngữ nhận diện: vi-VN hoặc km-KH
  Future<void> setRecognitionLanguage(String language) async {
    if (language == 'km-KH' || language == 'vi-VN') {
      _selectedLocaleId = language;
      _khmerAvailable = (language == 'km-KH');
      debugPrint('[SpeechService] Recognition language set to: $language');
    }
  }

  /// Lấy ngôn ngữ nhận diện hiện tại
  String getRecognitionLanguage() {
    return _selectedLocaleId;
  }

  // ─── Audio Quality Helpers ──────────────────────────────────────

  /// Lấy danh sách tất cả locales có sẵn
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_initialized) {
      await init();
    }
    return _speech.locales();
  }

  /// Kiểm tra xem có locale cụ thể không
  Future<bool> hasLocale(String localeId) async {
    final locales = await getAvailableLocales();
    return locales.any((l) => l.localeId.toLowerCase() == localeId.toLowerCase());
  }

  /// Đề xuất locale tốt nhất cho Khmer
  Future<String> suggestBestLocale() async {
    final locales = await getAvailableLocales();

    // Ưu tiên: km-KH > vi-VN > th-TH > en-US
    final priorities = ['km-kh', 'km', 'vi-vn', 'vi', 'th-th', 'th', 'en-us', 'en'];

    for (final priority in priorities) {
      final found = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith(priority),
        orElse: () => stt.LocaleName('', ''),
      );
      if (found.localeId.isNotEmpty) {
        debugPrint('[SpeechService] Suggested locale: ${found.localeId}');
        return found.localeId;
      }
    }

    return 'vi-VN'; // Fallback
  }

  /// Cải thiện confidence bằng cách phân tích audio quality
  double enhanceConfidence(double rawConfidence, {AudioAnalysisResult? audioAnalysis}) {
    audioAnalysis ??= _lastAudioAnalysis;
    if (audioAnalysis == null) return rawConfidence;

    // Boost confidence nếu audio quality tốt
    double boost = 0.0;

    switch (audioAnalysis.quality) {
      case AudioQuality.excellent:
        boost = 0.15; // +15%
        break;
      case AudioQuality.good:
        boost = 0.10; // +10%
        break;
      case AudioQuality.fair:
        boost = 0.05; // +5%
        break;
      case AudioQuality.poor:
        boost = -0.05; // -5%
        break;
      case AudioQuality.veryPoor:
        boost = -0.10; // -10%
        break;
    }

    // Thêm boost dựa trên SNR
    if (audioAnalysis.signalToNoiseRatio > 20) {
      boost += 0.05;
    } else if (audioAnalysis.signalToNoiseRatio < 10) {
      boost -= 0.05;
    }

    // Thêm boost dựa trên voice activity ratio
    if (audioAnalysis.voiceActivityRatio > 0.5) {
      boost += 0.03;
    } else if (audioAnalysis.voiceActivityRatio < 0.2) {
      boost -= 0.03;
    }

    final enhanced = (rawConfidence + boost).clamp(0.0, 1.0);

    debugPrint('[SpeechService] Confidence: $rawConfidence → $enhanced (boost: ${boost > 0 ? '+' : ''}${(boost * 100).toStringAsFixed(1)}%)');

    return enhanced;
  }

  /// Lấy gợi ý cải thiện dựa trên audio analysis
  List<String> getImprovementTips() {
    if (_lastAudioAnalysis == null) return [];

    final tips = <String>[];
    final analysis = _lastAudioAnalysis!;

    if (analysis.tooQuiet) {
      tips.add('🔇 Nói to hơn hoặc đưa micro gần miệng');
    }
    if (analysis.tooLoud || analysis.hasClipping) {
      tips.add('📢 Nói nhỏ hơn, giọng bị méo');
    }
    if (analysis.signalToNoiseRatio < 15) {
      tips.add('🔊 Tìm nơi yên tĩnh hơn, nhiễu quá lớn');
    }
    if (analysis.voiceActivityRatio < 0.3) {
      tips.add('⏱️ Nói rõ ràng và đủ dài');
    }

    return tips;
  }
}
