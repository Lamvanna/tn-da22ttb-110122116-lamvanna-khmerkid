import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/pronunciation_result.dart';
import '../services/voice_recognition_service.dart';


enum SpeakState { idle, recording, processing, result }

/// Widget luyện phát âm tiếng Khmer cho trẻ em, tích hợp thu âm và so sánh giọng nói
class KhmerSpeakWidget extends StatefulWidget {
  final String targetWord;       // Từ mẫu chuẩn cần so khớp phát âm
  final String romanized;        // Phiên âm Latin
  final String meaning;          // Nghĩa tiếng Việt của từ
  final VoidCallback? onComplete; // Callback kích hoạt khi phát âm đạt yêu cầu
  final Color accentColor;
  final Color accentColorDark;
  final Color surfaceColor;

  const KhmerSpeakWidget({
    super.key,
    required this.targetWord,
    required this.romanized,
    required this.meaning,
    this.onComplete,
    this.accentColor = const Color(0xFF1E88E5),
    this.accentColorDark = const Color(0xFF1565C0),
    this.surfaceColor = const Color(0xFFEEF4FC),
  });

  @override
  State<KhmerSpeakWidget> createState() => _KhmerSpeakWidgetState();
}

class _KhmerSpeakWidgetState extends State<KhmerSpeakWidget>
    with SingleTickerProviderStateMixin {
  final VoiceRecognitionService _recordService = VoiceRecognitionService();


  late AnimationController _pulseCtrl;
  SpeakState _state = SpeakState.idle;
  
  Timer? _timer;
  int _recordSeconds = 0;
  String? _filePath;
  
  PronunciationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Bắt đầu thu âm giọng nói của bé
  void _startRecording() async {
    setState(() {
      _state = SpeakState.recording;
      _recordSeconds = 0;
      _errorMessage = null;
      _result = null;
    });

    _pulseCtrl.repeat(reverse: true);
    
    // Gọi phương thức bắt đầu thu âm từ service
    _recordService.startRecording();

    // Kích hoạt bộ đếm thời gian
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
      // Tự động dừng nếu quá 30 giây (giới hạn an toàn)
      if (_recordSeconds >= 30) {
        _stopRecording();
      }
    });
  }

  /// Dừng thu âm và tự động tải lên backend để chấm điểm
  void _stopRecording() async {
    _timer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.value = 0.0;

    setState(() {
      _state = SpeakState.processing;
    });

    try {
      final path = await _recordService.stopRecording();
      if (path == null) {
        throw Exception("Không thể lấy tệp tin âm thanh đã ghi.");
      }
      _filePath = path;

      // Upload và nhận kết quả chấm điểm từ server
      final result = await _recordService.uploadAudio(_filePath!, widget.targetWord);

      setState(() {
        _result = result;
        _state = SpeakState.result;
      });

      // Nếu phát âm đạt chuẩn (isCorrect = true), kích hoạt callback hoàn thành
      if (result.isCorrect) {
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _state = SpeakState.result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tiêu đề hoạt động ──
        Padding(
          padding: EdgeInsets.only(top: 12.h, bottom: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: widget.accentColor, size: 22.w),
              SizedBox(width: 8.w),
              Text(
                'Luyện phát âm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: widget.accentColorDark,
                ),
              ),
            ],
          ),
        ),

        // ── Khung nội dung thay đổi theo trạng thái ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Hiển thị từ mẫu (Không có khung, không có phiên âm/nghĩa)
                 // 1. Hiển thị từ mẫu (Không có khung, không có phiên âm/nghĩa, không có loa)
                Center(
                  child: Text(
                    widget.targetWord,
                    style: GoogleFonts.battambang(
                      fontSize: 56.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColorDark,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // 2. Khu vực trạng thái chính
                _buildMainStateView(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Xây dựng giao diện chính tùy theo trạng thái ghi âm
  Widget _buildMainStateView() {
    switch (_state) {
      case SpeakState.idle:
        return Column(
          children: [
            _buildMicButton(
              onPressed: _startRecording,
              icon: Icons.mic_rounded,
              color: widget.accentColor,
              label: 'Chạm để nói',
            ),
            SizedBox(height: 12.h),
            Text(
              'Nhấn nút và đọc to từ mẫu nhé!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ],
        );

      case SpeakState.recording:
        return Column(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                return _buildMicButton(
                  onPressed: _stopRecording,
                  icon: Icons.stop_rounded,
                  color: Colors.redAccent,
                  label: 'Đang ghi âm...',
                  pulseValue: _pulseCtrl.value,
                );
              },
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '0:${_recordSeconds.toString().padLeft(2, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'Chạm một lần nữa để hoàn tất phát âm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ],
        );

      case SpeakState.processing:
        return Column(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 45.w,
                  height: 45.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Đang chấm điểm phát âm...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: widget.accentColorDark,
              ),
            ),
          ],
        );

      case SpeakState.result:
        return _buildResultView();
    }
  }

  /// Nút micro tùy chỉnh hỗ trợ hiệu ứng xung nhịp (pulse animation)
  Widget _buildMicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String label,
    double pulseValue = 0.0,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 110.w,
        height: 110.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: pulseValue > 0.0 ? 0.3 : 0.15),
            width: (pulseValue > 0.0 ? 1.5 + 8 * pulseValue : 1.5).w,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Center(
          child: Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35 + 0.15 * pulseValue),
                  blurRadius: (12 + 10 * pulseValue).r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 38.w,
            ),
          ),
        ),
      ),
    );
  }

  /// Khung hiển thị kết quả chấm điểm
  Widget _buildResultView() {
    if (_errorMessage != null) {
      return Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48.w),
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _state = SpeakState.idle;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              'Thử lại nhé',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
          ),
        ],
      );
    }

    final res = _result!;
    final isCorrect = res.isCorrect;

    return Column(
      children: [
        // Vòng tròn điểm số
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            border: Border.all(
              color: isCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
              width: 3.w,
            ),
          ),
          child: Center(
            child: Text(
              '${res.finalScore.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // Phản hồi chữ nghĩa
        Text(
          res.feedback,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
        SizedBox(height: 10.h),

        // So sánh chi tiết
        if (!res.isSTTEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  'Con đã nói: "${res.recognizedText}"',
                  style: GoogleFonts.battambang(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Độ tương đồng: ${res.similarityPercentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // Các nút hành động cuối
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _state = SpeakState.idle;
                  _result = null;
                });
              },
              icon: Icon(
                isCorrect ? Icons.replay_rounded : Icons.refresh_rounded,
                color: Colors.white,
                size: 18.w,
              ),
              label: Text(
                isCorrect ? 'Nói lại' : 'Thử lại',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? AppColors.textHint : widget.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
            ),
            if (isCorrect) ...[
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: () {
                  // Chỉ đóng sheet kết quả
                  // (Tiến trình Nói sẽ được đánh dấu hoàn thành)
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  'Tuyệt vời',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
