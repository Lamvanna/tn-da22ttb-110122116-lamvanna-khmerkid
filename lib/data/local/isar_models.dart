import 'package:isar/isar.dart';

part 'isar_models.g.dart';

// ═══════════════════════════════════════════════════════════════
// LESSON CACHE — Cache bài học từ MongoDB
// ═══════════════════════════════════════════════════════════════
@collection
class LessonCache {
  Id id = Isar.autoIncrement;

  /// MongoDB _id
  @Index(unique: true, replace: true)
  late String lessonId;

  /// Loại bài: consonant, vowel, number, coeng, vocabulary, reading, spelling, diacritical, writing
  @Index()
  late String type;

  /// Tiêu đề
  late String title;

  /// Chữ Khmer
  late String khmerText;

  /// Phiên âm Latin
  String? romanized;

  /// Nghĩa tiếng Việt
  String? meaning;

  /// Phát âm
  String? pronunciation;

  /// Mô tả
  String? description;

  /// Độ khó
  String? difficulty;

  /// Thứ tự hiển thị
  int order = 0;

  /// URL hình ảnh
  String? imageUrl;

  /// URL audio
  String? audioUrl;

  /// URL video
  String? videoUrl;

  /// Dữ liệu examples/questions/readingLines/strokeOrder (JSON string)
  String? extraDataJson;

  /// Category
  String? category;

  /// Có active không
  bool isActive = true;

  /// Thời điểm cache
  DateTime cachedAt = DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
// USER PROGRESS — Tiến độ học của user
// ═══════════════════════════════════════════════════════════════
@collection
class UserProgress {
  Id id = Isar.autoIncrement;

  /// User ID từ MongoDB
  @Index()
  late String userId;

  /// Lesson ID từ MongoDB
  @Index()
  late String lessonId;

  /// Loại bài học
  @Index()
  late String lessonType;

  /// Thứ tự bài trong danh sách
  int lessonOrder = 0;

  /// Số sao đạt được (0-5)
  int stars = 0;

  /// Đã hoàn thành chưa
  @Index()
  bool isCompleted = false;

  /// Đã mở khóa chưa
  bool isUnlocked = false;

  /// Thời điểm hoàn thành
  DateTime? completedAt;

  /// Đã sync lên server chưa
  bool isSynced = false;

  /// Thời điểm cập nhật local
  DateTime updatedAt = DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
// SYNC QUEUE — Hàng đợi đồng bộ khi offline
// ═══════════════════════════════════════════════════════════════
@collection
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  /// Loại action: complete_lesson, unlock_lesson, update_xp, game_result, etc.
  @Index()
  late String action;

  /// Payload JSON
  late String payloadJson;

  /// Trạng thái: pending, syncing, synced, failed
  @Index()
  String status = 'pending';

  /// Số lần retry
  int retryCount = 0;

  /// Thời điểm tạo
  DateTime createdAt = DateTime.now();

  /// Thời điểm sync thành công
  DateTime? syncedAt;

  /// Lỗi nếu có
  String? errorMessage;
}

// ═══════════════════════════════════════════════════════════════
// GAME RESULT CACHE — Kết quả game offline
// ═══════════════════════════════════════════════════════════════
@collection
class GameResultCache {
  Id id = Isar.autoIncrement;

  /// User ID
  @Index()
  late String userId;

  /// Loại game
  late String gameType;

  /// Điểm
  int score = 0;

  /// Thời gian chơi (giây)
  int timeSeconds = 0;

  /// Số câu đúng
  int correctAnswers = 0;

  /// Tổng số câu
  int totalQuestions = 0;

  /// Đã sync chưa
  bool isSynced = false;

  /// Thời điểm chơi
  DateTime playedAt = DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
// ACHIEVEMENT CACHE — Achievements đã mở khóa
// ═══════════════════════════════════════════════════════════════
@collection
class AchievementCache {
  Id id = Isar.autoIncrement;

  /// User ID
  @Index()
  late String userId;

  /// Achievement ID
  @Index(unique: true, replace: true, composite: [CompositeIndex('userId')])
  late String achievementId;

  /// Tên achievement
  String? name;

  /// Mô tả
  String? description;

  /// Đã sync chưa
  bool isSynced = false;

  /// Thời điểm mở khóa
  DateTime unlockedAt = DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
// USER PROFILE CACHE — Cache profile từ server
// ═══════════════════════════════════════════════════════════════
@collection
class UserProfileCache {
  Id id = Isar.autoIncrement;

  /// User ID từ MongoDB
  @Index(unique: true, replace: true)
  late String userId;

  /// Tên
  late String name;

  /// Email
  late String email;

  /// Avatar URL
  String? avatar;

  /// XP
  int xp = 0;

  /// Stars
  int stars = 0;

  /// Streak
  int streak = 0;

  /// Longest streak
  int longestStreak = 0;

  /// Level
  int level = 1;

  /// Rank
  int rank = 0;

  /// Total lessons completed
  int totalLessonsCompleted = 0;

  /// Total games played
  int totalGamesPlayed = 0;

  /// Total study time (minutes)
  int totalStudyTime = 0;

  /// Skill levels
  int listeningLevel = 0;
  int speakingLevel = 0;
  int readingLevel = 0;
  int writingLevel = 0;

  /// JSON danh sách completedLessons IDs
  String? completedLessonsJson;

  /// JSON danh sách unlockedLessons IDs
  String? unlockedLessonsJson;

  /// Thời điểm cache
  DateTime cachedAt = DateTime.now();

  /// Thời điểm sync cuối
  DateTime? lastSyncAt;
}
