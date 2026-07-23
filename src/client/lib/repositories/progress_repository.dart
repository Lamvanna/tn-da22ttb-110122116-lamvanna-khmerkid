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

/// Repository cho Tiß║┐n ─Éß╗Ö Hß╗ìc ΓÇö Offline-First, Database-Driven
/// MongoDB = source of truth, Isar = local cache + offline support
class ProgressRepository {
  static ProgressRepository? _instance;

  final ProgressLocalDataSource _localDS = ProgressLocalDataSource();
  final ProgressRemoteDataSource _remoteDS = ProgressRemoteDataSource();
  final SyncQueueDataSource _syncQueue = SyncQueueDataSource();

  // RAM cache for completed lessons to bypass local database entirely
  List<dynamic> _completedLessonsCache = [];
  bool _hasLoaded = false;

  /// Stream controller ─æß╗â notify UI khi progress thay ─æß╗òi
  final _progressController = StreamController<void>.broadcast();
  Stream<void> get onProgressChanged => _progressController.stream;

  ProgressRepository._();

  static ProgressRepository get instance {
    _instance ??= ProgressRepository._();
    return _instance!;
  }

  /// Nß║íp tiß║┐n ─æß╗Ö hß╗ìc trß╗▒c tuyß║┐n tß╗½ server
  Future<void> loadRemoteProgress() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final data = await _remoteDS.fetchProgress();
      if (data != null) {
        final rawList = data['completedLessons'] as List? ?? [];
        final progressList = rawList.map((l) => Map<String, dynamic>.from(l as Map)).toList();

        // ΓöÇΓöÇΓöÇ ─Éß╗ÆNG Bß╗ÿ/GIß║óI QUYß║╛T SAI Lß╗åCH CHß╗ê Sß╗É (LESSON ORDER HEALING) ΓöÇΓöÇΓöÇ
        final objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
        for (final p in progressList) {
          final lessonId = p['lessonId']?.toString();
          // Sß╗¡a c├íc b├ái hß╗ìc bß╗ï sai hoß║╖c mß║╖c ─æß╗ïnh l├á 0 hoß║╖c thiß║┐u type
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
            } else {
              // Lesson kh├┤ng c├▓n tß╗ôn tß║íi tr├¬n server (404) do database bß╗ï seed lß║íi
              p['lessonOrder'] = -99;
              p['lessonType'] = 'unknown';
              if (kDebugMode) {
                print('[ProgressRepo] Remote lesson $lessonId not found on server. Marked as unknown to prevent re-fetching.');
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

  /// User ID hiß╗çn tß║íi
  String get _userId {
    final profile = AuthService().userProfile;
    return profile?['_id']?.toString() ?? profile?['id']?.toString() ?? 'local';
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // COMPLETE LESSON ΓÇö Core flow
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  /// Ho├án th├ánh b├ái hß╗ìc ΓÇö Offline-First
  /// 1. Save local ngay ΓåÆ UI update tß╗⌐c th├¼
  /// 2. Auto-unlock next lesson trong local
  /// 3. Queue sync ΓåÆ background push MongoDB
  Future<void> completeLesson({
    required String lessonId,
    required String lessonType,
    required int lessonOrder,
    required int stars,
    int? xp,
  }) async {
    if (kDebugMode) print('[ProgressRepo] Online-driven: completing lesson $lessonId on server (stars: $stars, xp: $xp)');

    // ΓöÇΓöÇΓöÇ OPTIMISTIC UI UPDATE ΓöÇΓöÇΓöÇ
    final isDone = await isLessonCompleted(lessonId);
    if (!isDone) {
      // 1. Cß╗Öng Sao & XP trß╗▒c quan tß╗⌐c th├¼ tr├¬n Header
      AuthService().addStarsAndXpOptimistically(stars, xp ?? 0);

      // 2. Th├¬m tß║ím thß╗¥i v├áo RAM cache ─æß╗â bß║ún ─æß╗ô hß╗ìc cß║¡p nhß║¡t ho├án th├ánh ngay lß║¡p tß╗⌐c
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

    // K├¡ch hoß║ít gß╗ìi trß╗▒c tiß║┐p l├¬n server
    if (ConnectivityService.instance.isOnline) {
      final result = await _remoteDS.completeLesson(
        lessonId: lessonId,
        stars: stars,
        lessonType: lessonType,
        lessonOrder: lessonOrder,
        xp: xp,
      );

      if (result != null) {
        // Tß║úi lß║íi th├┤ng tin c├í nh├ón mß╗¢i nhß║Ñt ─æß╗â cß║¡p nhß║¡t UI Stars & XP (─æß║úm bß║úo ─æß╗ông bß╗Ö ch├¡nh x├íc tß╗½ server)
        await AuthService().fetchProfile();
        // Cß║¡p nhß║¡t lß║íi cache tiß║┐n ─æß╗Ö hß╗ìc tß║¡p tr├¬n RAM
        await loadRemoteProgress();
      }
    } else {
      if (kDebugMode) print('[ProgressRepo] Offline - cannot save progress (requires online mode)');
    }

    // Notify UI (final check)
    _progressController.add(null);

    // Cß║¡p nhß║¡t lß╗ïch th├┤ng b├ío nhß║»c hß╗ìc offline
    LocalNotificationService().scheduleDailyReminders(studiedToday: true);
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // READ PROGRESS ΓÇö Online-driven memory cache
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  /// Lß║Ñy danh s├ích b├ái ─æ├ú ho├án th├ánh
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

  /// Lß║Ñy danh s├ích b├ái ─æ├ú mß╗ƒ kh├│a
  Future<List<String>> getUnlockedLessonIds() async {
    // Vß╗¢i m├┤ h├¼nh trß╗▒c tuyß║┐n, coi c├íc b├ái ─æ├ú ho├án th├ánh l├á mß╗ƒ kh├│a.
    return await getCompletedLessonIds();
  }

  /// Kiß╗âm tra b├ái ─æ├ú unlock ch╞░a
  Future<bool> isLessonUnlocked(String lessonId) async {
    return true;
  }

  /// Kiß╗âm tra b├ái ─æ├ú ho├án th├ánh ch╞░a
  Future<bool> isLessonCompleted(String lessonId) async {
    final completedIds = await getCompletedLessonIds();
    return completedIds.contains(lessonId);
  }

  /// Lß║Ñy progress map {index: stars} cho t╞░╞íng th├¡ch ng╞░ß╗úc
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

  /// Lß║Ñy tß║Ñt cß║ú progress theo loß║íi b├ái
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

  /// ─Éß║┐m sß╗æ b├ái ho├án th├ánh theo loß║íi
  Future<int> getCompletedCount(String lessonType) async {
    final completed = AuthService().userProfile?['learningProgress']?['completedLessons'] as List? ?? [];
    return completed.where((item) => item is Map && item['type'] == lessonType).length;
  }

  /// ─Éß║┐m sß╗æ b├ái ho├án th├ánh theo loß║íi (─æß╗ông bß╗Ö tß╗½ RAM cache)
  int getCompletedCountSync(String lessonType) {
    return _completedLessonsCache.where((item) {
      if (item is Map) {
        return item['lessonType'] == lessonType;
      }
      return false;
    }).length;
  }

  /// Kiß╗âm tra xem b├⌐ ─æ├ú ho├án th├ánh b├ái hß╗ìc n├áo h├┤m nay ch╞░a
  Future<bool> hasStudiedToday() async {
    return false;
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // SYNC ΓÇö Full bidirectional sync vß╗¢i MongoDB
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  /// Full sync ΓÇö gß╗ìi khi login hoß║╖c khi c├│ mß║íng lß║íi
  Future<void> fullSync() async {
    final userId = _userId;
    if (userId == 'local') {
      if (kDebugMode) print('[ProgressRepo] ΓÜá∩╕Å Not logged in, skipping sync');
      return;
    }

    try {
      // 1. Lß║Ñy local progress ch╞░a sync
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

      // 2. Gß╗¡i l├¬n server + nhß║¡n merged result
      final serverResult = await _remoteDS.syncProgress({
        'completedLessons': localData,
        'lastSyncAt': DateTime.now().toIso8601String(),
      });

      if (serverResult != null) {
        // 3. Update local vß╗¢i merged data tß╗½ server
        final serverLessons = serverResult['completedLessons'] as List<dynamic>? ?? [];
        final progressList = serverLessons.map((l) => Map<String, dynamic>.from(l as Map)).toList();

        // ΓöÇΓöÇΓöÇ ─Éß╗ÆNG Bß╗ÿ/GIß║óI QUYß║╛T SAI Lß╗åCH CHß╗ê Sß╗É (LESSON ORDER HEALING) ΓöÇΓöÇΓöÇ
        // Regex kiß╗âm tra MongoDB ObjectId hß╗úp lß╗ç (24 hex chars)
        final objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
        for (final p in progressList) {
          final lessonId = p['lessonId']?.toString();
          // Chß╗ë cß║ºn sß╗¡a ─æß╗òi c├íc b├ái hß╗ìc c├│ lessonOrder bß╗ï sai hoß║╖c mß║╖c ─æß╗ïnh l├á 0
          // V├á lessonId phß║úi l├á MongoDB ObjectId hß╗úp lß╗ç (bß╗Å qua c├íc ID tß╗òng hß╗úp nh╞░ 'writing_0')
          if (lessonId != null && objectIdRegex.hasMatch(lessonId) && (p['lessonOrder'] == 0 || p['lessonOrder'] == null)) {
            // Lß║Ñy th├┤ng tin b├ái hß╗ìc tß╗½ local cache/server
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
            } else {
              // Lesson kh├┤ng c├▓n tß╗ôn tß║íi tr├¬n server (404) do database bß╗ï seed lß║íi
              p['lessonOrder'] = -99;
              p['lessonType'] = 'unknown';
              if (kDebugMode) {
                print('[ProgressRepo] Lesson $lessonId not found on server. Marked as unknown.');
              }
            }
          }
        }

        await _localDS.bulkSaveProgress(userId, progressList);

        // 4. ─É├ính dß║Ñu ─æ├ú sync
        final ids = unsyncedProgress.map((p) => p.id).toList();
        await _localDS.markSynced(ids);

        // 5. Update profile cache
        if (serverResult['profile'] != null) {
          await _localDS.saveProfileCache(userId, Map<String, dynamic>.from(serverResult['profile'] as Map));
        }

        // 6. Notify UI
        _progressController.add(null);

        if (kDebugMode) print('[ProgressRepo] Γ£à Full sync completed! (${progressList.length} lessons merged)');
      }
    } catch (e) {
      if (kDebugMode) print('[ProgressRepo] ΓÜá∩╕Å Full sync failed: $e');
    }
  }

  /// Save profile cache v├áo Isar
  Future<void> saveProfileCache(Map<String, dynamic> profile) async {
    await _localDS.saveProfileCache(_userId, profile);
  }

  /// Bulk save/update progress directly to Isar
  Future<void> bulkSaveProgress(String userId, List<Map<String, dynamic>> progressList) async {
    await _localDS.bulkSaveProgress(userId, progressList);
  }

  /// ─Éß╗ông bß╗Ö tiß║┐n ─æß╗Ö tß╗½ local Isar sang SharedPreferences
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
      if (kDebugMode) print('[ProgressRepo] Γ£à Synced local progress from Isar to StorageService SharedPreferences');
    } catch (e) {
      if (kDebugMode) print('[ProgressRepo] ΓÜá∩╕Å Error syncing Isar to SharedPreferences: $e');
    }
  }

  /// X├│a dß╗» liß╗çu khi logout
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
