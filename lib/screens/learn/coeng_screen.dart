import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_coeng.dart';

/// Màn hình học phụ âm có chân Khmer (phụ âm trên + ្ + phụ âm dưới + nguyên âm)
class CoengScreen extends StatefulWidget {
  final int initialIndex;
  const CoengScreen({super.key, this.initialIndex = 0});
  @override
  State<CoengScreen> createState() => _CoengScreenState();
}

class _CoengScreenState extends State<CoengScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerCoeng> _lessons = KhmerCoengData.lessons;
  final Map<int, Set<int>> _completedSteps = {};
  int _activeSheet = 0;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/elephant_mascot.png'), context);
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  KhmerCoeng get _lesson => _lessons[_idx];

  void _goTo(int i) {
    if (i < 0 || i >= _lessons.length) return;
    _animCtrl.reset();
    setState(() { _idx = i; _activeSheet = 0; });
    _animCtrl.forward();
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));
    if (_completedSteps[_idx]!.length == 3) _onLessonCompleted();
  }

  void _onLessonCompleted() {
    _lesson.isLearned = true;
    _lesson.starRating = 3;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _lessons.length - 1;
    showDialog(context: context, barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🎉', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text('Chúc mừng!', style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
            SizedBox(height: 8.h),
            Text('Bạn đã hoàn thành phụ âm chân "${_lesson.combined}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            SizedBox(height: 6.h),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(Icons.star_rounded, size: 28.w, color: AppColors.secondary))),
            SizedBox(height: 6.h),
            Text('+30 XP ⭐', style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            SizedBox(height: 20.h),
            if (hasNext) ...[
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _goTo(_idx + 1); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                child: Text('Bài tiếp theo →', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)))),
              SizedBox(height: 8.h),
            ],
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                side: BorderSide(color: AppColors.violet)),
              child: Text('Quay về bản đồ', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.violet)))),
          ]))));
  }

  bool _isStepComplete(int step) => _completedSteps[_idx]?.contains(step) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnBackground,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: ScaleTransition(scale: _scaleAnim,
            child: Column(children: [
              Stack(children: [
                RepaintBoundary(child: _buildSpellingCard()),
                if (_activeSheet != 0) Positioned.fill(child: _buildInlineSheet()),
              ]),
              SizedBox(height: 10.h),
              _buildActionRow(),
              SizedBox(height: 16.h),
              _buildNavButtons(),
            ])))),
      ]),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFFE65100), Color(0xFFFF6D00), Color(0xFFFFB300)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.35), blurRadius: 24.r, offset: Offset(0, 8.h))]),
      child: Stack(children: [
        Positioned(right: -20.w, top: -20.h,
          child: Container(width: 100.w, height: 100.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -30.w, bottom: -10.h,
          child: Container(width: 70.w, height: 70.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
        SafeArea(bottom: false,
          child: Transform.translate(offset: Offset(0, -5.h),
            child: Padding(padding: EdgeInsets.fromLTRB(8.w, 0, 0, 2.h),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    IconButton(onPressed: () => Navigator.pop(context),
                      icon: Container(padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_rounded, size: 20)),
                      color: Colors.white, padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.w)),
                    SizedBox(width: 6.w),
                    Expanded(child: Text('Phụ âm chân ${_idx + 1}/${_lessons.length}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                  ]),
                  Padding(padding: EdgeInsets.only(left: 54.w, top: 8.h),
                    child: Row(children: [
                      Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12.r)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('⭐', style: TextStyle(fontSize: 13.sp)), SizedBox(width: 4.w),
                          Text('${_lessons.where((l) => l.isLearned).length * 20}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        ])),
                      SizedBox(width: 6.w),
                      Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12.r)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('🔥', style: TextStyle(fontSize: 13.sp)), SizedBox(width: 4.w),
                          Text('Phụ Âm Chân', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        ])),
                    ])),
                ])),
                Transform.translate(offset: Offset(-5.w, -5.h),
                  child: SizedBox(width: 130.w, height: 75.h,
                    child: OverflowBox(maxHeight: 200.w, maxWidth: 200.w,
                      child: RepaintBoundary(child: Image.asset('assets/images/elephant_mascot.png',
                        width: 200.w, height: 200.w, fit: BoxFit.contain, cacheWidth: 400))))),
              ])))),
      ]),
    );
  }

  // ═══════════════════ THẺ CÔNG THỨC — 3 ô + kết quả ═══════════════════
  Widget _buildSpellingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20.r, offset: Offset(0, 6.h))]),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 70.h, 12.w, 24.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormulaBox(_lesson.upperConsonant, const Color(0xFFFF6D00), 'P.âm trên'),
              Padding(padding: EdgeInsets.only(top: 24.h),
                child: Text('្', style: GoogleFonts.battambang(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5)))),
              _buildFormulaBox(_lesson.lowerConsonant, const Color(0xFF1CB0F6), 'P.âm dưới'),
              Padding(padding: EdgeInsets.only(top: 24.h),
                child: Text('+', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5)))),
              _buildFormulaBox(_lesson.vowel, const Color(0xFFFF4B4B), 'Nguyên âm'),
              Padding(padding: EdgeInsets.only(top: 24.h),
                child: Text('=', style: GoogleFonts.plusJakartaSans(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB0BEC5)))),
              _buildFormulaBox(_lesson.combined, const Color(0xFF58CC02), 'Kết quả'),
            ],
          ),
        ),
        SizedBox(height: 40.h),
        Container(
          margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.15)),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6D00).withValues(alpha: 0.08), blurRadius: 10.r, offset: Offset(0, 3.h))]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_lesson.romanized.isNotEmpty && _lesson.romanized != '...')
                Text('"${_lesson.romanized}"', style: GoogleFonts.battambang(fontSize: 24.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE65100))),
              SizedBox(height: 6.h),
              Row(children: [
                Icon(Icons.volume_up_rounded, size: 16.w, color: const Color(0xFFFF6D00)),
                SizedBox(width: 6.w),
                Expanded(child: Text(_lesson.meaning.isNotEmpty ? 'Nghĩa: ${_lesson.meaning}' : 'Bài luyện phụ âm chân',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
              ]),
            ])),
            SizedBox(width: 8.w),
            Container(width: 56.w, height: 56.w,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8.r, offset: Offset(0, 2.h))]),
              child: Icon(Icons.account_tree_rounded, color: const Color(0xFFFF6D00), size: 26.sp)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFormulaBox(String char, Color color, String label) {
    return Column(children: [
      Container(width: 60.w, height: 60.w,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12.r, offset: Offset(0, 6.h))]),
        child: Center(child: Text(char,
          style: GoogleFonts.battambang(fontSize: 32.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)))),
      SizedBox(height: 8.h),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    ]);
  }

  // ═══════════════════ INLINE SHEET ═══════════════════
  Widget _buildInlineSheet() {
    return ClipRRect(borderRadius: BorderRadius.circular(28.r),
      child: Container(width: double.infinity, color: Colors.white,
        child: Stack(children: [
          Column(children: [
            if (_activeSheet == 1) Expanded(child: _InlineListenContent(lesson: _lesson, onComplete: () => _markStepComplete(0))),
            if (_activeSheet == 2) Expanded(child: _InlineSpeakContent(lesson: _lesson, onComplete: () => _markStepComplete(1))),
            if (_activeSheet == 3) Expanded(child: _InlineWriteContent(lesson: _lesson, onComplete: () => _markStepComplete(2))),
          ]),
          Positioned(top: 8.h, right: 8.w,
            child: GestureDetector(onTap: () => setState(() => _activeSheet = 0), behavior: HitTestBehavior.opaque,
              child: Container(width: 44.w, height: 44.w,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.r, offset: Offset(0, 2.h))]),
                child: Icon(Icons.close_rounded, size: 20.sp, color: AppColors.textSecondary)))),
        ])));
  }

  Widget _buildActionRow() {
    return Row(children: [
      Expanded(child: GestureDetector(onTap: () => setState(() => _activeSheet = 1),
        child: _actionCard(imagePath: 'image/Nghe.png', label: 'Nghe', sub: 'Học phát âm',
          bgColor: const Color(0xFFE8F5E9), accentColor: const Color(0xFF43A047), stepIdx: 0))),
      SizedBox(width: 10.w),
      Expanded(child: GestureDetector(onTap: () => setState(() => _activeSheet = 2),
        child: _actionCard(imagePath: 'image/Mic.png', label: 'Nói', sub: 'Luyện nói',
          bgColor: const Color(0xFFFFF3E0), accentColor: const Color(0xFFF57C00), stepIdx: 1))),
      SizedBox(width: 10.w),
      Expanded(child: GestureDetector(onTap: () => setState(() => _activeSheet = 3),
        child: _actionCard(imagePath: 'image/Viết.png', label: 'Viết', sub: 'Tập viết',
          bgColor: const Color(0xFFEDE7F6), accentColor: const Color(0xFF5E35B1), stepIdx: 2))),
    ]);
  }

  Widget _actionCard({required String imagePath, required String label, required String sub,
    required Color bgColor, required Color accentColor, required int stepIdx}) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: done ? accentColor.withValues(alpha: 0.6) : accentColor.withValues(alpha: 0.18), width: done ? 2.5 : 1.5),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 16.r, offset: Offset(0, 6.h))]),
      child: Column(children: [
        Image.asset(imagePath, width: 64.w, height: 64.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          if (done) ...[SizedBox(width: 4.w), Icon(Icons.check_circle_rounded, size: 14.w, color: accentColor)],
        ]),
        SizedBox(height: 2.h),
        Text(sub, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildNavButtons() {
    final hasPrev = _idx > 0; final hasNext = _idx < _lessons.length - 1;
    return Row(children: [
      if (hasPrev) Expanded(child: OutlinedButton.icon(onPressed: () => _goTo(_idx - 1),
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text('Bài trước', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.sp)),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), side: BorderSide(color: AppColors.surfaceContainerHighest)))),
      if (hasPrev && hasNext) SizedBox(width: 12.w),
      if (hasNext) Expanded(child: ElevatedButton.icon(onPressed: () => _goTo(_idx + 1),
        icon: Text('Bài tiếp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.sp)),
        label: const Icon(Icons.arrow_forward_rounded, size: 18),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE NGHE (TTS)
// ═══════════════════════════════════════════════════════════════
class _InlineListenContent extends StatefulWidget {
  final KhmerCoeng lesson; final VoidCallback onComplete;
  const _InlineListenContent({required this.lesson, required this.onComplete});
  @override State<_InlineListenContent> createState() => _InlineListenContentState();
}

class _InlineListenContentState extends State<_InlineListenContent> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false; int _playCount = 0; bool _ttsReady = false; bool _khmerSupported = false;
  late AnimationController _pulseCtrl;

  @override void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)); _initTts(); }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(_khmerSupported ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.4); await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    _tts.setErrorHandler((_) { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    if (mounted) setState(() => _ttsReady = true);
  }

  @override void dispose() { _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() { _isPlaying = true; _playCount++; });
    _pulseCtrl.repeat(reverse: true);
    final text = _khmerSupported ? widget.lesson.combined : widget.lesson.meaning;
    final result = await _tts.speak(text);
    if (result != 1 && mounted) Future.delayed(const Duration(milliseconds: 2500), () { if (mounted) { setState(() => _isPlaying = false); _pulseCtrl.stop(); } });
    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.headphones_rounded, color: AppColors.tertiary, size: 20.w), SizedBox(width: 8.w),
          Text('Nghe phụ âm chân', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.tertiaryDark)),
        ])),
      Expanded(child: Align(alignment: const Alignment(0, -0.2),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: AppColors.tertiarySurface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.15))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _smallCharBox(widget.lesson.upperConsonant, const Color(0xFFFF6D00)),
                SizedBox(width: 4.w), Text('្', style: GoogleFonts.battambang(fontSize: 16.sp, color: AppColors.textHint)),
                _smallCharBox(widget.lesson.lowerConsonant, const Color(0xFF1E88E5)),
                SizedBox(width: 4.w), Icon(Icons.add, color: AppColors.textHint, size: 14.sp), SizedBox(width: 4.w),
                _smallCharBox(widget.lesson.vowel, const Color(0xFFE53935)),
                SizedBox(width: 6.w), Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 14.sp), SizedBox(width: 6.w),
                _smallCharBox(widget.lesson.combined, const Color(0xFF43A047)),
              ])),
            SizedBox(height: 24.h),
            GestureDetector(onTap: _ttsReady ? _play : null,
              child: AnimatedBuilder(animation: _pulseCtrl,
                builder: (context, child) => Container(width: 140.w, height: 140.w,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.5 : 0.25), width: 1.5.w, strokeAlign: BorderSide.strokeAlignOutside)),
                  child: Center(child: Container(width: 120.w, height: 120.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiarySurface),
                    child: Center(child: Container(width: 90.w, height: 90.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: _isPlaying ? [AppColors.tertiary, AppColors.tertiaryDark] : [AppColors.tertiaryLight, AppColors.tertiary]),
                        boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.3 + (_isPlaying ? 0.25 * _pulseCtrl.value : 0)),
                          blurRadius: (16 + (_isPlaying ? 12 * _pulseCtrl.value : 0)).r, offset: Offset(0, 4.h))]),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 40.w)))))))),
            SizedBox(height: 14.h),
            Text(_isPlaying ? 'Đang phát âm...' : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại' : 'Nhấn nút để nghe phát âm mẫu',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _isPlaying ? AppColors.tertiary : AppColors.textHint)),
          ]))))
    ]);
  }

  Widget _smallCharBox(String ch, Color c) {
    return Container(width: 44.w, height: 44.w,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1.5)),
      child: Center(child: Text(ch, style: GoogleFonts.battambang(fontSize: 16.sp, fontWeight: FontWeight.w700, color: c))));
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE NÓI (STT)
// ═══════════════════════════════════════════════════════════════
class _InlineSpeakContent extends StatefulWidget {
  final KhmerCoeng lesson; final VoidCallback onComplete;
  const _InlineSpeakContent({required this.lesson, required this.onComplete});
  @override State<_InlineSpeakContent> createState() => _InlineSpeakContentState();
}

