import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// ════════════════════════════════════════════════════════════════════
/// Audio Preprocessing Service — Xử lý âm thanh trước khi nhận diện
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Noise reduction (giảm nhiễu)
///   • Audio normalization (chuẩn hóa âm lượng)
///   • Voice Activity Detection (phát hiện giọng nói)
///   • Silence removal (loại bỏ khoảng lặng)
///   • Audio quality analysis (phân tích chất lượng)
/// ════════════════════════════════════════════════════════════════════

enum AudioQuality {
  excellent, // > 80% - Rất tốt
  good,      // 60-80% - Tốt
  fair,      // 40-60% - Khá
  poor,      // 20-40% - Kém
  veryPoor,  // < 20% - Rất kém
}

class AudioAnalysisResult {
  final AudioQuality quality;
  final double signalToNoiseRatio; // SNR (dB)
  final double voiceActivityRatio; // % thời gian có giọng nói
  final double averageAmplitude;   // Biên độ trung bình
  final bool hasClipping;          // Có bị cắt đỉnh không
  final bool tooQuiet;             // Quá nhỏ
  final bool tooLoud;              // Quá to
  final String feedback;           // Phản hồi cho người dùng

  const AudioAnalysisResult({
    required this.quality,
    required this.signalToNoiseRatio,
    required this.voiceActivityRatio,
    required this.averageAmplitude,
    required this.hasClipping,
    required this.tooQuiet,
    required this.tooLoud,
    required this.feedback,
  });

  bool get isGoodQuality => quality == AudioQuality.excellent || quality == AudioQuality.good;
}

class AudioPreprocessingService {
  AudioPreprocessingService._();
  static final AudioPreprocessingService instance = AudioPreprocessingService._();

  // ─── Config ─────────────────────────────────────────────────────
  static const double minVoiceAmplitude = 0.15;      // Ngưỡng phát hiện giọng nói
  static const double maxAmplitude = 0.95;           // Ngưỡng clipping
  static const double minAverageAmplitude = 0.08;    // Âm lượng tối thiểu
  static const double targetAmplitude = 0.6;         // Mục tiêu normalize
  static const double noiseFloor = 0.05;             // Ngưỡng nhiễu nền
  static const int smoothingWindowSize = 5;          // Cửa sổ làm mượt

  // ─── Voice Activity Detection (VAD) ─────────────────────────────
  /// Phát hiện các đoạn có giọng nói trong audio
  /// Trả về danh sách các khoảng thời gian (start, end) có giọng nói
  List<({double start, double end})> detectVoiceActivity({
    required List<double> samples,
    required double sampleRate,
    double threshold = minVoiceAmplitude,
    double minDuration = 0.1, // Tối thiểu 100ms
  }) {
    if (samples.isEmpty) return [];

    final List<({double start, double end})> segments = [];
    bool inVoice = false;
    int voiceStart = 0;

    // Tính energy cho mỗi frame (20ms)
    final frameSize = (sampleRate * 0.02).round(); // 20ms frames
    final hopSize = frameSize ~/ 2; // 50% overlap

    for (int i = 0; i < samples.length - frameSize; i += hopSize) {
      final frame = samples.sublist(i, i + frameSize);
      final energy = _calculateEnergy(frame);

      if (!inVoice && energy > threshold) {
        // Bắt đầu đoạn có giọng nói
        inVoice = true;
        voiceStart = i;
      } else if (inVoice && energy <= threshold) {
        // Kết thúc đoạn có giọng nói
        final duration = (i - voiceStart) / sampleRate;
        if (duration >= minDuration) {
          segments.add((
            start: voiceStart / sampleRate,
            end: i / sampleRate,
          ));
        }
        inVoice = false;
      }
    }

    // Xử lý đoạn cuối nếu vẫn đang trong voice
    if (inVoice) {
      final duration = (samples.length - voiceStart) / sampleRate;
      if (duration >= minDuration) {
        segments.add((
          start: voiceStart / sampleRate,
          end: samples.length / sampleRate,
        ));
      }
    }

    return segments;
  }

  // ─── Noise Reduction ────────────────────────────────────────────
  /// Giảm nhiễu bằng spectral subtraction đơn giản
  /// Trong thực tế, speech_to_text đã xử lý audio ở native layer
  /// Hàm này chủ yếu để phân tích và đánh giá chất lượng
  List<double> reduceNoise(List<double> samples, {double noiseThreshold = noiseFloor}) {
    if (samples.isEmpty) return samples;

    // Ước lượng nhiễu nền từ 100ms đầu (giả sử là khoảng lặng)
    final noiseEstimateSize = math.min(samples.length ~/ 10, 4800); // ~100ms @ 48kHz
    final noiseSamples = samples.sublist(0, noiseEstimateSize);
    final noiseLevel = _calculateRMS(noiseSamples);

    // Áp dụng noise gate đơn giản
    return samples.map((sample) {
      final abs = sample.abs();
      if (abs < noiseLevel * 1.5) {
        return 0.0; // Loại bỏ nhiễu
      }
      return sample;
    }).toList();
  }

