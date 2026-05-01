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

  // ─── STARS / POINTS ──────────────────────────────────────────
  static const _keyStars = 'total_stars';
  static const _keyXp = 'total_xp';

  int getStars() => _prefs?.getInt(_keyStars) ?? 0;
  Future<void> setStars(int val) async => await _prefs?.setInt(_keyStars, val);
  Future<void> addStars(int amount) async {
    final current = getStars();
    await setStars(current + amount);
  }

  int getXp() => _prefs?.getInt(_keyXp) ?? 0;
  Future<void> addXp(int amount) async {
    final current = getXp();
    await _prefs?.setInt(_keyXp, current + amount);
  }

  // ─── STREAK ──────────────────────────────────────────────────
  static const _keyStreak = 'streak_days';
  static const _keyLastStudy = 'last_study_date';

  int getStreak() => _prefs?.getInt(_keyStreak) ?? 0;

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastStudy = _prefs?.getString(_keyLastStudy) ?? '';

    if (lastStudy == todayStr) return; // Already studied today

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    int streak = getStreak();
    if (lastStudy == yesterdayStr) {
      streak++;
    } else {
      streak = 1; // Reset streak
    }

    await _prefs?.setInt(_keyStreak, streak);
    await _prefs?.setString(_keyLastStudy, todayStr);
  }

  // ─── LETTER PROGRESS ────────────────────────────────────────
  static const _keyLetterProgress = 'letter_progress';

  /// Lưu tiến độ chữ cái: {index: starRating}
  Map<int, int> getLetterProgress() {
    final json = _prefs?.getString(_keyLetterProgress);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveLetterProgress(int index, int stars) async {
    final progress = getLetterProgress();
    progress[index] = stars;
    await _prefs?.setString(_keyLetterProgress,
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── VOWEL PROGRESS ─────────────────────────────────────────
  static const _keyVowelProgress = 'vowel_progress';

  Map<int, int> getVowelProgress() {
    final json = _prefs?.getString(_keyVowelProgress);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveVowelProgress(int index, int stars) async {
    final progress = getVowelProgress();
    progress[index] = stars;
    await _prefs?.setString(_keyVowelProgress,
        jsonEncode(progress.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ─── VOCABULARY PROGRESS ────────────────────────────────────
  static const _keyVocabLearned = 'vocab_learned';

  Set<String> getLearnedVocab() {
    final list = _prefs?.getStringList(_keyVocabLearned);
    return list?.toSet() ?? {};
  }

  Future<void> markVocabLearned(String wordKhmer) async {
    final set = getLearnedVocab();
    set.add(wordKhmer);
    await _prefs?.setStringList(_keyVocabLearned, set.toList());
  }

  // ─── TEST HISTORY ────────────────────────────────────────────
  static const _keyTestHistory = 'test_history';

  List<Map<String, dynamic>> getTestHistory() {
    final json = _prefs?.getString(_keyTestHistory);
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
    await _prefs?.setString(_keyTestHistory, jsonEncode(history));
  }

  // ─── GAME SCORES ────────────────────────────────────────────
  static const _keyGameScores = 'game_scores';

  Map<String, int> getGameScores() {
    final json = _prefs?.getString(_keyGameScores);
    if (json == null) return {};
    return (jsonDecode(json) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveGameScore(String gameName, int score) async {
    final scores = getGameScores();
    final current = scores[gameName] ?? 0;
    if (score > current) scores[gameName] = score;
    await _prefs?.setString(_keyGameScores, jsonEncode(scores));
  }

  // ─── SETTINGS ────────────────────────────────────────────────
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyLanguage = 'app_language';

  bool getSoundEnabled() => _prefs?.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool val) async =>
      await _prefs?.setBool(_keySoundEnabled, val);

  String getLanguage() => _prefs?.getString(_keyLanguage) ?? 'vi';
  Future<void> setLanguage(String lang) async =>
      await _prefs?.setString(_keyLanguage, lang);

  // ─── PROFILE ─────────────────────────────────────────────────
  static const _keyUsername = 'username';
  static const _keyAvatar = 'avatar_index';

  String getUsername() => _prefs?.getString(_keyUsername) ?? 'Bé học giỏi';
  Future<void> setUsername(String name) async =>
      await _prefs?.setString(_keyUsername, name);

  int getAvatarIndex() => _prefs?.getInt(_keyAvatar) ?? 0;
  Future<void> setAvatarIndex(int idx) async =>
      await _prefs?.setInt(_keyAvatar, idx);

  // ─── STUDY TIME ──────────────────────────────────────────────
  static const _keyTotalStudyMinutes = 'total_study_minutes';
  static const _keyDailyStudy = 'daily_study';

  int getTotalStudyMinutes() => _prefs?.getInt(_keyTotalStudyMinutes) ?? 0;

  Future<void> addStudyMinutes(int minutes) async {
    final total = getTotalStudyMinutes() + minutes;
    await _prefs?.setInt(_keyTotalStudyMinutes, total);

    // Daily
    final today = DateTime.now();
    final key = '${_keyDailyStudy}_${today.year}_${today.month}_${today.day}';
    final daily = (_prefs?.getInt(key) ?? 0) + minutes;
    await _prefs?.setInt(key, daily);
  }

  int getDailyStudyMinutes() {
    final today = DateTime.now();
    final key = '${_keyDailyStudy}_${today.year}_${today.month}_${today.day}';
    return _prefs?.getInt(key) ?? 0;
  }

  // ─── ACHIEVEMENTS ────────────────────────────────────────────
  static const _keyAchievements = 'achievements_unlocked';

  Set<String> getUnlockedAchievements() {
    return _prefs?.getStringList(_keyAchievements)?.toSet() ?? {};
  }

  Future<void> unlockAchievement(String id) async {
    final set = getUnlockedAchievements();
    set.add(id);
    await _prefs?.setStringList(_keyAchievements, set.toList());
  }

  // ─── CLEAR ALL ───────────────────────────────────────────────
  Future<void> clearAll() async => await _prefs?.clear();
}