class _InlineSpeakContentState extends State<_InlineSpeakContent> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;
  bool _sttReady = false; bool _isListening = false; String _recognized = ''; String _statusMsg = '';
  bool _hasResult = false; bool _isCorrect = false; int _score = 0; String _selectedLocaleId = 'km';

  @override void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)); _initTts(); _initSTT(); }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.4); await _tts.setVolume(1.0);
  }

  Future<void> _initSTT() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) { if (mounted) setState(() => _statusMsg = 'Cần cấp quyền microphone!'); return; }
    try {
      _sttReady = await _speech.initialize(
        onError: (err) { if (mounted && _isListening) { _pulseCtrl.stop(); setState(() { _isListening = false; if (_recognized.isEmpty) _statusMsg = 'Không nhận diện được. Hãy nói to hơn!'; else _evaluate(); }); } },
        onStatus: (status) { if (status == 'done' && mounted && _isListening) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } });
      if (_sttReady) { final locales = await _speech.locales(); for (final l in locales) { if (l.localeId.toLowerCase().startsWith('km')) { _selectedLocaleId = l.localeId; break; } } }
    } catch (_) { _sttReady = false; }
    if (mounted) setState(() {});
  }

  @override void dispose() { _speech.stop(); _tts.stop(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startListening() async {
    await _tts.stop();
    setState(() { _recognized = ''; _statusMsg = ''; _hasResult = false; _isListening = true; });
    _pulseCtrl.repeat(reverse: true);
    try {
      await _speech.listen(
        onResult: (result) { if (mounted) { setState(() => _recognized = result.recognizedWords); if (result.finalResult) { _pulseCtrl.stop(); setState(() => _isListening = false); _evaluate(); } } },
        listenFor: const Duration(seconds: 8), pauseFor: const Duration(seconds: 3), localeId: _selectedLocaleId);
    } catch (_) { _pulseCtrl.stop(); if (mounted) setState(() { _isListening = false; _statusMsg = 'Lỗi nhận diện. Thử lại!'; }); }
  }

  void _evaluate() {
    if (_hasResult) return;
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) { setState(() => _statusMsg = 'Không nhận diện được. Hãy nói to hơn!'); return; }
    String normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final spokenNorm = normalize(spoken);
    final targets = [widget.lesson.combined, widget.lesson.romanized].where((t) => t.isNotEmpty).map(normalize).toList();
    bool exact = targets.any((t) => spokenNorm.contains(t) || t.contains(spokenNorm));
    if (exact) { _score = 5; _isCorrect = true; } else {
      double best = 0;
      for (final t in targets) { final s = _sim(spokenNorm, t); if (s > best) best = s; }
      if (best > 0.4) { _score = 4; _isCorrect = true; } else if (best > 0.25) { _score = 3; _isCorrect = true; } else { _score = 1; _isCorrect = false; }
    }
    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(padding: EdgeInsets.all(24.w), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_isCorrect ? '🎉' : '😅', style: TextStyle(fontSize: 48.sp)),
        SizedBox(height: 12.h),
        Text(_isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác', style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: _isCorrect ? AppColors.tertiary : AppColors.coral)),
        SizedBox(height: 20.h),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () { Navigator.pop(ctx); setState(() { _hasResult = false; _recognized = ''; _statusMsg = ''; _score = 0; }); },
          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), side: BorderSide(color: AppColors.violet)),
          child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.violet)))),
      ]))));
  }

  double _sim(String a, String b) { if (a.isEmpty || b.isEmpty) return 0; final mx = a.length > b.length ? a.length : b.length; return 1.0 - (_lev(a, b) / mx); }
  int _lev(String s, String t) { final m = s.length, n = t.length; final d = List.generate(m + 1, (_) => List.filled(n + 1, 0)); for (int i = 0; i <= m; i++) d[i][0] = i; for (int j = 0; j <= n; j++) d[0][j] = j; for (int i = 1; i <= m; i++) { for (int j = 1; j <= n; j++) { final c = s[i - 1] == t[j - 1] ? 0 : 1; int minVal = d[i - 1][j] + 1; if (d[i][j - 1] + 1 < minVal) minVal = d[i][j - 1] + 1; if (d[i - 1][j - 1] + c < minVal) minVal = d[i - 1][j - 1] + c; d[i][j] = minVal; } } return d[m][n]; }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mic_rounded, color: AppColors.secondary, size: 20.w), SizedBox(width: 8.w),
          Text('Luyện nói', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        ])),
      Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(color: AppColors.secondarySurface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
            child: Column(children: [
              Text('Hãy phát âm:', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              SizedBox(height: 6.h),
              Text(widget.lesson.combined, style: GoogleFonts.battambang(fontSize: 48.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ])),
          SizedBox(height: 18.h),
          GestureDetector(onTap: _sttReady && !_isListening ? _startListening : null,
            child: Container(width: 86.w, height: 86.w,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _isListening ? AppColors.coral.withValues(alpha: 0.15) : AppColors.secondary.withValues(alpha: 0.1),
                border: Border.all(color: _isListening ? AppColors.coral : AppColors.secondary, width: _isListening ? 3.w : 1.5.w)),
              child: Center(child: Container(width: 66.w, height: 66.w,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _isListening ? [AppColors.coral, AppColors.coralDark] : [AppColors.secondary, AppColors.secondaryDark])),
                child: Icon(_isListening ? Icons.hearing_rounded : Icons.mic_rounded, color: Colors.white, size: 28.sp))))),
          SizedBox(height: 10.h),
          Text(_isListening ? 'Đang nghe... 🎙️' : _statusMsg.isNotEmpty ? _statusMsg : 'Nhấn Mic để bắt đầu',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _isListening ? AppColors.coral : AppColors.textSecondary)),
        ]))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE VIẾT (CANVAS)
