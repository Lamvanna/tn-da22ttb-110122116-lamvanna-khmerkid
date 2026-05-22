import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'letter_map_screen.dart';
import 'spelling_hub_screen.dart';
import 'writing_map_screen.dart';
import 'reading_screen.dart';
import 'vowel_screen.dart';
import 'vocabulary_screen.dart';
import '../../services/score_service.dart';
import '../../widgets/app_page_route.dart';

/// Màn hình Học - Lộ trình học tập Khmer (dạng danh sách) - RESPONSIVE
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _showLetterMap = false;
  bool _showVowels = false;
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_showLetterMap) {
      return LetterMapView(onBack: () => setState(() => _showLetterMap = false));
    }
    if (_showVowels) {
      return VowelScreen(onBack: () => setState(() => _showVowels = false));
    }
    return _buildOverview(context);
  }

  List<_Zone> _getZones() {
    final lp = (_score?.lettersLearned ?? 0) / 33;
    final vp = (_score?.vowelsLearned ?? 0) / 18;
    return [
      _Zone(n: 1, title: 'Học phụ âm', sub: 'Nhận biết 33 phụ âm Khmer',
        icon: Icons.abc_rounded, img: 'image/Phụ âm.png', prog: lp, total: 33, done: _score?.lettersLearned ?? 0,
        color: const Color(0xFF2979FF), stars: 10, btn: 'Bắt đầu học',
        onTap: () => setState(() => _showLetterMap = true)),
      _Zone(n: 2, title: 'Học nguyên âm', sub: 'Học 18 nguyên âm Khmer',
        icon: Icons.record_voice_over_rounded, img: 'image/Nguyên âm.png', prog: vp, total: 18, done: _score?.vowelsLearned ?? 0,
        color: const Color(0xFFFF1744), stars: 10, btn: 'Bắt đầu học',
        onTap: () => setState(() => _showVowels = true)),
      _Zone(n: 3, title: 'Ghép vần', sub: 'Ghép âm thành tiếng và từ',
        icon: Icons.spellcheck_rounded, img: 'image/Đánh vần.png', prog: 0, total: 30, done: 0,
        color: const Color(0xFFAA00FF), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, AppPageRoute(page: const SpellingHubScreen()))),
      _Zone(n: 4, title: 'Tập đọc', sub: 'Làm quen và đọc câu đơn giản',
        icon: Icons.auto_stories_rounded, img: 'image/Tập đọc.png', prog: 0, total: 28, done: 0,
        color: const Color(0xFF00B0FF), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, AppPageRoute(page: const ReadingScreen()))),
      _Zone(n: 5, title: 'Luyện viết', sub: 'Tập viết chữ Khmer đúng nét',
        icon: Icons.draw_rounded, img: 'image/Tập viết.png', prog: 0, total: 30, done: 0,
        color: const Color(0xFFFF9100), stars: 15, btn: 'Bắt đầu học',
        onTap: () => Navigator.push(context, AppPageRoute(page: const WritingMapScreen()))),
      _Zone(n: 6, title: 'Đọc hiểu', sub: 'Hiểu nội dung và trả lời câu hỏi',
        icon: Icons.menu_book_rounded, img: 'image/Đọc hiểu.png', prog: 0, total: 25, done: 0,
        color: const Color(0xFFFF4081), stars: 20, btn: 'Sắp ra mắt', isComingSoon: true,
        onTap: () => _showComingSoon(context)),
      _Zone(n: 7, title: 'Khám phá văn hóa', sub: 'Tìm hiểu văn hóa Khmer',
        icon: Icons.temple_buddhist_rounded, img: 'image/Khám phá văn hóa.png', prog: 0, total: 20, done: 0,
        color: const Color(0xFF536DFE), stars: 20, btn: 'Sắp ra mắt', isComingSoon: true,
        onTap: () => _showComingSoon(context)),
    ];
  }

  Widget _buildOverview(BuildContext context) {
    final zones = _getZones();
    final cont = zones.firstWhere((z) => z.prog < 1.0, orElse: () => zones.first);

    return Scaffold(
      backgroundColor: AppColors.learnBackground,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            SizedBox(height: 16.h),
            _buildContinueCard(cont),
            SizedBox(height: 20.h),
            ...zones.map((z) => _buildZoneRow(z, isLast: z.n == zones.length)),
            SizedBox(height: 8.h),
            _buildDevBanner(),
            SizedBox(height: 100.h),
          ]),
        )),
      ]),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.construction_rounded, color: Colors.white, size: 20.sp),
        SizedBox(width: 10.w),
        Text('Tính năng này sắp ra mắt! 🚀',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
      backgroundColor: AppColors.headerMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.headerMid, AppColors.headerEnd]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r), bottomRight: Radius.circular(20.r))),
      child: SafeArea(bottom: false, child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
        child: Row(children: [
          // Stars badge - white card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8.r, offset: Offset(0, 2.h))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('image/sao.png', width: 18.w, height: 18.h),
                SizedBox(width: 5.w),
                Text('${_score?.totalStars ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
              SizedBox(height: 2.h),
              Text('Điểm của bạn', style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF616161))),
            ]),
          ),
          const Spacer(),
          Text('Lộ trình học', style: GoogleFonts.plusJakartaSans(
            fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          const Spacer(),
          // Streak badge - white card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8.r, offset: Offset(0, 2.h))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('image/Lửa chuổi.png', width: 18.w, height: 18.h),
                SizedBox(width: 5.w),
                Text('${_score?.streak ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
              SizedBox(height: 2.h),
              Text('Chuỗi ngày', style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      )),
    );
  }

  // ── Continue Learning Card ──
  Widget _buildContinueCard(_Zone zone) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20.r, offset: Offset(0, 6.h))]),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: SizedBox(width: 150.w, height: 150.h,
              child: Image.asset('image/Sách.png', fit: BoxFit.contain)),
          ),
          SizedBox(width: 12.w),
          // RIGHT: title + progress + reward
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiếp tục học', style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              SizedBox(height: 8.h),
              Row(children: [
                SizedBox(width: 65.w, height: 65.w,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: zone.prog.clamp(0, 1).toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 65.w, height: 65.w, child: CircularProgressIndicator(
                        value: 1.0, strokeWidth: 5.w,
                        color: const Color(0xFFFFA726).withValues(alpha: 0.15))),
                      SizedBox(width: 65.w, height: 65.w, child: CircularProgressIndicator(
                        value: value, strokeWidth: 5.w,
                        color: const Color(0xFFFFA726), strokeCap: StrokeCap.round)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${(value * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text('${zone.done}/${zone.total} bài', style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ]),
                    ]),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 65.w, height: 65.w,
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14.r)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('image/sao.png', width: 18.w, height: 18.h),
                    SizedBox(height: 2.h),
                    Text('+${zone.stars}', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFFF0A030))),
                    Text('Điểm', style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: zone.onTap,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB340), Color(0xFFF0A030)]),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFF0A030).withValues(alpha: 0.30),
                      blurRadius: 6.r, offset: Offset(0, 2.h))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Tiếp tục học', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(width: 6.w),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
                  ]),
                ),
              ),
            ],
          )),
        ]),
      ]),
    );
  }

  Widget _buildZoneRow(_Zone zone, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Timeline: circle + dotted line
          SizedBox(width: 36.w, child: Column(children: [
            Container(
              width: 34.w, height: 34.w,
              decoration: BoxDecoration(
                color: zone.color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: zone.color.withValues(alpha: 0.3),
                  blurRadius: 6.r, offset: Offset(0, 2.h))]),
              child: Center(child: Text('${zone.n}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            if (!isLast)
              Expanded(child: CustomPaint(
                painter: _DottedLinePainter(color: zone.color.withValues(alpha: 0.3)))),
          ])),
          SizedBox(width: 10.w),
          // Card
          Expanded(child: Container(
            margin: EdgeInsets.only(bottom: 14.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12.r, offset: Offset(0, 4.h))]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Left: Image or Icon
              Container(
                width: 85.w, height: 90.h,
                decoration: BoxDecoration(
                  color: zone.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18.r)),
                child: zone.img != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Image.asset(zone.img!, fit: BoxFit.contain)))
                  : Icon(zone.icon, color: zone.color, size: 36.sp),
              ),
              SizedBox(width: 12.w),
              // Right: content
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Title + Stars badge
                  Row(children: [
                    Expanded(child: Text(zone.title, 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp, 
                        fontWeight: FontWeight.w800, 
                        color: AppColors.textPrimary))),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1), 
                        borderRadius: BorderRadius.circular(10.r)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('image/sao.png', width: 14.w, height: 14.h),
                        SizedBox(width: 3.w),
                        Text('+${zone.stars}', style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFFF0A030))),
                      ]),
                    ),
                  ]),
                  SizedBox(height: 3.h),
                  // Row 2: Subtitle
                  Text(zone.sub, style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp, 
                    fontWeight: FontWeight.w500, 
                    color: AppColors.textSecondary)),
                  SizedBox(height: 8.h),
                  // Row 3: Progress + Button
                  Row(children: [
                    Text('${(zone.prog * 100).toInt()}%', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp, 
                        fontWeight: FontWeight.w700, 
                        color: zone.color)),
                    SizedBox(width: 6.w),
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(5.r),
                      child: LinearProgressIndicator(
                        value: zone.prog.clamp(0, 1), 
                        minHeight: 5.h,
                        backgroundColor: zone.color.withValues(alpha: 0.12), 
                        color: zone.color),
                    )),
                    SizedBox(width: 6.w),
                    Text('${zone.done}/${zone.total} bài', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp, 
                        fontWeight: FontWeight.w600, 
                        color: AppColors.textSecondary)),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: zone.onTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: zone.isComingSoon ? zone.color.withValues(alpha: 0.4) : zone.color,
                          borderRadius: BorderRadius.circular(10.r)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (zone.isComingSoon)
                            Padding(
                              padding: EdgeInsets.only(right: 4.w),
                              child: Icon(Icons.lock_rounded, size: 12.sp, color: Colors.white)),
                          Text(zone.btn, 
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp, 
                              fontWeight: FontWeight.w700, 
                              color: Colors.white)),
                        ]),
                      ),
                    ),
                  ]),
                ],
              )),
            ]),
          )),
        ])),
    );
  }

  // ── Dev Banner ──
  Widget _buildDevBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1976D2).withValues(alpha: 0.25),
          blurRadius: 16.r, offset: Offset(0, 6.h))]),
      child: Row(children: [
        Text('🚧', style: TextStyle(fontSize: 28.sp)),
        SizedBox(width: 12.w),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đang phát triển', style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 2.h),
            Text('Nhiều bài học mới sẽ sớm ra mắt!', style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85))),
          ],
        )),
        Container(
          width: 36.w, height: 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(Icons.build_rounded, color: Colors.white, size: 20.sp),
        ),
      ]),
    );
  }
}

class _Zone {
  final int n, total, done, stars;
  final String title, sub, btn;
  final String? img;
  final IconData icon;
  final double prog;
  final Color color;
  final VoidCallback? onTap;
  final bool isComingSoon;

  _Zone({
    required this.n, required this.title, required this.sub,
    required this.icon, this.img, required this.prog,
    required this.total, required this.done,
    required this.color, required this.btn, required this.stars,
    this.onTap, this.isComingSoon = false,
  });
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5.w
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    double y = 6.h;
    while (y < size.height) {
      canvas.drawCircle(Offset(cx, y), 1.5.r, paint);
      y += 8.h;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
