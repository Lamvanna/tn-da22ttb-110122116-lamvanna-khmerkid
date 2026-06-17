import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const Duration _timeout = Duration(seconds: 12);

  String get _baseUrl => AuthService().baseUrl;
  String? get _token => AuthService().accessToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Lấy danh sách thông báo của người dùng hiện tại
  Future<Map<String, dynamic>> fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications'), 
        headers: _headers
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body['data'] ?? [];
        final notifications = list.map((item) => AppNotification.fromJson(item)).toList();
        return {'success': true, 'data': notifications};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [NotificationService] fetchNotifications error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: _headers,
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [NotificationService] markAsRead error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: _headers,
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Lỗi ${res.statusCode}'};
    } catch (e) {
      debugPrint('❌ [NotificationService] markAllAsRead error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }
}
