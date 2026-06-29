import 'package:flutter/foundation.dart';
import '../data/local/lesson_local_datasource.dart';
import '../data/remote/lesson_remote_datasource.dart';

/// Repository cho Bài Học — Offline-First
/// Load local cache trước → background fetch server → update cache → refresh UI
class LessonRepository {
  static LessonRepository? _instance;

  final LessonLocalDataSource _localDS = LessonLocalDataSource();
  final LessonRemoteDataSource _remoteDS = LessonRemoteDataSource();

  LessonRepository._();

  static LessonRepository get instance {
    _instance ??= LessonRepository._();
    return _instance!;
  }

  /// Tải bài học theo loại — Offline-First Pattern
  /// 1. Return cached ngay (fast UI)
  /// 2. Background fetch server
  /// 3. Update cache
  /// 4. Gọi onUpdate callback để refresh UI
  Future<List<Map<String, dynamic>>> fetchLessonsByType(
    String type, {
    Function(List<Map<String, dynamic>>)? onUpdate,
  }) async {
    // Step 1: Return cached data ngay lập tức
    List<Map<String, dynamic>> cached = await _localDS.getCachedLessons(type);

    if (cached.isNotEmpty) {
      if (kDebugMode) print('[LessonRepo] ⚡ Returning ${cached.length} cached $type lessons');
    }

    // Step 2: Background fetch từ server
    _backgroundFetch(type, onUpdate);

    return cached;
  }

  /// Background fetch + cache update
  Future<void> _backgroundFetch(
    String type,
    Function(List<Map<String, dynamic>>)? onUpdate,
  ) async {
    try {
      final remote = await _remoteDS.fetchLessonsByType(type);

      if (remote.isNotEmpty) {
        // Step 3: Update Isar cache
        await _localDS.cacheLessons(type, remote);

        // Step 4: Notify UI
        if (onUpdate != null) {
          if (kDebugMode) print('[LessonRepo] 🔄 Updated $type lessons from server (${remote.length} items)');
          onUpdate(remote);
        }
      }
    } catch (e) {
      if (kDebugMode) print('[LessonRepo] ⚠️ Background fetch failed for $type: $e');
    }
  }

  /// Force refresh từ server (pull-to-refresh)
  Future<List<Map<String, dynamic>>> forceRefresh(String type) async {
    final remote = await _remoteDS.fetchLessonsByType(type);

    if (remote.isNotEmpty) {
      await _localDS.cacheLessons(type, remote);
      return remote;
    }

    // Fallback to cache
    return await _localDS.getCachedLessons(type);
  }

  /// Lấy 1 bài học theo ID — local first, fallback remote
  Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    // Try local
    final local = await _localDS.getLessonById(lessonId);
    if (local != null) return local;

    // Fallback remote
    return await _remoteDS.fetchLessonById(lessonId);
  }

  /// Kiểm tra có cache không
  Future<bool> hasCachedLessons(String type) async {
    return await _localDS.hasCachedLessons(type);
  }

  /// Xóa cache
  Future<void> clearCache(String type) async {
    await _localDS.clearCache(type);
  }
}
