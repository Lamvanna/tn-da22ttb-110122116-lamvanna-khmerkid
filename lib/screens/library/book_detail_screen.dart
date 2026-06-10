import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/app_header.dart';
import '../../widgets/feedback_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final String title;
  final String imagePath;

  const BookDetailScreen({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  int _currentPage = 0;
  bool _isSpeaking = false;

  // Mock pages of a book
  final List<_BookPage> _pages = [
    const _BookPage(
      textKhmer: 'សួស្តីឆ្នាំថ្មី ឆ្នាំថ្មីឆ្នាំចរ។',
      textVietnamese: 'Chúc mừng năm mới, năm mới tốt lành.',
      illustration: 'image/Khám phá văn hóa.png',
    ),
    const _BookPage(
      textKhmer: 'យើងទាំងអស់គ្នាស្រឡាញ់គ្រួសាររបស់យើង។',
      textVietnamese: 'Tất cả chúng ta đều yêu quý gia đình của mình.',
      illustration: 'image/Sách.png',
    ),
    const _BookPage(
      textKhmer: 'ការរៀនសូត្រនាំមកនូវចំណេះដឹងដ៏អស្ចារ្យ។',
      textVietnamese: 'Học tập mang lại nguồn tri thức tuyệt vời.',
      illustration: 'image/Học.png',
    ),
    const _BookPage(
      textKhmer: 'កុមារគ្រប់រូបមានសិទ្ធិទទួលបានការអប់រំ។',
      textVietnamese: 'Mọi đứa trẻ đều có quyền được giáo dục.',
      illustration: 'image/Đọc hiểu.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
    await _tts.setSpeechRate(0.35);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Column(
        children: [
          // Header
          AppHeader(
            title: widget.title,
            onBack: () => Navigator.pop(context),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu vào danh mục yêu thích! ❤️')),
                );
              },
            ),
          ),

          // Main book content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                children: [
                  // Page Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Illustration
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            height: 180.h,
                            color: const Color(0xFFEDF4FF),
                            child: Center(
                              child: Image.asset(
                                page.illustration,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Khmer text display
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            page.textKhmer,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.battambang(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Audio speak trigger
                        GestureDetector(
                          onTap: () => _speak(page.textKhmer),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F1FF),
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                  color: const Color(0xFF2B7DD9),
                                  size: 20.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  _isSpeaking ? 'Dừng đọc' : 'Nghe phát âm',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2B7DD9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Translation box
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dịch nghĩa:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                page.textVietnamese,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Bottom Page Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous page button
                      Opacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _tts.stop();
                                    _isSpeaking = false;
                                  });
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded, size: 14.sp, color: const Color(0xFF475569)),
                                SizedBox(width: 8.w),
                                Text(
                                  'Trang trước',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Page numbers
                      Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF475569),
                        ),
                      ),

                      // Next / Complete page button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage < _pages.length - 1) {
                            setState(() {
                              _currentPage++;
                              _tts.stop();
                              _isSpeaking = false;
                            });
                          } else {
                            _showFinishDialog();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2B7DD9), Color(0xFF6BB8F7)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2B7DD9).withValues(alpha: 0.25),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentPage < _pages.length - 1 ? 'Trang tiếp' : 'Hoàn thành',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                _currentPage < _pages.length - 1
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.check_circle_rounded,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
      xpEarned: 25,
      message: 'Chúc mừng con đã đọc xong cuốn sách tuyệt vời này! 📚✨',
    );
  }
}

class _BookPage {
  final String textKhmer;
  final String textVietnamese;
  final String illustration;

  const _BookPage({
    required this.textKhmer,
    required this.textVietnamese,
    required this.illustration,
  });
}
