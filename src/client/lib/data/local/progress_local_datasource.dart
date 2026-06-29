import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_models.dart';
import 'local_database.dart';

/// DataSource cục bộ cho Tiến Độ Học — đọc/ghi progress trong Isar
class ProgressLocalDataSource {
  Isar get _isar => LocalDatabase.instance.isar;

  // ─── SAVE PROGRESS ────────────────────────────────────────────

  /// Lưu hoặc cập nhật tiến độ 1 bài học
  Future<void> saveProgress({
    required String userId,
    required String lessonId,
    required String lessonType,
    required int lessonOrder,
    required int stars,
    required bool isCompleted,
    required bool isUnlocked,
  }) async {
    await _isar.writeTxn(() async {
      // Tìm progress hiện tại
      final existing = await _isar.userProgress
          .filter()
          .userIdEqualTo(userId)
          .lessonIdEqualTo(lessonId)
          .findFirst();

      if (existing != null) {
        // Update — chỉ update nếu stars mới cao hơn (take-max)
        existing.stars = existing.stars > stars ? existing.stars : stars;
        existing.isCompleted = existing.isCompleted || isCompleted;
        existing.isUnlocked = existing.isUnlocked || isUnlocked;
        existing.lessonOrder = lessonOrder;
        existing.lessonType = lessonType;
        if (isCompleted && existing.completedAt == null) {
          existing.completedAt = DateTime.now();
        }
        existing.isSynced = false;
        existing.updatedAt = DateTime.now();
        await _isar.userProgress.put(existing);
      } else {
        // Insert mới
        final progress = UserProgress()
          ..userId = userId
          ..lessonId = lessonId
          ..lessonType = lessonType
          ..lessonOrder = lessonOrder
          ..stars = stars
          ..isCompleted = isCompleted
          ..isUnlocked = isUnlocked
          ..completedAt = isCompleted ? DateTime.now() : null
          ..isSynced = false
          ..updatedAt = DateTime.now();
        await _isar.userProgress.put(progress);
      }
    });
  }

  /// Bulk save/update progress (khi sync từ server)
  Future<void> bulkSaveProgress(String userId, List<Map<String, dynamic>> progressList) async {
    await _isar.writeTxn(() async {
      // 1. Xóa các record đã sync cục bộ nhưng không còn tồn tại trên server (bị reset trên server)
      final localSynced = await _isar.userProgress
          .filter()
          .userIdEqualTo(userId)
          .isSyncedEqualTo(true)
          .findAll();

      final serverLessonIds = progressList.map((p) => p['lessonId']?.toString() ?? '').toSet();

      final toDelete = localSynced.where((p) => !serverLessonIds.contains(p.lessonId)).map((p) => p.id).toList();
      if (toDelete.isNotEmpty) {
        await _isar.userProgress.deleteAll(toDelete);
        if (kDebugMode) {
          print('[Isar] Deleted ${toDelete.length} legacy synced records because they are not on server.');
        }
      }

      // 2. Lưu hoặc cập nhật dữ liệu từ server
      for (final p in progressList) {
        final lessonId = p['lessonId'] as String;

        // Nếu lessonId là ObjectId, tìm và xóa bản ghi custom ID tương ứng (nếu có) để tránh nhân đôi dữ liệu
        if (lessonId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(lessonId)) {
          final type = p['lessonType'] as String? ?? '';
          final order = (p['lessonOrder'] as num?)?.toInt() ?? 0;
          if (type.isNotEmpty) {
            final legacyId = '${type}_$order';
            await _isar.userProgress
                .filter()
                .userIdEqualTo(userId)
                .lessonIdEqualTo(legacyId)
                .deleteAll();
          }
        }

        final existing = await _isar.userProgress
            .filter()
            .userIdEqualTo(userId)
            .lessonIdEqualTo(lessonId)
            .findFirst();

        final stars = (p['stars'] as num?)?.toInt() ?? 0;
        final isCompleted = p['isCompleted'] as bool? ?? false;
        final isUnlocked = p['isUnlocked'] as bool? ?? false;

        if (existing != null) {
          // Merge — take max strategy
          existing.stars = existing.stars > stars ? existing.stars : stars;
          existing.isCompleted = existing.isCompleted || isCompleted;
          existing.isUnlocked = existing.isUnlocked || isUnlocked;
          existing.lessonOrder = (p['lessonOrder'] as num?)?.toInt() ?? existing.lessonOrder;
          if (p['lessonType'] != null && (p['lessonType'] as String).isNotEmpty) {
            existing.lessonType = p['lessonType'] as String;
          }
          existing.isSynced = true;
          existing.updatedAt = DateTime.now();
          await _isar.userProgress.put(existing);
        } else {
          final progress = UserProgress()
            ..userId = userId
            ..lessonId = lessonId
            ..lessonType = p['lessonType'] as String? ?? ''
            ..lessonOrder = (p['lessonOrder'] as num?)?.toInt() ?? 0
            ..stars = stars
            ..isCompleted = isCompleted
            ..isUnlocked = isUnlocked
            ..completedAt = isCompleted ? DateTime.now() : null
            ..isSynced = true
            ..updatedAt = DateTime.now();
          await _isar.userProgress.put(progress);
        }
      }
    });
  }

  // ─── READ PROGRESS ────────────────────────────────────────────

  /// Lấy danh sách bài đã hoàn thành
  Future<List<String>> getCompletedLessonIds(String userId) async {
    final items = await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .isCompletedEqualTo(true)
        .findAll();
    return items.map((e) => e.lessonId).toList();
  }

  /// Lấy danh sách bài đã mở khóa
  Future<List<String>> getUnlockedLessonIds(String userId) async {
    final items = await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .isUnlockedEqualTo(true)
        .findAll();
    return items.map((e) => e.lessonId).toList();
  }

