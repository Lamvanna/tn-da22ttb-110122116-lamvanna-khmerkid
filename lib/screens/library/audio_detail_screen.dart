import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_header.dart';
import '../../widgets/feedback_dialog.dart';
import 'category_list_screen.dart';

class AudioDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;

  const AudioDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  State<AudioDetailScreen> createState() => _AudioDetailScreenState();
}

class _AudioDetailScreenState extends State<AudioDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  bool _isPlaying = false;
  double _sliderVal = 12.0;
  final double _maxDuration = 128.0;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _rotationCtrl.repeat();
      } else {
        _rotationCtrl.stop();
      }
    });
  }

  String _formatDuration(double seconds) {
    final int min = (seconds / 60).floor();
    final int sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Nghe kể chuyện 🎧',
            onBack: () => Navigator.pop(context),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  // Title + Desc
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8896AB),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Spinning Disc / Thumbnail Area
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Disc Ring Outer shadow
                        Container(
                          width: 190.w,
                          height: 190.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        // Spinning Disc representation
                        RotationTransition(
                          turns: _rotationCtrl,
                          child: Container(
                            width: 175.w,
                            height: 175.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E293B),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16.r,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: EdgeInsets.all(35.w),
                                child: widget.imagePath.startsWith('http')
                                    ? Image.network(
                                        DocItem.optimizeUrl(widget.imagePath, width: 500),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        widget.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        // Small center gold pin
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD700),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Audio Control Bar Card
                  Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Progress Slider
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6.h,
                            activeTrackColor: const Color(0xFF4580C4),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            thumbColor: const Color(0xFF4580C4),
                            overlayColor: const Color(0xFF4580C4).withValues(alpha: 0.1),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                          ),
                          child: Slider(
                            value: _sliderVal,
                            min: 0.0,
                            max: _maxDuration,
                            onChanged: (value) {
                              setState(() {
                                _sliderVal = value;
                              });
                            },
                          ),
                        ),
                        // Time counters
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_sliderVal),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8896AB),
                                ),
                              ),
                              Text(
                                _formatDuration(_maxDuration),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8896AB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // Playback Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Back 10s
                            IconButton(
                              icon: Icon(Icons.replay_10_rounded, size: 28.sp, color: const Color(0xFF8896AB)),
                              onPressed: () {
                                setState(() {
                                  _sliderVal = (_sliderVal - 10).clamp(0.0, _maxDuration);
                                });
                              },
                            ),
                            SizedBox(width: 14.w),

                            // Main Play/Pause Button
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4580C4), Color(0xFF6BB8F7)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4580C4).withValues(alpha: 0.25),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),

                            // Forward 10s
                            IconButton(
                              icon: Icon(Icons.forward_10_rounded, size: 28.sp, color: const Color(0xFF8896AB)),
                              onPressed: () {
                                setState(() {
                                  _sliderVal = (_sliderVal + 10).clamp(0.0, _maxDuration);
                                  if (_sliderVal >= _maxDuration) {
                                    _rotationCtrl.stop();
                                    _isPlaying = false;
                                    _showFinishDialog();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Transcript area
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lời truyện tiếng Khmer:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'កាលពីព្រេងនាយ មានសត្វទន្សាយមួយ រស់នៅក្នុងព្រៃជ្រៅ។ ទន្សាយនោះមានចរិតឆ្លាតវៃណាស់។ ថ្ងៃមួយទន្សាយបានជួបនឹងខ្លាធំមួយ...',
                          style: GoogleFonts.battambang(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                            height: 1.6,
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

  void _showFinishDialog() {
    FeedbackDialog.showSuccess(
      context,
      xpEarned: 20,
      message: 'Con đã nghe xong câu chuyện rồi, thật tuyệt vời! 🎧🌟',
    );
  }
}