// ═══════════════════════════════════════════════════════════════
class _InlineWriteContent extends StatefulWidget {
  final KhmerCoeng lesson; final VoidCallback onComplete;
  const _InlineWriteContent({required this.lesson, required this.onComplete});
  @override State<_InlineWriteContent> createState() => _InlineWriteContentState();
}

class _InlineWriteContentState extends State<_InlineWriteContent> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool? _passed; String? _feedback;

  void _check() {
    if (_strokes.isEmpty) { setState(() { _passed = false; _feedback = 'Bé ơi, hãy vẽ nét chữ lên bảng nhé!'; }); return; }
    int totalPoints = 0; for (final s in _strokes) totalPoints += s.length;
    if (totalPoints < 12) { setState(() { _passed = false; _feedback = 'Nét vẽ hơi ngắn, viết kỹ hơn nhé!'; }); }
    else { setState(() { _passed = true; _feedback = null; }); widget.onComplete(); _showSuccessDialog(); }
  }

  void _showSuccessDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(padding: EdgeInsets.all(24.w), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🏆', style: TextStyle(fontSize: 48.sp)),
        SizedBox(height: 12.h),
        Text('Chữ viết rất đẹp!', style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
        SizedBox(height: 20.h),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
          child: Text('Hoàn thành ✅', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)))),
      ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.edit_rounded, color: AppColors.primary, size: 20.w), SizedBox(width: 8.w),
          Text('Tập viết: ${widget.lesson.combined}', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ])),
      if (_feedback != null && _passed == false)
        Padding(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
          child: Container(padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: const Color(0xFFEF9A9A))),
            child: Row(children: [
              Text('😅', style: TextStyle(fontSize: 16.sp)), SizedBox(width: 8.w),
              Expanded(child: Text(_feedback!, style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFFC62828)))),
            ]))),
      Expanded(child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 8.h),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _passed == null ? const Color(0xFFD7CCC8) : _passed! ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), width: 2.w),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10.r)]),
        child: ClipRRect(borderRadius: BorderRadius.circular(18.r),
          child: Stack(children: [
            CustomPaint(size: Size.infinite, painter: _GridPainter()),
            Center(child: Text(widget.lesson.combined, style: GoogleFonts.battambang(fontSize: 140.sp, fontWeight: FontWeight.w300, color: const Color(0xFFE0D5C5).withValues(alpha: 0.45)))),
            GestureDetector(
              onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; _feedback = null; }),
              onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
              onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
              child: CustomPaint(size: Size.infinite, painter: _StrokePainter(_strokes, _current))),
          ])))),
      Padding(padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
        child: Container(padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFE0D5C5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6.r, offset: Offset(0, 2.h))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _toolBtn(icon: Icons.check_circle_outline_rounded, label: 'Kiểm tra',
              color: _strokes.isNotEmpty ? AppColors.tertiary : AppColors.textHint, onTap: _strokes.isNotEmpty ? _check : null),
            _toolBtn(icon: Icons.auto_fix_high_rounded, label: 'Cục tẩy',
              color: _strokes.isNotEmpty ? AppColors.secondary : AppColors.textHint,
              onTap: _strokes.isNotEmpty ? () => setState(() { _strokes.removeLast(); _passed = null; _feedback = null; }) : null),
            _toolBtn(icon: Icons.refresh_rounded, label: 'Làm lại', color: AppColors.coral,
              onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; })),
          ]))),
    ]);
  }

  Widget _toolBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14.r)),
        child: Icon(icon, color: color, size: 22.w)),
      SizedBox(height: 4.h),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFFE0D5C5).withValues(alpha: 0.4)..strokeWidth = 0.8;
    const cols = 8; final cellW = size.width / cols; final rows = (size.height / cellW).ceil();
    for (int i = 0; i <= cols; i++) { final x = i * cellW; canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint); }
    for (int j = 0; j <= rows; j++) { final y = j * cellW; canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint); }
    final cp = Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), cp);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), cp);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes; final List<Offset> current;
  _StrokePainter(this.strokes, this.current);
  @override void paint(Canvas canvas, Size size) {
    final done = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes) { if (s.length < 2) continue; final path = Path()..moveTo(s[0].dx, s[0].dy); for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy); canvas.drawPath(path, done); }
    if (current.length >= 2) { final active = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke; final path = Path()..moveTo(current[0].dx, current[0].dy); for (int i = 1; i < current.length; i++) path.lineTo(current[i].dx, current[i].dy); canvas.drawPath(path, active); }
  }
  @override bool shouldRepaint(covariant _StrokePainter old) => true;
}
