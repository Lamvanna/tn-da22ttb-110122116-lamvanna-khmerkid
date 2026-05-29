import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// ════════════════════════════════════════════════════════════════════
/// Speech Service — Singleton quản lý Speech-to-Text
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Auto-detect locale: km_KH → no fallback
///   • partialResults: true (realtime transcript)
///   • listenFor: 7 giây
///   • pauseFor: 3 giây
///   • Permission handling tự động
///   • Clean error handling
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
  bool _initialized = false;
  bool _isListening = false;
  String _selectedLocaleId = 'km-KH';
  bool _khmerAvailable = false;
  DateTime? _startTime;

  // ─── Config ─────────────────────────────────────────────────────
  static const Duration defaultListenFor = Duration(seconds: 7);
  static const Duration defaultPauseFor = Duration(seconds: 3);

  // ─── Callbacks ──────────────────────────────────────────────────
  void Function(String text, double confidence, bool isFinal)? onResult;
  void Function(String status)? onStatus;
  void Function(String error)? onError;

  // ─── Getters ────────────────────────────────────────────────────
  bool get isInitialized => _initialized;
  bool get isListening => _isListening;
  bool get isKhmerAvailable => _khmerAvailable;
  String get activeLocale => _selectedLocaleId;

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
      final systemLocale = await _speech.systemLocale();
      if (systemLocale != null && systemLocale.localeId.toLowerCase().startsWith('km')) {
        _selectedLocaleId = systemLocale.localeId;
        _khmerAvailable = true;
        return;
      }

      // Search for Khmer locale in all available locales
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('km')) {
          _selectedLocaleId = l.localeId;
          _khmerAvailable = true;
          return;
        }
      }

      // If no Khmer locale is found, do NOT fallback to Vietnamese/English
      _khmerAvailable = false;
      _selectedLocaleId = 'km-KH';
    } catch (e) {
      debugPrint('[SpeechService] Locale detection error: $e');
      _khmerAvailable = false;
      _selectedLocaleId = 'km-KH';
    }
  }

  // ─── Listen ─────────────────────────────────────────────────────
  Future<bool> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    if (!_initialized) {
      final ok = await init();
      if (!ok) return false;
    }

    if (_isListening) {
      await cancel();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    try {
      _isListening = true;
      _startTime = DateTime.now();
      
      // ignore: deprecated_member_use
      await _speech.listen(
        onResult: (result) {
          onResult?.call(result.recognizedWords, result.confidence, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            final durationMs = DateTime.now().difference(_startTime!).inMilliseconds;
            _logSTTResult(result.recognizedWords, result.confidence, durationMs);
          }
        },
        // ignore: deprecated_member_use
        listenFor: listenFor ?? defaultListenFor,
        // ignore: deprecated_member_use
        pauseFor: pauseFor ?? defaultPauseFor,
        // ignore: deprecated_member_use
        localeId: localeId ?? _selectedLocaleId,
        // ignore: deprecated_member_use
        partialResults: true,
        // ignore: deprecated_member_use
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      debugPrint('[SpeechService] ❌ Listen error: $e');
      _isListening = false;
      onError?.call(e.toString());
      return false;
    }
  }

  void _logSTTResult(String text, double confidence, int durationMs) {
    try {
      final osName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);
      final deviceInfo = '$osName ${Platform.operatingSystemVersion}';

      final logMap = {
        'locale': _selectedLocaleId,
        'recognizedText': text,
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
  }
}
