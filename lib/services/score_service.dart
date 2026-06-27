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
  /// Stars từ backend MongoDB (source of truth)
  int get totalStars {
    return (AuthService().userProfile?['stars'] as num?)?.toInt() ?? _storage.getStars();
  }
  /// XP từ backend MongoDB (source of truth)
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
  
  Set<String> get purchasedItems {
    // Ưu tiên dữ liệu từ server (source of truth)
    final serverItems = AuthService().userProfile?['purchasedItems'];
    if (serverItems != null && serverItems is List) {
      return serverItems.map((e) => e.toString()).toSet();
    }
    return _storage.getPurchasedItems();
  }

  // --- POWER-UPS & COOLDOWNS ---
  int get hintsLeft => _storage.getHintsCount();
  int get timePowerupsLeft => _storage.getTimePowerupsCount();
  int get livesPowerupsLeft => _storage.getLivesPowerupsCount();
  int get doubleScorePowerupsLeft => _storage.getDoubleScorePowerupsCount();

  // Biến theo dõi giá trị inventory đã đồng bộ gần nhất (tránh gọi server trùng lặp)
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
        if (kDebugMode) print('[ScoreService] Đồng bộ inventory lên CSDL thành công!');
        // Cập nhật giá trị đã đồng bộ gần nhất
        _lastSyncedHints = hintsLeft;
        _lastSyncedTime = timePowerupsLeft;
        _lastSyncedLives = livesPowerupsLeft;
        _lastSyncedDouble = doubleScorePowerupsLeft;
        // Cập nhật profile mới để đảm bảo tính nhất quán
        await authService.fetchProfile();
      } else {
        if (kDebugMode) {
          print('[ScoreService] Đồng bộ inventory thất bại. Mã lỗi: ${response.statusCode}, Nội dung: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ScoreService] Lỗi đồng bộ inventory: $e');
    }
  }

  /// Kiểm tra và đồng bộ vật phẩm đã hồi phục lên CSDL
  /// Gọi khi mở màn hình game, khi app quay lại foreground, v.v.
  /// Chỉ gửi request khi phát hiện số lượng thay đổi (hồi phục xảy ra)
  Future<void> syncRegeneratedInventory() async {
    final authService = AuthService();
    if (!authService.isAuthenticated) return;

    // Đọc số lượng hiện tại — _getRegeneratedCount() tự động tính hồi phục
    final hints = hintsLeft;
    final time = timePowerupsLeft;
    final lives = livesPowerupsLeft;
    final dbl = doubleScorePowerupsLeft;

    // So sánh với giá trị đã đồng bộ gần nhất — nếu giống nhau thì bỏ qua
    if (_lastSyncedHints == hints &&
        _lastSyncedTime == time &&
        _lastSyncedLives == lives &&
        _lastSyncedDouble == dbl) {
      return;
    }

    if (kDebugMode) {
      print('[ScoreService] Phát hiện thay đổi inventory do hồi phục! '
          'Gợi ý: $_lastSyncedHints→$hints, Thời gian: $_lastSyncedTime→$time, '
          'Mạng: $_lastSyncedLives→$lives, Nhân đôi: $_lastSyncedDouble→$dbl');
    }

    await _syncInventoryToBackend();
  }

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

  bool isRewardClaimed(int zoneId) {
    return _storage.isRewardClaimed(zoneId);
  }

  Future<void> claimReward(int zoneId) async {
    await _storage.claimReward(zoneId);
  }
  Future<void> updateStreak() async => await _storage.updateStreak();

  Future<void> addPurchasedItem(String itemKey) async {
    await _storage.addPurchasedItem(itemKey);
  }

  /// Đồng bộ dữ liệu local (storage) từ server profile
  /// Gọi sau khi AuthService.fetchProfile() đã tải profile mới
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
      await _storage.setPurchasedItems(purchasedItems.map((e) => e.toString()).toSet());
    }
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
    
    // Stars/XP do backend cộng khi hoàn thành bài (qua completeLesson API)
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhận thưởng bonus hoàn thành cả 3 hoạt động
  Future<Map<String, int>> completeBonusReward() async {
    int stars = 1;
    int xp = 10;
    // Stars/XP do backend cộng
    await _storage.updateStreak();
    return {'stars': stars, 'xp': xp};
  }

  /// Nhận toàn bộ thưởng (mặc định 5 sao và 60 XP) khi hoàn thành bài học 3 bước
  Future<Map<String, int>> completeWholeLessonReward({int stars = 5, int xp = 60}) async {
    // Stars/XP do backend cộng
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
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 10);

    // Check achievements
    await _checkAchievements();

    // Cập nhật streak
    await _storage.updateStreak();

    final resolvedId = lessonId ?? 'consonant_$letterIndex';

    // Lưu trực tiếp lên MongoDB thông qua ProgressRepository
    try {
      await ProgressRepository.instance.completeLesson(
        lessonId: resolvedId,
        lessonType: 'consonant',
        lessonOrder: letterIndex,
        stars: earnedStars,
        xp: earnedXp,
      );
    } catch (e) {
      debugPrint('⚠️ Error completing letter lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học nguyên âm
  Future<Map<String, int>> completeVowelLesson(
    int vowelIndex,
    int stars, {
    required String? lessonId,
    String vowelText = 'ា',
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
      debugPrint('⚠️ Error completing vowel lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học tập đọc
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
      debugPrint('⚠️ Error completing reading lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học số Khmer
  Future<Map<String, int>> completeNumberLesson(
    int numberIndex,
    int stars, {
    required String? lessonId,
    String numberText = '០',
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
      debugPrint('⚠️ Error completing number lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học dấu Khmer
  Future<Map<String, int>> completeDiacriticalLesson(
    int diacriticalIndex,
    int stars, {
    required String? lessonId,
    String diacriticalText = '់',
    String transliteration = '់',
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
      debugPrint('⚠️ Error completing diacritical lesson: $e');
    }

    return {'stars': earnedStars, 'xp': earnedXp};
  }

  /// Hoàn thành bài học ghép vần Khmer
  Future<Map<String, int>> completeSpellingLesson(
    int spellingIndex,
    int stars, {
    required String? lessonId,
    String spellingText = 'កា',
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
      debugPrint('⚠️ Error completing spelling lesson: $e');
    }

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
    int? xp,
  }) async {
    int earnedStars = stars;
    int earnedXp = xp ?? (stars * 5);

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
        debugPrint('⚠️ Error completing writing lesson: $e');
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

  /// Tính toán số sao nhận được dựa trên số câu đúng và tổng số câu
  int calculateGameStars(int correct, int total) {
    if (total <= 0) return 0;
    
    // Thang điểm tối đa 20 câu đúng ứng với 20⭐.
    // Chuyển đổi tỉ lệ đúng sang thang điểm 20:
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

  /// Tính toán XP nhận được dựa trên số sao đạt được
  int calculateGameXp(int stars) {
    // XP = (Sao đạt được ÷ 20) × 70 (làm tròn số nguyên, tối đa 70 XP)
    return ((stars / 20.0) * 70.0).round().clamp(0, 70);
  }

  /// Tính xếp loại dựa trên tỉ lệ đúng
  String calculateGameRating(int correct, int total) {
    if (total <= 0) return '🌱 Cần cố gắng';
    final accuracy = ((correct / total) * 100).round();
    if (accuracy >= 100) return '👑 Hoàn hảo';
    if (accuracy >= 85) return '🌟 Xuất sắc';
    if (accuracy >= 70) return '🎉 Tốt';
    if (accuracy >= 50) return '👍 Khá';
    return '🌱 Cần cố gắng';
  }

  /// Hoàn thành mini-game
  Future<Map<String, dynamic>> completeGame(
    String gameName,
    int score, {
    bool syncToBackend = true,
    int? correctAnswers,
    int? totalQuestions,
  }) async {
    int stars = 0;
    int xp = 0;
    String rating = '🌱 Cần cố gắng';

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

    // Lưu local
    await _storage.saveGameScore(gameName, score);

    // Chỉ cộng sao, XP và cập nhật thành tích khi game kết thúc (syncToBackend = true)
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
    // 1. Hãy thử lấy từ RAM cache của ProgressRepository trước (chứa đủ cả ID dạng Object và ID dự phòng)
    final cacheCount = ProgressRepository.instance.getCompletedCountSync(type);
    if (cacheCount > 0) {
      return cacheCount;
    }

    // 2. Fallback sang userProfile completedLessons (hỗ trợ cả field 'type' và 'lessonType')
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

  /// Tổng số bài vần đóng đã học
  int get closedSyllableLearned => _countLearned('closed_syllable', () => 0);

  /// Tổng số bài phụ âm chân đã học
  int get coengLearned => _countLearned('coeng', () => 0);

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
  Future<void> _syncGameResult(
    String gameName,
    int score, {
    int? correctAnswers,
    int? totalQuestions,
  }) async {
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
          'correctAnswers': correctAnswers ?? (score / 10).ceil().clamp(1, 10),
          'totalQuestions': totalQuestions ?? 10,
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
}
