/// ═══════════════════════════════════════════════════════════════════════
/// Handwriting WebSocket Client — Tier 2: Real-time AI Stroke Feedback
/// ═══════════════════════════════════════════════════════════════════════
///
/// This service manages the Socket.IO connection to the backend
/// AI Stroke Analyzer. It:
///
///   1. Sends the child's raw stroke data (with timestamps) to the
///      server immediately when they finish drawing.
///
///   2. Listens for the `stroke_analysis_result` event containing
///      detailed geometric feedback (similarity score, direction
///      errors, specific stroke corrections).
///
///   3. Pre-fetches character metadata (expected stroke count,
///      difficulty) via the `get_character_info` event so that
///      the Tier 1 anti-false recognition filter can use it.
///
/// ─── Architecture Note ─────────────────────────────────────────────
///
/// This client works alongside [KhmerHandwritingService] (Tier 1).
/// Tier 1 gives instant pass/fail feedback using ML Kit.
/// Tier 2 (this service) runs asynchronously and provides
/// detailed "how to fix your stroke" guidance.
///
/// The client reuses the existing Socket.IO connection from
/// [AuthService] when available, or creates a dedicated one.
///
/// @module services/handwriting_websocket_client
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'auth_service.dart';
import 'khmer_handwriting_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// Data Models
// ═══════════════════════════════════════════════════════════════════════

/// Result from the Tier 2 backend AI geometric analysis.
class StrokeAnalysisResult {
  /// Whether the analysis completed successfully.
  final bool success;

  /// Composite similarity score (0–100).
  final int similarityScore;

  /// Shape sub-score (DTW-based, 0–100).
  final int shapeScore;

  /// Direction alignment sub-score (0–100).
  final int directionScore;

  /// Stroke count sub-score (0–100).
  final int strokeCountScore;

  /// Child-friendly Vietnamese feedback string.
  final String feedback;

  /// Index of the problematic stroke, or -1 if none.
  final int errorStrokeIndex;

  /// All error descriptions.
  final List<String> errors;

  /// Stars earned (0–3).
  final int stars;

  /// Whether the child passed this attempt.
  final bool passed;

  /// XP earned.
  final int xpEarned;

  const StrokeAnalysisResult({
    required this.success,
    required this.similarityScore,
    required this.shapeScore,
    required this.directionScore,
    required this.strokeCountScore,
    required this.feedback,
    required this.errorStrokeIndex,
    required this.errors,
    required this.stars,
    required this.passed,
    required this.xpEarned,
  });

  factory StrokeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return StrokeAnalysisResult(
      success: json['success'] == true,
      similarityScore: (json['similarityScore'] as num?)?.toInt() ?? 0,
      shapeScore: (json['shapeScore'] as num?)?.toInt() ?? 0,
      directionScore: (json['directionScore'] as num?)?.toInt() ?? 0,
      strokeCountScore: (json['strokeCountScore'] as num?)?.toInt() ?? 0,
      feedback: json['feedback'] as String? ?? '',
      errorStrokeIndex: (json['errorStrokeIndex'] as num?)?.toInt() ?? -1,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      passed: json['passed'] == true,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
    );
  }

  /// Factory for a failure/error result.
  factory StrokeAnalysisResult.error(String message) {
    return StrokeAnalysisResult(
      success: false,
      similarityScore: 0,
      shapeScore: 0,
      directionScore: 0,
      strokeCountScore: 0,
      feedback: message,
      errorStrokeIndex: -1,
      errors: [message],
      stars: 0,
      passed: false,
      xpEarned: 0,
    );
  }

  @override
  String toString() =>
      'StrokeAnalysisResult(score: $similarityScore, passed: $passed, '
      'feedback: "$feedback")';
}

/// Metadata about a character from the StandardCharacters collection.
class CharacterInfo {
  final String character;
  final int totalStrokes;
  final String difficulty;
  final String hint;
  final String type;

  const CharacterInfo({
    required this.character,
    required this.totalStrokes,
    required this.difficulty,
    required this.hint,
    required this.type,
  });