  // ─── Audio Normalization ────────────────────────────────────────
  /// Chuẩn hóa âm lượng về mức mục tiêu
  List<double> normalize(List<double> samples, {double target = targetAmplitude}) {
    if (samples.isEmpty) return samples;

    final maxAbs = samples.map((s) => s.abs()).reduce(math.max);
    if (maxAbs < 0.001) return samples; // Tránh chia cho 0

    final gain = target / maxAbs;
    return samples.map((s) => (s * gain).clamp(-1.0, 1.0)).toList();
  }

  // ─── Audio Quality Analysis ─────────────────────────────────────
  /// Phân tích chất lượng audio và đưa ra feedback
  AudioAnalysisResult analyzeQuality({
    required List<double> samples,
    required double sampleRate,
  }) {
    if (samples.isEmpty) {
      return const AudioAnalysisResult(
        quality: AudioQuality.veryPoor,
        signalToNoiseRatio: 0,
        voiceActivityRatio: 0,
        averageAmplitude: 0,
        hasClipping: false,
        tooQuiet: true,
        tooLoud: false,
        feedback: 'Không có dữ liệu âm thanh',
      );
    }

    // 1. Tính các metrics cơ bản
    final avgAmplitude = _calculateRMS(samples);
    final maxAmplitude = samples.map((s) => s.abs()).reduce(math.max);
    final hasClipping = maxAmplitude > AudioPreprocessingService.maxAmplitude;
    final tooQuiet = avgAmplitude < minAverageAmplitude;
    final tooLoud = avgAmplitude > 0.8;

    // 2. Ước lượng SNR (Signal-to-Noise Ratio)
    final noiseEstimateSize = math.min(samples.length ~/ 10, 4800);
    final noiseSamples = samples.sublist(0, noiseEstimateSize);
    final noiseLevel = _calculateRMS(noiseSamples);
    final signalLevel = avgAmplitude;
    final snr = noiseLevel > 0.001
        ? 20 * math.log(signalLevel / noiseLevel) / math.ln10
        : 60.0; // Max SNR nếu noise quá nhỏ

    // 3. Voice Activity Detection
    final voiceSegments = detectVoiceActivity(
      samples: samples,
      sampleRate: sampleRate,
    );
    final totalVoiceTime = voiceSegments.fold<double>(
      0.0,
      (sum, seg) => sum + (seg.end - seg.start),
    );
    final totalTime = samples.length / sampleRate;
    final voiceActivityRatio = totalTime > 0 ? totalVoiceTime / totalTime : 0.0;

    // 4. Đánh giá chất lượng tổng thể
    AudioQuality quality;
    String feedback;

    if (tooQuiet) {
      quality = AudioQuality.veryPoor;
      feedback = '🔇 Giọng nói quá nhỏ. Hãy nói to hơn hoặc đưa micro gần miệng hơn!';
    } else if (hasClipping) {
      quality = AudioQuality.poor;
      feedback = '📢 Giọng nói quá to, bị méo. Hãy nói nhỏ hơn hoặc đưa micro xa miệng!';
    } else if (snr < 10) {
      quality = AudioQuality.poor;
      feedback = '🔊 Nhiễu nền quá lớn. Hãy tìm nơi yên tĩnh hơn để ghi âm!';
    } else if (voiceActivityRatio < 0.2) {
      quality = AudioQuality.fair;
      feedback = '⏱️ Thời gian nói quá ngắn. Hãy nói rõ ràng và đủ dài!';
    } else if (snr >= 20 && voiceActivityRatio >= 0.4 && !tooQuiet && !hasClipping) {
      quality = AudioQuality.excellent;
      feedback = '✨ Chất lượng âm thanh xuất sắc!';
    } else if (snr >= 15 && voiceActivityRatio >= 0.3) {
      quality = AudioQuality.good;
      feedback = '👍 Chất lượng âm thanh tốt!';
    } else {
      quality = AudioQuality.fair;
      feedback = '😊 Chất lượng âm thanh khá, có thể cải thiện thêm!';
    }

    debugPrint('[AudioPreprocessing] Quality: $quality, SNR: ${snr.toStringAsFixed(1)}dB, '
        'VAR: ${(voiceActivityRatio * 100).toStringAsFixed(1)}%, '
        'Avg: ${(avgAmplitude * 100).toStringAsFixed(1)}%');

    return AudioAnalysisResult(
      quality: quality,
      signalToNoiseRatio: snr,
      voiceActivityRatio: voiceActivityRatio,
      averageAmplitude: avgAmplitude,
      hasClipping: hasClipping,
      tooQuiet: tooQuiet,
      tooLoud: tooLoud,
      feedback: feedback,
    );
  }

