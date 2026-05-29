import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service theo dõi kết nối mạng — wrap connectivity_plus
class ConnectivityService {
  static ConnectivityService? _instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _onlineController = StreamController<bool>.broadcast();

  bool _isOnline = true;

  ConnectivityService._();

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  /// Stream online/offline
  Stream<bool> get onConnectivityChanged => _onlineController.stream;

  /// Trạng thái hiện tại
  bool get isOnline => _isOnline;

  /// Khởi tạo — gọi 1 lần
  Future<void> init() async {
    // Check trạng thái ban đầu
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
    } catch (_) {
      _isOnline = true; // Default online
    }

    // Lắng nghe thay đổi
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final online = !results.contains(ConnectivityResult.none);
        if (online != _isOnline) {
          _isOnline = online;
          _onlineController.add(_isOnline);
          if (kDebugMode) {
            print('[Connectivity] ${_isOnline ? '🟢 Online' : '🔴 Offline'}');
          }
        }
      },
    );

    if (kDebugMode) print('[Connectivity] ✅ Initialized (${_isOnline ? 'Online' : 'Offline'})');
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
