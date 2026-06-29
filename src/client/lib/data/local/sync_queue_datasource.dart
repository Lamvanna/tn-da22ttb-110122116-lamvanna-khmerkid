import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_models.dart';
import 'local_database.dart';

/// DataSource cho hàng đợi đồng bộ (Sync Queue)
/// Lưu các action chờ sync lên server khi offline
class SyncQueueDataSource {
  Isar get _isar => LocalDatabase.instance.isar;

  /// Thêm action vào hàng đợi
  Future<void> addToQueue({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    await _isar.writeTxn(() async {
      final item = SyncQueueItem()
        ..action = action
        ..payloadJson = jsonEncode(payload)
        ..status = 'pending'
        ..retryCount = 0
        ..createdAt = DateTime.now();
      await _isar.syncQueueItems.put(item);
    });
    if (kDebugMode) print('[SyncQueue] Added: $action');
  }

  /// Lấy danh sách pending (chưa sync)
  Future<List<SyncQueueItem>> getPendingQueue() async {
    return await _isar.syncQueueItems
        .filter()
        .statusEqualTo('pending')
        .sortByCreatedAt()
        .findAll();
  }

  /// Lấy danh sách failed (đã thử nhưng lỗi)
  Future<List<SyncQueueItem>> getFailedQueue() async {
    return await _isar.syncQueueItems
        .filter()
        .statusEqualTo('failed')
        .retryCountLessThan(5) // Max 5 retry
        .sortByCreatedAt()
        .findAll();
  }

  /// Đánh dấu item đang syncing
  Future<void> markSyncing(int id) async {
    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems.get(id);
      if (item != null) {
        item.status = 'syncing';
        await _isar.syncQueueItems.put(item);
      }
    });
  }

  /// Đánh dấu sync thành công
  Future<void> markSynced(int id) async {
    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems.get(id);
      if (item != null) {
        item.status = 'synced';
        item.syncedAt = DateTime.now();
        await _isar.syncQueueItems.put(item);
      }
    });
  }

  /// Đánh dấu sync thất bại
  Future<void> markFailed(int id, String errorMessage) async {
    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems.get(id);
      if (item != null) {
        item.status = 'failed';
        item.retryCount += 1;
        item.errorMessage = errorMessage;
        await _isar.syncQueueItems.put(item);
      }
    });
  }

  /// Reset failed items về pending để retry
  Future<void> retryFailed() async {
    final failedItems = await getFailedQueue();
    await _isar.writeTxn(() async {
      for (final item in failedItems) {
        item.status = 'pending';
        await _isar.syncQueueItems.put(item);
      }
    });
    if (kDebugMode) print('[SyncQueue] Reset ${failedItems.length} failed items to pending');
  }

  /// Xóa tất cả items đã synced
  Future<void> removeSynced() async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.filter().statusEqualTo('synced').deleteAll();
    });
  }

  /// Đếm số pending + failed
  Future<int> getPendingCount() async {
    final pending = await _isar.syncQueueItems.filter().statusEqualTo('pending').count();
    final failed = await _isar.syncQueueItems.filter().statusEqualTo('failed').retryCountLessThan(5).count();
    return pending + failed;
  }

  /// Xóa toàn bộ queue
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.clear();
    });
  }

  /// Parse payload JSON từ SyncQueueItem
  Map<String, dynamic> parsePayload(SyncQueueItem item) {
    try {
      return jsonDecode(item.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
