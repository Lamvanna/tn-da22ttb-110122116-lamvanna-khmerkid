import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';
import 'audio_asset_service.dart';

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
  final AudioAssetService _audioAsset = AudioAssetService.instance;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _khmerSupported = false;
  String _khmerLocale = 'km'; // Locale Khmer thực tế đã match (vd 'km-KH')
  TtsSpeed _speed = TtsSpeed.normal;
  bool _soundEnabled = true;
  bool _useAudioAssets = true; // Ưu tiên dùng file âm thanh chuẩn

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
  bool get soundEnabled => _soundEnabled;

  /// Bật/tắt toàn bộ âm thanh đọc. Khi tắt, [speak] sẽ bỏ qua.
  set soundEnabled(bool value) {
    _soundEnabled = value;
    if (!value) stop();
  }

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

    // Khởi tạo audio asset service trước
    await _audioAsset.init();

    // Khôi phục cài đặt âm thanh đã lưu (bật/tắt + tốc độ đọc)
    try {
      final storage = await StorageService.getInstance();
      _soundEnabled = storage.getSoundEnabled();
      _speed = TtsSpeed.values[storage.getTtsSpeed().clamp(0, 2)];
    } catch (_) {
      // Bỏ qua nếu storage chưa sẵn sàng — dùng mặc định
    }
    try {
      final languages = await _tts.getLanguages;

      // Find the exact matching Khmer language string supported by the device
      String? matchedKhmer;
      for (final dynamic lang in languages) {
        final String lStr = lang.toString();
        final String lLower = lStr.toLowerCase();
        if (lLower == 'km' || lLower == 'km-kh' || lLower == 'km_kh') {
          matchedKhmer = lStr;
          break;
        }
      }

      // Fallback search if exact not found
      if (matchedKhmer == null) {
        for (final dynamic lang in languages) {
          final String lStr = lang.toString();
          final String lLower = lStr.toLowerCase();
          if (lLower.contains('km') || lLower.contains('khmer')) {
            matchedKhmer = lStr;
            break;
          }
        }
      }

      // Sử dụng giọng Khmer native nếu thiết bị hỗ trợ
      // Đây là cách ĐÚNG để học phát âm Khmer chuẩn
      _khmerSupported = matchedKhmer != null;

      if (_khmerSupported) {
        await _tts.setLanguage(matchedKhmer!);
        _khmerLocale = matchedKhmer; // Lưu lại để khôi phục chính xác sau khi đọc tiếng Việt
      } else {
        String? viLang;
        for (final dynamic lang in languages) {
          final String lStr = lang.toString();
          final String lLower = lStr.toLowerCase();
          if (lLower.contains('vi')) {
            viLang = lStr;
            break;
          }
        }
        await _tts.setLanguage(viLang ?? 'vi-VN');
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
      debugPrint('[TtsService] ✅ Initialized. Khmer=$_khmerSupported, Matched=$matchedKhmer');
      debugPrint('[TtsService] 🎵 Audio Assets: ${_useAudioAssets ? 'ENABLED (Recommended)' : 'DISABLED'}');

      // Validate audio assets (không chặn nếu thiếu file)
      if (_useAudioAssets) {
        // Chạy validation nhưng không await để không chặn init
        validateAudioAssets().then((_) {
          debugPrint('[TtsService] ℹ️ Audio validation completed in background');
        }).catchError((e) {
          debugPrint('[TtsService] ⚠️ Audio validation error (non-critical): $e');
        });
      }
    } catch (e) {
      debugPrint('[TtsService] ❌ Init error: $e');
      _initialized = false;
    }
  }

  // ─── Speed Control ──────────────────────────────────────────────
  Future<void> setSpeed(TtsSpeed speed) async {
    _speed = speed;
    await _tts.setSpeechRate(_speedRate);
    try {
      final storage = await StorageService.getInstance();
      await storage.setTtsSpeed(speed.index);
    } catch (_) {/* bỏ qua lỗi lưu */}
  }

  // ─── Speak ──────────────────────────────────────────────────────
  /// Phát âm text. Nếu là chữ Khmer và device hỗ trợ thì dùng km.
  /// Nếu không, dùng [fallbackText] (romanized/pronunciation).
  Future<bool> speak(String text, {String? fallbackText}) async {
    if (!_soundEnabled) return false; // Người dùng đã tắt âm thanh
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

  /// Đọc một chuỗi phiên âm TIẾNG VIỆT (vd "srăk a") bằng giọng vi-VN,
  /// BỎ QUA ưu tiên Khmer và audio asset.
  /// Dùng cho các trường hợp cần đọc đúng "tên" theo phiên âm Việt, không phải
  /// đọc ký tự Khmer (vốn ra âm khác). Sau khi đọc xong sẽ khôi phục ngôn ngữ cũ.
  Future<bool> speakVietnamese(String text) async {
    if (!_soundEnabled) return false;
    if (text.trim().isEmpty) return false;
    if (!_initialized) await init();
    if (_isPlaying) await stop();

    try {
      // Tạm chuyển sang vi-VN để đọc phiên âm Việt cho chuẩn
      if (_khmerSupported) {
        await _tts.setLanguage('vi-VN');
      }
      await _tts.setSpeechRate(_speedRate);
      final result = await _tts.speak(text);
      _isPlaying = result == 1;

      if (result != 1) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isPlaying) {
            _isPlaying = false;
            onComplete?.call();
          }
        });
      }
      return result == 1;
    } finally {
      // Khôi phục lại ngôn ngữ Khmer nếu thiết bị hỗ trợ
      if (_khmerSupported) {
        await _tts.setLanguage(_khmerLocale);
      }
    }
  }
  /// Phát âm chữ Khmer letter với ưu tiên file âm thanh chuẩn
  ///
  /// QUAN TRỌNG: Đây là hàm CHÍNH để phát âm chữ Khmer.
  /// Ưu tiên:
  /// 1. File âm thanh chuẩn (do người bản ngữ ghi âm) - CHÍNH XÁC 100%
  /// 2. Khmer TTS (nếu thiết bị hỗ trợ) - có thể sai
  /// 3. Fallback sang phiên âm Latin - SAI HOÀN TOÀN
  Future<bool> speakKhmerLetter({
    required String character,
    String pronunciation = '',
    String romanized = '',
    String? audioUrl,
  }) async {
    if (!_soundEnabled) return false;
    if (!_initialized) await init(); // Đảm bảo TTS + AudioAsset đã sẵn sàng

    // ═══════════════════════════════════════════════════════════════
    // BƯỚC 0: Ưu tiên tuyệt đối số 1 - Phát tệp ghi âm từ backend nếu có
    // ═══════════════════════════════════════════════════════════════
    if (audioUrl != null && audioUrl.isNotEmpty) {
      debugPrint('[TtsService] 🌐 Using REMOTE CUSTOM AUDIO URL: $audioUrl');

      _audioAsset.onStart = () {
        _isPlaying = true;
        onStart?.call();
      };
      _audioAsset.onComplete = () {
        _isPlaying = false;
        onComplete?.call();
      };
      _audioAsset.onError = (err) {
        _isPlaying = false;
        onError?.call(err);
      };

      final success = await _audioAsset.playFromUrl(audioUrl);
      if (success) {
        return true;
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // BƯỚC 1: Ưu tiên số 2 - Dùng file âm thanh local chuẩn (nếu file CÓ THẬT)
    // ═══════════════════════════════════════════════════════════════
    if (_useAudioAssets && _audioAsset.hasAudio(character)) {
      debugPrint('[TtsService] ✅ Using AUDIO ASSET (100% accurate): $character');

      // Setup callbacks cho audio asset
      _audioAsset.onStart = () {
        _isPlaying = true;
        onStart?.call();
      };
      _audioAsset.onComplete = () {
        _isPlaying = false;
        onComplete?.call();
      };
      _audioAsset.onError = (err) {
        _isPlaying = false;
        onError?.call(err);
      };

      final success = await _audioAsset.playCharacter(character);
      if (success) {
        return true;
      } else {
        debugPrint('[TtsService] ⚠️ Audio asset failed, falling back to TTS');
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // BƯỚC 2: Fallback - Dùng Khmer TTS (CÓ THỂ SAI)
    // ═══════════════════════════════════════════════════════════════

    // Danh sách chữ BIẾT CHẮC bị TTS đọc sai
    // Các chữ này KHÔNG BAO GIỜ dùng TTS, chỉ dùng audio asset
    final knownProblematicChars = [
      'ច', // cho - TTS thường đọc sai
      'ឆ', // chhor - TTS thường đọc sai
      'ជ', // cho - TTS dễ nhầm với ច
      'ឈ', // chhor - TTS thường đọc sai
      'ញ', // nhor - TTS thường đọc sai
    ];

    if (knownProblematicChars.contains(character)) {
      debugPrint('[TtsService] ❌ Character $character is KNOWN to be mispronounced by TTS');
      debugPrint('[TtsService] ⚠️ CRITICAL: Audio asset missing for $character!');
      debugPrint('[TtsService] ⚠️ User will hear INCORRECT pronunciation!');

      // Vẫn thử TTS nhưng log cảnh báo nghiêm trọng
      final fallback = pronunciation.isNotEmpty ? pronunciation : romanized;
      return speak(character, fallbackText: fallback);
    }

    // Các chữ khác có thể thử TTS
    final fallback = pronunciation.isNotEmpty ? pronunciation : romanized;
    return speak(character, fallbackText: fallback);
  }

  /// Bật/tắt sử dụng audio assets
  void setUseAudioAssets(bool value) {
    _useAudioAssets = value;
    debugPrint('[TtsService] Audio assets: ${value ? 'ENABLED' : 'DISABLED'}');
  }

  /// Kiểm tra tính khả dụng của audio assets
  Future<void> validateAudioAssets() async {
    try {
      final missing = await _audioAsset.getMissingAudioFiles();
      if (missing.isEmpty) {
        debugPrint('[TtsService] ✅ All audio assets available');
      } else {
        debugPrint('[TtsService] ℹ️ Missing ${missing.length} audio files (expected during development)');
        debugPrint('[TtsService] ℹ️ App will use TTS fallback for missing files');
        debugPrint('[TtsService] 📖 See docs/AUDIO_FIX_GUIDE.md for recording instructions');
      }
    } catch (e) {
      debugPrint('[TtsService] ⚠️ Audio validation error (non-critical): $e');
    }
  }

  // ─── Stop ───────────────────────────────────────────────────────
  Future<void> stop() async {
    await _tts.stop();
    await _audioAsset.stop();
    _isPlaying = false;
  }

  // ─── Dispose ────────────────────────────────────────────────────
  void dispose() {
    _tts.stop();
    _audioAsset.dispose();
    _isPlaying = false;
    onStart = null;
    onComplete = null;
    onError = null;
    onProgress = null;
  }
}

/// ════════════════════════════════════════════════════════════════════
/// HƯỚNG DẪN SỬ DỤNG AUDIO ASSETS
/// ════════════════════════════════════════════════════════════════════
///
/// 1. Chuẩn bị file âm thanh:
///    - Tìm người bản ngữ Khmer ghi âm CHUẨN từng chữ cái
///    - Format: MP3, 16kHz, mono, chất lượng cao
///    - Độ dài: 0.5-1.5 giây mỗi chữ
///    - Không có nhiễu nền
///
/// 2. Đặt file vào thư mục:
///    assets/audio/khmer/
///      ├── consonants/  (33 file)
///      ├── vowels/      (20+ file)
///      └── numbers/     (10 file)
///
/// 3. Cập nhật pubspec.yaml:
///    flutter:
///      assets:
///        - assets/audio/khmer/consonants/
///        - assets/audio/khmer/vowels/
///        - assets/audio/khmer/numbers/
///
/// 4. Cài đặt package audioplayers:
///    dependencies:
///      audioplayers: ^5.2.1
///
/// 5. Test:
///    await TtsService.instance.init();
///    await TtsService.instance.validateAudioAssets();
///    await TtsService.instance.speakKhmerLetter(character: 'ក');
///
/// ════════════════════════════════════════════════════════════════════
