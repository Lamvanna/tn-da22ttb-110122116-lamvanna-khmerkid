import 'storage_service.dart';

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
  int get totalStars => _storage.getStars();
  int get totalXp => _storage.getXp();
  int get streak => _storage.getStreak();
  int get level => (totalXp / 100).floor() + 1;
  double get levelProgress => (totalXp % 100) / 100.0;
  
  Set<String> get purchasedItems => _storage.getPurchasedItems();

  // ─── EARN & SPEND REWARDS ────────────────────────────────────
  
  Future<bool> spendStars(int amount) async {
    return await _storage.spendStars(amount);
  }

  Future<void> addPurchasedItem(String itemKey) async {
    await _storage.addPurchasedItem(itemKey);
  }

  /// Hoàn thành bài học chữ cái
  Future<Map<String, int>> completeLetterLesson(int letterIndex, int stars) async {
    int earnedStars = stars;
    int earnedXp = stars * 5;

    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.saveLetterProgress(letterIndex, stars);
    await _storage.updateStreak();

    // Check achievements
    await _checkAchievements();

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học nguyên âm
  Future<Map<String, int>> completeVowelLesson(int vowelIndex, int stars) async {
    int earnedStars = stars;
    int earnedXp = stars * 5;

    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.saveVowelProgress(vowelIndex, stars);
    await _storage.updateStreak();

    await _checkAchievements();
    return {'stars': earnedStars, 'xp': earnedXp};
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
  Future<Map<String, int>> completeGame(String gameName, int score) async {
    int earnedStars = (score / 10).ceil().clamp(1, 5);
    int earnedXp = score;

    await _storage.addStars(earnedStars);
    await _storage.addXp(earnedXp);
    await _storage.saveGameScore(gameName, score);
    await _storage.updateStreak();

    await _checkAchievements();
    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Học từ vựng
  Future<void> learnVocab(String wordKhmer) async {
    await _storage.markVocabLearned(wordKhmer);
    await _storage.addXp(5);
    await _storage.addStars(1);
    await _storage.updateStreak();
  }

  // ─── STATISTICS ──────────────────────────────────────────────

  /// Tổng số chữ đã học
  int get lettersLearned => _storage.getLetterProgress().length;

  /// Tổng số nguyên âm đã học
  int get vowelsLearned => _storage.getVowelProgress().length;

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

  /// Số huy chương
  int get totalMedals => _storage.getUnlockedAchievements().length;

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
}
