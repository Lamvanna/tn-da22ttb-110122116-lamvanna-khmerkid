import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../data/local/progress_local_datasource.dart';

/// Repository cho Rewards (XP, Stars, Streak, Achievements)
/// Đọc từ Isar cache + AuthService profile
class RewardRepository {
  static RewardRepository? _instance;

  final ProgressLocalDataSource _localDS = ProgressLocalDataSource();

  RewardRepository._();

  static RewardRepository get instance {
    _instance ??= RewardRepository._();
    return _instance!;
  }

  AuthService get _auth => AuthService();

  String get _userId {
    final profile = _auth.userProfile;
    return profile?['_id']?.toString() ?? profile?['id']?.toString() ?? 'local';
  }

  // ─── XP ───────────────────────────────────────────────────────

  /// Total XP — từ MongoDB profile (source of truth) với fallback local
  int get totalXp {
    return _auth.userProfile?['xp'] as int? ?? 0;
  }

  // ─── STARS ────────────────────────────────────────────────────

  /// Total Stars — từ MongoDB profile
  int get totalStars {
    return _auth.userProfile?['stars'] as int? ?? 0;
  }

  // ─── STREAK ───────────────────────────────────────────────────

  /// Current streak
  int get streak {
    return _auth.userProfile?['streak'] as int? ?? 0;
  }

  int get longestStreak {
    return _auth.userProfile?['longestStreak'] as int? ?? 0;
  }

  // ─── LEVEL ────────────────────────────────────────────────────

  int get level {
    return _auth.userProfile?['level'] as int? ?? 1;
  }

  int get rank {
    return _auth.userProfile?['rank'] as int? ?? 0;
  }

  // ─── LEVEL INFO ───────────────────────────────────────────────

  int get currentLevelXp {
    final curXp = _auth.userProfile?['levelInfo']?['currentLevelXp'];
    if (curXp != null) return (curXp as num).toInt();
    return totalXp % 100;
  }

  int get nextLevelXp {
    final nextXp = _auth.userProfile?['levelInfo']?['nextLevelXp'];
    if (nextXp != null) return (nextXp as num).toInt();
    return 100;
  }

  double get levelProgress {
    final progress = _auth.userProfile?['levelInfo']?['progress'];
    if (progress != null) return progress.toDouble() / 100.0;
    return (totalXp % 100) / 100.0;
  }

  // ─── SKILL LEVELS ─────────────────────────────────────────────

  int get listeningLevel {
    return (_auth.userProfile?['learningProgress']?['listeningLevel'] as num?)?.toInt() ?? 0;
  }

  int get speakingLevel {
    return (_auth.userProfile?['learningProgress']?['speakingLevel'] as num?)?.toInt() ?? 0;
  }

  int get readingLevel {
    return (_auth.userProfile?['learningProgress']?['readingLevel'] as num?)?.toInt() ?? 0;
  }

  int get writingLevel {
    return (_auth.userProfile?['learningProgress']?['writingLevel'] as num?)?.toInt() ?? 0;
  }

  // ─── STATISTICS ───────────────────────────────────────────────

  int get totalLessonsCompleted {
    return (_auth.userProfile?['learningProgress']?['totalLessonsCompleted'] as num?)?.toInt() ?? 0;
  }

  int get totalGamesPlayed {
    return (_auth.userProfile?['learningProgress']?['totalGamesPlayed'] as num?)?.toInt() ?? 0;
  }

  int get totalStudyTime {
    return (_auth.userProfile?['learningProgress']?['totalStudyTime'] as num?)?.toInt() ?? 0;
  }

  int get totalMedals {
    final profile = _auth.userProfile;
    final badges = profile?['badges'] as List? ?? [];
    final achievements = profile?['achievements'] as List? ?? [];
    return badges.length + achievements.length;
  }
}
