import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'auth_service.dart';
import '../models/pronunciation_result.dart';

/// Exception ném ra khi tệp âm thanh quá nhỏ, thể hiện người dùng chưa nói gì
class SilenceException implements Exception {
  final String message;
  SilenceException([this.message = "Con chưa nói gì — hãy thử lại nhé!"]);

  @override
  String toString() => message;
}

/// Dịch vụ Ghi âm và Gửi âm thanh lên Backend để đánh giá phát âm
class VoiceRecognitionService {
  // Singleton pattern
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _startTime;
  int _durationMs = 0;

  /// Bắt đầu ghi âm
  void startRecording() async {
    try {
      // 1. Kiểm tra và yêu cầu quyền sử dụng microphone
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/temp_pronunciation.wav';

        // Xóa tệp cũ nếu đã tồn tại để tránh rác tệp tin
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }

        _durationMs = 0;
        _startTime = DateTime.now();

        // 2. Cấu hình ghi âm chuẩn: WAV (LINEAR16), sampleRate: 16000, numChannels: 1 (Mono), bitRate: 128000
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: filePath,
        );
        debugPrint('🎙️ [VoiceRecognitionService] Bắt đầu ghi âm tại: $filePath');
      } else {
        debugPrint('⚠️ [VoiceRecognitionService] Không có quyền truy cập microphone.');
      }
    } catch (e) {
      debugPrint('❌ [VoiceRecognitionService] Lỗi khi startRecording: $e');
    }
  }

  /// Dừng ghi âm và trả về đường dẫn tệp âm thanh vừa ghi
  Future<String?> stopRecording() async {
    try {
      final filePath = await _audioRecorder.stop();
      if (_startTime != null) {
        _durationMs = DateTime.now().difference(_startTime!).inMilliseconds;
      }
      debugPrint('🎙️ [VoiceRecognitionService] Đã dừng ghi âm. Thời lượng: ${_durationMs}ms. Đường dẫn: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ [VoiceRecognitionService] Lỗi khi stopRecording: $e');
      return null;
    }
  }

  /// Upload tệp âm thanh lên backend Node.js để đánh giá phát âm
  Future<PronunciationResult> uploadAudio(String filePath, String targetWord) async {
    // ─── VALIDATION TRƯỚC KHI UPLOAD ───────────────────────────
    final file = File(filePath);

    // 1. Kiểm tra file tồn tại
    if (!await file.exists()) {
      throw Exception("Tệp âm thanh không tồn tại. Con hãy thử nói lại nhé!");
    }

    // 2. Kiểm tra kích thước file >= 10KB (10240 bytes)
    final fileSize = await file.length();
    if (fileSize < 10240) {
      throw SilenceException();
    }

    // 3. Kiểm tra thời lượng ghi âm >= 0.5 giây và <= 30 giây
    final durationSeconds = _durationMs / 1000.0;
    if (durationSeconds < 0.5) {
      throw Exception("Con nói ngắn quá — hãy giữ nút và nói rõ hơn nhé!");
    }
    if (durationSeconds > 30.0) {
      throw Exception("Con nói dài quá — chỉ nói tối đa 30 giây thôi con nhé!");
    }

    // ─── UPLOAD MULTIPART REQUEST ────────────────────────────────
    try {
      final authService = AuthService();
      final url = Uri.parse('${authService.baseUrl}/pronunciation/check');

      final request = http.MultipartRequest('POST', url);

      // Thêm Authorization Header nếu người dùng đã đăng nhập
      if (authService.accessToken != null) {
        request.headers['Authorization'] = 'Bearer ${authService.accessToken}';
      }

      // Thêm Fields
      request.fields['targetWord'] = targetWord;
      request.fields['audioDurationMs'] = _durationMs.toString();

      // Thêm File âm thanh
      request.files.add(
        await http.MultipartFile.fromPath(
          'audioFile',
          filePath,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      debugPrint('📤 [VoiceRecognitionService] Gửi request đánh giá phát âm: $url');
      // Timeout 15 giây cho toàn bộ request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [VoiceRecognitionService] Phản hồi từ backend: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PronunciationResult.fromJson(responseData);
      } else {
        // Parse error message từ backend JSON nếu có
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? 'Lỗi không xác định từ máy chủ.';
          throw Exception(message);
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
          throw Exception("Lỗi máy chủ (${response.statusCode}). Vui lòng thử lại!");
        }
      }
    } on SocketException {
      throw Exception("Không có kết nối mạng");
    } on TimeoutException {
      throw Exception("Máy chủ phản hồi quá chậm");
    } on SilenceException {
      rethrow;
    } catch (e) {
      if (e is SilenceException) rethrow;
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Giải phóng tài nguyên ghi âm khi không còn sử dụng
  void dispose() {
    _audioRecorder.dispose();
  }
}
