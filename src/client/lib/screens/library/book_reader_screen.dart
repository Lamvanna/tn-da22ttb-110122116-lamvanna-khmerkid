import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'category_list_screen.dart';
import '../../widgets/feedback_dialog.dart';

class BookReaderScreen extends StatefulWidget {
  final String title;
  final String imagePath;
  final List<Map<String, dynamic>>? pages;

  const BookReaderScreen({
    super.key,
    required this.title,
    required this.imagePath,
    this.pages,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final FlutterTts _tts = FlutterTts();
  
  // ── Common State ──
  bool get _isStory {
    final t = widget.title.toLowerCase();
    return t.contains('truyện') ||
        t.contains('thỏ') ||
        t.contains('rùa') ||
        t.contains('sóc') ||
        t.contains('cầu vồng') ||
        t.contains('tích') ||
        t.contains('ngụ ngôn') ||
        t.contains('thông minh') ||
        t.contains('ដំរី') || 
        t.contains('ស្វា') || 
        t.contains('ទន្សាយ') || 
        t.contains('អណ្តើក');
  }
  bool _isFavorited = false;

  // ── Story Reader State ──
  int _currentStoryPage = 0;
  bool _isSpeaking = false;
  bool _isAutoReading = false;
  bool _showTranslation = true;
  List<_BookPage> _storyPages = [];

  // ── Consonant Book Reader State ──
  double _pdfZoom = 1.0;
  int _currentPdfPage = 1;
  final PageController _pdfPageController = PageController();
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    if (_isStory) {
      _storyPages = _getStoryPages(widget.title, widget.imagePath);
    }
    _initTts();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    if (!mounted) return;
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if ((_pdfZoom - scale).abs() > 0.01) {
      setState(() {
        _pdfZoom = scale;
      });
    }
  }

  void _setPdfZoom(double scale) {
    if (scale < 0.8) scale = 0.8;
    if (scale > 3.0) scale = 3.0;
    _transformationController.value = Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    _pdfPageController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  // ── TTS Methods ──
  Future<void> _initTts() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages != null) {
        final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
        final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
        await _tts.setLanguage(hasKhmer ? 'km' : 'vi-VN');
      } else {
        await _tts.setLanguage('km');
      }
    } catch (_) {
      try {
        await _tts.setLanguage('km');
      } catch (_) {}
    }
    await _tts.setSpeechRate(0.35);

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
      if (_isAutoReading && _isStory) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || !_isAutoReading) return;
          if (_currentStoryPage < _storyPages.length - 1) {
            setState(() {
              _currentStoryPage++;
            });
            _speakKhmerAndContinue();
          } else {
            setState(() {
              _isAutoReading = false;
            });
            _showFinishDialog();
          }
        });
      }
    });
  }

  Future<void> _speakKhmerAndContinue() async {
    final text = _storyPages[_currentStoryPage].textKhmer;
    setState(() => _isSpeaking = true);
    await _tts.setLanguage('km');
    await _tts.speak(text);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking || _isAutoReading) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _isAutoReading = false;
      });
    } else {
      setState(() => _isSpeaking = true);
      await _tts.setLanguage('km');
      await _tts.speak(text);
    }
  }

  Future<void> _speakVietnamese(String text) async {
    if (_isSpeaking || _isAutoReading) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _isAutoReading = false;
      });
    } else {
      setState(() => _isSpeaking = true);
      await _tts.setLanguage('vi-VN');
      await _tts.speak(text);
    }
  }

  // ── Helper Data Builder ──
  List<_BookPage> _getStoryPages(String title, String defaultImg) {
    final t = title.toLowerCase();
    if (t.contains('ទន្សាយ') || t.contains('thỏ') || t.contains('rùa') || t.contains('អណ្តើក')) {
      return [
        _BookPage(
          textKhmer: 'ថ្ងៃមួយ ទន្សាយ បានជួប អណ្តើក។\nមានទន្សាយ បាននិយាយថា៖\n“ខ្ញុំរត់លឿនជាងអ្នក!”\nអណ្តើក បានឆ្លើយថា៖\n“យើងសាកប្រណាំងគ្នាទៅ!”',
          textVietnamese: 'Một ngày nọ, Thỏ gặp Rùa.\nThỏ nói:\n“Tôi chạy nhanh hơn bạn!”\nRùa trả lời:\n“Chúng ta hãy thi chạy nhé!”',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'អណ្តើក', 'រត់លឿន'],
        ),
        _BookPage(
          textKhmer: 'ទន្សាយ បានសើចចំអកឱ្យអណ្តើកយ៉ាងខ្លាំង។\nវាបានយល់ព្រមភ្លាមៗចំពោះការប្រណាំងនេះ។\nសត្វផ្សេងទៀតនៅក្នុងព្រៃបានមកធ្វើជាសាក្សី។',
          textVietnamese: 'Thỏ bật cười chế giễu Rùa một cách dữ dội.\nNó lập tức đồng ý cuộc thi chạy này.\nCác loài vật khác trong rừng đã đến để làm chứng.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'អណ្តើក', 'សើចចំអក'],
        ),
        _BookPage(
          textKhmer: 'ការប្រណាំងបានចាប់ផ្តើម។\nទន្សាយ បានរត់យ៉ាងលឿនដូចខ្យល់ព្យុះ।\nក្នុងមួយប៉ប្រិចភ្នែក វារត់ទៅបាត់យ៉ាងឆ្ងាយ។',
          textVietnamese: 'Cuộc đua bắt đầu.\nThỏ chạy nhanh như một cơn gió.\nChỉ trong chớp mắt, nó đã chạy biến đi thật xa.',
          illustration: defaultImg,
          highlights: const ['ការប្រណាំង', 'ទន្សាយ', 'លឿន'],
        ),
        _BookPage(
          textKhmer: 'អណ្តើក មិនអស់សង្ឃឹមឡើយ។\nវាដើរមួយជំហានម្តងៗ យឺតៗ ប៉ុន្តែច្បាស់លាស់។\nវាមិនព្រមឈប់សម្រាកឡើយ។',
          textVietnamese: 'Rùa không hề nản lòng.\nNó bước đi từng bước một, chậm rãi nhưng chắc chắn.\nNó quyết không dừng lại nghỉ ngơi.',
          illustration: defaultImg,
          highlights: const ['អណ្តើក', 'យឺតៗ', 'không dừng'],
        ),
        _BookPage(
          textKhmer: 'បន្ទាប់ពីរត់បានពាក់កណ្តាលផ្លូវ ទន្សាយ បានងាកក្រោយ។\nវាឃើញ អណ្តើក នៅឆ្ងាយណាស់ ស្ទើរមើល không ឃើញ។\nទន្សាយ គិតថា ខ្លួនប្រាកដជាឈ្នះ។',
          textVietnamese: 'Sau khi chạy được nửa đường, Thỏ ngoảnh lại nhìn.\nNó thấy Rùa còn ở rất xa, gần như không nhìn thấy nữa.\nThỏ nghĩ rằng mình chắc chắn sẽ thắng.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'អណ្តើក', 'ឈ្នះ'],
        ),
        _BookPage(
          textKhmer: 'ទន្សាយ ឃើញដើមឈើធំ một ដែលមានម្លប់ត្រជាក់។\nវាសម្រេចចិត្តសម្រាកនៅក្រោមដើមឈើនោះ។\nវាគិតថា ទោះបីជាគេង một ស្របក់ក៏នៅតែឈ្នះដែរ។',
          textVietnamese: 'Thỏ thấy một cây to có bóng mát mát rượi.\nNó quyết định nghỉ ngơi dưới gốc cây đó.\nNó nghĩ dù có ngủ một lát thì vẫn sẽ thắng.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'ដើមឈើ', 'សម្រាក'],
        ),
        _BookPage(
          textKhmer: 'មិនយូរប៉ុន្មាន ទន្សាយ ក៏បានលង់លក់យ៉ាងស្កប់ស្កល់។\nវាបានគេងលក់យ៉ាងស្រួលក្រោមខ្យល់បក់ត្រជាក់។\nវាស្រមៃឃើញខ្លួនឯងទទួលបានជ័យជំនះ។',
          textVietnamese: 'Chẳng bao lâu sau, Thỏ đã ngủ thiếp đi ngon lành.\nNó ngủ rất say dưới làn gió mát rượi.\nNó mơ thấy mình giành được chiến thắng.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'គេងលក់', 'ជ័យជំនះ'],
        ),
        _BookPage(
          textKhmer: 'ខណៈពេលដែល ទន្សាយ កំពុងគេងលក់ អណ្តើក នៅតែបន្តដើរ។\nវាមិនខ្វល់ពីភាពហត់នឿយ ឬភាពយឺតយ៉ាវរបស់ខ្លួនឡើយ។\nវាដើរទៅមុខដោយការតាំងចិត្តខ្ពស់។',
          textVietnamese: 'Trong lúc Thỏ đang ngủ say, Rùa vẫn tiếp tục bước đi.\nNó không màng đến sự mệt mỏi hay sự chậm chạp của mình.\nNó đi về phía trước với quyết tâm cao.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'អណ្តើក', 'ដើr'],
        ),
        _BookPage(
          textKhmer: 'ទីបំផុត អណ្តើក បានដើរកាត់ ទន្សាយ ដែលកំពុងគេងលក់។\nអណ្តើក ដើរទៅមុខដោយស្ងៀមស្ងាត់បំផុត។\nទន្សាយ នៅតែគេងលក់យ៉ាងស្កប់ស្កល់ មិនដឹងខ្លួនឡើយ។',
          textVietnamese: 'Cuối cùng, Rùa đã đi qua chỗ Thỏ đang ngủ say.\nRùa bước đi một cách vô cùng lặng lẽ.\nThỏ vẫn ngủ say sưa, không hề hay biết gì.',
          illustration: defaultImg,
          highlights: const ['អណ្តើក', 'ទន្សាយ', 'គេងលក់'],
        ),
        _BookPage(
          textKhmer: 'អណ្តើក បានដើរជិតដល់ទីព្រ័ត្រហើយ។\nសត្វទាំងអស់នៅក្នុងព្រៃចាប់ផ្តើមស្រែកហ៊ោរកញ្ជ្រៀវ។\nពួកគេលើកទឹកចិត្ត អណ្តើក យ៉ាងខ្លាំង។',
          textVietnamese: 'Rùa đã đi gần đến vạch đích rồi.\nTất cả muông thú trong rừng bắt đầu reo hò cổ vũ.\nHọ cổ vũ cho Rùa rất nhiệt tình.',
          illustration: defaultImg,
          highlights: const ['អណ្តើក', 'ទីព្រ័ត្រ', 'ស្រែកហ៊ោរ'],
        ),
        _BookPage(
          textKhmer: 'សំឡេងហ៊ោរកញ្ជ្រៀវបានធ្វើឱ្យ ទន្សាយ ភ្ญាក់ពីគេង។\nវាក្រឡេកមើលទៅទីព្រ័ត្រ ហើយស្រឡាំងកាំង។\nវាឃើញ អណ្តើក ជិតដល់ទីព្រ័ត្របាត់ទៅហើយ។',
          textVietnamese: 'Tiếng reo hò náo nhiệt đã làm Thỏ thức giấc.\nNó nhìn về phía vạch đích và sửng sốt.\nNó thấy Rùa đã ở sát vạch đích mất rồi.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'ភ្ញាក់ពីគេង', 'អណ្តើក'],
        ),
        _BookPage(
          textKhmer: 'ទន្សាយ បានស្ទុះរត់យ៉ាងលឿនបំផុត ប៉ុន្តែហួសពេលទៅហើយ។\nអណ្តើក បានដើរឆ្លងកាត់ទីព្រ័ត្រមុនគេ។\nអណ្តើក បានឈ្នះការប្រណាំងដោយសារការព្យាយาม।',
          textVietnamese: 'Thỏ vội vàng chạy hết sức bình sinh nhưng đã quá muộn.\nRùa đã bước qua vạch đích trước tiên.\nRùa đã chiến thắng cuộc đua nhờ sự kiên trì.',
          illustration: defaultImg,
          highlights: const ['ទន្សាយ', 'អណ្តើក', 'ឈ្នះ'],
        ),
      ];
    } else if (t.contains('ដំរី') || t.contains('voi')) {
      return [
        _BookPage(
          textKhmer: 'កាលពីព្រេងនាយ មានកូនដំរីមួយ រស់នៅក្នុងព្រៃធំ។\nកូនដំរីនោះមានឈ្មោះថា ម៉ាំបូ។\nម៉ាំបូជាសត្វដំរីតូច một ប៉ុន្តែមានចិត្តក្លាហានណាស់។',
          textVietnamese: 'Ngày xửa ngày xưa, có một chú voi con sống trong một khu rừng lớn.\nChú voi con đó tên là Mambo.\nMambo là một chú voi nhỏ nhưng rất dũng cảm.',
          illustration: defaultImg,
          highlights: const ['ដំរី', 'ព្រៃធំ', 'ក្លាហាន'],
        ),
        _BookPage(
          textKhmer: 'ថ្ងៃមួយ មានសត្វតោសាហាវមួយចង់ចាប់សត្វព្រៃ។\nកូនដំរីតូច ម៉ាំបូ មិនខ្លាចញញើតឡើយ។\nវាបានស្រែកបន្លឺសំឡេងយ៉ាងខ្លាំងដើម្បីការពារមិត្តភក្តិ។',
          textVietnamese: 'Một ngày nọ, có một con sư tử hung dữ muốn bắt các loài thú rừng.\nChú voi con Mambo không hề sợ hãi.\nChú đã rống lên thật to để bảo vệ các bạn của mình.',
          illustration: defaultImg,
          highlights: const ['សាហាវ', 'កូនដំរី', 'ការពារ'],
        ),
      ];
    }
    return [
      _BookPage(
        textKhmer: 'កាលពីព្រេងនាយ មានរឿងនិទានដ៏អស្ចារ្យជាច្រើន។\nសូមរីករាយជាមួយការអានសៀវភៅនេះ!',
        textVietnamese: 'Ngày xửa ngày xưa, có rất nhiều câu chuyện kỳ diệu.\nHãy cùng vui vẻ đọc cuốn sách này nhé!',
        illustration: defaultImg,
        highlights: const ['រឿងនិទាន', 'អានសៀវភៅ'],
      ),
    ];
  }

  void _showFinishDialog() {
    FeedbackDialog.showSuccess(
      context,
      xpEarned: 25,
      message: 'Con đã hoàn thành câu chuyện tuyệt vời này! 📚✨',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isStory) {
      return _buildStoryReader();
    }
    return _buildConsonantBookReader();
  }

  // ═══════════════════════════════════════════════════
  // 1. STORY READER VIEW (Giao diện đọc truyện của bạn)
  // ═══════════════════════════════════════════════════
  Widget _buildStoryReader() {
    final page = _storyPages[_currentStoryPage];
    final bookTitleKhmer = widget.title.split('(').first.trim();
    final bookTitleVietnamese = widget.title.contains('(')
        ? widget.title.split('(').last.replaceAll(')', '').trim()
        : widget.title;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBAE6FD), Color(0xFFF0F9FF)],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16.sp, color: const Color(0xFF2563EB)),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$bookTitleKhmer 📖',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.battambang(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '($bookTitleVietnamese)',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isFavorited = !_isFavorited),
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Icon(
                          _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18.sp,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 30.h),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Story illustration card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Container(
                          height: 220.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF4FF),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: page.illustration.startsWith('http')
                              ? Image.network(DocItem.optimizeUrl(page.illustration, width: 500), fit: BoxFit.cover)
                              : Image.asset(page.illustration, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Page Controller Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _currentStoryPage > 0 ? () => setState(() => _currentStoryPage--) : null,
                            child: Opacity(
                              opacity: _currentStoryPage > 0 ? 1.0 : 0.4,
                              child: Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
                                child: Icon(Icons.chevron_left_rounded, size: 20.sp, color: const Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Text(
                            'Trang ${_currentStoryPage + 1}/${_storyPages.length}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                          ),
                          SizedBox(width: 20.w),
                          GestureDetector(
                            onTap: () {
                              if (_currentStoryPage < _storyPages.length - 1) {
                                setState(() => _currentStoryPage++);
                              } else {
                                _showFinishDialog();
                              }
                            },
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2563EB)),
                              child: Icon(Icons.chevron_right_rounded, size: 20.sp, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Khmer Text Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10.r, offset: Offset(0, 4.h))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8.r)),
                                  child: Text('ខ្មែរ', style: GoogleFonts.battambang(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED))),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _speak(page.textKhmer),
                                  child: Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F3FF)),
                                    child: Icon(Icons.volume_up_rounded, color: const Color(0xFF7C3AED), size: 18.sp),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _buildHighlightedKhmerText(page.textKhmer, page.highlights),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Translation Box
                      if (_showTranslation)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8.r, offset: Offset(0, 2.h))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8.r)),
                                    child: Text('Dịch nghĩa', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _speakVietnamese(page.textVietnamese),
                                    child: Container(
                                      width: 32.w,
                                      height: 32.w,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F5E9)),
                                      child: Icon(Icons.volume_up_rounded, color: const Color(0xFF15803D), size: 18.sp),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                page.textVietnamese,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, height: 1.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 16.h),

                      // Actions row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: _isSpeaking && !_isAutoReading ? Icons.stop_rounded : Icons.headphones_rounded,
                              label: 'Nghe\nkể chuyện',
                              textColor: _isSpeaking && !_isAutoReading ? const Color(0xFF6D28D9) : const Color(0xFF7C3AED),
                              cardBgColor: _isSpeaking && !_isAutoReading ? const Color(0xFFEDE9FE) : const Color(0xFFF5F3FF),
                              iconColor: _isSpeaking && !_isAutoReading ? Colors.white : const Color(0xFF7C3AED),
                              iconBgColor: _isSpeaking && !_isAutoReading ? const Color(0xFF7C3AED) : const Color(0xFFEDE9FE),
                              onTap: () => _speak(page.textKhmer),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: _buildActionButton(
                              icon: _isAutoReading ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              textColor: _isAutoReading ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
                              cardBgColor: _isAutoReading ? const Color(0xFFDBEAFE) : const Color(0xFFEFF6FF),
                              iconColor: Colors.white,
                              iconBgColor: _isAutoReading ? const Color(0xFF2563EB) : const Color(0xFF3B82F6),
                              label: 'Đọc\ntự động',
                              onTap: _toggleAutoRead,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.public_rounded,
                              textColor: _showTranslation ? const Color(0xFFB45309) : const Color(0xFF4B5563),
                              cardBgColor: _showTranslation ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                              iconColor: Colors.white,
                              iconBgColor: _showTranslation ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                              label: 'Hiện dịch',
                              onTap: () => setState(() => _showTranslation = !_showTranslation),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: _buildActionButton(
                              icon: _isFavorited ? Icons.star_rounded : Icons.star_border_rounded,
                              textColor: _isFavorited ? const Color(0xFFBE185D) : const Color(0xFFE11D48),
                              cardBgColor: _isFavorited ? const Color(0xFFFCE7F3) : const Color(0xFFFFF1F2),
                              iconColor: Colors.white,
                              iconBgColor: _isFavorited ? const Color(0xFFEC4899) : const Color(0xFFFDA4AF),
                              label: 'Lưu\nyêu thích',
                              onTap: () {
                                setState(() => _isFavorited = !_isFavorited);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_isFavorited ? 'Đã thêm vào yêu thích! ❤️' : 'Đã xóa khỏi yêu thích!'), duration: const Duration(seconds: 1)),
                                );
                              },
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
        ),
      ),
    );
  }

  void _toggleAutoRead() {
    if (_isAutoReading) {
      _tts.stop();
      setState(() {
        _isSpeaking = false;
        _isAutoReading = false;
      });
    } else {
      setState(() {
        _isAutoReading = true;
      });
      _speakKhmerAndContinue();
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color cardBgColor,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4.r, offset: Offset(0, 2.h))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBgColor),
              child: Icon(icon, size: 20.sp, color: iconColor),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: textColor, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedKhmerText(String text, List<String> highlights) {
    final defaultStyle = TextStyle(fontSize: 16.sp, height: 1.6, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B));
    final highlightStyle = TextStyle(fontSize: 16.sp, height: 1.6, fontWeight: FontWeight.w800, color: const Color(0xFFFF5252));

    if (highlights.isEmpty) {
      return Text(text, style: GoogleFonts.battambang(textStyle: defaultStyle));
    }

    List<TextSpan> spans = [];
    String remaining = text;

    while (remaining.isNotEmpty) {
      int index = -1;
      String matchWord = '';
      for (final word in highlights) {
        int wordIdx = remaining.indexOf(word);
        if (wordIdx != -1) {
          if (index == -1 || wordIdx < index) {
            index = wordIdx;
            matchWord = word;
          }
        }
      }

      if (index == -1) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (index > 0) {
        spans.add(TextSpan(text: remaining.substring(0, index)));
      }

      spans.add(TextSpan(text: matchWord, style: GoogleFonts.battambang(textStyle: highlightStyle)));
      remaining = remaining.substring(index + matchWord.length);
    }

    return RichText(text: TextSpan(style: GoogleFonts.battambang(textStyle: defaultStyle), children: spans));
  }

  // ═══════════════════════════════════════════════════
  // 2. CONSONANT BOOK READER VIEW (Giao diện học chữ cái)
  // - Hỗ trợ Tab 1: Đọc tương tác (Mở sách)
  // - Hỗ trợ Tab 2: Tài liệu PDF (Dạng PDF)
  // ═══════════════════════════════════════════════════
  Widget _buildConsonantBookReader() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: EdgeInsets.only(left: 14.w),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16.sp, color: const Color(0xFF1E293B)),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.title.split('(').first.trim(),
              style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
            Text(
              'Tài liệu PDF',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _buildPDFView(),
    );
  }

  // ── Tab 2: PDF view mode ──
  Widget _buildPDFView() {
    return Stack(
      children: [
        // Modern clean slate-blue gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FAFC), // Cool clean white-slate
                  Color(0xFFE2E8F0), // Elegant light slate gray
                ],
              ),
            ),
          ),
        ),

        // Page content viewer
        Positioned.fill(
          child: PageView.builder(
            controller: _pdfPageController,
            onPageChanged: (index) {
              setState(() {
                _currentPdfPage = index + 1;
              });
            },
            itemCount: 5,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pdfPageController,
                builder: (context, child) {
                  double pageOffset = 0.0;
                  if (_pdfPageController.hasClients && _pdfPageController.position.haveDimensions) {
                    pageOffset = _pdfPageController.page! - index;
                  } else {
                    pageOffset = ((_currentPdfPage - 1) - index).toDouble();
                  }

                  if (pageOffset > 0 && pageOffset <= 1) {
                    double screenWidth = MediaQuery.of(context).size.width;
                    
                    // Calculate positions for 3D paper curl simulation
                    double curlWidth = 24.w;
                    double curlLocalRight = screenWidth - (pageOffset * screenWidth * 0.15);
                    double curlLocalLeft = curlLocalRight - curlWidth;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Clipped turning page with a slight compression (scale X)
                        ClipRect(
                          clipper: PageCurlClipper(pageOffset: pageOffset),
                          child: Transform(
                            transform: Matrix4.diagonal3Values(1.0 - pageOffset * 0.15, 1.0, 1.0),
                            alignment: Alignment.centerLeft,
                            child: child,
                          ),
                        ),
                        
                        // Crease gradient cylinder overlay (reflection / curl highlight)
                        Positioned(
                          left: curlLocalLeft,
                          top: 0,
                          bottom: 0,
                          width: curlWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.12 * pageOffset),
                                  Colors.white.withValues(alpha: 0.35 * pageOffset),
                                  Colors.black.withValues(alpha: 0.20 * pageOffset),
                                  Colors.black.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                        
                        // Soft drop shadow cast on the page underneath (to the right of the curl)
                        Positioned(
                          left: curlLocalRight,
                          top: 0,
                          bottom: 0,
                          width: 36.w,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.18 * pageOffset),
                                  Colors.black.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return child!;
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  maxScale: 3.0,
                  minScale: 0.8,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 80.h),
                      child: GestureDetector(
                          onTapUp: (details) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final x = details.globalPosition.dx;
                            if (x < screenWidth * 0.3) {
                              if (_currentPdfPage > 1) {
                                _pdfPageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            } else if (x > screenWidth * 0.7) {
                              if (_currentPdfPage < 5) {
                                _pdfPageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Stacked Page 3 (Deepest)
                              Positioned(
                                top: 6.h,
                                left: 6.w,
                                right: -6.w,
                                bottom: -6.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4.r,
                                        offset: Offset(2.w, 2.h),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5.w),
                                  ),
                                ),
                              ),
                              // Stacked Page 2
                              Positioned(
                                top: 3.h,
                                left: 3.w,
                                right: -3.w,
                                bottom: -3.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 6.r,
                                        offset: Offset(1.w, 1.h),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5.w),
                                  ),
                                ),
                              ),
                              
                              // Main Page Sheet
                              Container(
                                height: 480.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 16.r,
                                      offset: Offset(0, 8.h),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Stack(
                                    children: [
                                      // The main content of the PDF page
                                      _buildPDFPageContent(index),

                                      // Gutter crease shadow on the left margin (binding area)
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: 14.w,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.08),
                                                Colors.black.withValues(alpha: 0.04),
                                                Colors.black.withValues(alpha: 0.0),
                                              ],
                                              stops: const [0.0, 0.3, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Pill-shaped Mini Controls Bar at the bottom
        Positioned(
          bottom: 24.h,
          left: 20.w,
          right: 20.w,
          child: _buildFloatingToolbar(),
        ),
      ],
    );
  }

  // Floating Glassmorphic Control Bar
  Widget _buildFloatingToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                // Zoom out
                GestureDetector(
                  onTap: _pdfZoom > 0.81 ? () => _setPdfZoom(_pdfZoom - 0.1) : null,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pdfZoom > 0.8 ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    ),
                    child: Icon(Icons.zoom_out_rounded, size: 18.sp, color: _pdfZoom > 0.8 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                  ),
                ),
                SizedBox(width: 8.w),
                // Zoom percent text
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${(_pdfZoom * 100).round()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Zoom in
                GestureDetector(
                  onTap: _pdfZoom < 2.99 ? () => _setPdfZoom(_pdfZoom + 0.1) : null,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pdfZoom < 2.0 ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    ),
                    child: Icon(Icons.zoom_in_rounded, size: 18.sp, color: _pdfZoom < 2.0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                  ),
                ),
                const Spacer(),
                // Page indicator badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Trang $_currentPdfPage / 5',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Reset Zoom button
                GestureDetector(
                  onTap: () => _setPdfZoom(1.0),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
                    ),
                    child: Icon(Icons.aspect_ratio_rounded, size: 18.sp, color: const Color(0xFF1E293B)),
                  ),
                ),
                SizedBox(width: 8.w),
                // Help tooltip triggers SnackBar
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bé vuốt hoặc chạm 2 bên rìa để lật trang nhé! 📖✨',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF4F46E5),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF5F3FF),
                    ),
                    child: Icon(Icons.help_outline_rounded, size: 18.sp, color: const Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPDFPageContent(int pageIndex) {
    // Highly polished children's educational book layout styles
    switch (pageIndex) {
      case 0:
        // Page 1: Cover sheet
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Double-line border frame
            Positioned(
              left: 14.w, right: 14.w, top: 14.h, bottom: 14.h,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5.w),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            Positioned(
              left: 19.w, right: 19.w, top: 19.h, bottom: 19.h,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFEF3C7), width: 1.w),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFFFEDD5), width: 1.w),
                    ),
                    child: Text(
                      'Sách Học Chữ Khmer'.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD97706),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    '33 CHỮ PHỤ ÂM\nKHMER',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E3A8A),
                      height: 1.25,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          offset: Offset(2.w, 2.h),
                          blurRadius: 4.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Styled open book badge
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 16.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 44.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Tài Liệu Học Tập Chính Thức'.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 36.h),
                  Text(
                    'Nhóm Biên Soạn Na Khmer\nNăm 2026',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        // Page 2: Table of Contents
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEFF6FF),
                    ),
                    child: Icon(Icons.list_alt_rounded, color: const Color(0xFF2563EB), size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Mục lục tài liệu'.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E3A8A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Divider(thickness: 1.5.h, color: const Color(0xFF2563EB)),
              SizedBox(height: 10.h),
              
              // TOC items wrapping
              Expanded(
                child: Column(
                  children: [
                    _buildPDFTocRow('Lời nói đầu & Hướng dẫn học', 'Trang 2', icon: Icons.menu_book_rounded, iconColor: const Color(0xFF3B82F6)),
                    _buildPDFTocRow('Bảng 33 phụ âm hoàn chỉnh', 'Trang 3', icon: Icons.grid_on_rounded, iconColor: const Color(0xFF10B981)),
                    _buildPDFTocRow('Nhóm phụ âm A (ក, ខ, គ, ឃ, ង)', 'Trang 6', icon: Icons.font_download_rounded, iconColor: const Color(0xFFF59E0B)),
                    _buildPDFTocRow('Nhóm phụ âm O (ច, ឆ, ជ, ឈ, ញ)', 'Trang 16', icon: Icons.font_download_rounded, iconColor: const Color(0xFFEC4899)),
                    _buildPDFTocRow('Nhóm phụ âm tổng hợp & Tập viết', 'Trang 30', icon: Icons.edit_rounded, iconColor: const Color(0xFF8B5CF6)),
                    _buildPDFTocRow('Bài tập ôn tập củng cố kiến thức', 'Trang 40', icon: Icons.task_alt_rounded, iconColor: const Color(0xFF6366F1)),
                  ],
                ),
              ),
              Center(child: Text('- 2 -', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)))),
            ],
          ),
        );
      case 2:
        // Page 3: General alphabet table with standard romanization pronunciation and groups
        final List<Map<String, String>> alphabetList = [
          {'char': 'ក', 'pron': 'kô', 'type': 'A'},
          {'char': 'ខ', 'pron': 'khô', 'type': 'A'},
          {'char': 'គ', 'pron': 'kô', 'type': 'O'},
          {'char': 'ឃ', 'pron': 'khô', 'type': 'O'},
          {'char': 'ង', 'pron': 'ngô', 'type': 'O'},
          {'char': 'ច', 'pron': 'chô', 'type': 'A'},
          {'char': 'ឆ', 'pron': 'chhô', 'type': 'A'},
          {'char': 'ជ', 'pron': 'chô', 'type': 'O'},
          {'char': 'ឈ', 'pron': 'chhô', 'type': 'O'},
          {'char': 'ញ', 'pron': 'nhô', 'type': 'O'},
          {'char': 'ដ', 'pron': 'dâ', 'type': 'A'},
          {'char': 'ឋ', 'pron': 'thâ', 'type': 'A'},
          {'char': 'ឌ', 'pron': 'dâ', 'type': 'O'},
          {'char': 'ឍ', 'pron': 'thâ', 'type': 'O'},
          {'char': 'ណ', 'pron': 'nâ', 'type': 'A'},
        ];

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bảng 33 phụ âm khmer'.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A)),
              ),
              SizedBox(height: 4.h),
              Divider(thickness: 1.5.h, color: const Color(0xFF2563EB)),
              SizedBox(height: 8.h),
              Text(
                'Phụ âm chia làm giọng A (nhẹ) và giọng O (trầm):',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              SizedBox(height: 10.h),
              
              // Grid layout of alphabet
              Expanded(
                child: GridView.count(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6.w,
                  mainAxisSpacing: 6.h,
                  physics: const NeverScrollableScrollPhysics(),
                  children: alphabetList.map((item) {
                    final isTypeA = item['type'] == 'A';
                    return Container(
                      decoration: BoxDecoration(
                        color: isTypeA ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF),
                        border: Border.all(
                          color: isTypeA ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE),
                          width: 1.w,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['char']!,
                            style: GoogleFonts.battambang(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                              color: isTypeA ? const Color(0xFFC2410C) : const Color(0xFF0284C7),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            item['pron']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: isTypeA ? const Color(0xFFEA580C) : const Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 6.h),
              Center(child: Text('- 3 -', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)))),
            ],
          ),
        );
      case 3:
        // Page 4: Lesson page for Letter ក (Ko)
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bài 1: Phụ âm ក (Ko)'.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A)),
              ),
              SizedBox(height: 4.h),
              Divider(thickness: 1.5.h, color: const Color(0xFF2563EB)),
              SizedBox(height: 8.h),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beautiful giant character display
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFF97316), width: 1.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.1),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'ក',
                        style: GoogleFonts.battambang(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.w),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.volume_up_rounded, size: 14.sp, color: const Color(0xFF2563EB)),
                              SizedBox(width: 4.w),
                              Text(
                                'Giọng A: Phát âm "Ko"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Cách viết: Khởi đầu từ chân trái lên đầu, lượn sóng rồi kéo thẳng xuống chân phải.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              color: const Color(0xFF1E3A8A),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 14.h),
              Text(
                'Hướng dẫn tập viết:'.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 6.h),
              
              // Tablet/ chalkboard handwriting practice guide mockup
              Container(
                height: 110.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(
                    children: [
                      // Guidelines background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: NotebookLinesPainter(),
                        ),
                      ),
                      // Practice tracing lines
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PracticeStrokePainter(character: 'ក', opacity: 0.25),
                        ),
                      ),
                      // Small pencil decoration
                      Positioned(
                        right: 8.w,
                        top: 8.h,
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 10.sp, color: const Color(0xFF94A3B8)),
                            SizedBox(width: 2.w),
                            Text(
                              'Bé viết theo nét',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Center(child: Text('- 4 -', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)))),
            ],
          ),
        );
      default:
        // Page 5: Vocab examples
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bài 1: Từ vựng ví dụ'.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A)),
              ),
              SizedBox(height: 4.h),
              Divider(thickness: 1.5.h, color: const Color(0xFF2563EB)),
              SizedBox(height: 8.h),
              Text(
                'Từ vựng đại diện cho chữ cái "ក":',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
              ),
              SizedBox(height: 10.h),
              
              // Vocab Card 1: Con gà (มีน / មាន់)
              _buildVocabCard(
                khmer: 'មាន់',
                latin: 'moan',
                translation: 'Con gà 🐔',
                icon: Icons.pets_rounded,
                iconGradientColors: [const Color(0xFFFF9900), const Color(0xFFFF5E36)],
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFFEDD5),
              ),
              SizedBox(height: 12.h),

              // Vocab Card 2: Ấm nước/Cái ca
              _buildVocabCard(
                khmer: 'កា',
                latin: 'ka',
                translation: 'Ấm nước / Cái ca ☕',
                icon: Icons.coffee_rounded,
                iconGradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFEDE9FE),
              ),

              const Spacer(),
              Center(child: Text('- 5 -', style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)))),
            ],
          ),
        );
    }
  }

  // Supporting Vocab Row Card Builder
  Widget _buildVocabCard({
    required String khmer,
    required String latin,
    required String translation,
    required IconData icon,
    required List<Color> iconGradientColors,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Graphic Illustration circle
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: iconGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconGradientColors.last.withValues(alpha: 0.25),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          // Word, Phonetic spelling & translation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      khmer,
                      style: GoogleFonts.battambang(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '/$latin/',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Vietnamese translation bubble
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: borderColor, width: 0.5.w),
                  ),
                  child: Text(
                    translation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Volume play button
          GestureDetector(
            onTap: () => _speakKhmer(khmer),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: iconGradientColors.first,
                size: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFTocRow(String title, String page, {required IconData icon, required Color iconColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12.sp, color: iconColor),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    '.' * 80,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            page,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _speakKhmer(String text) async {
    await _tts.setLanguage('km');
    await _tts.speak(text);
  }
}

// ── Supporting Data & Draw Painters ──
class _BookPage {
  final String textKhmer;
  final String textVietnamese;
  final String illustration;
  final List<String> highlights;

  const _BookPage({
    required this.textKhmer,
    required this.textVietnamese,
    required this.illustration,
    required this.highlights,
  });
}

class _PracticeStrokePainter extends CustomPainter {
  final String character;
  final double opacity;
  _PracticeStrokePainter({required this.character, this.opacity = 0.2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    final double midX = size.width / 2;
    final double midY = size.height / 2;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);

    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(8.r)), borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: GoogleFonts.battambang(
          fontSize: 60.sp,
          fontWeight: FontWeight.normal,
          color: Colors.black.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - textPainter.height / 2));

    if (opacity > 0.1) {
      final arrowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(midX - 12.w, midY + 12.h)
        ..lineTo(midX - 12.w, midY - 8.h)
        ..quadraticBezierTo(midX, midY - 16.h, midX + 12.w, midY - 8.h)
        ..lineTo(midX + 12.w, midY + 12.h);
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageCurlClipper extends CustomClipper<Rect> {
  final double pageOffset;
  PageCurlClipper({required this.pageOffset});

  @override
  Rect getClip(Size size) {
    double left = pageOffset * size.width;
    double right = size.width - (pageOffset * size.width * 0.15);
    if (left > right) {
      return Rect.zero;
    }
    return Rect.fromLTRB(left, 0, right, size.height);
  }

  @override
  bool shouldReclip(covariant PageCurlClipper oldClipper) => oldClipper.pageOffset != pageOffset;
}

class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 1.0;
    
    final paintRed = Paint()
      ..color = const Color(0xFFFECACA)
      ..strokeWidth = 1.0;

    // Draw horizontal guidelines
    double stepY = size.height / 4;
    canvas.drawLine(Offset(0, stepY), Offset(size.width, stepY), paintBlue);
    canvas.drawLine(Offset(0, stepY * 2), Offset(size.width, stepY * 2), paintRed); // Middle line (red guide)
    canvas.drawLine(Offset(0, stepY * 3), Offset(size.width, stepY * 3), paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}






