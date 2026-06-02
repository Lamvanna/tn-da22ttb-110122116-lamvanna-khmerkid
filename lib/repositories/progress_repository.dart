import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/local/progress_local_datasource.dart';
import '../data/local/sync_queue_datasource.dart';
import '../data/remote/progress_remote_datasource.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Repository cho Tiến Độ Học — Offline-First, Database-Driven
/// MongoDB = source of truth, Isar = local cache + offline support
class ProgressRepository {
  static ProgressRepository? _instance;

  final ProgressLocalDataSource _localDS = ProgressLocalDataSource();
  final ProgressRemoteDataSource _remoteDS = ProgressRemoteDataSource();
  final SyncQueueDataSource _syncQueue = SyncQueueDataSource();

  /// Stream controller để notify UI khi progress thay đổi
  final _progressController = StreamController<void>.broadcast();
  Stream<void> get onProgressChanged => _progressController.stream;

  ProgressRepository._();

  static ProgressRepository get instance {
    _instance ??= ProgressRepository._();
    return _instance!;
  }

  /// User ID hiện tại
  String get _userId {
    final profile = AuthService().userProfile;
    return profile?['_id']?.toString() ?? profile?['id']?.toString() ?? 'local';
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPLETE LESSON — Core flow
  // ═══════════════════════════════════════════════════════════════

  /// Hoàn thành bài học — Offline-First
  /// 1. Save local ngay → UI update tức thì
  /// 2. Auto-unlock next lesson trong local
  /// 3. Queue sync → background push MongoDB
  Future<void> completeLesson({
    required String lessonId,
    required String lessonType,
    required int lessonOrder,
    required int stars,
  }) async {
    final userId = _userId;

    // Step 1: Save local NGAY LẬP TỨC
    await _localDS.saveProgress(
      userId: userId,
      lessonId: lessonId,
      lessonType: lessonType,
      lessonOrder: lessonOrder,
      stars: stars,
      isCompleted: true,
      isUnlocked: true,
    );

    if (kDebugMode) print('[ProgressRepo] ✅ Lesson $lessonId completed locally (⭐$stars)');

    // Step 2: Auto-unlock next lesson
    await _autoUnlockNext(userId, lessonType, lessonOrder);

    // Step 3: Notify UI
    _progressController.add(null);

    // Step 4: Queue sync to server (background)
    await _syncQueue.addToQueue(
      action: 'complete_lesson',
      payload: {
        'lessonId': lessonId,
        'lessonType': lessonType,
        'lessonOrder': lessonOrder,
        'stars': stars,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );

    // Step 5: Try immediate sync if online
    _tryImmediateSync(lessonId, stars, lessonType);
  }

  /// Auto-unlock bài tiếp theo
  Future<void> _autoUnlockNext(String userId, String lessonType, int currentOrder) async {
    final nextOrder = currentOrder + 1;
    // Tạo ID dự kiến cho bài tiếp theo
    final nextLessonId = '${lessonType}_$nextOrder';

    await _localDS.unlockLesson(
      userId: userId,
      lessonId: nextLessonId,
      lessonType: lessonType,
      lessonOrder: nextOrder,
    );

    if (kDebugMode) print('[ProgressRepo] 🔓 Auto-unlocked next: $nextLessonId');
  }

  /// Try sync ngay nếu có mạng
  Future<void> _tryImmediateSync(String lessonId, int stars, String lessonType) async {
    try {
      final result = await _remoteDS.completeLesson(
        lessonId: lessonId,
        stars: stars,
        lessonType: lessonType,
      );

      if (result != null) {
        if (kDebugMode) print('[ProgressRepo] 🔄 Synced lesson completion to server');
        // Refresh profile
        await AuthService().fetchProfile();
      }
    } catch (e) {
      if (kDebugMode) print('[ProgressRepo] ⚠️ Immediate sync failed (will retry): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // READ PROGRESS — Fast from Isar
  // ═══════════════════════════════════════════════════════════════

  /// Lấy danh sách bài đã hoàn thành
  Future<List<String>> getCompletedLessonIds() async {
    return await _localDS.getCompletedLessonIds(_userId);
  }

  /// Lấy danh sách bài đã mở khóa
  Future<List<String>> getUnlockedLessonIds() async {
    return await _localDS.getUnlockedLessonIds(_userId);
  }

  /// Kiểm tra bài đã unlock chưa
  Future<bool> isLessonUnlocked(String lessonId) async {
    return await _localDS.isLessonUnlocked(_userId, lessonId);
  }

  /// Kiểm tra bài đã hoàn thành chưa
  Future<bool> isLessonCompleted(String lessonId) async {
    return await _localDS.isLessonCompleted(_userId, lessonId);
  }

  /// Lấy progress map {index: stars} cho tương thích ngược
  Future<Map<int, int>> getProgressMap(String lessonType) async {
    return await _localDS.getProgressMap(_userId, lessonType);
  }

  /// Lấy tất cả progress theo loại bài
  Future<List<Map<String, dynamic>>> getProgressByType(String lessonType) async {
    final items = await _localDS.getProgressByType(_userId, lessonType);
    return items.map((p) => {
      'lessonId': p.lessonId,
      'lessonType': p.lessonType,
      'lessonOrder': p.lessonOrder,
      'stars': p.stars,
      'isCompleted': p.isCompleted,
      'isUnlocked': p.isUnlocked,
      'completedAt': p.completedAt?.toIso8601String(),
    }).toList();
  }

  /// Đếm số bài hoàn thành theo loại
  Future<int> getCompletedCount(String lessonType) async {
    return await _localDS.getCompletedCountByType(_userId, lessonType);
  }

  // ═══════════════════════════════════════════════════════════════
  // SYNC — Full bidirectional sync với MongoDB
  // ═══════════════════════════════════════════════════════════════

  /// Full sync — gọi khi login hoặc khi có mạng lại
  Future<void> fullSync() async {
    final userId = _userId;
    if (userId == 'local') {
      if (kDebugMode) print('[ProgressRepo] ⚠️ Not logged in, skipping sync');
      return;
    }

    try {
      // 1. Lấy local progress chưa sync
      final unsyncedProgress = await _localDS.getUnsyncedProgress(userId);
      final localData = unsyncedProgress.map((p) => {
        'lessonId': p.lessonId,
        'lessonType': p.lessonType,
        'lessonOrder': p.lessonOrder,
        'stars': p.stars,
        'isCompleted': p.isCompleted,
        'isUnlocked': p.isUnlocked,
        'completedAt': p.completedAt?.toIso8601String(),
      }).toList();

      // 2. Gửi lên server + nhận merged result
      final serverResult = await _remoteDS.syncProgress({
        'completedLessons': localData,
        'lastSyncAt': DateTime.now().toIso8601String(),
      });

      if (serverResult != null) {
        // 3. Update local với merged data từ server
        final serverLessons = serverResult['completedLessons'] as List<dynamic>? ?? [];
        final progressList = serverLessons.map((l) => Map<String, dynamic>.from(l as Map)).toList();
        await _localDS.bulkSaveProgress(userId, progressList);

        // 4. Đánh dấu đã sync
        final ids = unsyncedProgress.map((p) => p.id).toList();
        await _localDS.markSynced(ids);

        // 5. Update profile cache
        if (serverResult['profile'] != null) {
          await _localDS.saveProfileCache(userId, Map<String, dynamic>.from(serverResult['profile'] as Map));
        }

        // 6. Notify UI
        _progressController.add(null);

        if (kDebugMode) print('[ProgressRepo] ✅ Full sync completed! (${progressList.length} lessons merged)');
      }
    } catch (e) {
      if (kDebugMode) print('[ProgressRepo] ⚠️ Full sync failed: $e');
    }
  }

  /// Save profile cache vào Isar
  Future<void> saveProfileCache(Map<String, dynamic> profile) async {
    await _localDS.saveProfileCache(_userId, profile);
  }

  /// Đồng bộ tiến độ từ local Isar sang SharedPreferences
  Future<void> syncLocalProgressToSharedPreferences() async {
    try {
      final storage = await StorageService.getInstance();
      
      final consonants = await getProgressByType('consonant');
      for (final p in consonants) {
        await storage.saveLetterProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final vowels = await getProgressByType('vowel');
      for (final p in vowels) {
        await storage.saveVowelProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final numbers = await getProgressByType('number');
      for (final p in numbers) {
        await storage.saveNumberProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final readings = await getProgressByType('reading');
      for (final p in readings) {
        await storage.saveReadingProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final diacriticals = await getProgressByType('diacritical');
      for (final p in diacriticals) {
        await storage.saveDiacriticalProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final spellings = await getProgressByType('spelling');
      for (final p in spellings) {
        await storage.saveSpellingProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      
      final writings = await getProgressByType('writing');
      for (final p in writings) {
        await storage.saveWritingProgress(p['lessonOrder'] as int, p['stars'] as int);
      }
      if (kDebugMode) print('[ProgressRepo] ✅ Synced local progress from Isar to StorageService SharedPreferences');
    } catch (e) {
      if (kDebugMode) print('[ProgressRepo] ⚠️ Error syncing Isar to SharedPreferences: $e');
    }
  }

  /// Xóa dữ liệu khi logout
  Future<void> clearUserData() async {
    await _localDS.clearUserProgress(_userId);
    _progressController.add(null);
  }

  void dispose() {
    _progressController.close();
  }
}
