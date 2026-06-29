import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'isar_models.dart';

/// Quản lý Isar Local Database — Singleton
/// Khởi tạo DB, migration từ SharedPreferences, và cung cấp instance toàn cục
class LocalDatabase {
  static LocalDatabase? _instance;
  static Isar? _isar;

  LocalDatabase._();

  /// Singleton getter — phải gọi init() trước
  static LocalDatabase get instance {
    if (_instance == null) {
      throw StateError('LocalDatabase chưa được khởi tạo! Gọi LocalDatabase.init() trước.');
    }
    return _instance!;
  }

  /// Isar instance
  Isar get isar {
    if (_isar == null) {
      throw StateError('Isar chưa được mở! Gọi LocalDatabase.init() trước.');
    }
    return _isar!;
  }

  /// Khởi tạo Isar database
  /// Gọi 1 lần duy nhất trong main.dart trước runApp()
  static Future<void> init() async {
    if (_instance != null && _isar != null && _isar!.isOpen) {
      if (kDebugMode) print('[LocalDB] Already initialized.');
      return;
    }

    _instance = LocalDatabase._();

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        LessonCacheSchema,
        UserProgressSchema,
        SyncQueueItemSchema,
        GameResultCacheSchema,
        AchievementCacheSchema,
        UserProfileCacheSchema,
      ],
      directory: dir.path,
      name: 'khmerkid_db',
    );

    if (kDebugMode) print('[LocalDB] ✅ Isar database opened at ${dir.path}');

    // One-time migration từ SharedPreferences
    await _instance!._migrateFromSharedPreferences();
  }

  /// Migration từ SharedPreferences sang Isar (chạy 1 lần)
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('_isar_migration_done') ?? false;

    if (migrated) {
      if (kDebugMode) print('[LocalDB] Migration already done. Skipping.');
      return;
    }

    if (kDebugMode) print('[LocalDB] 🔄 Starting migration from SharedPreferences...');

    try {
      // Migrate letter progress
      await _migrateProgress(prefs, 'letter_progress', 'consonant');
      // Migrate vowel progress
      await _migrateProgress(prefs, 'vowel_progress', 'vowel');
      // Migrate number progress
      await _migrateProgress(prefs, 'number_progress', 'number');
      // Migrate reading progress
      await _migrateProgress(prefs, 'reading_progress', 'reading');
      // Migrate diacritical progress
      await _migrateProgress(prefs, 'diacritical_progress', 'diacritical');
      // Migrate spelling progress
      await _migrateProgress(prefs, 'spelling_progress', 'spelling');
      // Migrate writing progress
      await _migrateProgress(prefs, 'writing_progress', 'writing');

      // Migrate cached lessons
      for (final type in ['consonant', 'vowel', 'number', 'coeng', 'vocabulary', 'reading', 'spelling', 'diacritical', 'writing']) {
        await _migrateCachedLessons(prefs, type);
      }

      // Migrate achievements
      await _migrateAchievements(prefs);

      // Migrate game scores
      await _migrateGameScores(prefs);

      // Đánh dấu migration hoàn tất
      await prefs.setBool('_isar_migration_done', true);
      if (kDebugMode) print('[LocalDB] ✅ Migration from SharedPreferences completed!');
    } catch (e) {
      if (kDebugMode) print('[LocalDB] ⚠️ Migration error: $e');
    }
  }

  /// Helper: Migrate progress data (Map<index, stars>) → UserProgress
  Future<void> _migrateProgress(SharedPreferences prefs, String key, String lessonType) async {
    final json = prefs.getString(key);
    if (json == null) return;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final items = <UserProgress>[];

      for (final entry in map.entries) {
        final index = int.tryParse(entry.key) ?? 0;
        final stars = entry.value as int;

        final progress = UserProgress()
          ..userId = 'local' // Sẽ được update khi login
          ..lessonId = '${lessonType}_$index'
          ..lessonType = lessonType
          ..lessonOrder = index
          ..stars = stars
          ..isCompleted = stars > 0
          ..isUnlocked = true
          ..completedAt = stars > 0 ? DateTime.now() : null
          ..isSynced = false
          ..updatedAt = DateTime.now();

        items.add(progress);
      }

      if (items.isNotEmpty) {
        await _isar!.writeTxn(() async {
          await _isar!.userProgress.putAll(items);
        });
        if (kDebugMode) print('[LocalDB] Migrated ${items.length} $lessonType progress entries');
      }
    } catch (e) {
      if (kDebugMode) print('[LocalDB] Error migrating $key: $e');
    }
  }

  /// Helper: Migrate cached lessons JSON → LessonCache
  Future<void> _migrateCachedLessons(SharedPreferences prefs, String type) async {
    final json = prefs.getString('cached_lessons_$type');
    if (json == null) return;

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      final items = <LessonCache>[];

      for (final lesson in decoded) {
        if (lesson is Map<String, dynamic>) {
          final cache = LessonCache()
            ..lessonId = lesson['_id'] ?? lesson['id'] ?? '${type}_${items.length}'
            ..type = type
            ..title = lesson['title'] ?? ''
            ..khmerText = lesson['khmerText'] ?? ''
            ..romanized = lesson['romanized']
            ..meaning = lesson['meaning']
            ..pronunciation = lesson['pronunciation']
            ..description = lesson['description']
            ..difficulty = lesson['difficulty']
            ..order = lesson['order'] ?? items.length
            ..imageUrl = lesson['imageUrl']
            ..audioUrl = lesson['audioUrl']
            ..videoUrl = lesson['videoUrl']
            ..category = lesson['category']
            ..isActive = lesson['isActive'] ?? true
            ..cachedAt = DateTime.now();

          // Store examples/questions/etc as JSON string
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
      }

      if (items.isNotEmpty) {
        await _isar!.writeTxn(() async {
          await _isar!.lessonCaches.putAll(items);
        });
        if (kDebugMode) print('[LocalDB] Migrated ${items.length} cached $type lessons');
      }
    } catch (e) {
      if (kDebugMode) print('[LocalDB] Error migrating cached $type lessons: $e');
    }
  }

  /// Helper: Migrate achievements
  Future<void> _migrateAchievements(SharedPreferences prefs) async {
    final list = prefs.getStringList('achievements_unlocked');
    if (list == null || list.isEmpty) return;

    try {
      final items = list.map((id) => AchievementCache()
        ..userId = 'local'
        ..achievementId = id
        ..isSynced = false
        ..unlockedAt = DateTime.now()
      ).toList();

      await _isar!.writeTxn(() async {
        await _isar!.achievementCaches.putAll(items);
      });
      if (kDebugMode) print('[LocalDB] Migrated ${items.length} achievements');
    } catch (e) {
      if (kDebugMode) print('[LocalDB] Error migrating achievements: $e');
    }
  }

  /// Helper: Migrate game scores
  Future<void> _migrateGameScores(SharedPreferences prefs) async {
    final json = prefs.getString('game_scores');
    if (json == null) return;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final items = <GameResultCache>[];

      for (final entry in map.entries) {
        items.add(GameResultCache()
          ..userId = 'local'
          ..gameType = entry.key
          ..score = entry.value as int
          ..isSynced = false
          ..playedAt = DateTime.now()
        );
      }

      if (items.isNotEmpty) {
        await _isar!.writeTxn(() async {
          await _isar!.gameResultCaches.putAll(items);
        });
        if (kDebugMode) print('[LocalDB] Migrated ${items.length} game scores');
      }
    } catch (e) {
      if (kDebugMode) print('[LocalDB] Error migrating game scores: $e');
    }
  }

  /// Xóa toàn bộ dữ liệu local (khi logout)
  Future<void> clearAll() async {
    await _isar!.writeTxn(() async {
      await _isar!.userProgress.clear();
      await _isar!.syncQueueItems.clear();
      await _isar!.gameResultCaches.clear();
      await _isar!.achievementCaches.clear();
      await _isar!.userProfileCaches.clear();
      // Giữ lại LessonCache vì đây là data chung
    });
    if (kDebugMode) print('[LocalDB] 🗑️ Cleared all user data');
  }

  /// Đóng database (khi app terminate)
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;
    if (kDebugMode) print('[LocalDB] Database closed');
  }
}
