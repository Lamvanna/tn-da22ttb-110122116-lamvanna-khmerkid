import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../data/local/isar_models.dart';
import '../data/local/local_database.dart';

/// Repository cho Analytics — cache events locally, batch sync to server
class AnalyticsRepository {
  static AnalyticsRepository? _instance;

  Isar get _isar => LocalDatabase.instance.isar;

  AnalyticsRepository._();

  static AnalyticsRepository get instance {
    _instance ??= AnalyticsRepository._();
    return _instance!;
  }

  /// Log event cục bộ
  Future<void> logEvent({
    required String event,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item = SyncQueueItem()
          ..action = 'analytics_event'
          ..payloadJson = jsonEncode({
            'event': event,
            'data': data ?? {},
            'timestamp': DateTime.now().toIso8601String(),
          })
          ..status = 'pending'
          ..createdAt = DateTime.now();
        await _isar.syncQueueItems.put(item);
      });
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging event: $e');
    }
  }

  /// Log lesson start
  Future<void> logLessonStart(String lessonId, String type) async {
    await logEvent(event: 'lesson_start', data: {'lessonId': lessonId, 'type': type});
  }

  /// Log lesson complete
  Future<void> logLessonComplete(String lessonId, String type, int stars) async {
    await logEvent(event: 'lesson_complete', data: {
      'lessonId': lessonId,
      'type': type,
      'stars': stars,
    });
  }

  /// Log game play
  Future<void> logGamePlay(String gameType, int score) async {
    await logEvent(event: 'game_play', data: {'gameType': gameType, 'score': score});
  }

  /// Log session time
  Future<void> logSessionTime(int minutes) async {
    await logEvent(event: 'session_time', data: {'minutes': minutes});
  }
}
