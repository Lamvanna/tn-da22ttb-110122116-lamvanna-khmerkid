import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Simple audio recorder using platform MethodChannel
/// Works on Android using MediaRecorder
class SimpleRecorder {
  static const _channel = MethodChannel('com.khmerkid/audio_recorder');
  String? _currentPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;

  Future<String?> start() async {
    if (_isRecording) await stop();
    
    try {
      final dir = await getTemporaryDirectory();
      _currentPath = '${dir.path}/khmer_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _channel.invokeMethod('startRecording', {'path': _currentPath});
      _isRecording = true;
      debugPrint('[SimpleRecorder] Started: $_currentPath');
      return _currentPath;
    } catch (e) {
      debugPrint('[SimpleRecorder] Start error: $e');
      _isRecording = false;
      _currentPath = null;
      return null;
    }
  }

  Future<String?> stop() async {
    if (!_isRecording) return _currentPath;
    
    try {
      await _channel.invokeMethod('stopRecording');
      _isRecording = false;
      debugPrint('[SimpleRecorder] Stopped: $_currentPath');
      return _currentPath;
    } catch (e) {
      debugPrint('[SimpleRecorder] Stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  void dispose() {
    stop();
  }
}
