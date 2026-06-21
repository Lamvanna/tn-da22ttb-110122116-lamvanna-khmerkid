import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/local/progress_local_datasource.dart';
import '../data/local/sync_queue_datasource.dart';
import '../data/remote/progress_remote_datasource.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/local_notification_service.dart';
import '../services/sync_manager.dart';
import '../models/khmer_letter.dart';
import '../models/khmer_vowel.dart';
import '../models/khmer_number.dart';
import 'lesson_repository.dart';
import '../services/connectivity_service.dart';

/// Repository cho Tiến Độ Học — Offline-First, Database-Driven
/// MongoDB = source of truth, Isar = local cache + offline support
class ProgressRepository {
  static ProgressRepository? _instance;

  final ProgressLocalDataSource _localDS = ProgressLocalDataSource();
  final ProgressRemoteDataSource _remoteDS = ProgressRemoteDataSource();
  final SyncQueueDataSource _syncQueue = SyncQueueDataSource();

  // RAM cache for completed lessons to bypass local database entirely
  List<dynamic> _completedLessonsCache = [];
  bool _hasLoaded = false;

  /// Stream controller để notify UI khi progress thay đổi
  final _progressController = StreamController<void>.broadcast();
  Stream<void> get onProgressChanged => _progressController.stream;

  ProgressRepository._();

  static ProgressRepository get instance {
    _instance ??= ProgressRepository._();
    return _instance!;
  }