  // ─── Silence Removal ────────────────────────────────────────────
  /// Loại bỏ khoảng lặng đầu và cuối
  List<double> trimSilence(List<double> samples, {double threshold = noiseFloor}) {
    if (samples.isEmpty) return samples;

    // Tìm điểm bắt đầu có âm thanh
    int start = 0;
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].abs() > threshold) {
        start = i;
        break;
      }
    }

    // Tìm điểm kết thúc có âm thanh
    int end = samples.length - 1;
    for (int i = samples.length - 1; i >= 0; i--) {
      if (samples[i].abs() > threshold) {
        end = i;
        break;
      }
    }

    if (start >= end) return samples;
    return samples.sublist(start, end + 1);
  }

  // ─── Audio Smoothing ────────────────────────────────────────────
  /// Làm mượt audio bằng moving average
  List<double> smooth(List<double> samples, {int windowSize = smoothingWindowSize}) {
    if (samples.isEmpty || windowSize <= 1) return samples;

    final smoothed = <double>[];
    final halfWindow = windowSize ~/ 2;

    for (int i = 0; i < samples.length; i++) {
      final start = math.max(0, i - halfWindow);
      final end = math.min(samples.length, i + halfWindow + 1);
      final window = samples.sublist(start, end);
      final avg = window.reduce((a, b) => a + b) / window.length;
      smoothed.add(avg);
    }

    return smoothed;
  }

  // ─── Helper Methods ─────────────────────────────────────────────

  /// Tính năng lượng (energy) của frame
  double _calculateEnergy(List<double> frame) {
    if (frame.isEmpty) return 0.0;
    return frame.map((s) => s * s).reduce((a, b) => a + b) / frame.length;
  }

  /// Tính RMS (Root Mean Square) - biên độ trung bình
  double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    final sumSquares = samples.map((s) => s * s).reduce((a, b) => a + b);
    return math.sqrt(sumSquares / samples.length);
  }

  /// Tính Zero Crossing Rate - tỷ lệ đổi dấu (hữu ích cho phân biệt voiced/unvoiced)
  double _calculateZCR(List<double> samples) {
    if (samples.length < 2) return 0.0;
    int crossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0 && samples[i - 1] < 0) ||
          (samples[i] < 0 && samples[i - 1] >= 0)) {
        crossings++;
      }
    }
    return crossings / (samples.length - 1);
  }

  // ─── Audio Feedback Generation ──────────────────────────────────

  /// Tạo feedback chi tiết cho người dùng dựa trên phân tích
  String generateDetailedFeedback(AudioAnalysisResult analysis) {
    final tips = <String>[];

    if (analysis.tooQuiet) {
      tips.add('• Nói to hơn hoặc đưa micro gần miệng hơn');
      tips.add('• Kiểm tra âm lượng micro trong cài đặt thiết bị');
    }

    if (analysis.tooLoud || analysis.hasClipping) {
      tips.add('• Nói nhỏ hơn hoặc đưa micro xa miệng');
      tips.add('• Giảm âm lượng micro trong cài đặt');
    }

    if (analysis.signalToNoiseRatio < 15) {
      tips.add('• Tìm nơi yên tĩnh hơn để ghi âm');
      tips.add('• Tắt quạt, điều hòa, TV và các nguồn ồn khác');
      tips.add('• Đóng cửa sổ để giảm tiếng ồn từ bên ngoài');
    }

    if (analysis.voiceActivityRatio < 0.3) {
      tips.add('• Nói rõ ràng và đủ dài');
      tips.add('• Không ngập ngừng quá nhiều');
      tips.add('• Đọc liền mạch từ đầu đến cuối');
    }

    if (tips.isEmpty) {
      return '✨ Chất lượng ghi âm rất tốt! Tiếp tục phát huy nhé!';
    }

    return '${analysis.feedback}\n\nGợi ý cải thiện:\n${tips.join('\n')}';
  }

  // ─── Real-time Audio Monitoring ─────────────────────────────────

  /// Callback để monitor audio realtime (dùng cho UI)
  void Function(double level)? onAudioLevel;
  void Function(bool isVoice)? onVoiceDetected;

  /// Xử lý audio chunk realtime (gọi từ stream)
  void processRealtimeChunk(List<double> chunk, double sampleRate) {
    if (chunk.isEmpty) return;

    // Tính level cho UI
    final level = _calculateRMS(chunk);
    onAudioLevel?.call(level);

    // Phát hiện giọng nói
    final hasVoice = level > minVoiceAmplitude;
    onVoiceDetected?.call(hasVoice);
  }
}