  factory CharacterInfo.fromJson(Map<String, dynamic> json) {
    return CharacterInfo(
      character: json['character'] as String? ?? '',
      totalStrokes: (json['totalStrokes'] as num?)?.toInt() ?? 1,
      difficulty: json['difficulty'] as String? ?? 'easy',
      hint: json['hint'] as String? ?? '',
      type: json['type'] as String? ?? 'consonant',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════

/// Timeout for waiting for backend analysis response.
const Duration _kAnalysisTimeout = Duration(seconds: 15);

/// Timeout for character info requests.
const Duration _kInfoTimeout = Duration(seconds: 5);

// ═══════════════════════════════════════════════════════════════════════
// Service Singleton
// ═══════════════════════════════════════════════════════════════════════

/// Manages the WebSocket connection and message exchange with the
/// backend AI Stroke Analyzer.
class HandwritingWebSocketClient {
  HandwritingWebSocketClient._();
  static final HandwritingWebSocketClient instance =
      HandwritingWebSocketClient._();

  // ── Internal state ────────────────────────────────────────────────

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isRefreshingToken = false;

  /// Cache of character info to avoid repeated server calls.
  final Map<String, CharacterInfo> _characterInfoCache = {};

  /// Pending analysis completers (keyed by a request ID).
  final Map<String, Completer<StrokeAnalysisResult>> _pendingAnalysis = {};

  /// Stream controller for broadcasting analysis results to listeners.
  final StreamController<StrokeAnalysisResult> _resultStreamController =
      StreamController<StrokeAnalysisResult>.broadcast();

  /// Stream of analysis results — UI widgets can listen to this.
  Stream<StrokeAnalysisResult> get resultStream =>
      _resultStreamController.stream;

  /// Whether the socket is currently connected.
  bool get isConnected => _isConnected;

  // ═══════════════════════════════════════════════════════════════════
  // Connection Lifecycle
  // ═══════════════════════════════════════════════════════════════════

  /// Connect to the backend WebSocket server.
  ///
  /// Uses the auth token from [AuthService] for authentication.
  /// If already connected, this is a no-op.
  void connect() {
    if (_isConnected && _socket != null) {
      debugPrint('[HandwritingWS] Already connected.');
      return;
    }

    final authService = AuthService();
    if (!authService.isAuthenticated) {
      debugPrint('[HandwritingWS] Not authenticated. Cannot connect.');
      return;
    }

    final serverUrl = authService.baseUrl.replaceAll('/api', '');
    final token = authService.accessToken;

    debugPrint('[HandwritingWS] Connecting to $serverUrl...');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': 'Bearer $token'})
          .setQuery({'token': token})
          .build(),
    );

    // ── Event listeners ───────────────────────────────────────────

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('[HandwritingWS] ✅ Connected (id: ${_socket!.id})');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[HandwritingWS] ❌ Disconnected');
    });

    _socket!.onConnectError((err) async {
      _isConnected = false;
      debugPrint('[HandwritingWS] Connection error: $err');
      
      final errorStr = err.toString();
      if (errorStr.contains('expired token') || 
          errorStr.contains('Authentication error') || 
          errorStr.contains('jwt expired')) {
        debugPrint('[HandwritingWS] 🔑 WebSocket authentication failed due to expired token.');
        
        // Immediately disconnect to prevent auto-reconnection loops using the old token
        disconnect();
        
        if (_isRefreshingToken) {
          debugPrint('[HandwritingWS] Token refresh already in progress, skipping duplicate request.');
          return;
        }
        
        _isRefreshingToken = true;
        try {
          debugPrint('[HandwritingWS] Attempting to refresh access token...');
          final refreshed = await AuthService().refreshAccessToken();
          if (refreshed) {
            debugPrint('[HandwritingWS] 🔑 Access token refreshed successfully. Reconnecting WebSocket...');
            connect();
          } else {
            debugPrint('[HandwritingWS] ❌ Failed to refresh token. WebSocket connection unauthorized.');
          }
        } catch (e) {
          debugPrint('[HandwritingWS] ⚠️ Error during auto token refresh: $e');
        } finally {
          _isRefreshingToken = false;
        }
      }
    });

    _socket!.onError((err) {
      debugPrint('[HandwritingWS] Socket error: $err');
    });

    // ── Listen for analysis results ───────────────────────────────

    _socket!.on('stroke_analysis_result', (data) {
      debugPrint('[HandwritingWS] Received stroke_analysis_result');
      try {
        final result = StrokeAnalysisResult.fromJson(
          Map<String, dynamic>.from(data as Map),
        );

        // Broadcast to stream listeners (UI)
        _resultStreamController.add(result);

        // Resolve any pending completer (for await-based callers)
        // We resolve all pending since we don't have request IDs in response
        for (final entry in _pendingAnalysis.entries) {
          if (!entry.value.isCompleted) {
            entry.value.complete(result);
          }
        }
        _pendingAnalysis.clear();
      } catch (e) {
        debugPrint('[HandwritingWS] Error parsing result: $e');
      }
    });

    _socket!.on('character_info_result', (data) {
      debugPrint('[HandwritingWS] Received character_info_result');
      // Handled via ack callbacks, not here
    });

    _socket!.connect();
  }

