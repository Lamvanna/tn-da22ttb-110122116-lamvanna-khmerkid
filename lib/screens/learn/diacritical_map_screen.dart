import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/khmer_diacritical.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import 'diacritical_screen.dart';
import '../../repositories/progress_repository.dart';

/// Bản đồ học dấu Khmer dạng Timeline - Premium 100% đồng bộ SpellingMapScreen
class DiacriticalMapScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DiacriticalMapScreen({super.key, required this.onBack});

  @override
  State<DiacriticalMapScreen> createState() => _DiacriticalMapScreenState();
}

class _DiacriticalMapScreenState extends State<DiacriticalMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _staggerCtrl;

  final List<KhmerDiacritical> _items = KhmerDiacriticalData.diacriticals;
  ScoreService? _score;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _staggerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    try {
      final progress = await ProgressRepository.instance.getProgressMap('diacritical');
      if (mounted) {
        setState(() {
          for (int i = 0; i < _items.length; i++) {
            if (progress.containsKey(i)) {
              _items[i].isLearned = true;
              _items[i].starRating = progress[i]!;
            } else {
              _items[i].isLearned = false;
              _items[i].starRating = 0;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading diacritical progress: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(10.w, 18.h, 16.w, 100.h),
              child: Column(
                children: List.generate(_items.length, (i) {
                  final delay = (i * 0.12).clamp(0.0, 1.0);
                  final end = (delay + 0.4).clamp(0.0, 1.0);
                  final anim = CurvedAnimation(
                    parent: _staggerCtrl,
                    curve: Interval(delay, end, curve: Curves.easeOutCubic),
                  );

                  return AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Opacity(
                      opacity: anim.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - anim.value)),
                        child: child,
                      ),
                    ),
                    child: _DiacriticalCard(
                      item: _items[i],
                      index: i,
                      isLast: i == _items.length - 1,
                      pulseCtrl: _pulseCtrl,
                      onTap: () => _openLesson(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.learnHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: AppColors.headerDark.withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8))]),
      child: Stack(children: [
        Positioned(right: -40.w, top: -30.h,
          child: Container(width: 120.w, height: 120.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -25.w, bottom: -20.h,
          child: Container(width: 80.w, height: 80.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 105.w, 32.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(width: 36.w, height: 36.w,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.w))),
                  SizedBox(width: 12.w),
                  Flexible(child: Text(context.translate('learn.learn_diacritic_khmer'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
            ]))),
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
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⭐', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text('${_score?.totalStars ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔥', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 4.w),
              Text('${_score?.streak ?? 0}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0)),
            ],
          ),
        ),
      ],
    );
  }

  void _openLesson(int idx) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiacriticalScreen(initialIndex: idx),
      ),
    ).then((_) {
      if (mounted) {
        _loadScore();
        setState(() {});
      }
    });
  }
}

class _DiacriticalCard extends StatelessWidget {
  final KhmerDiacritical item;
  final int index;
  final bool isLast;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;

  const _DiacriticalCard({
    required this.item,
    required this.index,
    required this.isLast,
    required this.pulseCtrl,
    required this.onTap,
  });

