import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'storage_service.dart';
import '../repositories/progress_repository.dart';

/// Service quản lý điểm số, sao, XP và gamification
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

  // ─── GETTERS ─────────────────────────────────────────────────
  int get totalStars {
    final local = _storage.getStars();
    final remote = AuthService().userProfile?['stars'] ?? 0;
    return local > remote ? local : remote;
  }
  int get totalXp {
    final local = _storage.getXp();
    final remote = AuthService().userProfile?['xp'] ?? 0;
    return local > remote ? local : remote;
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
  
  Set<String> get purchasedItems => _storage.getPurchasedItems();

  // --- POWER-UPS & COOLDOWNS ---
  int get hintsLeft => _storage.getHintsCount();
  int get timePowerupsLeft => _storage.getTimePowerupsCount();
  int get livesPowerupsLeft => _storage.getLivesPowerupsCount();
  int get doubleScorePowerupsLeft => _storage.getDoubleScorePowerupsCount();

  Future<void> useHint() async => await _storage.useHint();
  Future<void> useTimePowerup() async => await _storage.useTimePowerup();
  Future<void> useLivesPowerup() async => await _storage.useLivesPowerup();
  Future<void> useDoubleScorePowerup() async => await _storage.useDoubleScorePowerup();

  Future<void> addHints(int amount) async => await _storage.addHints(amount);
  Future<void> addTimePowerups(int amount) async => await _storage.addTimePowerups(amount);
  Future<void> addLivesPowerups(int amount) async => await _storage.addLivesPowerups(amount);
  Future<void> addDoubleScorePowerups(int amount) async => await _storage.addDoubleScorePowerups(amount);

  int get hintsCooldownRemaining => _storage.getHintsCooldownRemaining();
  int get timeCooldownRemaining => _storage.getTimePowerupsCooldownRemaining();
  int get livesCooldownRemaining => _storage.getLivesPowerupsCooldownRemaining();
  int get doubleScoreCooldownRemaining => _storage.getDoubleScoreCooldownRemaining();

  // ─── EARN & SPEND REWARDS ────────────────────────────────────
  
  Future<bool> spendStars(int amount) async {
    return await _storage.spendStars(amount);
  }

  Future<void> addStars(int amount) async => await _storage.addStars(amount);
  Future<void> addXp(int amount) async => await _storage.addXp(amount);
  Future<void> updateStreak() async => await _storage.updateStreak();

  Future<void> addPurchasedItem(String itemKey) async {
    await _storage.addPurchasedItem(itemKey);
  }

  /// Nhận thưởng cho từng hoạt động nhỏ trong bài học
  /// step: 0 = Nghe, 1 = Nói, 2 = Viết
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
    
    if (stars > 0) {
      await _storage.addStars(stars);
    }
    if (xp > 0) {
      await _storage.addXp(xp);
    }
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhận thưởng bonus hoàn thành cả 3 hoạt động
  Future<Map<String, int>> completeBonusReward() async {
    int stars = 1;
    int xp = 10;
    await _storage.addStars(stars);
    await _storage.addXp(xp);
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhận toàn bộ thưởng 5 sao và 60 XP khi hoàn thành bài học 3 bước
  Future<Map<String, int>> completeWholeLessonReward() async {
    int stars = 5;
    int xp = 60;
    await _storage.addStars(stars);
    await _storage.addXp(xp);
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Hoàn thành bài học chữ cái
  Future<Map<String, int>> completeLetterLesson(
    int letterIndex,
    int stars, {
    required String? lessonId,
    String letterText = 'ក',
    String transliteration = 'ko',
  }) async {
    // Note: Stars and XP are now awarded step-by-step and as a bonus, so we don't add them here to avoid double-counting.
    int earnedStars = 0;
    int earnedXp = 0;

    // Check achievements
    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveLetterProgress(letterIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'consonant_$letterIndex',
        lessonType: 'consonant',
        lessonOrder: letterIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving letter progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncListeningResult(100, lessonId: lessonId);
    await _syncWritingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học nguyên âm
  Future<Map<String, int>> completeVowelLesson(
    int vowelIndex,
    int stars, {
    required String? lessonId,
    String vowelText = 'ា',
    String transliteration = 'aa',
  }) async {
    // Note: Stars and XP are now awarded step-by-step and as a bonus, so we don't add them here to avoid double-counting.
    int earnedStars = 0;
    int earnedXp = 0;

    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveVowelProgress(vowelIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'vowel_$vowelIndex',
        lessonType: 'vowel',
        lessonOrder: vowelIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving vowel progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncListeningResult(100, lessonId: lessonId);
    await _syncWritingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học tập đọc
  Future<Map<String, int>> completeReadingLesson(int readingIndex, int stars, {required String? lessonId}) async {
    int earnedStars = stars;
    int earnedXp = stars * 5;

    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveReadingProgress(readingIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'reading_$readingIndex',
        lessonType: 'reading',
        lessonOrder: readingIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving reading progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncReadingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học số Khmer
  Future<Map<String, int>> completeNumberLesson(
    int numberIndex,
    int stars, {
    required String? lessonId,
    String numberText = '០',
    String transliteration = '0',
  }) async {
    // Note: Stars and XP are now awarded step-by-step and as a bonus, so we don't add them here to avoid double-counting.
    int earnedStars = 0;
    int earnedXp = 0;

    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveNumberProgress(numberIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'number_$numberIndex',
        lessonType: 'number',
        lessonOrder: numberIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving number progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncListeningResult(100, lessonId: lessonId);
    await _syncWritingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học dấu Khmer
  Future<Map<String, int>> completeDiacriticalLesson(
    int diacriticalIndex,
    int stars, {
    required String? lessonId,
    String diacriticalText = '់',
    String transliteration = '់',
  }) async {
    // Note: Stars and XP are now awarded step-by-step and as a bonus, so we don't add them here to avoid double-counting.
    int earnedStars = 0;
    int earnedXp = 0;

    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveDiacriticalProgress(diacriticalIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'diacritical_$diacriticalIndex',
        lessonType: 'diacritical',
        lessonOrder: diacriticalIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving diacritical progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncListeningResult(100, lessonId: lessonId);
    await _syncWritingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học ghép vần Khmer
  Future<Map<String, int>> completeSpellingLesson(
    int spellingIndex,
    int stars, {
    required String? lessonId,
    String spellingText = 'កា',
    String transliteration = 'kaa',
  }) async {
    // Note: Stars and XP are now awarded step-by-step and as a bonus, so we don't add them here to avoid double-counting.
    int earnedStars = 0;
    int earnedXp = 0;

    await _checkAchievements();

    // Lưu cục bộ SharedPreferences (tương thích cũ)
    await _storage.saveSpellingProgress(spellingIndex, stars);
    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.updateStreak();

    // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: lessonId ?? 'spelling_$spellingIndex',
        lessonType: 'spelling',
        lessonOrder: spellingIndex,
        stars: stars,
      );
    } catch (e) {
      debugPrint('⚠️ Error saving spelling progress to Isar: $e');
    }

    // Đồng bộ lên backend MongoDB Atlas
    await _syncListeningResult(100, lessonId: lessonId);
    await _syncWritingResult(100, lessonId: lessonId);

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài luyện viết Khmer (hỗ trợ đánh giá AI 2 lớp)
  Future<Map<String, dynamic>> completeWritingLesson(
    int writingIndex,
    int stars, {
    required String? lessonId,
    List<List<Offset>>? strokes,
    String? targetCharacter,
    bool passed = true,
  }) async {
    int earnedStars = stars;
    int earnedXp = stars * 5;

    await _checkAchievements();

    // Đồng bộ lên backend trước để chạy đánh giá AI 2 lớp
    final backendResult = await _syncWritingResult(
      stars * 33, // Điểm số dự phòng từ số sao
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
      // Lưu cục bộ SharedPreferences (tương thích cũ)
      await _storage.saveWritingProgress(writingIndex, earnedStars);
      await _storage.addStars(earnedStars);
      await _storage.addXp(earnedXp);
      await _storage.updateStreak();

      // Lưu vào Isar ProgressRepository (Isolated đa người dùng)
      try {
        await ProgressRepository.instance.completeLesson(
          lessonId: lessonId ?? 'writing_$writingIndex',
          lessonType: 'writing',
          lessonOrder: writingIndex,
          stars: earnedStars,
        );
      } catch (e) {
        debugPrint('⚠️ Error saving writing progress to Isar: $e');
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

  /// Hoàn thành bài kiểm tra
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

  /// Hoàn thành mini-game
  Future<Map<String, int>> completeGame(String gameName, int score, {bool syncToBackend = true}) async {
    int earnedStars = (score / 10).ceil().clamp(1, 5);
    int earnedXp = score;

    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.saveGameScore(gameName, score);
    await _storage.updateStreak();

    await _checkAchievements();

    if (syncToBackend) {
      await _syncGameResult(gameName, score);
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Học từ vựng
  Future<void> learnVocab(String wordKhmer) async {
    final learned = _storage.getLearnedVocab();
    if (learned.contains(wordKhmer)) return;
    await _storage.markVocabLearned(wordKhmer);
    await _storage.addXp(5);
    await _storage.addStars(1);
    await _storage.updateStreak();
  }


  // ─── STATISTICS (Dynamic from MongoDB) ────────────────────────

  /// Tổng số bài học đã hoàn thành (từ MongoDB learningProgress)
  int get totalLessonsCompleted {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalLessonsCompleted'] as num?)?.toInt() ?? 0;
  }

  /// Tổng số game đã chơi (từ MongoDB learningProgress)
  int get totalGamesPlayed {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalGamesPlayed'] as num?)?.toInt() ?? 0;
  }

  /// Tổng thời gian học (phút) (từ MongoDB learningProgress)
  int get totalStudyTime {
    final lp = AuthService().userProfile?['learningProgress'];
    return (lp?['totalStudyTime'] as num?)?.toInt() ?? 0;
  }

  /// Skill levels (0-100) từ MongoDB
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

  int _countLearned(String type, int Function() storageCountGetter) {
    final lp = AuthService().userProfile?['learningProgress'];
    final completed = lp?['completedLessons'] as List?;
    if (completed != null && completed.isNotEmpty) {
      return completed.where((item) {
        if (item is Map) {
          return item['type'] == type;
        }
        return false;
      }).length;
    }
    return storageCountGetter();
  }

  /// Tổng số chữ đã học (MongoDB completedLessons count, fallback to local)
  int get lettersLearned => _countLearned('consonant', () => _storage.getLetterProgress().length);

  /// Tổng số nguyên âm đã học
  int get vowelsLearned => _countLearned('vowel', () => _storage.getVowelProgress().length);

  /// Tổng số bài tập đọc đã học
  int get readingLearned => _countLearned('reading', () => _storage.getReadingProgress().length);

  /// Tổng số số đã học
  int get numbersLearned => _countLearned('number', () => _storage.getNumberProgress().length);

  /// Tổng số dấu đã học
  int get diacriticalsLearned => _countLearned('diacritical', () => _storage.getDiacriticalProgress().length);

  /// Tổng số bài ghép vần đã học
  int get spellingLearned => _countLearned('spelling', () => _storage.getSpellingProgress().length);

  /// Tổng số bài luyện viết đã học
  int get writingLearned => _countLearned('writing', () => _storage.getWritingProgress().length);

  /// Tổng số từ vựng đã học
  int get vocabLearned => _storage.getLearnedVocab().length;

  /// Tổng số bài test
  int get totalTests => _storage.getTestHistory().length;

  /// Điểm TB bài test
  double get avgTestScore {
    final history = _storage.getTestHistory();
    if (history.isEmpty) return 0;
    double total = 0;
    for (final t in history) {
      total += (t['correct'] as int) / (t['total'] as int) * 100;
    }
    return total / history.length;
  }

  /// Số huy chương (từ MongoDB badges + achievements)
  int get totalMedals {
    final profile = AuthService().userProfile;
    final badges = profile?['badges'] as List? ?? [];
    final achievements = profile?['achievements'] as List? ?? [];
    final count = badges.length + achievements.length;
    if (count > 0) return count;
    return _storage.getUnlockedAchievements().length;
  }

  // ─── ACHIEVEMENTS CHECK ──────────────────────────────────────
  Future<void> _checkAchievements() async {
    // Bước đầu tiên: hoàn thành 1 bài học
    if (lettersLearned >= 1) await _storage.unlockAchievement('first_lesson');

    // 5 ngày streak
    if (streak >= 5) await _storage.unlockAchievement('streak_5');

    // 10 bài test
    if (totalTests >= 10) await _storage.unlockAchievement('test_10');

    // Học hết 33 phụ âm
    if (lettersLearned >= 33) await _storage.unlockAchievement('all_consonants');

    // 100% bài test
    final history = _storage.getTestHistory();
    if (history.any((t) => t['correct'] == t['total'])) {
      await _storage.unlockAchievement('perfect_test');
    }

    // Nuôi thú 30 lần
    // (sẽ được gọi từ pet screen)
  }

  /// Kiểm tra achievement có mở khóa chưa
  bool isAchievementUnlocked(String id) =>
      _storage.getUnlockedAchievements().contains(id);

  /// Đồng bộ kết quả game lên backend MongoDB Atlas
  Future<void> _syncGameResult(String gameName, int score) async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        if (kDebugMode) print('[ScoreService] Chưa đăng nhập. Không đồng bộ lên backend.');
        return;
      }

      String gameType = 'catch_letter';
      if (gameName.contains('catch') || gameName == 'Bắt chữ Khmer') {
        gameType = 'catch_letter';
      } else if (gameName.contains('match') || gameName == 'Nối từ' || gameName.contains('Giải cứu') || gameName.contains('word_search')) {
        gameType = 'match_word';
      } else if (gameName.contains('arrange') || gameName == 'Sắp xếp chữ') {
        gameType = 'arrange_letter';
      } else if (gameName.contains('listening') || gameName == 'Trắc nghiệm nghe') {
        gameType = 'listening_quiz';
      } else if (gameName.contains('pronunciation') || gameName == 'Trắc nghiệm phát âm') {
        gameType = 'pronunciation_quiz';
      }

      final url = Uri.parse('${authService.baseUrl}/games/result');
      if (kDebugMode) print('[ScoreService] Đồng bộ kết quả game lên backend: $url ($gameName -> $gameType)');

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
          'correctAnswers': (score / 10).ceil().clamp(1, 10),
          'totalQuestions': 10,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) print('[ScoreService] Đồng bộ kết quả game lên backend thành công!');
        // Tải lại profile mới nhất từ MongoDB
        await authService.fetchProfile();
      } else {
        if (kDebugMode) {
          print('[ScoreService] Đồng bộ kết quả game thất bại. Mã lỗi: ${response.statusCode}, Nội dung: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Lỗi khi đồng bộ kết quả game: $e');
    }
  }

  /// Đồng bộ kết quả Nghe lên backend
  Future<void> _syncListeningResult(int score, {String? lessonId}) async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) return;

      final url = Uri.parse('${authService.baseUrl}/listening/result');
      if (kDebugMode) print('[ScoreService] Đồng bộ Listening: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.accessToken}',
        },
        body: jsonEncode({
          'lessonId': lessonId,
          'answers': [],
          'correctAnswers': score,
          'totalQuestions': 100,
        }),
      );
      if (kDebugMode) print('[ScoreService] Listening Sync Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await authService.fetchProfile();
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Error syncing listening: $e');
    }
  }



  /// Đồng bộ kết quả Viết lên backend (hỗ trợ đánh giá 2 lớp bằng AI)
  Future<Map<String, dynamic>?> _syncWritingResult(
    int score, {
    String? lessonId,
    List<List<Offset>>? strokes,
    String? targetCharacter,
  }) async {
    // Completely disabled backend writing sync - client-only canvas drawing is retained
    return null;
  }

  /// Đồng bộ kết quả Đọc lên backend
  Future<void> _syncReadingResult(int score, {String? lessonId}) async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) return;

      final url = Uri.parse('${authService.baseUrl}/reading/result');
      if (kDebugMode) print('[ScoreService] Đồng bộ Reading: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.accessToken}',
        },
        body: jsonEncode({
          'lessonId': lessonId,
          'answers': score,
          'correctAnswers': score,
          'totalQuestions': 100,
        }),
      );
      if (kDebugMode) print('[ScoreService] Reading Sync Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await authService.fetchProfile();
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Error syncing reading: $e');
    }
  }
}
