import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ════════════════════════════════════════════════════════════════════
/// TTS Service — Singleton quản lý Text-to-Speech
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Auto-detect Khmer (km-KH) → vi-VN → en-US
///   • 3 tốc độ phù hợp trẻ em: chậm / vừa / nhanh
///   • Callbacks: onStart, onComplete, onError
///   • Word-by-word progress cho highlight
///   • Dispose-safe
/// ════════════════════════════════════════════════════════════════════

enum TtsSpeed { slow, normal, fast }

class TtsService {
  TtsService._();
  static TtsService? _instance;
  static TtsService get instance {
    _instance ??= TtsService._();
    return _instance!;
  }

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isPlaying = false;
  bool _khmerSupported = false;
  TtsSpeed _speed = TtsSpeed.normal;

  // ─── Callbacks ──────────────────────────────────────────────────
  VoidCallback? onStart;
  VoidCallback? onComplete;
  void Function(String)? onError;
  void Function(String text, int start, int end)? onProgress;

  // ─── Getters ────────────────────────────────────────────────────
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _initialized;
  bool get isKhmerSupported => _khmerSupported;
  TtsSpeed get speed => _speed;

  double get _speedRate {
    switch (_speed) {
      case TtsSpeed.slow:
        return 0.2;
      case TtsSpeed.normal:
        return 0.4;
      case TtsSpeed.fast:
        return 0.7;
    }
  }

  // ─── Initialization ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    try {
      final languages = await _tts.getLanguages;
      final langList =
          (languages as List).map((l) => l.toString().toLowerCase()).toList();

      _khmerSupported =
          langList.any((l) => l.contains('km') || l.contains('khmer'));

      if (_khmerSupported) {
        await _tts.setLanguage('km-KH');
      } else {
        final viSupported = langList.any((l) => l.contains('vi'));
        await _tts.setLanguage(viSupported ? 'vi-VN' : 'en-US');
      }

      await _tts.setSpeechRate(_speedRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isPlaying = true;
        onStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
        onComplete?.call();
      });

      _tts.setErrorHandler((msg) {
        _isPlaying = false;
        onError?.call(msg.toString());
      });

      _tts.setProgressHandler((text, start, end, word) {
        onProgress?.call(text, start, end);
      });

      _initialized = true;
      debugPrint('[TtsService] ✅ Initialized. Khmer=$_khmerSupported');
    } catch (e) {
      debugPrint('[TtsService] ❌ Init error: $e');
      _initialized = false;
    }
  }

  // ─── Speed Control ──────────────────────────────────────────────
  Future<void> setSpeed(TtsSpeed speed) async {
    _speed = speed;
    await _tts.setSpeechRate(_speedRate);
  }

  // ─── Speak ──────────────────────────────────────────────────────
  /// Phát âm text. Nếu là chữ Khmer và device hỗ trợ thì dùng km.
  /// Nếu không, dùng [fallbackText] (romanized/pronunciation).
  Future<bool> speak(String text, {String? fallbackText}) async {
    if (!_initialized) await init();
    if (_isPlaying) await stop();

    final textToSpeak =
        _khmerSupported ? text : (fallbackText ?? text);

    await _tts.setSpeechRate(_speedRate);
    final result = await _tts.speak(textToSpeak);
    _isPlaying = result == 1;

    if (result != 1) {
      // Auto-stop after timeout if speak didn't return success
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_isPlaying) {
          _isPlaying = false;
          onComplete?.call();
        }
      });
    }

    return result == 1;
  }

  /// Phát âm chữ Khmer letter với fallback thông minh
  Future<bool> speakKhmerLetter({
    required String character,
    String pronunciation = '',
    String romanized = '',
  }) async {
    final fallback = pronunciation.isNotEmpty ? pronunciation : romanized;
    return speak(character, fallbackText: fallback);
  }

  // ─── Stop ───────────────────────────────────────────────────────
  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  // ─── Dispose ────────────────────────────────────────────────────
  void dispose() {
    _tts.stop();
    _isPlaying = false;
    onStart = null;
    onComplete = null;
    onError = null;
    onProgress = null;
  }
}
