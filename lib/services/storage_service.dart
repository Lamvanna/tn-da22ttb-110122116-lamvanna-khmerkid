import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service lưu trữ dữ liệu cục bộ
/// Sử dụng SharedPreferences để lưu tiến độ, điểm, settings
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Tạo khóa tiền tố theo userId để tránh rò rỉ dữ liệu giữa các tài khoản khác nhau
  String _uKey(String baseKey) {
    try {
      final userProfileStr = _prefs?.getString('userProfile');
      if (userProfileStr != null && userProfileStr.isNotEmpty) {
        final profile = jsonDecode(userProfileStr) as Map<String, dynamic>;
        final userId = profile['_id']?.toString() ?? profile['id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          return '${userId}_$baseKey';
        }
      }
    } catch (_) {}
    return 'local_$baseKey';
  }

  // ─── STARS / POINTS ──────────────────────────────────────────
  static const _keyStars = 'total_stars';
  static const _keyXp = 'total_xp';

  int getStars() => _prefs?.getInt(_uKey(_keyStars)) ?? 0;
  Future<void> setStars(int val) async => await _prefs?.setInt(_uKey(_keyStars), val);
  Future<void> addStars(int amount) async {
    final current = getStars();
    await setStars(current + amount);
  }

  Future<bool> spendStars(int amount) async {
    final current = getStars();
    if (current >= amount) {
      await setStars(current - amount);
      return true;
    }
    return false;
  }

  int getXp() => _prefs?.getInt(_uKey(_keyXp)) ?? 0;
  Future<void> setXp(int val) async => await _prefs?.setInt(_uKey(_keyXp), val);
  Future<void> addXp(int amount) async {
    final current = getXp();
    await _prefs?.setInt(_uKey(_keyXp), current + amount);
  }

  // ─── STREAK ──────────────────────────────────────────────────
  static const _keyStreak = 'streak_days';
  static const _keyLastStudy = 'last_study_date';

  int getStreak() => _prefs?.getInt(_uKey(_keyStreak)) ?? 0;
  Future<void> setStreak(int val) async => await _prefs?.setInt(_uKey(_keyStreak), val);

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastStudy = _prefs?.getString(_uKey(_keyLastStudy)) ?? '';

    if (lastStudy == todayStr) return; // Already studied today

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    int streak = getStreak();
    if (lastStudy == yesterdayStr) {
      streak++;
    } else {
      streak = 1; // Reset streak
    }

    await _prefs?.setInt(_uKey(_keyStreak), streak);
    await _prefs?.setString(_uKey(_keyLastStudy), todayStr);
  }

  // ─── LETTER PROGRESS ────────────────────────────────────────
  static const _keyLetterProgress = 'letter_progress';

  /// Lưu tiến độ chữ cái: {index: starRating}
  Map<int, int> getLetterProgress() {
    final json = _prefs?.getString(_uKey(_keyLetterProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveLetterProgress(int index, int stars) async {
    final progress = getLetterProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyLetterProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── VOWEL PROGRESS ─────────────────────────────────────────
  static const _keyVowelProgress = 'vowel_progress';

  Map<int, int> getVowelProgress() {
    final json = _prefs?.getString(_uKey(_keyVowelProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveVowelProgress(int index, int stars) async {
    final progress = getVowelProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyVowelProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── READING PROGRESS ───────────────────────────────────────
  static const _keyReadingProgress = 'reading_progress';

  Map<int, int> getReadingProgress() {
    final json = _prefs?.getString(_uKey(_keyReadingProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveReadingProgress(int index, int stars) async {
    final progress = getReadingProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyReadingProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── NUMBER PROGRESS ────────────────────────────────────────
  static const _keyNumberProgress = 'number_progress';

  Map<int, int> getNumberProgress() {
    final json = _prefs?.getString(_uKey(_keyNumberProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveNumberProgress(int index, int stars) async {
    final progress = getNumberProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyNumberProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── DIACRITICAL PROGRESS ───────────────────────────────────
  static const _keyDiacriticalProgress = 'diacritical_progress';

  Map<int, int> getDiacriticalProgress() {
    final json = _prefs?.getString(_uKey(_keyDiacriticalProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveDiacriticalProgress(int index, int stars) async {
    final progress = getDiacriticalProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyDiacriticalProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── SPELLING PROGRESS ──────────────────────────────────────
  static const _keySpellingProgress = 'spelling_progress';

  Map<int, int> getSpellingProgress() {
    final json = _prefs?.getString(_uKey(_keySpellingProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveSpellingProgress(int index, int stars) async {
    final progress = getSpellingProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keySpellingProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── WRITING PROGRESS ───────────────────────────────────────
  static const _keyWritingProgress = 'writing_progress';

  Map<int, int> getWritingProgress() {
    final json = _prefs?.getString(_uKey(_keyWritingProgress));
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveWritingProgress(int index, int stars) async {
    final progress = getWritingProgress();
    progress[index] = stars;
    await _prefs?.setString(_uKey(_keyWritingProgress),
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── VOCABULARY PROGRESS ────────────────────────────────────
  static const _keyVocabLearned = 'vocab_learned';

  Set<String> getLearnedVocab() {
    final list = _prefs?.getStringList(_uKey(_keyVocabLearned));
    return list?.toSet() ?? {};
  }

  Future<void> markVocabLearned(String wordKhmer) async {
    final set = getLearnedVocab();
    set.add(wordKhmer);
    await _prefs?.setStringList(_uKey(_keyVocabLearned), set.toList());
  }

  // ─── TEST HISTORY ────────────────────────────────────────────
  static const _keyTestHistory = 'test_history';

  List<Map<String, dynamic>> getTestHistory() {
    final json = _prefs?.getString(_uKey(_keyTestHistory));
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  Future<void> addTestResult({
    required int correct,
    required int total,
    required int difficulty,
    required int stars,
  }) async {
    final history = getTestHistory();
    history.add({
      'correct': correct,
      'total': total,
      'difficulty': difficulty,
      'stars': stars,
      'date': DateTime.now().toIso8601String(),
    });
    // Keep last 50 results
    if (history.length > 50) history.removeRange(0, history.length - 50);
    await _prefs?.setString(_uKey(_keyTestHistory), jsonEncode(history));
  }

  // ─── GAME SCORES ────────────────────────────────────────────
  static const _keyGameScores = 'game_scores';

  Map<String, int> getGameScores() {
    final json = _prefs?.getString(_uKey(_keyGameScores));
    if (json == null) return {};
    return (jsonDecode(json) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveGameScore(String gameName, int score) async {
    final scores = getGameScores();
    final current = scores[gameName] ?? 0;
    if (score > current) scores[gameName] = score;
    await _prefs?.setString(_uKey(_keyGameScores), jsonEncode(scores));
  }

  // ─── SHOP ITEMS ──────────────────────────────────────────────
  static const _keyPurchasedItems = 'purchased_items';

  Set<String> getPurchasedItems() {
    return _prefs?.getStringList(_uKey(_keyPurchasedItems))?.toSet() ?? {};
  }

  Future<void> addPurchasedItem(String itemKey) async {
    final set = getPurchasedItems();
    set.add(itemKey);
    await _prefs?.setStringList(_uKey(_keyPurchasedItems), set.toList());
  }

  // ─── SETTINGS (Giữ nguyên toàn cục để giữ cấu hình thiết bị) ─────────────────────────
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyLanguage = 'app_language';
  static const _keyTtsSpeed = 'tts_speed';
  static const _keyHaptics = 'haptics_enabled';
  static const _keyOffline = 'offline_enabled';

  bool getSoundEnabled() => _prefs?.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool val) async =>
      await _prefs?.setBool(_keySoundEnabled, val);

  String getLanguage() => _prefs?.getString(_keyLanguage) ?? 'vi';
  Future<void> setLanguage(String lang) async =>
      await _prefs?.setString(_keyLanguage, lang);

  /// Tốc độ đọc TTS: 0 = chậm, 1 = vừa, 2 = nhanh (mặc định vừa)
  int getTtsSpeed() => _prefs?.getInt(_keyTtsSpeed) ?? 1;
  Future<void> setTtsSpeed(int val) async =>
      await _prefs?.setInt(_keyTtsSpeed, val);

  bool getHapticsEnabled() => _prefs?.getBool(_keyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool val) async =>
      await _prefs?.setBool(_keyHaptics, val);

  bool getOfflineEnabled() => _prefs?.getBool(_keyOffline) ?? false;
  Future<void> setOfflineEnabled(bool val) async =>
      await _prefs?.setBool(_keyOffline, val);

  // ─── PROFILE ─────────────────────────────────────────────────
  static const _keyUsername = 'username';
  static const _keyAvatar = 'avatar_index';
  static const _keyAvatarUrl = 'avatar_url';

  String getUsername() => _prefs?.getString(_uKey(_keyUsername)) ?? 'Bé học giỏi';
  Future<void> setUsername(String name) async =>
      await _prefs?.setString(_uKey(_keyUsername), name);

  int getAvatarIndex() => _prefs?.getInt(_uKey(_keyAvatar)) ?? 0;
  Future<void> setAvatarIndex(int idx) async =>
      await _prefs?.setInt(_uKey(_keyAvatar), idx);

  String getAvatarUrl() => _prefs?.getString(_uKey(_keyAvatarUrl)) ?? '';
  Future<void> setAvatarUrl(String url) async =>
      await _prefs?.setString(_uKey(_keyAvatarUrl), url);

  // ─── STUDY TIME ──────────────────────────────────────────────
  static const _keyTotalStudyMinutes = 'total_study_minutes';
  static const _keyDailyStudy = 'daily_study';

  int getTotalStudyMinutes() => _prefs?.getInt(_uKey(_keyTotalStudyMinutes)) ?? 0;

  Future<void> addStudyMinutes(int minutes) async {
    final total = getTotalStudyMinutes() + minutes;
    await _prefs?.setInt(_uKey(_keyTotalStudyMinutes), total);

    // Daily
    final today = DateTime.now();
    final key = '${_keyDailyStudy}_${today.year}_${today.month}_${today.day}';
    final daily = (_prefs?.getInt(_uKey(key)) ?? 0) + minutes;
    await _prefs?.setInt(_uKey(key), daily);
  }

  int getDailyStudyMinutes() {
    final today = DateTime.now();
    final key = '${_keyDailyStudy}_${today.year}_${today.month}_${today.day}';
    return _prefs?.getInt(_uKey(key)) ?? 0;
  }

  // ─── ACHIEVEMENTS ────────────────────────────────────────────
  static const _keyAchievements = 'achievements_unlocked';

  Set<String> getUnlockedAchievements() {
    return _prefs?.getStringList(_uKey(_keyAchievements))?.toSet() ?? {};
  }

  Future<void> unlockAchievement(String id) async {
    final set = getUnlockedAchievements();
    set.add(id);
    await _prefs?.setStringList(_uKey(_keyAchievements), set.toList());
  }

  // ─── OFFLINE LESSONS CACHE (Tải xuống offline toàn cục) ───────────────────────────────────
  static const _keyCachedLessonsPrefix = 'cached_lessons_';

  String? getCachedLessons(String type) {
    return _prefs?.getString('$_keyCachedLessonsPrefix$type');
  }

  Future<void> saveCachedLessons(String type, String jsonStr) async {
    await _prefs?.setString('$_keyCachedLessonsPrefix$type', jsonStr);
  }

  // ─── CLEAR ALL ───────────────────────────────────────────────
  Future<void> clearAll() async => await _prefs?.clear();

  /// Đặt lại CHỈ tiến độ học (giữ lại đăng nhập, hồ sơ & cài đặt).
  /// Dùng cho nút "Đặt lại tiến độ" trong màn hình Cài đặt.
  Future<void> clearProgress() async {
    const keys = [
      _keyStars, _keyXp, _keyStreak, _keyLastStudy,
      _keyLetterProgress, _keyVowelProgress, _keyReadingProgress,
      _keyNumberProgress, _keyDiacriticalProgress, _keySpellingProgress,
      _keyWritingProgress, _keyVocabLearned, _keyTestHistory,
      _keyGameScores, _keyAchievements, _keyTotalStudyMinutes,
    ];
    for (final k in keys) {
      await _prefs?.remove(_uKey(k));
    }
  }

  // ─── POWER-UPS REGENERATION SYSTEM ───────────────────────────
  static const _keyHintsCount = 'pu_hints_count';
  static const _keyHintsLastReg = 'pu_hints_last_reg';
  static const _keyTimeCount = 'pu_time_count';
  static const _keyTimeLastReg = 'pu_time_last_reg';
  static const _keyLivesCount = 'pu_lives_count';
  static const _keyLivesLastReg = 'pu_lives_last_reg';
  static const _keyDoubleCount = 'pu_double_count';
  static const _keyDoubleLastReg = 'pu_double_last_reg';

  static const int _maxHints = 2;
  static const int _maxTime = 2;
  static const int _maxLives = 1;
  static const int _maxDouble = 1;

  static const int _cooldownHintsSec = 7200;  // 2 hours
  static const int _cooldownTimeSec = 7200;   // 2 hours
  static const int _cooldownLivesSec = 10800;  // 3 hours
  static const int _cooldownDoubleSec = 10800; // 3 hours

  int _getRegeneratedCount(String countKey, String timeKey, int maxVal, int cooldownSec) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    
    if (_prefs?.get(countKey) == null) {
      _prefs?.setInt(countKey, maxVal);
      _prefs?.setInt(timeKey, nowMs);
      return maxVal;
    }

    int currentCount = _prefs?.getInt(countKey) ?? maxVal;
    int lastRegMs = _prefs?.getInt(timeKey) ?? nowMs;

    if (currentCount >= maxVal) {
      _prefs?.setInt(timeKey, nowMs);
      return currentCount;
    }

    final elapsedSec = (nowMs - lastRegMs) ~/ 1000;
    if (elapsedSec >= cooldownSec) {
      final itemsToRegen = elapsedSec ~/ cooldownSec;
      final extraTimeMs = (elapsedSec % cooldownSec) * 1000;

      currentCount = (currentCount + itemsToRegen).clamp(0, maxVal);
      lastRegMs = nowMs - extraTimeMs;

      _prefs?.setInt(countKey, currentCount);
      _prefs?.setInt(timeKey, lastRegMs);
    }

    return currentCount;
  }

  int getHintsCount() => _getRegeneratedCount(_uKey(_keyHintsCount), _uKey(_keyHintsLastReg), _maxHints, _cooldownHintsSec);
  int getTimePowerupsCount() => _getRegeneratedCount(_uKey(_keyTimeCount), _uKey(_keyTimeLastReg), _maxTime, _cooldownTimeSec);
  int getLivesPowerupsCount() => _getRegeneratedCount(_uKey(_keyLivesCount), _uKey(_keyLivesLastReg), _maxLives, _cooldownLivesSec);
  int getDoubleScorePowerupsCount() => _getRegeneratedCount(_uKey(_keyDoubleCount), _uKey(_keyDoubleLastReg), _maxDouble, _cooldownDoubleSec);

  Future<void> addHints(int amount) async {
    final current = getHintsCount();
    await _prefs?.setInt(_uKey(_keyHintsCount), current + amount);
  }

  Future<void> addTimePowerups(int amount) async {
    final current = getTimePowerupsCount();
    await _prefs?.setInt(_uKey(_keyTimeCount), current + amount);
  }

  Future<void> addLivesPowerups(int amount) async {
    final current = getLivesPowerupsCount();
    await _prefs?.setInt(_uKey(_keyLivesCount), current + amount);
  }

  Future<void> addDoubleScorePowerups(int amount) async {
    final current = getDoubleScorePowerupsCount();
    await _prefs?.setInt(_uKey(_keyDoubleCount), current + amount);
  }

  Future<void> useHint() async {
    final current = getHintsCount();
    if (current > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (current == _maxHints) {
        await _prefs?.setInt(_uKey(_keyHintsLastReg), nowMs);
      }
      await _prefs?.setInt(_uKey(_keyHintsCount), current - 1);
    }
  }

  Future<void> useTimePowerup() async {
    final current = getTimePowerupsCount();
    if (current > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (current == _maxTime) {
        await _prefs?.setInt(_uKey(_keyTimeLastReg), nowMs);
      }
      await _prefs?.setInt(_uKey(_keyTimeCount), current - 1);
    }
  }

  Future<void> useLivesPowerup() async {
    final current = getLivesPowerupsCount();
    if (current > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (current == _maxLives) {
        await _prefs?.setInt(_uKey(_keyLivesLastReg), nowMs);
      }
      await _prefs?.setInt(_uKey(_keyLivesCount), current - 1);
    }
  }

  Future<void> useDoubleScorePowerup() async {
    final current = getDoubleScorePowerupsCount();
    if (current > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (current == _maxDouble) {
        await _prefs?.setInt(_uKey(_keyDoubleLastReg), nowMs);
      }
      await _prefs?.setInt(_uKey(_keyDoubleCount), current - 1);
    }
  }

  int getHintsCooldownRemaining() => _getCooldownRemaining(_uKey(_keyHintsCount), _uKey(_keyHintsLastReg), _maxHints, _cooldownHintsSec);
  int getTimePowerupsCooldownRemaining() => _getCooldownRemaining(_uKey(_keyTimeCount), _uKey(_keyTimeLastReg), _maxTime, _cooldownTimeSec);
  int getLivesPowerupsCooldownRemaining() => _getCooldownRemaining(_uKey(_keyLivesCount), _uKey(_keyLivesLastReg), _maxLives, _cooldownLivesSec);
  int getDoubleScoreCooldownRemaining() => _getCooldownRemaining(_uKey(_keyDoubleCount), _uKey(_keyDoubleLastReg), _maxDouble, _cooldownDoubleSec);

  int _getCooldownRemaining(String countKey, String timeKey, int maxVal, int cooldownSec) {
    final current = _prefs?.getInt(countKey) ?? maxVal;
    if (current >= maxVal) return 0;
    
    final lastRegMs = _prefs?.getInt(timeKey) ?? DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = (DateTime.now().millisecondsSinceEpoch - lastRegMs) ~/ 1000;
    final remaining = cooldownSec - elapsedSec;
    return remaining.clamp(0, cooldownSec);
  }
}
