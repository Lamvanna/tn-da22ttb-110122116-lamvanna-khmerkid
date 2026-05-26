import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_number.dart';
import '../../services/score_service.dart';
import 'number_inline_listen.dart';
import 'number_inline_speak.dart';
import 'number_inline_write.dart';

/// Màn hình chi tiết số Khmer — Tích hợp 3 bước học inline (Nghe, Nói, Viết) tương tự nguyên âm
class NumberDetailScreen extends StatefulWidget {
  final int initialIndex;
  const NumberDetailScreen({super.key, this.initialIndex = 0});

  @override
  State<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends State<NumberDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerNumber> _numbers = KhmerNumberData.numbers;
  ScoreService? _score;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  // 0 = none, 1 = listen, 2 = speak, 3 = write
  int _activeSheet = 0;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    if (mounted) setState(() {});
  }


  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));
    if (_completedSteps[_idx]!.length == 3) _onCompleted();
  }

  void _onCompleted() {
    _numbers[_idx].isLearned = true;
    _numbers[_idx].starRating = 3;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _numbers.length - 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🎉', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text('Chúc mừng!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            SizedBox(height: 8.h),
            Text('Bạn đã hoàn thành số "${_num.value}" ( ${_num.character} )',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            SizedBox(height: 6.h),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (i) => Icon(Icons.star_rounded,
                        size: 28.sp, color: const Color(0xFFFFB300)))),
            SizedBox(height: 6.h),
            Text('+15 XP ⭐',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFB300))),
            SizedBox(height: 20.h),
            if (hasNext) ...[
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goTo(_idx + 1);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r))),
                    child: Text('Học số tiếp theo →',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )),
              SizedBox(height: 8.h),
            ],
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                      side: const BorderSide(color: AppColors.primary)),
                  child: Text('Quay về danh sách',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                )),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerNumber get _num => _numbers[_idx];
  bool _isStepComplete(int step) =>
      _completedSteps[_idx]?.contains(step) ?? false;

  bool _canGo(int i) => i >= 0 && i < _numbers.length;
  void _goTo(int i) {
    if (!_canGo(i)) return;
    _animCtrl.reset();
    setState(() {
      _idx = i;
      _activeSheet = 0;
    });
    _animCtrl.forward();
  }

  void _showListenSheet() =>
      setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1);
  void _showSpeakSheet() =>
      setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2);
  void _showWriteSheet() =>
      setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 470.h),
                  child: Stack(children: [
                    _buildMainCard(),
                    if (_activeSheet != 0)
                      Positioned.fill(child: _buildInlineSheet()),
                  ]),
                ),
                SizedBox(height: 8.h),
                _buildActionRow(),
                SizedBox(height: 16.h),
                _buildNavButtons(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment(-0.5, -1),
            end: Alignment(0.5, 1),
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)]),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24.r),
            bottomRight: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.35),
              blurRadius: 24.r,
              offset: Offset(0, 8.h))
        ],
      ),
      child: Stack(children: [
        Positioned(
            right: -40.w,
            top: -30.h,
            child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(
            left: -25.w,
            bottom: -20.h,
            child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 105.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12))),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20.w, color: Colors.white)),
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                        child: Text(
                            'Số ${_num.value} ( ${_num.character} )',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4.h,
          right: 16.w,
          child: _buildHeaderStats(),
        ),
      ]),
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
              Text('⭐', style: TextStyle(fontSize: 12.sp)),
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
              Text('🔥', style: TextStyle(fontSize: 12.sp)),
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

  // ═══════════════════ MAIN CARD ═══════════════════
  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 470.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
            color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20.r,
              offset: Offset(0, 6.h))
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(48.w),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06)),
              child: Text(_num.character,
                  style: GoogleFonts.battambang(
                      fontSize: 130.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.1)),
            ),
            SizedBox(height: 16.h),
            Text(
              '${_num.khmerWord} — ${_num.pronunciation}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D3748)),
            ),
            SizedBox(height: 24.h),
            Container(
                width: 100.w,
                height: 3.h,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.1)
                    ]),
                    borderRadius: BorderRadius.circular(2.r))),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ INLINE SHEET OVERLAY ═══════════════════
  Widget _buildInlineSheet() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(children: [
          Column(children: [
            if (_activeSheet == 1)
              Expanded(
                  child: NumberInlineListenContent(
                      number: _num, onComplete: () => _markStepComplete(0))),
            if (_activeSheet == 2)
              Expanded(
                  child: NumberInlineSpeakContent(
                      number: _num, onComplete: () => _markStepComplete(1))),
            if (_activeSheet == 3)
              Expanded(
                  child: NumberInlineWriteContent(
                      number: _num, onComplete: () => _markStepComplete(2))),
          ]),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: () => setState(() => _activeSheet = 0),
              behavior: HitTestBehavior.opaque,
              child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h))
                      ]),
                  child: Icon(Icons.close_rounded,
                      size: 20.sp, color: AppColors.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════ ACTION ROW ═══════════════════
  Widget _buildActionRow() {
    return Row(children: [
      Expanded(
          child: GestureDetector(
        onTap: _showListenSheet,
        child: _actionCard(
            imagePath: 'image/Nghe.png',
            label: 'Nghe',
            sub: 'Nghe phát âm',
            bgColor: const Color(0xFFE8F5E9),
            accentColor: const Color(0xFF43A047),
            stepIdx: 0),
      )),
      SizedBox(width: 10.w),
      Expanded(
          child: GestureDetector(
        onTap: _showSpeakSheet,
        child: _actionCard(
            imagePath: 'image/Mic.png',
            label: 'Nói',
            sub: 'Luyện phát âm',
            bgColor: const Color(0xFFFFF3E0),
            accentColor: const Color(0xFFF57C00),
            stepIdx: 1),
      )),
      SizedBox(width: 10.w),
      Expanded(
          child: GestureDetector(
        onTap: _showWriteSheet,
        child: _actionCard(
            imagePath: 'image/Viết.png',
            label: 'Viết',
            sub: 'Tập viết số',
            bgColor: const Color(0xFFEDE7F6),
            accentColor: const Color(0xFF5E35B1),
            stepIdx: 2),
      )),
    ]);
  }

  Widget _actionCard({
    required String imagePath,
    required String label,
    required String sub,
    required Color bgColor,
    required Color accentColor,
    required int stepIdx,
  }) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: done
                  ? accentColor.withValues(alpha: 0.5)
                  : accentColor.withValues(alpha: 0.18),
              width: done ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 16.r,
                offset: Offset(0, 6.h)),
            BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 4.r,
                offset: Offset(0, 2.h)),
          ]),
      child: Column(children: [
        Image.asset(imagePath, width: 70.w, height: 70.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: accentColor)),
        SizedBox(height: 3.h),
        Text(sub,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: accentColor.withValues(alpha: 0.65))),
      ]),
    );
  }

  // ═══════════════════ NAVIGATION + STEPPER ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _canGo(_idx - 1);
    final canNext = _canGo(_idx + 1);
    final labels = ['Nghe', 'Nói', 'Viết'];
    final stepColors = [
      const Color(0xFF3D5AFE),
      const Color(0xFFFF9100),
      const Color(0xFF7C4DFF)
    ];
    return Row(children: [
      GestureDetector(
        onTap: canPrev ? () => _goTo(_idx - 1) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chevron_left_rounded,
                color: canPrev ? AppColors.primary : AppColors.textHint,
                size: 18.w),
            Text('Trước',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: canPrev ? AppColors.primary : AppColors.textHint)),
          ]),
        ),
      ),
      SizedBox(width: 6.w),
      Expanded(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                if (i.isOdd) {
                  final prevDone = _isStepComplete(i ~/ 2);
                  return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          3,
                          (_) => Container(
                                width: 4.w,
                                height: 2.5.h,
                                margin:
                                    EdgeInsets.symmetric(horizontal: 1.5.w),
                                decoration: BoxDecoration(
                                    color: prevDone
                                        ? stepColors[i ~/ 2]
                                            .withValues(alpha: 0.5)
                                        : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(1.r)),
                              )));
                }
                final stepI = i ~/ 2;
                final done = _isStepComplete(stepI);
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: done
                                ? [
                                    stepColors[stepI],
                                    stepColors[stepI].withValues(alpha: 0.7)
                                  ]
                                : [
                                    const Color(0xFFE8E8E8),
                                    const Color(0xFFD8D8D8)
                                  ]),
                        boxShadow: done
                            ? [
                                BoxShadow(
                                    color: stepColors[stepI]
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6.r,
                                    offset: Offset(0, 2.h))
                              ]
                            : null,
                      ),
                      child: Center(
                          child: done
                              ? Icon(Icons.check_rounded,
                                  size: 14.w, color: Colors.white)
                              : Text('${stepI + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)))),
                  SizedBox(height: 2.h),
                  Text(labels[stepI],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: done ? stepColors[stepI] : AppColors.textHint)),
                ]);
              }))),
      SizedBox(width: 6.w),
      GestureDetector(
        onTap: canNext ? () => _goTo(_idx + 1) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
              gradient: canNext
                  ? const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)])
                  : null,
              color: canNext ? null : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: canNext
                  ? [
                      BoxShadow(
                          color:
                              const Color(0xFF1E88E5).withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          offset: Offset(0, 3.h))
                    ]
                  : null),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(canNext ? 'Tiếp theo' : 'Khóa',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: canNext ? Colors.white : AppColors.textHint)),
            SizedBox(width: 4.w),
            Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded,
                color: canNext ? Colors.white : AppColors.textHint, size: 18.w),
          ]),
        ),
      ),
    ]);
  }
}
