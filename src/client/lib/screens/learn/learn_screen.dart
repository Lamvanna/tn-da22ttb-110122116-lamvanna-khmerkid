import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'letter_map_screen.dart';
import 'spelling_hub_screen.dart';
import 'writing_map_screen.dart';
import 'reading_map_screen.dart';
import 'vowel_screen.dart';
import 'consonant_series_screen.dart';
import 'number_map_screen.dart';
import 'diacritical_map_screen.dart';
import 'vocabulary_screen.dart';
import '../../services/score_service.dart';
import '../../widgets/app_page_route.dart';
import '../../models/khmer_number.dart';
import '../../models/khmer_spelling.dart';
import '../../models/khmer_diacritical.dart';
import '../../models/khmer_writing.dart';

/// Màn hình Học - Lộ trình học tập Khmer (dạng danh sách) - RESPONSIVE
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
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

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      AppPageRoute(page: screen),
    ).then((_) {
      if (mounted) {
        _loadScore();
      }
    });
  }

  String _getZoneBtnText(int zoneId, double prog, bool isComingSoon) {
    if (isComingSoon) return context.translate('learning_path.coming_soon');
    if (prog >= 1.0) {
      final claimed = _score?.isRewardClaimed(zoneId) ?? false;
      return claimed ? "Đã nhận" : "Nhận phần thưởng";
    }
    return prog > 0.0 ? context.translate('learning_path.continue') : context.translate('learning_path.start');
  }

  void _showRewardDialog(_Zone zone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header icon (trophy/gift)
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset('image/sao.png', width: 50.w, height: 50.h),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Chúc mừng bé! 🎉',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFA000),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Bé đã hoàn thành xuất sắc lộ trình:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  zone.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: zone.color,
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () async {
                    if (_score != null) {
                      await _score!.addStars(zone.stars);
                      await _score!.claimReward(zone.n);
                      await _loadScore(); // Reload score & update UI
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bé đã nhận thành công +${zone.stars} sao! ⭐',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 3,
                  ),
                  child: Text(
                    'Nhận +${zone.stars} Sao 🌟',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildOverview(context);
  }

  List<_Zone> _getZones() {
    final lp = (_score?.lettersLearned ?? 0) / 33;
    final vp = (_score?.vowelsLearned ?? 0) / 24;

    final totalNumbers = KhmerNumberData.numbers.length;
    final doneNumbers = _score?.numbersLearned ?? 0;
    final numProg = totalNumbers > 0 ? doneNumbers / totalNumbers : 0.0;

    final totalSpelling = KhmerSpellingData.lessons.length;
    final doneSpelling = _score?.spellingLearned ?? 0;
    final spellProg = totalSpelling > 0 ? doneSpelling / totalSpelling : 0.0;

    final totalDiacritical = KhmerDiacriticalData.diacriticals.length;
    final doneDiacritical = _score?.diacriticalsLearned ?? 0;
    final diacritProg = totalDiacritical > 0 ? doneDiacritical / totalDiacritical : 0.0;

    final totalWriting = KhmerWritingData.lessons.length;
    final doneWriting = _score?.writingLearned ?? 0;
    final writeProg = totalWriting > 0 ? doneWriting / totalWriting : 0.0;

    // Phụ âm o-ô tính tổng hợp dựa trên số phụ âm + nguyên âm đã học
    final totalO_O = 33 + 24;
    final doneO_O = (_score?.lettersLearned ?? 0) + (_score?.vowelsLearned ?? 0);
    final o_oProg = totalO_O > 0 ? doneO_O / totalO_O : 0.0;

    final totalVocab = 38;
    final doneVocab = _score?.vocabLearned ?? 0;
    final vocabProg = totalVocab > 0 ? doneVocab / totalVocab : 0.0;

    final readingProg = (_score?.readingLearned ?? 0) / 5;

    return [
      _Zone(n: 1, title: context.translate('learning_path.consonants'), sub: context.translate('learning_path.consonants_sub'),
        icon: Icons.abc_rounded, img: 'image/Phụ âm.png', prog: lp, total: 33, done: _score?.lettersLearned ?? 0,
        color: const Color(0xFF2979FF), stars: 100, btn: _getZoneBtnText(1, lp, false),
        onTap: () => _navigateTo(LetterMapView(onBack: () => Navigator.pop(context)))),
      _Zone(n: 2, title: context.translate('learning_path.vowels'), sub: context.translate('learning_path.vowels_sub'),
        icon: Icons.record_voice_over_rounded, img: 'image/Nguyên âm.png', prog: vp, total: 24, done: _score?.vowelsLearned ?? 0,
        color: const Color(0xFFFF1744), stars: 100, btn: _getZoneBtnText(2, vp, false),
        onTap: () => _navigateTo(VowelScreen(onBack: () => Navigator.pop(context)))),
      _Zone(n: 3, title: context.translate('learning_path.o_o'), sub: context.translate('learning_path.o_o_sub'),
        icon: Icons.text_fields_rounded, img: 'image/Học phụ âm o và ô.png', prog: o_oProg, total: totalO_O, done: doneO_O,
        color: const Color(0xFF43A047), stars: 100, btn: _getZoneBtnText(3, o_oProg, false),
        onTap: () => _navigateTo(ConsonantSeriesScreen(onBack: () => Navigator.pop(context)))),
      _Zone(n: 4, title: context.translate('learning_path.numbers'), sub: context.translate('learning_path.numbers_sub'),
        icon: Icons.calculate_rounded, img: 'image/Học số.png', prog: numProg, total: totalNumbers, done: doneNumbers,
        color: const Color(0xFF00ACC1), stars: 100, btn: _getZoneBtnText(4, numProg, false),
        onTap: () => _navigateTo(NumberMapScreen(onBack: () => Navigator.pop(context)))),
      _Zone(n: 5, title: context.translate('learning_path.spelling'), sub: context.translate('learning_path.spelling_sub'),
        icon: Icons.spellcheck_rounded, img: 'image/Đánh vần.png', prog: spellProg, total: totalSpelling, done: doneSpelling,
        color: const Color(0xFFF57C00), stars: 150, btn: _getZoneBtnText(5, spellProg, false),
        onTap: () => _navigateTo(const SpellingHubScreen())),
      _Zone(n: 6, title: context.translate('learning_path.diacritics'), sub: context.translate('learning_path.diacritics_sub'),
        icon: Icons.format_shapes_rounded, img: 'image/Học dấu.png', prog: diacritProg, total: totalDiacritical, done: doneDiacritical,
        color: const Color(0xFFFFD600), stars: 100, btn: _getZoneBtnText(6, diacritProg, false),
        onTap: () => _navigateTo(DiacriticalMapScreen(onBack: () => Navigator.pop(context)))),
      _Zone(n: 7, title: context.translate('learning_path.reading'), sub: context.translate('learning_path.reading_sub'),
        icon: Icons.auto_stories_rounded, img: 'image/Tập đọc.png', prog: readingProg, total: 5, done: _score?.readingLearned ?? 0,
        color: const Color(0xFF00B0FF), stars: 150, btn: _getZoneBtnText(7, readingProg, false),
        onTap: () => _navigateTo(ReadingMapScreen(onBack: () => Navigator.pop(context)))),
      _Zone(n: 8, title: context.translate('learning_path.writing'), sub: context.translate('learning_path.writing_sub'),
        icon: Icons.draw_rounded, img: 'image/Tập viết.png', prog: writeProg, total: totalWriting, done: doneWriting,
        color: const Color(0xFFFF9100), stars: 150, btn: _getZoneBtnText(8, writeProg, false),
        onTap: () => _navigateTo(const WritingMapScreen())),
      _Zone(n: 9, title: context.translate('learning_path.vocabulary'), sub: context.translate('learning_path.vocabulary_sub'),
        icon: Icons.book_rounded, img: 'image/Sách.png', prog: vocabProg, total: totalVocab, done: doneVocab,
        color: const Color(0xFF7E57C2), stars: 100, btn: _getZoneBtnText(9, vocabProg, false),
        onTap: () => _navigateTo(const VocabularyScreen())),
      _Zone(n: 10, title: context.translate('learning_path.reading_comp'), sub: context.translate('learning_path.reading_comp_sub'),
        icon: Icons.menu_book_rounded, img: 'image/Đọc hiểu.png', prog: 0, total: 25, done: 0,
        color: const Color(0xFFFF4081), stars: 200, btn: _getZoneBtnText(10, 0, true), isComingSoon: true,
        onTap: () => _showComingSoon(context)),
      _Zone(n: 11, title: context.translate('learning_path.culture'), sub: context.translate('learning_path.culture_sub'),
        icon: Icons.temple_buddhist_rounded, img: 'image/Khám phá văn hóa.png', prog: 0, total: 20, done: 0,
        color: const Color(0xFF536DFE), stars: 200, btn: _getZoneBtnText(11, 0, true), isComingSoon: true,
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
        Text(context.translate('learning_path.coming_soon_toast'),
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
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ─── Decorative circles ──
          Positioned(
            right: -40.w, top: -30.h,
            child: Container(
              width: 120.w, height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -25.w, bottom: -20.h,
            child: Container(
              width: 80.w, height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ─── Content ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(80.w, 4.h, 80.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          context.translate('learning_path.title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats positioned beautifully at top right of the header!
          Positioned(
            top: MediaQuery.of(context).padding.top + 2.h,
            right: 16.w,
            child: _buildHeaderStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Stars
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('image/sao.png', width: 14.w, height: 14.h, fit: BoxFit.contain),
              SizedBox(width: 4.w),
              Text(
                '${_score?.totalStars ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        // Streak
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('image/Lửa chuổi.png', width: 14.w, height: 14.h, fit: BoxFit.contain),
              SizedBox(width: 4.w),
              Text(
                '${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Continue Learning Card ──
  Widget _buildContinueCard(_Zone zone) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: zone.onTap,
      child: Container(
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
                Text(context.translate('learning_path.continue'), style: GoogleFonts.plusJakartaSans(
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
                          Text(context.translate('learning_path.lessons_count', args: {'done': zone.done, 'total': zone.total}), style: GoogleFonts.plusJakartaSans(
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
                      Text(context.translate('learning_path.points'), style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ]),
                  ),
                ]),
                SizedBox(height: 8.h),
                Container(
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
                    Text(context.translate('learning_path.continue'), style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(width: 6.w),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
                  ]),
                ),
              ],
            )),
          ]),
        ]),
      ),
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
          Expanded(child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (zone.btn == "Nhận phần thưởng") {
                _showRewardDialog(zone);
              } else {
                zone.onTap?.call();
              }
            },
            child: Container(
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
                    SizedBox(height: 6.h),
                    // Row 3: Progress % & Button on the same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Progress % and count
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(zone.prog * 100).toInt()}%', 
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp, 
                                  fontWeight: FontWeight.w800, 
                                  color: zone.color)),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  context.translate('learning_path.lessons_count', args: {'done': zone.done, 'total': zone.total}), 
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp, 
                                    fontWeight: FontWeight.w600, 
                                    color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // Right: Button
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: zone.btn == "Nhận phần thưởng"
                              ? const Color(0xFF4CAF50)
                              : zone.btn == "Đã nhận"
                                ? const Color(0xFF90A4AE)
                                : (zone.isComingSoon ? zone.color.withValues(alpha: 0.4) : zone.color),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: zone.btn == "Nhận phần thưởng"
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                  : zone.btn == "Đã nhận"
                                    ? Colors.black12
                                    : zone.color.withValues(alpha: 0.15),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (zone.isComingSoon)
                                Padding(
                                  padding: EdgeInsets.only(right: 4.w),
                                  child: Icon(Icons.lock_rounded, size: 11.sp, color: Colors.white)),
                              if (zone.btn == "Nhận phần thưởng")
                                Padding(
                                  padding: EdgeInsets.only(right: 4.w),
                                  child: Icon(Icons.card_giftcard_rounded, size: 11.sp, color: Colors.white)),
                              Text(zone.btn, 
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp, 
                                  fontWeight: FontWeight.w700, 
                                  color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
              ]),
            ),
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
            Text(context.translate('learning_path.developing'), style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 2.h),
            Text(context.translate('learning_path.more_lessons'), style: GoogleFonts.plusJakartaSans(
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
