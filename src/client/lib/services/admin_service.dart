import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Service gọi API Admin — Quản trị hệ thống KhmerKid
/// Sử dụng singleton pattern, gọi các endpoint /api/admin/*
class AdminService {
  // Singleton
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  /// Timeout cho mọi request
  static const Duration _timeout = Duration(seconds: 12);

  /// Timeout dành riêng cho việc tải tệp lên (ảnh, âm thanh, video, pdf)
  static const Duration _uploadTimeout = Duration(seconds: 120);

  /// Base URL lấy từ AuthService
  String get _baseUrl => AuthService().baseUrl;

  /// Access Token lấy từ AuthService
  String? get _token => AuthService().accessToken;

  /// Header chuẩn cho mọi request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Auto-retry request khi gặp 401: refresh token rồi thử lại
  Future<http.Response> _authGet(Uri uri) async {
    var res = await http.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode == 401) {
      debugPrint('🔄 [AdminService] Got 401, trying refreshAccessToken...');
      final refreshed = await AuthService().refreshAccessToken();
      if (refreshed) {
        debugPrint('✅ [AdminService] Token refreshed, retrying...');
        res = await http.get(uri, headers: _headers).timeout(_timeout);
      } else {
        debugPrint('❌ [AdminService] Token refresh failed');
      }
    }
    return res;
  }

  Future<http.Response> _authPost(Uri uri, {Object? body}) async {
    var res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
    if (res.statusCode == 401) {
      final refreshed = await AuthService().refreshAccessToken();
      if (refreshed) {
        res = await http.post(uri, headers: _headers, body: body).timeout(_timeout);
      }
    }
    return res;
  }

  Future<http.Response> _authPut(Uri uri, {Object? body}) async {
    var res = await http.put(uri, headers: _headers, body: body).timeout(_timeout);
    if (res.statusCode == 401) {
      final refreshed = await AuthService().refreshAccessToken();
      if (refreshed) {
        res = await http.put(uri, headers: _headers, body: body).timeout(_timeout);
      }
    }
    return res;
  }

  Future<http.Response> _authDelete(Uri uri) async {
    var res = await http.delete(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode == 401) {
      final refreshed = await AuthService().refreshAccessToken();
      if (refreshed) {
        res = await http.delete(uri, headers: _headers).timeout(_timeout);
      }
    }
    return res;
  }

  // ════════════════════════════════════════════════════════════════════
  // Dashboard & Statistics
  // ════════════════════════════════════════════════════════════════════

  /// Lấy dữ liệu Dashboard tổng quan
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final res = await _authGet(Uri.parse('$_baseUrl/admin/dashboard'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [AdminService] fetchDashboard error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Lấy dữ liệu Thống kê chi tiết
  Future<Map<String, dynamic>> fetchStatistics() async {
    try {
      final res = await _authGet(Uri.parse('$_baseUrl/admin/statistics'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [AdminService] fetchStatistics error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // User Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách Users (phân trang, tìm kiếm)
  Future<Map<String, dynamic>> fetchUsers({int page = 1, int limit = 10, String? search, String? role}) async {
    try {
      final query = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (role != null && role.isNotEmpty) query['role'] = role;

      final uri = Uri.parse('$_baseUrl/admin/users').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'data': body['data'] ?? [],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [AdminService] fetchUsers error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Đổi role user
  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/users/$userId/role'), body: jsonEncode({'role': role}));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      debugPrint('❌ [AdminService] updateUserRole error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Xóa user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/users/$userId'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      debugPrint('❌ [AdminService] deleteUser error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Lesson Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách Lessons (phân trang, filter)
  Future<Map<String, dynamic>> fetchLessons({int page = 1, int limit = 20, String? type, String? search}) async {
    try {
      final query = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/lessons').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [AdminService] fetchLessons error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Tạo Lesson mới
  Future<Map<String, dynamic>> createLesson(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/lessons'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi tạo bài học'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật Lesson
  Future<Map<String, dynamic>> updateLesson(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/lessons/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi cập nhật'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Xóa Lesson
  Future<Map<String, dynamic>> deleteLesson(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/lessons/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi xóa'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Mission Management
  // ════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> fetchMissions({int page = 1, int limit = 20, String? type, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/missions').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> createMission(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/missions'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMission(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/missions/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMission(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/missions/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Badge Management
  // ════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> fetchBadges({int page = 1, int limit = 20, String? type, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/badges').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> createBadge(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/badges'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBadge(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/badges/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteBadge(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/badges/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Tải ảnh lên máy chủ (Cloudinary)
  Future<String?> uploadImage(String filePath) async {
    try {
      final uploadUri = Uri.parse('$_baseUrl/upload/image');
      final request = http.MultipartRequest('POST', uploadUri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('image', file.path));
        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData['data']?['imageUrl'] ?? responseData['imageUrl'];
        }
      }
    } catch (e) {
      debugPrint('❌ [AdminService] uploadImage error: $e');
    }
    return null;
  }

  /// Tải tệp PDF lên máy chủ (Cloudinary)
  Future<String?> uploadPdf(String filePath) async {
    try {
      final uploadUri = Uri.parse('$_baseUrl/upload/pdf');
      final request = http.MultipartRequest('POST', uploadUri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('pdf', file.path));
        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData['data']?['pdfUrl'] ?? responseData['pdfUrl'];
        }
      }
    } catch (e) {
      debugPrint('❌ [AdminService] uploadPdf error: $e');
    }
    return null;
  }

  /// Tải tệp âm thanh (audio) lên máy chủ (Cloudinary)
  Future<String?> uploadAudio(String filePath) async {
    try {
      final uploadUri = Uri.parse('$_baseUrl/upload/audio');
      final request = http.MultipartRequest('POST', uploadUri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('audio', file.path));
        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData['data']?['audioUrl'] ?? responseData['audioUrl'];
        }
      }
    } catch (e) {
      debugPrint('❌ [AdminService] uploadAudio error: $e');
    }
    return null;
  }

  /// Tải tệp video (video) lên máy chủ (Cloudinary)
  Future<String?> uploadVideo(String filePath) async {
    try {
      final uploadUri = Uri.parse('$_baseUrl/upload/video');
      final request = http.MultipartRequest('POST', uploadUri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('video', file.path));
        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData['data']?['videoUrl'] ?? responseData['videoUrl'];
        }
      }
    } catch (e) {
      debugPrint('❌ [AdminService] uploadVideo error: $e');
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════
  // Library Item Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách Library Items (Admin)
  Future<Map<String, dynamic>> fetchLibraryItems({int page = 1, int limit = 20, String? type, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/library').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Tạo Library Item mới (Admin)
  Future<Map<String, dynamic>> createLibraryItem(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/library'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật Library Item (Admin)
  Future<Map<String, dynamic>> updateLibraryItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/library/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Xóa Library Item (Admin)
  Future<Map<String, dynamic>> deleteLibraryItem(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/library/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy danh sách Library Items (User - Public)
  Future<Map<String, dynamic>> fetchLibraryItemsForUser({int page = 1, int limit = 20, String? type, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/library').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Game Question Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách Game Questions (Admin)
  Future<Map<String, dynamic>> fetchGameQuestions({int page = 1, int limit = 50, String? gameKey, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (gameKey != null && gameKey.isNotEmpty) query['gameKey'] = gameKey;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/game-questions').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Tạo Game Question mới (Admin)
  Future<Map<String, dynamic>> createGameQuestion(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/game-questions'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật Game Question (Admin)
  Future<Map<String, dynamic>> updateGameQuestion(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/game-questions/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Xóa Game Question (Admin)
  Future<Map<String, dynamic>> deleteGameQuestion(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/game-questions/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy danh sách câu hỏi chơi game (User - Public)
  Future<Map<String, dynamic>> fetchGameQuestionsForUser(String gameKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/games/questions?gameKey=$gameKey');
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Test Question Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách Test Questions (Admin)
  Future<Map<String, dynamic>> fetchTestQuestions({int page = 1, int limit = 50, String? testRange, String? search}) async {
    try {
      final query = <String, String>{'page': '$page', 'limit': '$limit'};
      if (testRange != null && testRange.isNotEmpty) query['testRange'] = testRange;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/test-questions').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? [], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Tạo Test Question mới (Admin)
  Future<Map<String, dynamic>> createTestQuestion(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(Uri.parse('$_baseUrl/admin/test-questions'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật Test Question (Admin)
  Future<Map<String, dynamic>> updateTestQuestion(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authPut(Uri.parse('$_baseUrl/admin/test-questions/$id'), body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Xóa Test Question (Admin)
  Future<Map<String, dynamic>> deleteTestQuestion(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/test-questions/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Notification Management
  // ════════════════════════════════════════════════════════════════════

  /// Lấy danh sách thông báo quản trị (Admin)
  Future<Map<String, dynamic>> fetchAdminNotifications({int page = 1, int limit = 10, String? search}) async {
    try {
      final query = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) query['search'] = search;

      final uri = Uri.parse('$_baseUrl/admin/notifications').replace(queryParameters: query);
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'data': body['data'] ?? [],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [AdminService] fetchAdminNotifications error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Gửi thông báo hệ thống mới (Admin)
  Future<Map<String, dynamic>> sendNotification(Map<String, dynamic> data) async {
    try {
      final res = await _authPost(
        Uri.parse('$_baseUrl/admin/notifications'),
        body: jsonEncode(data),
      );

      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      debugPrint('❌ [AdminService] sendNotification error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Xóa thông báo (Admin)
  Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      final res = await _authDelete(Uri.parse('$_baseUrl/admin/notifications/$id'));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': body['message'] ?? 'Lỗi'};
    } catch (e) {
      debugPrint('❌ [AdminService] deleteNotification error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Lấy danh sách câu hỏi kiểm tra cho học sinh (User - Public)
  Future<Map<String, dynamic>> fetchTestQuestionsForUser(String testRange) async {
    try {
      final uri = Uri.parse('$_baseUrl/tests/questions?testRange=$testRange');
      final res = await _authGet(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