  Color get _color {
    const colors = [
      Color(0xFFFF6D00),
      Color(0xFFE65100),
      Color(0xFFF4511E),
      Color(0xFFFF8F00),
      Color(0xFFEF6C00),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isCurrent = !item.isLearned && (index == 0 || KhmerDiacriticalData.diacriticals[index - 1].isLearned);
    final isLocked = !item.isLearned && index > 0 && !KhmerDiacriticalData.diacriticals[index - 1].isLearned;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52.w,
            child: Column(
              children: [
                SizedBox(height: 14.h),
                _buildNumberCircle(color, isCurrent, isLocked),
                SizedBox(height: 6.h),
                _buildStars(isLocked),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _DottedLinePainter(
                        color: isLocked ? const Color(0xFFD0D5E0) : color.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isLocked ? null : onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: 18.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white.withValues(alpha: 0.7) : Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: isLocked ? const Color(0xFFE0E5F0) : const Color(0xFFE8ECF2),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLocked ? Colors.black.withValues(alpha: 0.03) : color.withValues(alpha: 0.10),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                    if (isCurrent)
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 20.r,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isLocked ? const Color(0xFFE8EDF5) : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            context.translate('learn.lesson_n', args: {'number': index + 1}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: isLocked ? const Color(0xFFB0B8C8) : color,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            context.translate('learn.diacritic_label', args: {'character': item.character}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: isLocked ? const Color(0xFFB0B8C8) : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isLearned)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              context.translate('common.done'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          )
                        else if (!isLocked)
                          Text(
                            '0%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isLocked ? const Color(0xFFC0C8D8) : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildCharacterCircles(color, isLocked),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 7.h,
                            decoration: BoxDecoration(
                              color: isLocked ? const Color(0xFFE8EDF5) : color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: item.isLearned ? 1.0 : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [color.withValues(alpha: 0.7), color],
                                      ),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          item.isLearned ? '1/1 chữ' : '0/1 chữ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isLocked ? const Color(0xFFC0C8D8) : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLocked ? const Color(0xFFE8EDF5) : color,
                            boxShadow: isLocked
                                ? []
                                : [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.35),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 3.h),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                            color: isLocked ? const Color(0xFFB0B8C8) : Colors.white,
                            size: isLocked ? 16.sp : 22.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCircle(Color color, bool isCurrent, bool isLocked) {
    if (isLocked) {
      return Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE0E5F0),
          border: Border.all(color: const Color(0xFFD0D5E0), width: 3.w),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB0B8C8),
            ),
          ),
        ),
      );
    }

    final circle = Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.2)!, color],
        ),
        border: Border.all(color: Color.lerp(color, Colors.white, 0.4)!, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
          if (isCurrent)
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 16.r,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: item.isLearned
            ? Icon(Icons.check_rounded, color: Colors.white, size: 22.sp)
            : Text(
                '${index + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );

    if (isCurrent) {
      return AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + pulseCtrl.value * 0.06,
          child: child,
        ),
        child: circle,
      );
    }
    return circle;
  }

  Widget _buildStars(bool isLocked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          Icons.star_rounded,
          size: 14.w,
          color: isLocked
              ? const Color(0xFFE0E5F0)
              : (i < item.starRating ? const Color(0xFFFFB300) : const Color(0xFFE0E0E0)),
        ),
      ),
    );
  }

  List<String> _getDisplayChars(KhmerDiacritical item) {
    final first = '◌${item.character}';
    switch (item.character) {
      case '់': return [first, 'កក់', 'សក់', 'ដក់'];
      case 'ំ': return [first, 'កំ', 'ធំ', 'ដំ'];
      case 'ះ': return [first, 'សះ', 'កះ', 'ចះ'];
      case 'ៈ': return [first, 'នៈ', 'កៈ', 'ចៈ'];
      case '៉': return [first, 'ម៉ា', 'ប៉ា', 'ម៉ី'];
      case '៊': return [first, 'ស៊ី', 'ហ៊ឺ', 'ហ៊ា'];
      case '្': return [first, 'ស្រា', 'ខ្មែរ', 'ល្អ'];
      case 'ៗ': return [first, 'ធំៗ', 'តូចៗ', 'ថ្មីៗ'];
      case '។': return [first, 'ទៅ។', 'បាទ។', 'ចាស។'];
      case '៎': return [first, 'អត់៎', 'ណា៎', 'ទេ៎'];
      case '៌': return [first, 'ធម៌', 'ពណ៌', 'កម៌'];
      case '័': return [first, 'ខ័ន', 'ព័ទ្ធ', 'រ័ត្ន'];
      default:
        return [
          first,
          item.example.isNotEmpty ? item.example : '...',
          '...',
          '...'
        ];
    }
  }

  Widget _buildCharacterCircles(Color color, bool isLocked) {
    final chars = _getDisplayChars(item);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(top: 6.h, bottom: 2.h),
        child: Row(
          children: List.generate(chars.length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: _CharCircle(
                character: chars[i],
                isDone: item.isLearned,
                isLocked: isLocked,
                color: color,
                onTap: isLocked ? null : onTap,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CharCircle extends StatefulWidget {
  final String character;
  final bool isDone;
  final bool isLocked;
  final Color color;
  final VoidCallback? onTap;

  const _CharCircle({
    required this.character,
    required this.isDone,
    required this.isLocked,
    required this.color,
    this.onTap,
  });

  @override
  State<_CharCircle> createState() => _CharCircleState();
}

class _CharCircleState extends State<_CharCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _tapCtrl.forward().then((_) {
      _tapCtrl.reverse();
      widget.onTap!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value, child: child),
        child: SizedBox(
          width: 48.w, height: 48.w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rounded square background
              Container(
                width: 48.w, height: 48.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: widget.isLocked
                      ? const Color(0xFFF0F2F8)
                      : widget.isDone
                          ? widget.color.withValues(alpha: 0.10)
                          : const Color(0xFFF5F7FC),
                  border: Border.all(
                    color: const Color(0xFFE0E5F0),
                    width: 1.5.w,
                  ),
                ),
                child: Center(
                  child: widget.isLocked
                      ? Icon(Icons.lock_rounded,
                          color: const Color(0xFFB8C0D0), size: 18.sp)
                      : Text(
                          widget.character,
                          style: GoogleFonts.battambang(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: widget.isDone
                                ? widget.color
                                : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ),

              // Checkmark badge
              if (widget.isDone)
                Positioned(
                  top: -4.h, right: -4.w,
                  child: Container(
                    width: 18.w, height: 18.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                      border: Border.all(color: Colors.white, width: 2.w),
                      boxShadow: [BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 4.r,
                      )],
                    ),
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 10.sp),
                  ),
                ),

              // Lock badge
              if (widget.isLocked)
                Positioned(
                  top: -4.h, right: -4.w,
                  child: Container(
                    width: 18.w, height: 18.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD0D5E0),
                      border: Border.all(color: Colors.white, width: 2.w),
                    ),
                    child: Icon(Icons.lock_rounded,
                        color: Colors.white, size: 9.sp),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
