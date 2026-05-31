import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// ════════════════════════════════════════════════════════════════════
/// Audio Asset Service — Phát âm chuẩn từ file âm thanh ghi sẵn
/// ────────────────────────────────────────────────────────────────────
/// Giải pháp: Thay thế TTS không chính xác bằng file âm thanh
/// do người bản ngữ Khmer ghi âm chuẩn.
///
/// QUAN TRỌNG: Đây là giải pháp ĐÚNG để đảm bảo người học nghe
/// phát âm Khmer chính xác 100%, tránh học sai từ đầu.
/// ════════════════════════════════════════════════════════════════════

class AudioAssetService {
  AudioAssetService._();
  static AudioAssetService? _instance;
  static AudioAssetService get instance {
    _instance ??= AudioAssetService._();
    return _instance!;
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _initialized = false;

  // ─── Callbacks ──────────────────────────────────────────────────
  VoidCallback? onStart;
  VoidCallback? onComplete;
  void Function(String)? onError;

  // ─── Getters ────────────────────────────────────────────────────
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _initialized;

  // ─── Audio Asset Mapping ────────────────────────────────────────
  /// Map từ ký tự Khmer sang đường dẫn file âm thanh
  /// Format: assets/audio/khmer/{category}/{character}.mp3
  ///
  /// CẤU TRÚC THƯ MỤC ĐỀ XUẤT:
  /// assets/audio/khmer/
  ///   ├── consonants/     # 33 phụ âm
  ///   │   ├── ka.mp3      # ក
  ///   │   ├── kha.mp3     # ខ
  ///   │   ├── ko.mp3      # គ
  ///   │   └── ...
  ///   ├── vowels/         # Nguyên âm
  ///   │   ├── aa.mp3      # អា
  ///   │   ├── e.mp3       # អិ
  ///   │   └── ...
  ///   ├── numbers/        # Số
  ///   │   ├── 0.mp3       # ០
  ///   │   ├── 1.mp3       # ១
  ///   │   └── ...
  ///   └── words/          # Từ vựng
  ///       └── ...

  static const Map<String, String> _consonantAudioMap = {
    // Nhóm 1
    'ក': 'assets/audio/khmer/consonants/ka.mp3',
    'ខ': 'assets/audio/khmer/consonants/kha.mp3',
    'គ': 'assets/audio/khmer/consonants/ko.mp3',
    'ឃ': 'assets/audio/khmer/consonants/kho.mp3',
    'ង': 'assets/audio/khmer/consonants/ngo.mp3',

    // Nhóm 2 - CÁC CHỮ THƯỜNG BỊ PHÁT ÂM SAI
    'ច': 'assets/audio/khmer/consonants/cho.mp3',    // QUAN TRỌNG
    'ឆ': 'assets/audio/khmer/consonants/chhor.mp3',  // QUAN TRỌNG
    'ជ': 'assets/audio/khmer/consonants/cho2.mp3',   // QUAN TRỌNG (khác ច)
    'ឈ': 'assets/audio/khmer/consonants/chhor2.mp3', // QUAN TRỌNG
    'ញ': 'assets/audio/khmer/consonants/nhor.mp3',   // QUAN TRỌNG

    // Nhóm 3
    'ដ': 'assets/audio/khmer/consonants/da.mp3',
    'ឋ': 'assets/audio/khmer/consonants/tha.mp3',
    'ឌ': 'assets/audio/khmer/consonants/do.mp3',
    'ឍ': 'assets/audio/khmer/consonants/tho.mp3',
    'ណ': 'assets/audio/khmer/consonants/na.mp3',

    // Nhóm 4
    'ត': 'assets/audio/khmer/consonants/ta.mp3',
    'ថ': 'assets/audio/khmer/consonants/tha2.mp3',
    'ទ': 'assets/audio/khmer/consonants/to.mp3',
    'ធ': 'assets/audio/khmer/consonants/tho2.mp3',
    'ន': 'assets/audio/khmer/consonants/no.mp3',

    // Nhóm 5
    'ប': 'assets/audio/khmer/consonants/ba.mp3',
    'ផ': 'assets/audio/khmer/consonants/pha.mp3',
    'ព': 'assets/audio/khmer/consonants/po.mp3',
    'ភ': 'assets/audio/khmer/consonants/pho.mp3',
    'ម': 'assets/audio/khmer/consonants/mo.mp3',

    // Nhóm 6
    'យ': 'assets/audio/khmer/consonants/yo.mp3',
    'រ': 'assets/audio/khmer/consonants/ro.mp3',
    'ល': 'assets/audio/khmer/consonants/lo.mp3',
    'វ': 'assets/audio/khmer/consonants/vo.mp3',

    // Nhóm 7
    'ស': 'assets/audio/khmer/consonants/sa.mp3',
    'ហ': 'assets/audio/khmer/consonants/ha.mp3',
    'ឡ': 'assets/audio/khmer/consonants/la.mp3',
    'អ': 'assets/audio/khmer/consonants/a.mp3',
  };

  static const Map<String, String> _vowelAudioMap = {
    'អា': 'assets/audio/khmer/vowels/aa.mp3',
    'អិ': 'assets/audio/khmer/vowels/e.mp3',
    'អី': 'assets/audio/khmer/vowels/ei.mp3',
    'អឹ': 'assets/audio/khmer/vowels/ə.mp3',
    'អឺ': 'assets/audio/khmer/vowels/əə.mp3',
    'អុ': 'assets/audio/khmer/vowels/o.mp3',
    'អូ': 'assets/audio/khmer/vowels/oo.mp3',
    'អួ': 'assets/audio/khmer/vowels/uə.mp3',
    'អើ': 'assets/audio/khmer/vowels/əə2.mp3',
    'អឿ': 'assets/audio/khmer/vowels/ɨə.mp3',
    'អៀ': 'assets/audio/khmer/vowels/iə.mp3',
    'អេ': 'assets/audio/khmer/vowels/ee.mp3',
    'អែ': 'assets/audio/khmer/vowels/ae.mp3',
    'អៃ': 'assets/audio/khmer/vowels/aj.mp3',
    'អោ': 'assets/audio/khmer/vowels/ao.mp3',
    'អៅ': 'assets/audio/khmer/vowels/aw.mp3',
    'អំ': 'assets/audio/khmer/vowels/ɑm.mp3',
    'អុំ': 'assets/audio/khmer/vowels/om.mp3',
    'អះ': 'assets/audio/khmer/vowels/ah.mp3',
    'អាំ': 'assets/audio/khmer/vowels/am.mp3',
  };

  static const Map<String, String> _numberAudioMap = {
    '០': 'assets/audio/khmer/numbers/0.mp3',
    '១': 'assets/audio/khmer/numbers/1.mp3',
    '២': 'assets/audio/khmer/numbers/2.mp3',
    '៣': 'assets/audio/khmer/numbers/3.mp3',
    '៤': 'assets/audio/khmer/numbers/4.mp3',
    '៥': 'assets/audio/khmer/numbers/5.mp3',
    '៦': 'assets/audio/khmer/numbers/6.mp3',
    '៧': 'assets/audio/khmer/numbers/7.mp3',
    '៨': 'assets/audio/khmer/numbers/8.mp3',
    '៩': 'assets/audio/khmer/numbers/9.mp3',
  };

  // ─── Initialization ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Cấu hình audio player
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);

