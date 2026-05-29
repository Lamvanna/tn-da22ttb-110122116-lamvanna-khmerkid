import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

/// DataSource từ xa cho Progress — gọi API đồng bộ progress với MongoDB
class ProgressRemoteDataSource {
  AuthService get _auth => AuthService();

  /// Lấy toàn bộ progress từ server
  Future<Map<String, dynamic>?> fetchProgress() async {
    if (!_auth.isAuthenticated) return null;

    try {
      final url = Uri.parse('${_auth.baseUrl}/progress/get');
      if (kDebugMode) print('[ProgressRemoteDS] Fetching progress: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth.accessToken}',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (kDebugMode) print('[ProgressRemoteDS] ✅ Fetched progress successfully');
        return decoded['data'] as Map<String, dynamic>?;
      }

      if (kDebugMode) print('[ProgressRemoteDS] Server error: ${response.statusCode}');
      return null;
    } catch (e) {
      if (kDebugMode) print('[ProgressRemoteDS] Error fetching progress: $e');
      return null;
    }
  }

  /// Đồng bộ progress 2 chiều (gửi local + nhận server)
  Future<Map<String, dynamic>?> syncProgress(Map<String, dynamic> clientData) async {
    if (!_auth.isAuthenticated) return null;

    try {
      final url = Uri.parse('${_auth.baseUrl}/progress/sync');
      if (kDebugMode) print('[ProgressRemoteDS] Syncing progress: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth.accessToken}',
        },
        body: jsonEncode(clientData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (kDebugMode) print('[ProgressRemoteDS] ✅ Sync completed');
        return decoded['data'] as Map<String, dynamic>?;
      }

      if (kDebugMode) print('[ProgressRemoteDS] Sync failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      if (kDebugMode) print('[ProgressRemoteDS] Error syncing: $e');
      return null;
    }
  }

  /// Hoàn thành 1 bài học trên server
  Future<Map<String, dynamic>?> completeLesson({
    required String lessonId,
    required int stars,
    required String lessonType,
  }) async {
    if (!_auth.isAuthenticated) return null;

    try {
      final url = Uri.parse('${_auth.baseUrl}/progress/complete');
      if (kDebugMode) print('[ProgressRemoteDS] Completing lesson: $lessonId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth.accessToken}',
        },
        body: jsonEncode({
          'lessonId': lessonId,
          'stars': stars,
          'lessonType': lessonType,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (kDebugMode) print('[ProgressRemoteDS] ✅ Lesson completed on server');
        return decoded['data'] as Map<String, dynamic>?;
      }

      if (kDebugMode) print('[ProgressRemoteDS] Complete failed: ${response.statusCode}');
      return null;
    } catch (e) {
      if (kDebugMode) print('[ProgressRemoteDS] Error completing lesson: $e');
      return null;
    }
  }

  /// Mở khóa bài học trên server
  Future<bool> unlockLesson(String lessonId) async {
    if (!_auth.isAuthenticated) return false;

    try {
      final url = Uri.parse('${_auth.baseUrl}/progress/unlock');
      if (kDebugMode) print('[ProgressRemoteDS] Unlocking lesson: $lessonId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth.accessToken}',
        },
        body: jsonEncode({'lessonId': lessonId}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) print('[ProgressRemoteDS] ✅ Lesson unlocked on server');
        return true;
      }

      if (kDebugMode) print('[ProgressRemoteDS] Unlock failed: ${response.statusCode}');
      return false;
    } catch (e) {
      if (kDebugMode) print('[ProgressRemoteDS] Error unlocking: $e');
      return false;
    }
  }
}
