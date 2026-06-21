import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/khmer_consonant_series.dart';
import '../../models/khmer_vowel.dart';
import '../../models/khmer_letter.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import 'letter_detail_screen.dart';
import 'vowel_detail_screen.dart';

class ConsonantSeriesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ConsonantSeriesScreen({super.key, required this.onBack});

  @override
  State<ConsonantSeriesScreen> createState() => _ConsonantSeriesScreenState();
}

class _ConsonantSeriesScreenState extends State<ConsonantSeriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late ScrollController _scrollCtrl;
  ScoreService? _score;

  final List<KhmerConsonantSeries> _consonants = KhmerConsonantSeriesData.consonants;
  final List<KhmerVowel> _vowels = KhmerVowelData.vowels;

  late String _selectedCategory;
  late final List<String> _categories;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedCategory = context.translate('learn.consonants_o');
      _categories = [
        context.translate('learn.consonants_o'),
        context.translate('learn.consonants_oh'),
        context.translate('learn.vowels_o'),
        context.translate('learn.vowels_oh')
      ];
      _initialized = true;
    }
  }

  double get _nodeSize => 72.w;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    _loadScore();
  }

  Future<void> _loadScore() async {
    _score = await ScoreService.getInstance();
    try {
      final storage = await StorageService.getInstance();
      final letterProgress = storage.getLetterProgress();
      final vowelProgress = storage.getVowelProgress();

      // Update consonants progress dynamically
      for (int i = 0; i < _consonants.length; i++) {
        final c = _consonants[i];
        final mainIndex = KhmerLetterData.consonants.indexWhere((item) => item.character == c.character);
        if (mainIndex != -1 && letterProgress.containsKey(mainIndex)) {
          c.isLearned = true;
          c.starRating = letterProgress[mainIndex]!;
        } else {
          c.isLearned = false;
          c.starRating = 0;
        }
      }

      // Update vowels progress dynamically
      for (int i = 0; i < _vowels.length; i++) {
        final v = _vowels[i];
        final mainIndex = KhmerVowelData.vowels.indexWhere((item) => item.character == v.character);
        if (mainIndex != -1 && vowelProgress.containsKey(mainIndex)) {
          v.isLearned = true;
          v.starRating = vowelProgress[mainIndex]!;
        } else {
          v.isLearned = false;
          v.starRating = 0;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading progress in ConsonantSeriesScreen: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _isConsonant => _selectedCategory.startsWith(context.translate('learn.consonant'));
  bool get _isSeriesO => _selectedCategory.endsWith('o');

  Color get _currentColor {
    return _isSeriesO ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5);
  }

  List<dynamic> get _currentItems {
    if (_isConsonant) {
      return _consonants.where((c) => c.series == (_isSeriesO ? 'o' : 'ô')).toList();
    } else {
      return _vowels;
    }
  }

  int get _doneCount {
    return _currentItems.where((item) => item.isLearned).length;
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentItems;
    final color = _currentColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(children: [
        _buildHeader(),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                icon: Icon(Icons.expand_more_rounded, color: color, size: 28.sp),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                elevation: 8,
                menuMaxHeight: 300.h,
                selectedItemBuilder: (BuildContext context) {
                  return _categories.map<Widget>((String c) {
                    final isO = c.endsWith('o');
                    final isConsonant = c.startsWith(context.translate('learn.consonant'));
                    final cColor = isO ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5);
                    final icon = isConsonant ? Icons.text_fields_rounded : Icons.record_voice_over_rounded;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: cColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(icon, color: cColor, size: 18.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(c, style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp, fontWeight: FontWeight.w800, color: cColor)),
                      ],
                    );
                  }).toList();
                },
                items: _categories.map((c) {
                  final isO = c.endsWith('o');
                  final isConsonant = c.startsWith(context.translate('learn.consonant'));
                  final cColor = isO ? const Color(0xFF66BB6A) : const Color(0xFF42A5F5);
                  final icon = isConsonant ? Icons.text_fields_rounded : Icons.record_voice_over_rounded;
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: cColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: cColor, size: 20.sp),
                          ),
                          SizedBox(width: 14.w),
                          Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: GridView.builder(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildNode(items[index], index, color);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildNode(dynamic item, int index, Color color) {
    final done = item.isLearned;
    final items = _currentItems;
    final isCurrent = !done && (index == 0 || items[index - 1].isLearned);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _nodeSize, height: _nodeSize + 20.w,
            child: isCurrent
                ? AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                    child: _tile(item, color, done, isCurrent))
                : _tile(item, color, done, isCurrent),
          ),
        ],
      ),
    );
  }

  Widget _tile(dynamic item, Color color, bool done, bool curr) {
    String displayText = '';
    if (item is KhmerConsonantSeries) {
      final hasSubscript = item.character != 'ឡ';
      displayText = hasSubscript ? '${item.character}\u17D2${item.character}' : item.character;
    } else if (item is KhmerVowel) {
      displayText = item.character.replaceFirst('អ', '');
    }

    return Container(
      width: _nodeSize, height: _nodeSize + 20.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.20)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(color: Color.lerp(color, Colors.white, 0.4)!, width: 2.5.w),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.4)!.withValues(alpha: 0.5),
            blurRadius: 0, offset: Offset(0, 3.h)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(displayText,
            style: GoogleFonts.battambang(
              fontSize: (item is KhmerVowel) ? 46.sp : 40.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.1,
              shadows: [Shadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 2, offset: const Offset(0, 1))])),
          SizedBox(height: 4.h),
          Text(
            item.romanized,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          if (done) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (starIndex) => Icon(
                  Icons.star_rounded,
                  size: 14.sp,
                  color: starIndex < item.starRating
                      ? const Color(0xFFFFD600)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final color = _currentColor;
    final total = _currentItems.length;
    final progress = total > 0 ? _doneCount / total : 0.0;
    final pct = (progress * 100).toInt();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF29B6F6)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.35),
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
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 105.w, 35.h),
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
                  Flexible(child: Text(context.translate('learn.alphabet_board'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
            ]),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 2.h,
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

  void _showDetail(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r), topRight: Radius.circular(28.r))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40.w, height: 4.h,
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2.r))),
          SizedBox(height: 20.h),
          Text((item is KhmerVowel) ? item.character.replaceFirst('អ', '') : item.character, style: GoogleFonts.battambang(fontSize: 64.sp, fontWeight: FontWeight.w700,
            color: _currentColor)),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _currentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r)),
            child: Text(context.translate('level.prefix') + ' ' + (_isSeriesO ? context.translate('learn.series_o') : context.translate('learn.series_oh')), style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp, fontWeight: FontWeight.w700,
              color: _currentColor))),
          SizedBox(height: 12.h),
          Text('${item.romanized} — ${item.pronunciation}', style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF718096))),
          SizedBox(height: 12.h),
          // Row of stars for completed status in bottom sheet
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (starIndex) => Icon(
                Icons.star_rounded,
                size: 28.sp,
                color: item.isLearned && starIndex < item.starRating
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFE0E0E0),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          if (item.example.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16.r)),
              child: Column(children: [
                Text(context.translate('learn.example'), style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF9098A9))),
                SizedBox(height: 4.h),
                Text(item.example, style: GoogleFonts.battambang(
                  fontSize: 28.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2D3142))),
                Text(item.exampleMeaning, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF718096))),
              ])),
          SizedBox(height: 24.h),
          // Learn/Practice CTA Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_currentColor, Color.lerp(_currentColor, Colors.black, 0.15)!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: _currentColor.withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (item is KhmerConsonantSeries) {
                  final mainIndex = KhmerLetterData.consonants.indexWhere((c) => c.character == item.character);
                  if (mainIndex != -1) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LetterDetailScreen(initialIndex: mainIndex)),
                    ).then((_) => _loadScore());
                  }
                } else if (item is KhmerVowel) {
                  final mainIndex = KhmerVowelData.vowels.indexWhere((v) => v.character == item.character);
                  if (mainIndex != -1) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VowelDetailScreen(initialIndex: mainIndex)),
                    ).then((_) => _loadScore());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    item.isLearned ? 'Luyện tập lại' : 'Bắt đầu học ngay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ]),
      ),
    );
  }
}