  /// Lấy progress của 1 bài
  Future<UserProgress?> getProgress(String userId, String lessonId) async {
    return await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .lessonIdEqualTo(lessonId)
        .findFirst();
  }

  /// Lấy tất cả progress theo loại bài
  Future<List<UserProgress>> getProgressByType(String userId, String lessonType) async {
    return await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .lessonTypeEqualTo(lessonType)
        .sortByLessonOrder()
        .findAll();
  }

  /// Lấy toàn bộ progress
  Future<List<UserProgress>> getAllProgress(String userId) async {
    return await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .findAll();
  }

  /// Kiểm tra bài đã unlock chưa
  Future<bool> isLessonUnlocked(String userId, String lessonId) async {
    final progress = await getProgress(userId, lessonId);
    return progress?.isUnlocked ?? false;
  }

  /// Kiểm tra bài đã hoàn thành chưa
  Future<bool> isLessonCompleted(String userId, String lessonId) async {
    final progress = await getProgress(userId, lessonId);
    return progress?.isCompleted ?? false;
  }

  /// Đếm số bài đã hoàn thành theo loại
  Future<int> getCompletedCountByType(String userId, String lessonType) async {
    final items = await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .lessonTypeEqualTo(lessonType)
        .isCompletedEqualTo(true)
        .findAll();
    return items.map((e) => e.lessonOrder).toSet().length;
  }

  Future<Map<int, int>> getProgressMap(String userId, String lessonType) async {
    final items = await getProgressByType(userId, lessonType);
    final map = <int, int>{};
    for (final item in items) {
      if (item.isCompleted) {
        map[item.lessonOrder] = item.stars;
      }
    }
    return map;
  }

  // ─── UNLOCK ───────────────────────────────────────────────────

  /// Mở khóa bài tiếp theo
  Future<void> unlockLesson({
    required String userId,
    required String lessonId,
    required String lessonType,
    required int lessonOrder,
  }) async {
    await saveProgress(
      userId: userId,
      lessonId: lessonId,
      lessonType: lessonType,
      lessonOrder: lessonOrder,
      stars: 0,
      isCompleted: false,
      isUnlocked: true,
    );
  }

  // ─── SYNC HELPERS ─────────────────────────────────────────────

  /// Lấy danh sách progress chưa sync
  Future<List<UserProgress>> getUnsyncedProgress(String userId) async {
    return await _isar.userProgress
        .filter()
        .userIdEqualTo(userId)
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Đánh dấu đã sync
  Future<void> markSynced(List<int> ids) async {
    await _isar.writeTxn(() async {
      for (final id in ids) {
        final item = await _isar.userProgress.get(id);
        if (item != null) {
          item.isSynced = true;
          await _isar.userProgress.put(item);
        }
      }
    });
  }

  // ─── PROFILE CACHE ────────────────────────────────────────────

  /// Lưu profile cache
  Future<void> saveProfileCache(String userId, Map<String, dynamic> profile) async {
    await _isar.writeTxn(() async {
      final cache = UserProfileCache()
        ..userId = userId
        ..name = profile['name'] ?? ''
        ..email = profile['email'] ?? ''
        ..avatar = profile['avatar']
        ..xp = (profile['xp'] as num?)?.toInt() ?? 0
        ..stars = (profile['stars'] as num?)?.toInt() ?? 0
        ..streak = (profile['streak'] as num?)?.toInt() ?? 0
        ..longestStreak = (profile['longestStreak'] as num?)?.toInt() ?? 0
        ..level = (profile['level'] as num?)?.toInt() ?? 1
        ..rank = (profile['rank'] as num?)?.toInt() ?? 0
        ..totalLessonsCompleted = (profile['learningProgress']?['totalLessonsCompleted'] as num?)?.toInt() ?? 0
        ..totalGamesPlayed = (profile['learningProgress']?['totalGamesPlayed'] as num?)?.toInt() ?? 0
        ..totalStudyTime = (profile['learningProgress']?['totalStudyTime'] as num?)?.toInt() ?? 0
        ..listeningLevel = (profile['learningProgress']?['listeningLevel'] as num?)?.toInt() ?? 0
        ..speakingLevel = (profile['learningProgress']?['speakingLevel'] as num?)?.toInt() ?? 0
        ..readingLevel = (profile['learningProgress']?['readingLevel'] as num?)?.toInt() ?? 0
        ..writingLevel = (profile['learningProgress']?['writingLevel'] as num?)?.toInt() ?? 0
        ..cachedAt = DateTime.now()
        ..lastSyncAt = DateTime.now();

      // Completed lessons
      final completedLessons = profile['learningProgress']?['completedLessons'];
      if (completedLessons is List) {
        cache.completedLessonsJson = jsonEncode(completedLessons.map((e) => e.toString()).toList());
      }

      await _isar.userProfileCaches.put(cache);
    });
  }

  /// Đọc profile cache
  Future<UserProfileCache?> getProfileCache(String userId) async {
    return await _isar.userProfileCaches
      .filter()
      .userIdEqualTo(userId)
      .findFirst();
  }

  // ─── CLEANUP ──────────────────────────────────────────────────

  /// Xóa toàn bộ progress của user
  Future<void> clearUserProgress(String userId) async {
    await _isar.writeTxn(() async {
      await _isar.userProgress.filter().userIdEqualTo(userId).deleteAll();
      await _isar.userProfileCaches.filter().userIdEqualTo(userId).deleteAll();
      await _isar.achievementCaches.filter().userIdEqualTo(userId).deleteAll();
      await _isar.gameResultCaches.filter().userIdEqualTo(userId).deleteAll();
    });
  }
}
