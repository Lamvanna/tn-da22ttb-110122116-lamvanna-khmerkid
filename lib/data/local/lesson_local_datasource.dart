import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_models.dart';
import 'local_database.dart';

/// DataSource cục bộ cho Bài Học — đọc/ghi cache Isar
class LessonLocalDataSource {
  Isar get _isar => LocalDatabase.instance.isar;

  /// Lưu danh sách bài học vào cache Isar
  Future<void> cacheLessons(String type, List<Map<String, dynamic>> lessons) async {
    final items = <LessonCache>[];

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final cache = LessonCache()
        ..lessonId = lesson['_id'] ?? lesson['id'] ?? '${type}_$i'
        ..type = type
        ..title = lesson['title'] ?? ''
        ..khmerText = lesson['khmerText'] ?? ''
        ..romanized = lesson['romanized']
        ..meaning = lesson['meaning']
        ..pronunciation = lesson['pronunciation']
        ..description = lesson['description']
        ..difficulty = lesson['difficulty']
        ..order = lesson['order'] ?? i
        ..imageUrl = lesson['imageUrl']
        ..audioUrl = lesson['audioUrl']
        ..videoUrl = lesson['videoUrl']
        ..category = lesson['category']
        ..isActive = lesson['isActive'] ?? true
        ..cachedAt = DateTime.now();

      // Extra data (examples, questions, etc.)
      final extra = <String, dynamic>{};
      if (lesson['examples'] != null) extra['examples'] = lesson['examples'];
      if (lesson['questions'] != null) extra['questions'] = lesson['questions'];
      if (lesson['readingLines'] != null) extra['readingLines'] = lesson['readingLines'];
      if (lesson['strokeOrder'] != null) extra['strokeOrder'] = lesson['strokeOrder'];
      if (extra.isNotEmpty) {
        cache.extraDataJson = jsonEncode(extra);
      }

      items.add(cache);
    }

    await _isar.writeTxn(() async {
      // Xóa cache cũ của type này
      await _isar.lessonCaches.filter().typeEqualTo(type).deleteAll();
      // Lưu cache mới
      await _isar.lessonCaches.putAll(items);
    });

    if (kDebugMode) print('[LessonLocalDS] Cached ${items.length} $type lessons');
  }

  /// Đọc cache bài học từ Isar
  Future<List<Map<String, dynamic>>> getCachedLessons(String type) async {
    final items = await _isar.lessonCaches
        .filter()
        .typeEqualTo(type)
        .sortByOrder()
        .findAll();

    return items.map((cache) {
      final map = <String, dynamic>{
        '_id': cache.lessonId,
        'id': cache.lessonId,
        'type': cache.type,
        'title': cache.title,
        'khmerText': cache.khmerText,
        'romanized': cache.romanized,
        'meaning': cache.meaning,
        'pronunciation': cache.pronunciation,
        'description': cache.description,
        'difficulty': cache.difficulty,
        'order': cache.order,
        'imageUrl': cache.imageUrl,
        'audioUrl': cache.audioUrl,
        'videoUrl': cache.videoUrl,
        'category': cache.category,
        'isActive': cache.isActive,
      };

      // Parse extra data
      if (cache.extraDataJson != null) {
        try {
          final extra = jsonDecode(cache.extraDataJson!) as Map<String, dynamic>;
          map.addAll(extra);
        } catch (_) {}
      }

      return map;
    }).toList();
  }

  /// Lấy 1 bài học theo ID
  Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    final cache = await _isar.lessonCaches
        .filter()
        .lessonIdEqualTo(lessonId)
        .findFirst();

    if (cache == null) return null;

    final map = <String, dynamic>{
      '_id': cache.lessonId,
      'id': cache.lessonId,
      'type': cache.type,
      'title': cache.title,
      'khmerText': cache.khmerText,
      'romanized': cache.romanized,
      'meaning': cache.meaning,
      'pronunciation': cache.pronunciation,
      'description': cache.description,
      'difficulty': cache.difficulty,
      'order': cache.order,
      'imageUrl': cache.imageUrl,
      'audioUrl': cache.audioUrl,
      'videoUrl': cache.videoUrl,
      'category': cache.category,
      'isActive': cache.isActive,
    };

    if (cache.extraDataJson != null) {
      try {
        final extra = jsonDecode(cache.extraDataJson!) as Map<String, dynamic>;
        map.addAll(extra);
      } catch (_) {}
    }

    return map;
  }

  /// Xóa cache theo type
  Future<void> clearCache(String type) async {
    await _isar.writeTxn(() async {
      await _isar.lessonCaches.filter().typeEqualTo(type).deleteAll();
    });
    if (kDebugMode) print('[LessonLocalDS] Cleared $type cache');
  }

  /// Xóa toàn bộ cache
  Future<void> clearAllCache() async {
    await _isar.writeTxn(() async {
      await _isar.lessonCaches.clear();
    });
    if (kDebugMode) print('[LessonLocalDS] Cleared all lesson cache');
  }

  /// Kiểm tra cache có tồn tại không
  Future<bool> hasCachedLessons(String type) async {
    final count = await _isar.lessonCaches
        .filter()
        .typeEqualTo(type)
        .count();
    return count > 0;
  }
}