      // Setup callbacks
      _player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _isPlaying = true;
          onStart?.call();
        } else if (state == PlayerState.completed || state == PlayerState.stopped) {
          _isPlaying = false;
          onComplete?.call();
        }
      });

      _initialized = true;
      debugPrint('[AudioAssetService] ✅ Initialized');
    } catch (e) {
      debugPrint('[AudioAssetService] ❌ Init error: $e');
      _initialized = false;
    }
  }

  // ─── Play Audio ─────────────────────────────────────────────────

  /// Phát âm từ file asset
  Future<bool> playFromAsset(String assetPath) async {
    if (!_initialized) await init();
    if (_isPlaying) await stop();

    try {
      // Loại bỏ prefix 'assets/' nếu có vì AssetSource tự thêm
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _player.play(AssetSource(cleanPath));
      return true;
    } catch (e) {
      debugPrint('[AudioAssetService] ❌ Play error for $assetPath: $e');
      debugPrint('[AudioAssetService] ℹ️ File may not exist yet - this is expected during development');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Phát âm chữ cái Khmer (phụ âm)
  Future<bool> playConsonant(String character) async {
    final assetPath = _consonantAudioMap[character];
    if (assetPath == null) {
      debugPrint('[AudioAssetService] ⚠️ No audio for consonant: $character');
      return false;
    }

    debugPrint('[AudioAssetService] 🔊 Playing consonant: $character → $assetPath');
    return playFromAsset(assetPath);
  }

  /// Phát âm nguyên âm Khmer
  Future<bool> playVowel(String character) async {
    final assetPath = _vowelAudioMap[character];
    if (assetPath == null) {
      debugPrint('[AudioAssetService] ⚠️ No audio for vowel: $character');
      return false;
    }

    debugPrint('[AudioAssetService] 🔊 Playing vowel: $character → $assetPath');
    return playFromAsset(assetPath);
  }

  /// Phát âm số Khmer
  Future<bool> playNumber(String character) async {
    final assetPath = _numberAudioMap[character];
    if (assetPath == null) {
      debugPrint('[AudioAssetService] ⚠️ No audio for number: $character');
      return false;
    }

    debugPrint('[AudioAssetService] 🔊 Playing number: $character → $assetPath');
    return playFromAsset(assetPath);
  }

  /// Phát âm tự động (tự nhận diện loại)
  Future<bool> playCharacter(String character) async {
    // Thử phụ âm trước
    if (_consonantAudioMap.containsKey(character)) {
      return playConsonant(character);
    }

    // Thử nguyên âm
    if (_vowelAudioMap.containsKey(character)) {
      return playVowel(character);
    }

    // Thử số
    if (_numberAudioMap.containsKey(character)) {
      return playNumber(character);
    }

    debugPrint('[AudioAssetService] ⚠️ No audio found for: $character');
    return false;
  }

  /// Kiểm tra xem có file âm thanh cho ký tự không
  bool hasAudio(String character) {
    return _consonantAudioMap.containsKey(character) ||
           _vowelAudioMap.containsKey(character) ||
           _numberAudioMap.containsKey(character);
  }

  /// Lấy đường dẫn file âm thanh
  String? getAudioPath(String character) {
    return _consonantAudioMap[character] ??
           _vowelAudioMap[character] ??
           _numberAudioMap[character];
  }

  // ─── Stop ───────────────────────────────────────────────────────
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  // ─── Dispose ────────────────────────────────────────────────────
  void dispose() {
    _player.dispose();
    _isPlaying = false;
    onStart = null;
    onComplete = null;
    onError = null;
  }

  // ─── Validation & Testing ───────────────────────────────────────

  /// Kiểm tra tất cả file âm thanh có tồn tại không
  Future<Map<String, bool>> validateAllAudioFiles() async {
    final results = <String, bool>{};

    // Kiểm tra phụ âm
    for (final entry in _consonantAudioMap.entries) {
      try {
        final cleanPath = entry.value.startsWith('assets/')
            ? entry.value.substring(7)
            : entry.value;
        await _player.setSource(AssetSource(cleanPath));
        results[entry.key] = true;
      } catch (e) {
        results[entry.key] = false;
        debugPrint('[AudioAssetService] ⚠️ Missing: ${entry.key} → ${entry.value}');
      }
    }

    // Kiểm tra nguyên âm
    for (final entry in _vowelAudioMap.entries) {
      try {
        final cleanPath = entry.value.startsWith('assets/')
            ? entry.value.substring(7)
            : entry.value;
        await _player.setSource(AssetSource(cleanPath));
        results[entry.key] = true;
      } catch (e) {
        results[entry.key] = false;
        debugPrint('[AudioAssetService] ⚠️ Missing: ${entry.key} → ${entry.value}');
      }
    }

    // Kiểm tra số
    for (final entry in _numberAudioMap.entries) {
      try {
        final cleanPath = entry.value.startsWith('assets/')
            ? entry.value.substring(7)
            : entry.value;
        await _player.setSource(AssetSource(cleanPath));
        results[entry.key] = true;
      } catch (e) {
        results[entry.key] = false;
        debugPrint('[AudioAssetService] ⚠️ Missing: ${entry.key} → ${entry.value}');
      }
    }

    final total = results.length;
    final found = results.values.where((v) => v).length;
    final missing = total - found;

    if (missing > 0) {
      debugPrint('[AudioAssetService] 📊 Validation: $found/$total files found, $missing missing');
      debugPrint('[AudioAssetService] ℹ️ This is expected during development. See docs/AUDIO_FIX_GUIDE.md');
    } else {
      debugPrint('[AudioAssetService] ✅ All $total audio files found!');
    }

    return results;
  }

  /// Lấy danh sách file âm thanh còn thiếu
  Future<List<String>> getMissingAudioFiles() async {
    final validation = await validateAllAudioFiles();
    return validation.entries
        .where((e) => !e.value)
        .map((e) => '${e.key}: ${getAudioPath(e.key)}')
        .toList();
  }
}