  /// Disconnect from the WebSocket server.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _pendingAnalysis.clear();
    debugPrint('[HandwritingWS] Disconnected and disposed.');
  }

  // ═══════════════════════════════════════════════════════════════════
  // Stroke Analysis
  // ═══════════════════════════════════════════════════════════════════

  /// Send the child's strokes to the backend for AI geometric analysis.
  ///
  /// This is called silently when the child finishes their last stroke.
  /// The result is returned as a [Future] and also pushed to [resultStream].
  ///
  /// [strokes] — list of stroke point lists (with timestamps).
  /// [targetCharacter] — the character the child is writing.
  ///
  /// Returns a [StrokeAnalysisResult] with detailed feedback.
  Future<StrokeAnalysisResult> analyzeStrokes({
    required List<List<StrokePoint>> strokes,
    required String targetCharacter,
  }) async {
    if (!_isConnected || _socket == null) {
      debugPrint('[HandwritingWS] Not connected. Attempting reconnect...');
      connect();
      // Give it a moment to connect
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isConnected) {
        return StrokeAnalysisResult.error(
          'Không thể kết nối đến máy chủ phân tích.',
        );
      }
    }

    // ── Build the payload ──────────────────────────────────────────
    final payload = {
      'targetCharacter': targetCharacter,
      'userStrokeData': strokes
          .map(
            (stroke) => stroke.map((p) => p.toJson()).toList(),
          )
          .toList(),
    };

    // ── Create a completer for the response ───────────────────────
    final requestId = '${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<StrokeAnalysisResult>();
    _pendingAnalysis[requestId] = completer;

    // ── Emit the event ────────────────────────────────────────────
    debugPrint(
      '[HandwritingWS] Emitting analyze_strokes for "$targetCharacter" '
      '(${strokes.length} strokes, '
      '${strokes.fold<int>(0, (sum, s) => sum + s.length)} points)',
    );

    _socket!.emit('analyze_strokes', payload);

    // ── Wait for response with timeout ────────────────────────────
    try {
      final result = await completer.future.timeout(_kAnalysisTimeout);
      return result;
    } on TimeoutException {
      _pendingAnalysis.remove(requestId);
      debugPrint('[HandwritingWS] ⏰ Analysis timed out');
      return StrokeAnalysisResult.error(
        'Phân tích nét vẽ quá thời gian. Hãy thử lại nhé!',
      );
    } catch (e) {
      _pendingAnalysis.remove(requestId);
      debugPrint('[HandwritingWS] Analysis error: $e');
      return StrokeAnalysisResult.error(
        'Đã xảy ra lỗi khi phân tích nét vẽ.',
      );
    }
  }

  /// Fire-and-forget version: send strokes without waiting for response.
  /// The result will arrive via [resultStream].
  void analyzeStrokesAsync({
    required List<List<StrokePoint>> strokes,
    required String targetCharacter,
  }) {
    if (!_isConnected || _socket == null) {
      debugPrint('[HandwritingWS] Not connected. Skipping async analysis.');
      return;
    }

    final payload = {
      'targetCharacter': targetCharacter,
      'userStrokeData': strokes
          .map((stroke) => stroke.map((p) => p.toJson()).toList())
          .toList(),
    };

    debugPrint(
      '[HandwritingWS] Async emit analyze_strokes for "$targetCharacter"',
    );
    _socket!.emit('analyze_strokes', payload);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Character Info
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch character metadata from the server (with caching).
  ///
  /// Returns null if the character is not found or the request fails.
  Future<CharacterInfo?> getCharacterInfo(String character) async {
    // Check cache first
    if (_characterInfoCache.containsKey(character)) {
      return _characterInfoCache[character];
    }

    if (!_isConnected || _socket == null) {
      debugPrint('[HandwritingWS] Not connected. Cannot fetch character info.');
      return null;
    }

    try {
      final completer = Completer<CharacterInfo?>();

      _socket!.emitWithAck(
        'get_character_info',
        {'character': character},
        ack: (response) {
          try {
            final data = Map<String, dynamic>.from(response as Map);
            if (data['success'] == true) {
              final info = CharacterInfo.fromJson(data);
              _characterInfoCache[character] = info;
              completer.complete(info);
            } else {
              completer.complete(null);
            }
          } catch (e) {
            completer.complete(null);
          }
        },
      );

      return await completer.future.timeout(_kInfoTimeout);
    } on TimeoutException {
      debugPrint('[HandwritingWS] Character info request timed out');
      return null;
    } catch (e) {
      debugPrint('[HandwritingWS] Error fetching character info: $e');
      return null;
    }
  }

  /// Clear the character info cache (e.g., after a DB update).
  void clearCache() {
    _characterInfoCache.clear();
  }

  /// Dispose of all resources.
  void dispose() {
    disconnect();
    _resultStreamController.close();
    _characterInfoCache.clear();
  }
}
