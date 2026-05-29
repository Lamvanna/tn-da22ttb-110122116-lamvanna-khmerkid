import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:string_similarity/string_similarity.dart';

/// ════════════════════════════════════════════════════════════════════
/// OCR Service — Nhận dạng chữ Khmer viết tay
/// ────────────────────────────────────────────────────────────────────
/// Features:
///   • Render strokes → PNG image
///   • OCR bằng Tesseract (language: khm)
///   • So sánh kết quả OCR với chữ mẫu
///   • Fallback scoring nếu OCR không khả dụng
/// ════════════════════════════════════════════════════════════════════

class OcrResult {
  final String recognizedText;
  final int accuracy; // 0-100
  final bool passed;
  final bool ocrAvailable;

  const OcrResult({
    required this.recognizedText,
    required this.accuracy,
    required this.passed,
    this.ocrAvailable = true,
  });
}

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  bool _tessdataReady = false;

  // ─── Tessdata Setup ─────────────────────────────────────────────

  /// Kiểm tra và chuẩn bị tessdata cho Khmer OCR.
  /// Tessdata cần được đặt sẵn trong assets/tessdata/khm.traineddata
  /// và copy vào app documents/tessdata/ khi chạy lần đầu.
  Future<bool> ensureTessdata() async {
    if (_tessdataReady) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final tessDir = Directory('${dir.path}/tessdata');
      final trainedFile = File('${tessDir.path}/khm.traineddata');

      if (await trainedFile.exists()) {
        _tessdataReady = true;
        debugPrint('[OcrService] ✅ Tessdata ready');
        return true;
      }

      // Tessdata chưa có — cần copy từ assets
      debugPrint('[OcrService] ⚠️ khm.traineddata not found at ${tessDir.path}');
      debugPrint('[OcrService] Attempting to use Tesseract without pre-copied data...');
      
      // Try to create tessdata directory
      if (!await tessDir.exists()) {
        await tessDir.create(recursive: true);
      }

      // Note: In production, copy from assets bundle
      // For now, mark as not ready and use fallback
      _tessdataReady = false;
      return false;
    } catch (e) {
      debugPrint('[OcrService] ❌ Tessdata setup error: $e');
      _tessdataReady = false;
      return false;
    }
  }

  // ─── OCR from PNG file ──────────────────────────────────────────

  /// Nhận dạng chữ từ file PNG
  Future<OcrResult> recognizeFromFile(
    String imagePath, {
    required String expectedText,
  }) async {
    if (!_tessdataReady) {
      await ensureTessdata();
    }

    if (!_tessdataReady) {
      return OcrResult(
        recognizedText: '',
        accuracy: 0,
        passed: false,
        ocrAvailable: false,
      );
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final tessDataPath = dir.path;

      final recognized = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'khm',
        args: {
          'tessdata': tessDataPath,
          'psm': '10', // Treat image as single character
        },
      );

      final cleanText = recognized.trim();
      final accuracy = _compareTexts(cleanText, expectedText);
      final passed = accuracy >= 60;

      debugPrint(
          '[OcrService] OCR result: "$cleanText" vs "$expectedText" = $accuracy%');

      return OcrResult(
        recognizedText: cleanText,
        accuracy: accuracy,
        passed: passed,
        ocrAvailable: true,
      );
    } catch (e) {
      debugPrint('[OcrService] ❌ OCR error: $e');
      return OcrResult(
        recognizedText: '',
        accuracy: 0,
        passed: false,
        ocrAvailable: false,
      );
    }
  }

  // ─── Save strokes as PNG ────────────────────────────────────────

  /// Render danh sách strokes thành file PNG.
  /// Trả về đường dẫn file.
  Future<String?> saveStrokesAsPng({
    required List<List<Offset>> strokes,
    required double width,
    required double height,
  }) async {
    try {
      // Create a PictureRecorder to draw strokes
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const ui.Color(0xFFFFFFFF),
      );

      // Draw strokes
      final paint = Paint()
        ..color = const ui.Color(0xFF000000)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in strokes) {
        if (stroke.length < 2) continue;
        final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/khmer_write_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('[OcrService] ✅ Saved PNG: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[OcrService] ❌ Save PNG error: $e');
      return null;
    }
  }

  // ─── Helper ─────────────────────────────────────────────────────

  int _compareTexts(String recognized, String expected) {
    final a = recognized.trim().toLowerCase();
    final b = expected.trim().toLowerCase();

    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 100;
    if (a.contains(b) || b.contains(a)) return 90;

    final similarity = StringSimilarity.compareTwoStrings(a, b);
    return (similarity * 100).round().clamp(0, 100);
  }
}
