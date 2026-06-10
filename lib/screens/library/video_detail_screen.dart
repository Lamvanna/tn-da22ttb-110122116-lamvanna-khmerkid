import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_header.dart';
import '../../widgets/feedback_dialog.dart';

class VideoDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;

  const VideoDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  bool _isPlaying = false;
  bool _answeredCorrectly = false;
  int _selectedAnswerIndex = -1;

  final List<String> _quizOptions = [
    'A. Bảng chữ cái phụ âm',
    'B. Bảng chữ cái nguyên âm',
    'C. Số đếm tiếng Khmer',
    'D. Cách viết tên loài vật',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Xem & Học 📺',
            onBack: () => Navigator.pop(context),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Frame Card (Mockup Player)
                  Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background image/thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Opacity(
                            opacity: 0.45,
                            child: Image.asset(
                              widget.imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Play/Pause button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 68.w,
                            height: 68.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFFE88070),
                              boxShadow: _isPlaying
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFE88070).withValues(alpha: 0.35),
                                        blurRadius: 16.r,
                                        offset: Offset(0, 6.h),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38.sp,
                            ),
                          ),
                        ),

                        // Video Bottom Seek Bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24.r),
                                bottomRight: Radius.circular(24.r),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _isPlaying ? '00:45' : '00:00',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: LinearProgressIndicator(
                                      value: _isPlaying ? 0.35 : 0.0,
                                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE88070)),
                                      minHeight: 4.h,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  '03:40',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Title & Description
                  Text(
                    widget.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    widget.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Interactive Learning Quiz Section
                  Text(
                    'Câu hỏi ôn tập 📝',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Xem kỹ video và trả lời câu hỏi bên dưới:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Quiz Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video hôm nay hướng dẫn chúng ta bài học gì?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // Quiz Options
                        ...List.generate(_quizOptions.length, (index) {
                          final isSelected = _selectedAnswerIndex == index;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: GestureDetector(
                              onTap: _answeredCorrectly
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswerIndex = index;
                                      });
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  _quizOptions[index],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 12.h),

                        // Verify button
                        GestureDetector(
                          onTap: _selectedAnswerIndex == -1 || _answeredCorrectly
                              ? null
                              : () {
                                  if (_selectedAnswerIndex == 1) { // B is correct
                                    setState(() {
                                      _answeredCorrectly = true;
                                    });
                                    FeedbackDialog.showSuccess(
                                      context,
                                      xpEarned: 15,
                                      message: 'Tuyệt vời! Con đã trả lời chính xác và nhận được 15 XP! 🌟🏆',
                                    );
                                  } else {
                                    FeedbackDialog.showFailure(
                                      context,
                                      message: 'Chưa chính xác rồi, con hãy xem lại video và chọn lại nhé! 💪',
                                    );
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _selectedAnswerIndex == -1 || _answeredCorrectly
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Center(
                              child: Text(
                                _answeredCorrectly ? 'Đã hoàn thành câu hỏi' : 'Nộp câu trả lời',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
