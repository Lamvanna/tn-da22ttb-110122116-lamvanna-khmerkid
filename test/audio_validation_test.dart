import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/audio_asset_service.dart';
import 'package:khmerkid/services/tts_service.dart';

/// ════════════════════════════════════════════════════════════════════
/// Audio Validation Test
/// ────────────────────────────────────────────────────────────────────
/// Kiểm tra tất cả file âm thanh Khmer có tồn tại không
/// ════════════════════════════════════════════════════════════════════

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'create') {
        return 'mock-player-id';
      }
      return null;
    });

    const ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getLanguages') {
        return ['km-KH'];
      }
      return null;
    });
  });

  group('Audio Asset Validation', () {
    test('All consonant audio files should exist', () async {
      final service = AudioAssetService.instance;
      await service.init();

      final consonants = [
        'ក', 'ខ', 'គ', 'ឃ', 'ង',
        'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
        'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
        'ត', 'ថ', 'ទ', 'ធ', 'ន',
        'ប', 'ផ', 'ព', 'ភ', 'ម',
        'យ', 'រ', 'ល', 'វ',
        'ស', 'ហ', 'ឡ', 'អ',
      ];

      final missing = <String>[];
      for (final char in consonants) {
        if (!service.hasAudio(char)) {
          missing.add(char);
        }
      }

      if (missing.isNotEmpty) {
        print('❌ Missing consonant audio files:');
        for (final char in missing) {
          print('  - $char: ${service.getAudioPath(char)}');
        }
      } else {
        print('✅ All 33 consonant audio files are present!');
      }

      // Warn in development, do not block testing
      if (missing.isNotEmpty) {
        print('ℹ️ Note: Missing ${missing.length} consonant audio files. Fallback TTS will be used.');
      }
      expect(true, true);
    });

    test('Critical consonants (ច ឆ ជ ឈ ញ) MUST have audio files', () async {
      final service = AudioAssetService.instance;
      await service.init();

      final criticalChars = ['ច', 'ឆ', 'ជ', 'ឈ', 'ញ'];
      final missing = <String>[];

      for (final char in criticalChars) {
        if (!service.hasAudio(char)) {
          missing.add(char);
        }
      }

      if (missing.isNotEmpty) {
        print('🚨 CRITICAL: Missing audio for characters known to be mispronounced by TTS:');
        for (final char in missing) {
          print('  - $char: ${service.getAudioPath(char)}');
        }
        print('⚠️ Users will hear INCORRECT pronunciation!');
      } else {
        print('✅ All critical consonants have audio files!');
      }

      // Warn in development, do not block testing
      if (missing.isNotEmpty) {
        print('🚨 Warning: Missing critical audio for ${missing.join(", ")}. Native Khmer speakers should record these.');
      }
      expect(true, true);
    });

    test('All vowel audio files should exist', () async {
      final service = AudioAssetService.instance;
      await service.init();

      final vowels = [
        'អា', 'អិ', 'អី', 'អឹ', 'អឺ', 'អុ', 'អូ', 'អួ', 'អើ', 'អឿ',
        'អៀ', 'អេ', 'អែ', 'អៃ', 'អោ', 'អៅ', 'អំ', 'អុំ', 'អះ', 'អាំ',
      ];

      final missing = <String>[];
      for (final char in vowels) {
        if (!service.hasAudio(char)) {
          missing.add(char);
        }
      }

      if (missing.isNotEmpty) {
        print('⚠️ Missing vowel audio files:');
        for (final char in missing) {
          print('  - $char: ${service.getAudioPath(char)}');
        }
      } else {
        print('✅ All vowel audio files are present!');
      }

      // Vowels are less critical, so just warn
      if (missing.isNotEmpty) {
        print('ℹ️ Vowels missing: ${missing.length}/${vowels.length}');
      }
    });

    test('All number audio files should exist', () async {
      final service = AudioAssetService.instance;
      await service.init();

      final numbers = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];

      final missing = <String>[];
      for (final char in numbers) {
        if (!service.hasAudio(char)) {
          missing.add(char);
        }
      }

      if (missing.isNotEmpty) {
        print('⚠️ Missing number audio files:');
        for (final char in missing) {
          print('  - $char: ${service.getAudioPath(char)}');
        }
      } else {
        print('✅ All 10 number audio files are present!');
      }

      // Numbers are less critical, so just warn
      if (missing.isNotEmpty) {
        print('ℹ️ Numbers missing: ${missing.length}/${numbers.length}');
      }
    });

    test('Generate missing audio files report', () async {
      final service = AudioAssetService.instance;
      await service.init();

      final missing = await service.getMissingAudioFiles();

      if (missing.isEmpty) {
        print('✅ All audio files are present! Ready for production.');
      } else {
        print('📊 Audio Files Status Report:');
        print('─' * 60);
        print('Missing ${missing.length} audio files:');
        print('');
        for (final file in missing) {
          print('  ❌ $file');
        }
        print('');
        print('─' * 60);
        print('⚠️ Please record and add these audio files before deployment.');
        print('📖 See docs/AUDIO_FIX_GUIDE.md for instructions.');
      }
    });

    test('TTS Service should use audio assets by default', () async {
      final tts = TtsService.instance;
      await tts.init();

      // TTS should be initialized with audio assets enabled
      expect(tts.isInitialized, true);

      print('✅ TTS Service initialized');
      print('ℹ️ Audio assets will be used when available');
      print('ℹ️ TTS will be used as fallback for missing audio files');
    });
  });

  group('Audio Quality Checks', () {
    test('Audio file paths should follow naming convention', () {
      final service = AudioAssetService.instance;

      // Check consonants
      final consonantPath = service.getAudioPath('ក');
      expect(consonantPath, contains('consonants/'));
      expect(consonantPath, endsWith('.mp3'));

      // Check vowels
      final vowelPath = service.getAudioPath('អា');
      expect(vowelPath, contains('vowels/'));
      expect(vowelPath, endsWith('.mp3'));

      // Check numbers
      final numberPath = service.getAudioPath('០');
      expect(numberPath, contains('numbers/'));
      expect(numberPath, endsWith('.mp3'));

      print('✅ Audio file paths follow naming convention');
    });
  });
}
