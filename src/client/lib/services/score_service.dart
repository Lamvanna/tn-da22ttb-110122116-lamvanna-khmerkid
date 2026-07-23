import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'storage_service.dart';
import '../repositories/progress_repository.dart';

/// Service quß║ún l├╜ ─æiß╗âm sß╗æ, sao, XP v├á gamification
class ScoreService {
  static ScoreService? _instance;
  late StorageService _storage;

  ScoreService._();

  static Future<ScoreService> getInstance() async {
    if (_instance == null) {
      _instance = ScoreService._();
      _instance!._storage = await StorageService.getInstance();
    }
    return _instance!;
  }

  // ΓöÇΓöÇΓöÇ GETTERS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  /// Stars tß╗½ backend MongoDB (source of truth)
  int get totalStars {
    return (AuthService().userProfile?['stars'] as num?)?.toInt() ?? _storage.getStars();
  }
  /// XP tß╗½ backend MongoDB (source of truth)
  int get totalXp {
    return (AuthService().userProfile?['xp'] as num?)?.toInt() ?? _storage.getXp();
  }
  int get streak {
    final local = _storage.getStreak();
    final remote = AuthService().userProfile?['streak'] ?? 0;
    return local > remote ? local : remote;
  }
  int get level => AuthService().userProfile?['level'] ?? 1;
  int get rank => AuthService().userProfile?['rank'] ?? 1;

  int get currentLevelXp {
    final curXp = AuthService().userProfile?['levelInfo']?['currentLevelXp'];
    if (curXp != null) {
      return (curXp as num).toInt();
    }
    return totalXp % 100;
  }

  int get nextLevelXp {
    final nextXp = AuthService().userProfile?['levelInfo']?['nextLevelXp'];
    if (nextXp != null) {
      return (nextXp as num).toInt();
    }
    return 100;
  }

  double get levelProgress {
    final progress = AuthService().userProfile?['levelInfo']?['progress'];
    if (progress != null) {
      return progress.toDouble() / 100.0;
    }
    return (totalXp % 100) / 100.0;
  }
  
  List<String> get purchasedItems {
    // ╞»u ti├¬n dß╗» liß╗çu tß╗½ server (source of truth)
    final serverItems = AuthService().userProfile?['purchasedItems'];
    if (serverItems != null && serverItems is List) {
      return serverItems.map((e) => e.toString()).toList();
    }
    return _storage.getPurchasedItems();
  }

  // --- POWER-UPS & COOLDOWNS ---
  int get hintsLeft => _storage.getHintsCount();
  int get timePowerupsLeft => _storage.getTimePowerupsCount();
  int get livesPowerupsLeft => _storage.getLivesPowerupsCount();
  int get doubleScorePowerupsLeft => _storage.getDoubleScorePowerupsCount();

  // Biß║┐n theo d├╡i gi├í trß╗ï inventory ─æ├ú ─æß╗ông bß╗Ö gß║ºn nhß║Ñt (tr├ính gß╗ìi server tr├╣ng lß║╖p)
  int _lastSyncedHints = -1;
  int _lastSyncedTime = -1;
  int _lastSyncedLives = -1;
  int _lastSyncedDouble = -1;

  Future<void> useHint() async {
    await _storage.useHint();
    await _syncInventoryToBackend();
  }
  Future<void> useTimePowerup() async {
    await _storage.useTimePowerup();
    await _syncInventoryToBackend();
  }
  Future<void> useLivesPowerup() async {
    await _storage.useLivesPowerup();
    await _syncInventoryToBackend();
  }
  Future<void> useDoubleScorePowerup() async {
    await _storage.useDoubleScorePowerup();
    await _syncInventoryToBackend();
  }

  Future<void> addHints(int amount) async {
    await _storage.addHints(amount);
    await _syncInventoryToBackend();
  }
  Future<void> addTimePowerups(int amount) async {
    await _storage.addTimePowerups(amount);
    await _syncInventoryToBackend();
  }
  Future<void> addLivesPowerups(int amount) async {
    await _storage.addLivesPowerups(amount);
    await _syncInventoryToBackend();
  }
  Future<void> addDoubleScorePowerups(int amount) async {
    await _storage.addDoubleScorePowerups(amount);
    await _syncInventoryToBackend();
  }

