import 'dart:convert';

/// Model đại diện cho kết quả chấm điểm phát âm từ Backend Node.js
class PronunciationResult {
  final String targetWord;
  final String recognizedText;
  final double confidence;
  final double similarityPercentage;
  final double finalScore;
  final bool isCorrect;
  final String feedback;
  final String attemptId;
  final bool isSTTEmpty; // true nếu Google STT không nhận dạng được gì

  PronunciationResult({
    required this.targetWord,
    required this.recognizedText,
    required this.confidence,
    required this.similarityPercentage,
    required this.finalScore,
    required this.isCorrect,
    required this.feedback,
    required this.attemptId,
    required this.isSTTEmpty,
  });

  /// Factory constructor để tạo đối tượng từ JSON map
  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      targetWord: json['targetWord'] ?? '',
      recognizedText: json['recognizedText'] ?? '',
      // Đảm bảo ép kiểu double an toàn khi JSON trả về dạng int hoặc double
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      similarityPercentage: (json['similarityPercentage'] ?? 0.0).toDouble(),
      finalScore: (json['finalScore'] ?? 0.0).toDouble(),
      isCorrect: json['isCorrect'] ?? false,
      feedback: json['feedback'] ?? '',
      attemptId: json['attemptId'] ?? '',
      isSTTEmpty: json['isSTTEmpty'] ?? false,
    );
  }

  /// Chuyển đối tượng thành JSON map
  Map<String, dynamic> toJson() {
    return {
      'targetWord': targetWord,
      'recognizedText': recognizedText,
      'confidence': confidence,
      'similarityPercentage': similarityPercentage,
      'finalScore': finalScore,
      'isCorrect': isCorrect,
      'feedback': feedback,
      'attemptId': attemptId,
      'isSTTEmpty': isSTTEmpty,
    };
  }

  @override
  String toString() {
    return 'PronunciationResult(targetWord: $targetWord, recognizedText: $recognizedText, score: $finalScore, isCorrect: $isCorrect)';
  }
}
