import 'package:flutter/foundation.dart';
import '../repositories/lesson_repository.dart';
import 'storage_service.dart';

/// Dịch vụ quản lý Bài học — Hybrid Offline-First
/// Delegates to LessonRepository (Isar cache + MongoDB remote)
/// Giữ backward-compatible API cho các screen hiện tại
class LessonService {
  static LessonService? _instance;
  late StorageService _storage;
  final LessonRepository _repo = LessonRepository.instance;

  LessonService._();

  static Future<LessonService> getInstance() async {
    if (_instance == null) {
      _instance = LessonService._();
      _instance!._storage = await StorageService.getInstance();
    }
    return _instance!;
  }

  /// Tải danh sách bài học theo loại — Offline-First
  /// 1. Return cached Isar data ngay
  /// 2. Background fetch MongoDB
  /// 3. Update Isar cache
  /// 4. Gọi onUpdate callback để refresh UI
  Future<List<Map<String, dynamic>>> fetchLessonsByType(
    String type, {
    Function(List<Map<String, dynamic>>)? onUpdate,
  }) async {
    try {
      if (kDebugMode) print('[LessonService] Fetching $type lessons (offline-first)');

      final lessons = await _repo.fetchLessonsByType(
        type,
        onUpdate: onUpdate,
      );

      if (lessons.isNotEmpty) {
        // Backward compat: cũng lưu vào SharedPrefs (sẽ phase-out dần)
        // await _storage.saveCachedLessons(type, jsonEncode(lessons));
        return lessons;
      }

      // Nếu Isar cache trống, thử force refresh
      if (kDebugMode) print('[LessonService] Isar cache empty, force refreshing...');
      return await _repo.forceRefresh(type);
    } catch (e) {
      if (kDebugMode) print('[LessonService] Error: $e');
      return [];
    }
  }
}