  Future<void> _syncInventoryToBackend() async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) return;

      final url = Uri.parse('${authService.baseUrl}/users/inventory');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.accessToken}',
        },
        body: jsonEncode({
          'hints': hintsLeft,
          'timePowerups': timePowerupsLeft,
          'livesPowerups': livesPowerupsLeft,
          'doubleScorePowerups': doubleScorePowerupsLeft,
          'hintsLastReg': _storage.getHintsLastReg(),
          'timePowerupsLastReg': _storage.getTimeLastReg(),
          'livesPowerupsLastReg': _storage.getLivesLastReg(),
          'doubleScorePowerupsLastReg': _storage.getDoubleLastReg(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) print('[ScoreService] ─Éß╗ông bß╗Ö inventory l├¬n CSDL th├ánh c├┤ng!');
        // Cß║¡p nhß║¡t gi├í trß╗ï ─æ├ú ─æß╗ông bß╗Ö gß║ºn nhß║Ñt
        _lastSyncedHints = hintsLeft;
        _lastSyncedTime = timePowerupsLeft;
        _lastSyncedLives = livesPowerupsLeft;
        _lastSyncedDouble = doubleScorePowerupsLeft;
        // Cß║¡p nhß║¡t profile mß╗¢i ─æß╗â ─æß║úm bß║úo t├¡nh nhß║Ñt qu├ín
        await authService.fetchProfile();
      } else {
        if (kDebugMode) {
          print('[ScoreService] ─Éß╗ông bß╗Ö inventory thß║Ñt bß║íi. M├ú lß╗ùi: ${response.statusCode}, Nß╗Öi dung: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Lß╗ùi ─æß╗ông bß╗Ö inventory: $e');
    }
  }

  /// Kiß╗âm tra v├á ─æß╗ông bß╗Ö vß║¡t phß║⌐m ─æ├ú hß╗ôi phß╗Ñc l├¬n CSDL
  /// Gß╗ìi khi mß╗ƒ m├án h├¼nh game, khi app quay lß║íi foreground, v.v.
  /// Chß╗ë gß╗¡i request khi ph├ít hiß╗çn sß╗æ l╞░ß╗úng thay ─æß╗òi (hß╗ôi phß╗Ñc xß║úy ra)
  Future<void> syncRegeneratedInventory() async {
    final authService = AuthService();
    if (!authService.isAuthenticated) return;

    // ─Éß╗ìc sß╗æ l╞░ß╗úng hiß╗çn tß║íi ΓÇö _getRegeneratedCount() tß╗▒ ─æß╗Öng t├¡nh hß╗ôi phß╗Ñc
    final hints = hintsLeft;
    final time = timePowerupsLeft;
    final lives = livesPowerupsLeft;
    final dbl = doubleScorePowerupsLeft;

    // So s├ính vß╗¢i gi├í trß╗ï ─æ├ú ─æß╗ông bß╗Ö gß║ºn nhß║Ñt ΓÇö nß║┐u giß╗æng nhau th├¼ bß╗Å qua
    if (_lastSyncedHints == hints &&
        _lastSyncedTime == time &&
        _lastSyncedLives == lives &&
        _lastSyncedDouble == dbl) {
      return;
    }

    if (kDebugMode) {
      print('[ScoreService] Ph├ít hiß╗çn thay ─æß╗òi inventory do hß╗ôi phß╗Ñc! '
          'Gß╗úi ├╜: $_lastSyncedHintsΓåÆ$hints, Thß╗¥i gian: $_lastSyncedTimeΓåÆ$time, '
          'Mß║íng: $_lastSyncedLivesΓåÆ$lives, Nh├ón ─æ├┤i: $_lastSyncedDoubleΓåÆ$dbl');
    }

    await _syncInventoryToBackend();
  }

  int get hintsCooldownRemaining => _storage.getHintsCooldownRemaining();
  int get timeCooldownRemaining => _storage.getTimePowerupsCooldownRemaining();
  int get livesCooldownRemaining => _storage.getLivesPowerupsCooldownRemaining();
  int get doubleScoreCooldownRemaining => _storage.getDoubleScoreCooldownRemaining();

  // ΓöÇΓöÇΓöÇ EARN & SPEND REWARDS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  
  Future<bool> spendStars(int amount) async {
    return await _storage.spendStars(amount);
  }

  Future<void> addStars(int amount) async => await _storage.addStars(amount);
  Future<void> addXp(int amount) async => await _storage.addXp(amount);

  bool isRewardClaimed(int zoneId) {
    return _storage.isRewardClaimed(zoneId);
  }

  Future<void> claimReward(int zoneId) async {
    await _storage.claimReward(zoneId);
  }
  Future<void> updateStreak() async => await _storage.updateStreak();

  Future<void> freezeStreak() async {
    await _storage.freezeStreak();
  }

  Future<void> addPurchasedItem(String itemKey) async {
    await _storage.addPurchasedItem(itemKey);
  }

  Future<void> removePurchasedItem(String itemKey) async {
    await _storage.removePurchasedItem(itemKey);
  }

  /// ─Éß╗ông bß╗Ö dß╗» liß╗çu local (storage) tß╗½ server profile
  /// Gß╗ìi sau khi AuthService.fetchProfile() ─æ├ú tß║úi profile mß╗¢i
  Future<void> syncFromProfile() async {
    final profile = AuthService().userProfile;
    if (profile == null) return;

    // Sync stars & xp
    final stars = (profile['stars'] as num?)?.toInt() ?? 0;
    final xp = (profile['xp'] as num?)?.toInt() ?? 0;
    await _storage.setStars(stars);
    await _storage.setXp(xp);

    // Sync inventory
    final inv = profile['inventory'];
    if (inv != null) {
      if (inv['hints'] != null) await _storage.setHintsCount((inv['hints'] as num).toInt());
      if (inv['timePowerups'] != null) await _storage.setTimeCount((inv['timePowerups'] as num).toInt());
      if (inv['livesPowerups'] != null) await _storage.setLivesCount((inv['livesPowerups'] as num).toInt());
      if (inv['doubleScorePowerups'] != null) await _storage.setDoubleCount((inv['doubleScorePowerups'] as num).toInt());
    }

    // Sync purchased items
    final purchasedItems = profile['purchasedItems'];
    if (purchasedItems != null && purchasedItems is List) {
      await _storage.setPurchasedItems(purchasedItems.map((e) => e.toString()).toList());
    }
  }

  /// Nhß║¡n th╞░ß╗ƒng cho tß╗½ng hoß║ít ─æß╗Öng nhß╗Å trong b├ái hß╗ìc
  /// step: 0 = Nghe, 1 = N├│i, 2 = Viß║┐t
  Future<Map<String, int>> completeStepReward(int step) async {
    int stars = 0;
    int xp = 0;
    if (step == 0) {
      stars = 1;
      xp = 10;
    } else if (step == 1) {
      stars = 1;
      xp = 15;
    } else if (step == 2) {
      stars = 2;
      xp = 25;
    }
    
    // Stars/XP do backend cß╗Öng khi ho├án th├ánh b├ái (qua completeLesson API)
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhß║¡n th╞░ß╗ƒng bonus ho├án th├ánh cß║ú 3 hoß║ít ─æß╗Öng
  Future<Map<String, int>> completeBonusReward() async {
    int stars = 1;
    int xp = 10;
    // Stars/XP do backend cß╗Öng
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhß║¡n to├án bß╗Ö th╞░ß╗ƒng (mß║╖c ─æß╗ïnh 5 sao v├á 60 XP) khi ho├án th├ánh b├ái hß╗ìc 3 b╞░ß╗¢c
  Future<Map<String, int>> completeWholeLessonReward({int stars = 5, int xp = 60}) async {
    // Stars/XP do backend cß╗Öng
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc chß╗» c├íi
  Future<Map<String, int>> completeLetterLesson(
    int letterIndex,
    int stars, {
    required String? lessonId,
    String letterText = 'ß₧Ç',
    String transliteration = 'ko',
    int? xp,
    String lessonType = 'consonant',
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    // Check achievements
    await _checkAchievements();

    // Cß║¡p nhß║¡t streak
    await _storage.updateStreak();

    final resolvedId = lessonId ?? '${lessonType}_$letterIndex';

    // L╞░u trß╗▒c tiß║┐p l├¬n MongoDB th├┤ng qua ProgressRepository
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: lessonType,
        lessonOrder: letterIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing letter lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc nguy├¬n ├óm
  Future<Map<String, int>> completeVowelLesson(
    int vowelIndex,
    int stars, {
    required String? lessonId,
    String vowelText = 'ß₧╢',
    String transliteration = 'aa',
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    await _checkAchievements();

    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'vowel_$vowelIndex';

    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'vowel',
        lessonOrder: vowelIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing vowel lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc tß║¡p ─æß╗ìc
  Future<Map<String, int>> completeReadingLesson(
    int readingIndex,
    int stars, {
    required String? lessonId,
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 5);

    await _checkAchievements();

    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'reading_$readingIndex';

    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'reading',
        lessonOrder: readingIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing reading lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc sß╗æ Khmer
  Future<Map<String, int>> completeNumberLesson(
    int numberIndex,
    int stars, {
    required String? lessonId,
    String numberText = 'ßƒá',
    String transliteration = '0',
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    await _checkAchievements();

    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'number_$numberIndex';

    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'number',
        lessonOrder: numberIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing number lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc dß║Ñu Khmer
  Future<Map<String, int>> completeDiacriticalLesson(
    int diacriticalIndex,
    int stars, {
    required String? lessonId,
    String diacriticalText = 'ßƒï',
    String transliteration = 'ßƒï',
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    await _checkAchievements();

    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'diacritical_$diacriticalIndex';

    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'diacritical',
        lessonOrder: diacriticalIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing diacritical lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái hß╗ìc gh├⌐p vß║ºn Khmer
  Future<Map<String, int>> completeSpellingLesson(
    int spellingIndex,
    int stars, {
    required String? lessonId,
    String spellingText = 'ß₧Çß₧╢',
    String transliteration = 'kaa',
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    await _checkAchievements();

    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'spelling_$spellingIndex';

    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'spelling',
        lessonOrder: spellingIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('ΓÜá∩╕Å Error completing spelling lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Ho├án th├ánh b├ái luyß╗çn viß║┐t Khmer (hß╗ù trß╗ú ─æ├ính gi├í AI 2 lß╗¢p)
  Future<Map<String, dynamic>> completeWritingLesson(
    int writingIndex,
    int stars, {
    required String? lessonId,
    List<List<Offset>>? strokes,
    String? targetCharacter,
    bool passed = true,
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 5);

    await _checkAchievements();

    // ─Éß╗ông bß╗Ö l├¬n backend tr╞░ß╗¢c ─æß╗â chß║íy ─æ├ính gi├í AI 2 lß╗¢p
    final backendResult = await _syncWritingResult(
      stars * 33, // ─Éiß╗âm sß╗æ dß╗▒ ph├▓ng tß╗½ sß╗æ sao
      lessonId: lessonId,
      strokes: strokes,
      targetCharacter: targetCharacter,
    );

    bool finalPassed = passed;
    if (backendResult != null) {
      finalPassed = backendResult['passed'] ?? false;
      earnedStars = (backendResult['stars'] as num?)?.toInt() ?? stars;
      earnedXp = (backendResult['xpEarned'] as num?)?.toInt() ?? (earnedStars * 5);
    }

    if (finalPassed) {
      await _storage.updateStreak();

      try {
        await ProgressRepository.instance.completeLesson(
          lessonId: lessonId ?? 'writing_$writingIndex',
          lessonType: 'writing',
          lessonOrder: writingIndex,
          stars: earnedStars,
          xp: earnedXp,
        );
      } catch (e) {
        debugPrint('ΓÜá∩╕Å Error completing writing lesson: $e');
      }
    } else {
      earnedStars = 0;
      earnedXp = 0;
    }

    return {
      'stars': earnedStars,
      'xp': earnedXp,
      'backendResult': backendResult,
    };
  }

  /// Ho├án th├ánh b├ái kiß╗âm tra
  Future<Map<String, int>> completeTest({
    required int correct,
    required int total,
    required int difficulty,
  }) async {
    final pct = (correct / total * 100).toInt();
    int stars = pct >= 90 ? 3 : pct >= 70 ? 2 : pct >= 50 ? 1 : 0;

    int earnedStars = stars * 3 + (difficulty * 2);
    int earnedXp = correct * 3 + (stars * 10);

    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.addTestResult(
      correct: correct, total: total,
      difficulty: difficulty, stars: stars,
    );
    await _storage.updateStreak();

    await _checkAchievements();
    return {'stars': earnedStars, 'xp': earnedXp, 'testStars': stars};
  }

  /// T├¡nh to├ín sß╗æ sao nhß║¡n ─æ╞░ß╗úc dß╗▒a tr├¬n sß╗æ c├óu ─æ├║ng v├á tß╗òng sß╗æ c├óu
  int calculateGameStars(int correct, int total) {
    if (total <= 0) return 0;
    
    // Thang ─æiß╗âm tß╗æi ─æa 20 c├óu ─æ├║ng ß╗⌐ng vß╗¢i 20Γ¡É.
    // Chuyß╗ân ─æß╗òi tß╗ë lß╗ç ─æ├║ng sang thang ─æiß╗âm 20:
    final scaledCorrect = ((correct / total) * 20).round().clamp(0, 20);

    if (scaledCorrect <= 2) return 0;
    if (scaledCorrect <= 4) return 1;
    if (scaledCorrect <= 6) return 2;
    if (scaledCorrect <= 8) return 3;
    if (scaledCorrect <= 10) return 5;
    if (scaledCorrect == 11) return 7;
    if (scaledCorrect == 12) return 9;
    if (scaledCorrect == 13) return 11;
    if (scaledCorrect == 14) return 13;
    if (scaledCorrect == 15) return 15;
    if (scaledCorrect == 16) return 17;
    if (scaledCorrect == 17) return 18;
    if (scaledCorrect == 18) return 19;
    return 20; // 19 - 20
  }

  /// T├¡nh to├ín XP nhß║¡n ─æ╞░ß╗úc dß╗▒a tr├¬n sß╗æ sao ─æß║ít ─æ╞░ß╗úc
  int calculateGameXp(int stars) {
    // XP = (Sao ─æß║ít ─æ╞░ß╗úc ├╖ 20) ├ù 70 (l├ám tr├▓n sß╗æ nguy├¬n, tß╗æi ─æa 70 XP)
    return ((stars / 20.0) * 70.0).round().clamp(0, 70);
  }

  /// T├¡nh xß║┐p loß║íi dß╗▒a tr├¬n tß╗ë lß╗ç ─æ├║ng
  String calculateGameRating(int correct, int total) {
    if (total <= 0) return '≡ƒî▒ Cß║ºn cß╗æ gß║»ng';
    final accuracy = ((correct / total) * 100).round();
    if (accuracy >= 100) return '≡ƒææ Ho├án hß║úo';
    if (accuracy >= 85) return '≡ƒîƒ Xuß║Ñt sß║»c';
    if (accuracy >= 70) return '≡ƒÄë Tß╗æt';
    if (accuracy >= 50) return '≡ƒæì Kh├í';
    return '≡ƒî▒ Cß║ºn cß╗æ gß║»ng';
  }

  /// Ho├án th├ánh mini-game
  Future<Map<String, dynamic>> completeGame(
    String gameName,
    int score, {
    bool syncToBackend = true,
    int? correctAnswers,
    int? totalQuestions,
  }) async {
    int stars = 0;
    int xp = 0;
    String rating = '≡ƒî▒ Cß║ºn cß╗æ gß║»ng';

    if (correctAnswers != null && totalQuestions != null && totalQuestions > 0) {
      stars = calculateGameStars(correctAnswers, totalQuestions);
      xp = calculateGameXp(stars);
      rating = calculateGameRating(correctAnswers, totalQuestions);
    } else {
      final scorePercent = score.clamp(0, 100);
      stars = calculateGameStars((scorePercent / 5).round(), 20);
      xp = calculateGameXp(stars);
      rating = calculateGameRating(scorePercent, 100);
    }

    // L╞░u local
    await _storage.saveGameScore(gameName, score);

    // Chß╗ë cß╗Öng sao, XP v├á cß║¡p nhß║¡t th├ánh t├¡ch khi game kß║┐t th├║c (syncToBackend = true)
    if (syncToBackend) {
      await _storage.addStars(stars);
      await _storage.addXp(xp);
      await _storage.updateStreak();
      await _checkAchievements();

      await _syncGameResult(
        gameName,
        score,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );
    }

    return {
      'stars': stars,
      'xp': xp,
      'rating': rating,
    };
  }

  /// Hß╗ìc tß╗½ vß╗▒ng
  Future<void> learnVocab(String wordKhmer) async {
    final learned = _storage.getLearnedVocab();
    if (learned.contains(wordKhmer)) return;
    await _storage.markVocabLearned(wordKhmer);
    await _storage.addXp(5);
    await _storage.addStars(1);
    await _storage.updateStreak();
  }


  // ΓöÇΓöÇΓöÇ STATISTICS (Dynamic from MongoDB) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Tß╗òng sß╗æ b├ái hß╗ìc ─æ├ú ho├án th├ánh (tß╗½ MongoDB learningProgress)
  int get totalLessonsCompleted {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalLessonsCompleted'] as num?)?.toInt() ?? 0;
  }

  /// Tß╗òng sß╗æ game ─æ├ú ch╞íi (tß╗½ MongoDB learningProgress)
  int get totalGamesPlayed {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalGamesPlayed'] as num?)?.toInt() ?? 0;
  }

  /// Tß╗òng thß╗¥i gian hß╗ìc (ph├║t) (tß╗½ MongoDB learningProgress)
  int get totalStudyTime {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalStudyTime'] as num?)?.toInt() ?? 0;
  }

  /// Skill levels (0-100) tß╗½ MongoDB
  int get listeningLevel {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['listeningLevel'] as num?)?.toInt() ?? 0;
  }
  int get speakingLevel {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['speakingLevel'] as num?)?.toInt() ?? 0;
  }
  int get readingLevel {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['readingLevel'] as num?)?.toInt() ?? 0;
  }
  int get writingLevel {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['writingLevel'] as num?)?.toInt() ?? 0;
  }

  // Activity counters (for new badge requirements)
  int get writingPracticeCount {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['writingPracticeCount'] as num?)?.toInt() ?? 0;
  }
  int get readingCorrectCount {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['readingCorrectCount'] as num?)?.toInt() ?? 0;
  }
  int get speakingSuccessCount {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['speakingSuccessCount'] as num?)?.toInt() ?? 0;
  }
  int get listeningCompleteCount {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['listeningCompleteCount'] as num?)?.toInt() ?? 0;
  }
  int get readingLessonsCompleted {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['readingLessonsCompleted'] as num?)?.toInt() ?? 0;
  }
  bool get isAllContentComplete {
    return writingLevel >= 90 && readingLevel >= 90 && speakingLevel >= 90 && listeningLevel >= 90;
  }

  int _countLearned(String type, int Function() storageCountGetter) {
    // 1. H├úy thß╗¡ lß║Ñy tß╗½ RAM cache cß╗ºa ProgressRepository tr╞░ß╗¢c (chß╗⌐a ─æß╗º cß║ú ID dß║íng Object v├á ID dß╗▒ ph├▓ng)
    final cacheCount = ProgressRepository.instance.getCompletedCountSync(type);
    if (cacheCount > 0) {
      return cacheCount;
    }

    // 2. Fallback sang userProfile completedLessons (hß╗ù trß╗ú cß║ú field 'type' v├á 'lessonType')
    final lp = AuthService().userProfile?['learningProgress'];
    final completed = lp?['completedLessons'] as List?;
    if (completed != null && completed.isNotEmpty) {
      return completed.where((item) {
        if (item is Map) {
          return item['type'] == type || item['lessonType'] == type;
        }
        return false;
      }).length;
    }
    return storageCountGetter();
  }

  /// Tß╗òng sß╗æ chß╗» ─æ├ú hß╗ìc (MongoDB completedLessons count, fallback to local)
  int get lettersLearned => _countLearned('consonant', () => _storage.getLetterProgress().length);

  /// Tß╗òng sß╗æ nguy├¬n ├óm ─æ├ú hß╗ìc
  int get vowelsLearned => _countLearned('vowel', () => _storage.getVowelProgress().length);

  /// Tß╗òng sß╗æ b├ái tß║¡p ─æß╗ìc ─æ├ú hß╗ìc
  int get readingLearned => _countLearned('reading', () => _storage.getReadingProgress().length);

  /// Tß╗òng sß╗æ sß╗æ ─æ├ú hß╗ìc
  int get numbersLearned => _countLearned('number', () => _storage.getNumberProgress().length);

  /// Tß╗òng sß╗æ dß║Ñu ─æ├ú hß╗ìc
  int get diacriticalsLearned => _countLearned('diacritical', () => _storage.getDiacriticalProgress().length);

  /// Tß╗òng sß╗æ b├ái gh├⌐p vß║ºn ─æ├ú hß╗ìc
  int get spellingLearned => _countLearned('spelling', () => _storage.getSpellingProgress().length);

  /// Tß╗òng sß╗æ b├ái vß║ºn ─æ├│ng ─æ├ú hß╗ìc
  int get closedSyllableLearned => _countLearned('closed_syllable', () => 0);

  /// Tß╗òng sß╗æ b├ái phß╗Ñ ├óm ch├ón ─æ├ú hß╗ìc
  int get coengLearned => _countLearned('coeng', () => 0);

  /// Tß╗òng sß╗æ b├ái luyß╗çn viß║┐t ─æ├ú hß╗ìc
  int get writingLearned => _countLearned('writing', () => _storage.getWritingProgress().length);

  /// Tß╗òng sß╗æ tß╗½ vß╗▒ng ─æ├ú hß╗ìc
  int get vocabLearned => _storage.getLearnedVocab().length;

  /// Tß╗òng sß╗æ b├ái test
  int get totalTests => _storage.getTestHistory().length;

  /// ─Éiß╗âm TB b├ái test
  double get avgTestScore {
    final history = _storage.getTestHistory();
    if (history.isEmpty) return 0;
    double total = 0;
    for (final t in history) {
      total += (t['correct'] as int) / (t['total'] as int) * 100;
    }
    return total / history.length;
  }

  /// Sß╗æ huy ch╞░╞íng (tß╗½ MongoDB badges + achievements)
  int get totalMedals {
    final profile = AuthService().userProfile;
    final badges = profile?['badges'] as List? ?? [];
    final achievements = profile?['achievements'] as List? ?? [];
    final count = badges.length + achievements.length;
    if (count > 0) return count;
    return _storage.getUnlockedAchievements().length;
  }

  // ΓöÇΓöÇΓöÇ ACHIEVEMENTS CHECK ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<void> _checkAchievements() async {
    // B╞░ß╗¢c ─æß║ºu ti├¬n: ho├án th├ánh 1 b├ái hß╗ìc
    if (lettersLearned >= 1) await _storage.unlockAchievement('first_lesson');

    // 5 ng├áy streak
    if (streak >= 5) await _storage.unlockAchievement('streak_5');

    // 10 b├ái test
    if (totalTests >= 10) await _storage.unlockAchievement('test_10');

    // Hß╗ìc hß║┐t 33 phß╗Ñ ├óm
    if (lettersLearned >= 33) await _storage.unlockAchievement('all_consonants');

    // 100% b├ái test
    final history = _storage.getTestHistory();
    if (history.any((t) => t['correct'] == t['total'])) {
      await _storage.unlockAchievement('perfect_test');
    }

    // Nu├┤i th├║ 30 lß║ºn
    // (sß║╜ ─æ╞░ß╗úc gß╗ìi tß╗½ pet screen)
  }

  /// Kiß╗âm tra achievement c├│ mß╗ƒ kh├│a ch╞░a
  bool isAchievementUnlocked(String id) =>
      _storage.getUnlockedAchievements().contains(id);

  /// ─Éß╗ông bß╗Ö kß║┐t quß║ú game l├¬n backend MongoDB Atlas
  Future<void> _syncGameResult(
    String gameName,
    int score, {
    int? correctAnswers,
    int? totalQuestions,
  }) async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        if (kDebugMode) print('[ScoreService] Ch╞░a ─æ─âng nhß║¡p. Kh├┤ng ─æß╗ông bß╗Ö l├¬n backend.');
        return;
      }

      String gameType = 'catch_letter';
      if (gameName.contains('catch') || gameName == 'Bß║»t chß╗» Khmer') {
        gameType = 'catch_letter';
      } else if (gameName.contains('match') || gameName == 'Nß╗æi tß╗½' || gameName.contains('Giß║úi cß╗⌐u') || gameName.contains('word_search')) {
        gameType = 'match_word';
      } else if (gameName.contains('arrange') || gameName == 'Sß║»p xß║┐p chß╗»') {
        gameType = 'arrange_letter';
      } else if (gameName.contains('listening') || gameName == 'Trß║»c nghiß╗çm nghe') {
        gameType = 'listening_quiz';
      } else if (gameName.contains('pronunciation') || gameName == 'Trß║»c nghiß╗çm ph├ít ├óm') {
        gameType = 'pronunciation_quiz';
      }

      final url = Uri.parse('${authService.baseUrl}/games/result');
      if (kDebugMode) print('[ScoreService] ─Éß╗ông bß╗Ö kß║┐t quß║ú game l├¬n backend: $url ($gameName -> $gameType)');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.accessToken}',
        },
        body: jsonEncode({
          'gameType': gameType,
          'score': score,
          'level': 1,
          'time': 45,
          'correctAnswers': correctAnswers ?? (score / 10).ceil().clamp(1, 10),
          'totalQuestions': totalQuestions ?? 10,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) print('[ScoreService] ─Éß╗ông bß╗Ö kß║┐t quß║ú game l├¬n backend th├ánh c├┤ng!');
        // Tß║úi lß║íi profile mß╗¢i nhß║Ñt tß╗½ MongoDB
        await authService.fetchProfile();
      } else {
        if (kDebugMode) {
          print('[ScoreService] ─Éß╗ông bß╗Ö kß║┐t quß║ú game thß║Ñt bß║íi. M├ú lß╗ùi: ${response.statusCode}, Nß╗Öi dung: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Lß╗ùi khi ─æß╗ông bß╗Ö kß║┐t quß║ú game: $e');
    }
  }

  /// ─Éß╗ông bß╗Ö kß║┐t quß║ú Viß║┐t l├¬n backend (hß╗ù trß╗ú ─æ├ính gi├í 2 lß╗¢p bß║▒ng AI)
  Future<Map<String, dynamic>?> _syncWritingResult(
    int score, {
    String? lessonId,
    List<List<Offset>>? strokes,
    String? targetCharacter,
  }) async {
    // Completely disabled backend writing sync - client-only canvas drawing is retained
    return null;
  }
}