  /// Nạp tiến độ học trực tuyến từ server
  Future<void> loadRemoteProgress() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final data = await _remoteDS.fetchProgress();
      if (data != null) {
        final rawList = data['completedLessons'] as List? ?? [];
        final progressList = rawList.map((l) => Map<String, dynamic>.from(l as Map)).toList();

        // ─── ĐỒNG BỘ/GIẢI QUYẾT SAI LỆCH CHỈ SỐ (LESSON ORDER HEALING) ───
        final objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
        for (final p in progressList) {
          final lessonId = p['lessonId']?.toString();
          // Sửa các bài học bị sai hoặc mặc định là 0 hoặc thiếu type
          if (lessonId != null && 
              objectIdRegex.hasMatch(lessonId) && 
              (p['lessonOrder'] == 0 || p['lessonOrder'] == null || p['lessonType'] == null || p['lessonType'] == '')) {
            final lesson = await LessonRepository.instance.getLessonById(lessonId);
            if (lesson != null) {
              final type = lesson['type']?.toString();
              final khmerText = lesson['khmerText']?.toString();
              if (type != null && type.isNotEmpty) {
                p['lessonType'] = type;
              }
              if (khmerText != null && khmerText.isNotEmpty && type != null) {
                int resolvedOrder = -1;
                if (type == 'consonant') {
                  resolvedOrder = KhmerLetterData.consonants.indexWhere((l) => !l.isTest && l.character == khmerText);
                } else if (type == 'vowel') {
                  resolvedOrder = KhmerVowelData.vowels.indexWhere((v) => v.character == khmerText);
                } else if (type == 'number') {
                  resolvedOrder = KhmerNumberData.numbers.indexWhere((n) => n.character == khmerText);
                }

                if (resolvedOrder != -1) {
                  p['lessonOrder'] = resolvedOrder;
                  if (kDebugMode) {
                    print('[ProgressRepo] Healed remote lesson $lessonId ($khmerText) order to $resolvedOrder, type to $type');
                  }
                }
              }
            }
          }
        }

        _completedLessonsCache = progressList;
        _hasLoaded = true;
        _progressController.add(null);
      }
    } catch (e) {
      debugPrint('[ProgressRepo] Error loading remote progress: $e');
    }
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
    int? xp,
  }) async {
    if (kDebugMode) print('[ProgressRepo] Online-driven: completing lesson $lessonId on server (stars: $stars, xp: $xp)');

    // ─── OPTIMISTIC UI UPDATE ───
    final isDone = await isLessonCompleted(lessonId);
    if (!isDone) {
      // 1. Cộng Sao & XP trực quan tức thì trên Header
      AuthService().addStarsAndXpOptimistically(stars, xp ?? 0);

      // 2. Thêm tạm thời vào RAM cache để bản đồ học cập nhật hoàn thành ngay lập tức
      _completedLessonsCache.add({
        'lessonId': lessonId,
        'lessonType': lessonType,
        'lessonOrder': lessonOrder,
        'stars': stars,
        'isCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      });
      _progressController.add(null);
    }

    // Kích hoạt gọi trực tiếp lên server
    if (ConnectivityService.instance.isOnline) {
      final result = await _remoteDS.completeLesson(
        lessonId: lessonId,
        stars: stars,
        lessonType: lessonType,
        lessonOrder: lessonOrder,
        xp: xp,
      );

      if (result != null) {
        // Tải lại thông tin cá nhân mới nhất để cập nhật UI Stars & XP (đảm bảo đồng bộ chính xác từ server)
        await AuthService().fetchProfile();
        // Cập nhật lại cache tiến độ học tập trên RAM
        await loadRemoteProgress();
      }
    } else {
      if (kDebugMode) print('[ProgressRepo] Offline - cannot save progress (requires online mode)');
    }

    // Notify UI (final check)
    _progressController.add(null);

    // Cập nhật lịch thông báo nhắc học offline
    LocalNotificationService().scheduleDailyReminders(studiedToday: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // READ PROGRESS — Online-driven memory cache
  // ═══════════════════════════════════════════════════════════════

  /// Lấy danh sách bài đã hoàn thành
  Future<List<String>> getCompletedLessonIds() async {
    if (!_hasLoaded) {
      await loadRemoteProgress();
    }
    return _completedLessonsCache.map((item) {
      if (item is Map) {
        return item['lessonId']?.toString() ?? '';
      }
      return item.toString();
    }).where((id) => id.isNotEmpty).toList();
  }

  /// Lấy danh sách bài đã mở khóa
  Future<List<String>> getUnlockedLessonIds() async {
    // Với mô hình trực tuyến, coi các bài đã hoàn thành là mở khóa.
    return await getCompletedLessonIds();
  }

  /// Kiểm tra bài đã unlock chưa
  Future<bool> isLessonUnlocked(String lessonId) async {
    return true;
  }

  /// Kiểm tra bài đã hoàn thành chưa
  Future<bool> isLessonCompleted(String lessonId) async {
    final completedIds = await getCompletedLessonIds();
    return completedIds.contains(lessonId);
  }

  /// Lấy progress map {index: stars} cho tương thích ngược
  Future<Map<int, int>> getProgressMap(String lessonType) async {
    if (!_hasLoaded) {
      await loadRemoteProgress();
    }
    final map = <int, int>{};
    for (final item in _completedLessonsCache) {
      if (item is Map && item['lessonType'] == lessonType) {
        final order = item['lessonOrder'] as int?;
        if (order != null) {
          map[order] = (item['stars'] as num?)?.toInt() ?? 3;
        }
      }
    }
    return map;
  }

  /// Lấy tất cả progress theo loại bài
  Future<List<Map<String, dynamic>>> getProgressByType(String lessonType) async {
    if (!_hasLoaded) {
      await loadRemoteProgress();
    }
    final result = <Map<String, dynamic>>[];
    for (final item in _completedLessonsCache) {
      if (item is Map && item['lessonType'] == lessonType) {
        result.add({
          'lessonId': item['lessonId']?.toString() ?? '',
          'lessonType': item['lessonType']?.toString() ?? '',
          'lessonOrder': item['lessonOrder'] as int? ?? 0,
          'stars': (item['stars'] as num?)?.toInt() ?? 3,
          'isCompleted': item['isCompleted'] as bool? ?? true,
          'isUnlocked': true,
        });
      }
    }
    return result;
  }

  /// Đếm số bài hoàn thành theo loại
  Future<int> getCompletedCount(String lessonType) async {
    final completed = AuthService().userProfile?['learningProgress']?['completedLessons'] as List? ?? [];
    return completed.where((item) => item is Map && item['type'] == lessonType).length;
  }

  /// Đếm số bài hoàn thành theo loại (đồng bộ từ RAM cache)
  int getCompletedCountSync(String lessonType) {
    return _completedLessonsCache.where((item) {
      if (item is Map) {
        return item['lessonType'] == lessonType;
      }
      return false;
    }).length;
  }

  /// Kiểm tra xem bé đã hoàn thành bài học nào hôm nay chưa
  Future<bool> hasStudiedToday() async {
    return false;
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

        // ─── ĐỒNG BỘ/GIẢI QUYẾT SAI LỆCH CHỈ SỐ (LESSON ORDER HEALING) ───
        // Regex kiểm tra MongoDB ObjectId hợp lệ (24 hex chars)
        final objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
        for (final p in progressList) {
          final lessonId = p['lessonId']?.toString();
          // Chỉ cần sửa đổi các bài học có lessonOrder bị sai hoặc mặc định là 0
          // Và lessonId phải là MongoDB ObjectId hợp lệ (bỏ qua các ID tổng hợp như 'writing_0')
          if (lessonId != null && objectIdRegex.hasMatch(lessonId) && (p['lessonOrder'] == 0 || p['lessonOrder'] == null)) {
            // Lấy thông tin bài học từ local cache/server
            final lesson = await LessonRepository.instance.getLessonById(lessonId);
            if (lesson != null) {
              final type = lesson['type']?.toString();
              final khmerText = lesson['khmerText']?.toString();
              
              if (khmerText != null && khmerText.isNotEmpty) {
                int resolvedOrder = -1;
                if (type == 'consonant') {
                  resolvedOrder = KhmerLetterData.consonants.indexWhere((l) => !l.isTest && l.character == khmerText);
                } else if (type == 'vowel') {
                  resolvedOrder = KhmerVowelData.vowels.indexWhere((v) => v.character == khmerText);
                } else if (type == 'number') {
                  resolvedOrder = KhmerNumberData.numbers.indexWhere((n) => n.character == khmerText);
                }

                if (resolvedOrder != -1) {
                  p['lessonOrder'] = resolvedOrder;
                  if (kDebugMode) {
                    print('[ProgressRepo] Healed lesson $lessonId ($khmerText) order to $resolvedOrder');
                  }
                }
              }
            }
          }
        }

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

  /// Bulk save/update progress directly to Isar
  Future<void> bulkSaveProgress(String userId, List<Map<String, dynamic>> progressList) async {
    await _localDS.bulkSaveProgress(userId, progressList);
  }

  /// Đồng bộ tiến độ từ local Isar sang SharedPreferences
  Future<void> syncLocalProgressToSharedPreferences() async {
    try {
      final storage = await StorageService.getInstance();
      await storage.clearOnlyLessonProgress(); // Clear old SharedPreferences maps first
      
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
    _completedLessonsCache = [];
    _hasLoaded = false;
    _progressController.add(null);
  }

  void dispose() {
    _progressController.close();
  }
}
