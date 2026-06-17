import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import '../data/local/sync_queue_datasource.dart';
import '../data/local/isar_models.dart';
import '../data/remote/progress_remote_datasource.dart';
import '../repositories/progress_repository.dart';
import 'auth_service.dart';

/// SyncManager — Central sync engine cho Hybrid Offline-First Architecture
///
/// Responsibilities:
/// ✅ Detect online/offline
/// ✅ Auto sync background khi có mạng
/// ✅ Retry failed sync với exponential backoff
/// ✅ Conflict resolution (take-max strategy)
/// ✅ Queue pending requests
/// ✅ Merge local/server data
class SyncManager {
  static SyncManager? _instance;

  final SyncQueueDataSource _syncQueue = SyncQueueDataSource();
  final ProgressRemoteDataSource _remoteDS = ProgressRemoteDataSource();

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicSync;
  bool _isSyncing = false;

  /// Stream sync status
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get onSyncStatusChanged => _syncStatusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  SyncManager._();

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  /// Khởi tạo SyncManager — gọi sau khi LocalDatabase và ConnectivityService sẵn sàng
  Future<void> init() async {
    // Lắng nghe connectivity changes
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged.listen(
      (isOnline) {
        if (isOnline) {
          if (kDebugMode) print('[SyncManager] 🟢 Online! Starting sync...');
          _processQueue();
        } else {
          if (kDebugMode) print('[SyncManager] 🔴 Offline. Queueing changes locally.');
          _updateStatus(SyncStatus.offline);
        }
      },
    );

    // Periodic sync mỗi 5 phút (nếu online)
    _periodicSync = Timer.periodic(const Duration(minutes: 5), (_) {
      if (ConnectivityService.instance.isOnline) {
        _processQueue();
      }
    });

    // Sync ngay nếu đang online
    if (ConnectivityService.instance.isOnline) {
      // Delay nhỏ để app init xong
      Future.delayed(const Duration(seconds: 2), () => _processQueue());
    }

    if (kDebugMode) print('[SyncManager] ✅ Initialized');
  }

  /// Process toàn bộ pending queue — FIFO
  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      // 1. Retry failed items
      await _syncQueue.retryFailed();

      // 2. Process pending items
      final pendingItems = await _syncQueue.getPendingQueue();

      if (pendingItems.isEmpty) {
        _updateStatus(SyncStatus.synced);
        _isSyncing = false;
        return;
      }

      if (kDebugMode) print('[SyncManager] 🔄 Processing ${pendingItems.length} pending items...');

      int successCount = 0;
      int failCount = 0;

      for (final item in pendingItems) {
        if (!ConnectivityService.instance.isOnline) {
          if (kDebugMode) print('[SyncManager] ⚠️ Lost connection. Stopping sync.');
          _updateStatus(SyncStatus.offline);
          break;
        }

        await _syncQueue.markSyncing(item.id);

        try {
          final success = await _processItem(item);
          if (success) {
            await _syncQueue.markSynced(item.id);
            successCount++;
          } else {
            await _syncQueue.markFailed(item.id, 'Server returned error');
            failCount++;
          }
        } catch (e) {
          await _syncQueue.markFailed(item.id, e.toString());
          failCount++;

          // Exponential backoff
          final backoff = min(30, pow(2, item.retryCount).toInt());
          await Future.delayed(Duration(seconds: backoff));
        }
      }

      // Dọn dẹp items đã sync
      await _syncQueue.removeSynced();

      if (failCount == 0) {
        _updateStatus(SyncStatus.synced);
      } else {
        _updateStatus(SyncStatus.error);
      }

      if (kDebugMode) {
        print('[SyncManager] ✅ Sync done: $successCount success, $failCount failed');
      }
    } catch (e) {
      if (kDebugMode) print('[SyncManager] ❌ Queue processing error: $e');
      _updateStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Process 1 item trong queue
  Future<bool> _processItem(SyncQueueItem item) async {
    final payload = _syncQueue.parsePayload(item);

    switch (item.action) {
      case 'complete_lesson':
        final result = await _remoteDS.completeLesson(
          lessonId: payload['lessonId'] ?? '',
          stars: payload['stars'] ?? 0,
          lessonType: payload['lessonType'] ?? '',
          lessonOrder: payload['lessonOrder'] ?? 0,
        );
        return result != null;

      case 'unlock_lesson':
        return await _remoteDS.unlockLesson(payload['lessonId'] ?? '');

      case 'sync_progress':
        final result = await _remoteDS.syncProgress(payload);
        return result != null;

      case 'analytics_event':
        // Analytics — silent fail OK
        return true;

      default:
        if (kDebugMode) print('[SyncManager] Unknown action: ${item.action}');
        return true; // Remove unknown items
    }
  }

  /// Full sync — gọi khi login hoặc manual trigger
  Future<void> fullSync() async {
    if (!AuthService().isAuthenticated) return;

    _updateStatus(SyncStatus.syncing);

    try {
      // 1. Process pending queue trước
      await _processQueue();

      // 2. Full bidirectional sync
      await ProgressRepository.instance.fullSync();

      // 3. Refresh profile
      await AuthService().fetchProfile();

      _updateStatus(SyncStatus.synced);
      if (kDebugMode) print('[SyncManager] ✅ Full sync completed!');
    } catch (e) {
      if (kDebugMode) print('[SyncManager] ❌ Full sync error: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  /// Trigger sync thủ công
  Future<void> triggerSync() async {
    if (ConnectivityService.instance.isOnline) {
      await _processQueue();
    } else {
      if (kDebugMode) print('[SyncManager] Cannot sync: offline');
    }
  }

  /// Lấy số pending items
  Future<int> getPendingCount() async {
    return await _syncQueue.getPendingCount();
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicSync?.cancel();
    _syncStatusController.close();
  }
}

/// Trạng thái sync
enum SyncStatus {
  idle,      // Chưa sync
  syncing,   // Đang sync
  synced,    // Đã sync xong
  error,     // Sync lỗi
  offline,   // Không có mạng
}
