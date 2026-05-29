import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

/// DataSource từ xa cho Bài Học — gọi API MongoDB
class LessonRemoteDataSource {
  AuthService get _auth => AuthService();

  /// Tải danh sách bài học theo loại
  Future<List<Map<String, dynamic>>> fetchLessonsByType(String type) async {
    try {
      final url = Uri.parse('${_auth.baseUrl}/lessons/type/$type');
      if (kDebugMode) print('[LessonRemoteDS] Fetching: $url');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_auth.isAuthenticated) {
        headers['Authorization'] = 'Bearer ${_auth.accessToken}';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['data'] != null) {
          final dynamic dataField = decoded['data'];
          final List<dynamic> lessonsList = dataField is List
              ? dataField
              : (dataField is Map && dataField['lessons'] != null)
                  ? dataField['lessons']
                  : [];
          if (kDebugMode) print('[LessonRemoteDS] Fetched ${lessonsList.length} $type lessons');
          return List<Map<String, dynamic>>.from(lessonsList);
        }
      }

      if (kDebugMode) print('[LessonRemoteDS] Server error: ${response.statusCode}');
      return [];
    } catch (e) {
      if (kDebugMode) print('[LessonRemoteDS] Error: $e');
      return [];
    }
  }

  /// Tải 1 bài học theo ID
  Future<Map<String, dynamic>?> fetchLessonById(String lessonId) async {
    try {
      final url = Uri.parse('${_auth.baseUrl}/lessons/$lessonId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_auth.isAuthenticated) {
        headers['Authorization'] = 'Bearer ${_auth.accessToken}';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('[LessonRemoteDS] Error fetching lesson $lessonId: $e');
      return null;
    }
  }
}
