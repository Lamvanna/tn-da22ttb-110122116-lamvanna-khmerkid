import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';
import '../main_screen.dart';
import 'book_detail_screen.dart';
import 'book_reader_screen.dart';
import 'video_detail_screen.dart';
import 'category_list_screen.dart';
import 'song_player_screen.dart';

/// Màn hình Thư viện — Redesigned Premium UI
/// Phong cách Duolingo Kids / Khan Academy Kids
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0;

  // ── Data ──
  static const _tabs = [
    _TabData(icon: Icons.grid_view_rounded, label: 'Tất cả', count: 128, color: Color(0xFF1E6DEB)),
    _TabData(icon: Icons.menu_book_rounded, label: 'Sách', count: 45, color: Color(0xFF27AE60)),
    _TabData(icon: Icons.auto_stories_rounded, label: 'Truyện', count: 15, color: Color(0xFF00A896)),
    _TabData(icon: Icons.music_note_rounded, label: 'Bài hát', count: 18, color: Color(0xFFFD79A8)),
    _TabData(icon: Icons.play_circle_filled_rounded, label: 'Video', count: 28, color: Color(0xFFE67E22)),
    _TabData(icon: Icons.emoji_objects_rounded, label: 'Kiến thức', count: 25, color: Color(0xFFF1C40F)),
    _TabData(icon: Icons.favorite_rounded, label: 'Yêu thích', count: 12, color: Color(0xFFE74C3C)),
  ];

  static final _featuredCategories = [
    _FeaturedCat(
      title: 'Sách',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810872/khmerkid/library/l1lba7h2swazdzwlnp4m.png',
      gradient: const [Color(0xFF7EB1FF), Color(0xFF568FFF)]),
    _FeaturedCat(
      title: 'Truyện',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810866/khmerkid/library/ea7hwynods7uehxiwjyk.png',
      gradient: const [Color(0xFF7EE79D), Color(0xFF52BF76)]),
    _FeaturedCat(
      title: 'Bài hát',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810869/khmerkid/library/k2ddww6pnnw93cj5mcjo.png',
      gradient: const [Color(0xFFD39BFF), Color(0xFFAD6BFF)]),
    _FeaturedCat(
      title: 'Video',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810867/khmerkid/library/video.png',
      gradient: const [Color(0xFFFFB37E), Color(0xFFF88F48)]),
    _FeaturedCat(
      title: 'Kiến thức',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810870/khmerkid/library/fitdcgqfto7135no5aat.png',
      gradient: const [Color(0xFFFFE07D), Color(0xFFF2BC3F)]),
    _FeaturedCat(
      title: 'Yêu thích',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810868/khmerkid/library/lqlngfhcifbpvqcdygmm.png',
      gradient: const [Color(0xFFFF9EC3), Color(0xFFE86F9C)]),
  ];

  static final _fallbackDocs = DocItem.fallbackDocs;

  List<DocItem> _latestDocs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestDocs();
  }

  Future<void> _loadLatestDocs() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchLibraryItemsForUser();
    if (!mounted) return;
    if (result['success'] == true && result['data'] != null && (result['data'] as List).isNotEmpty) {
      final list = result['data'] as List;
      setState(() {
        _latestDocs = list.map((item) {
          final type = item['type'] ?? 'Sách';
          final title = item['title'] ?? '';
          final desc = item['description'] ?? '';
          final rating = (item['rating'] as num?)?.toDouble() ?? 5.0;
          final viewsCount = item['views'] ?? 0;
          final views = "$viewsCount lượt xem";
          final image = (item['image'] != null && item['image'].toString().isNotEmpty)
              ? item['image'].toString()
              : 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810872/khmerkid/library/l1lba7h2swazdzwlnp4m.png';

          IconData typeIcon = Icons.menu_book_rounded;
          Color typeColor = const Color(0xFF27AE60);
          String btnLabel = 'Đọc ngay';

          if (type == 'Audio') {
            typeIcon = Icons.music_note_rounded;
            typeColor = const Color(0xFFFD79A8);
            btnLabel = 'Nghe ngay';
          } else if (type == 'Video') {
            typeIcon = Icons.play_circle_rounded;
            typeColor = const Color(0xFFF2994A);
            btnLabel = 'Xem ngay';
          }

           var duration = item['duration']?.toString() ?? '';
          if (type == 'Video' && duration.isEmpty) {
            if (title.contains('1-10')) duration = '05:30';
            else if (title.contains('nguyên âm')) duration = '08:45';
            else if (title.contains('thú rừng')) duration = '10:15';
            else if (title.contains('Ngữ pháp')) duration = '12:40';
            else if (title.contains('tỷ phú')) duration = '15:20';
            else if (title.contains('khảo cổ')) duration = '09:50';
            else if (title.contains('Bắt chữ')) duration = '11:05';
            else duration = '08:45';
          }
          return DocItem(
            title: title,
            type: type,
            typeIcon: typeIcon,
            typeColor: typeColor,
            desc: desc,
            rating: rating,
            views: views,
            btnLabel: btnLabel,
            btnIcon: typeIcon,
            btnColor: typeColor,
            image: image,
            duration: duration.isNotEmpty ? duration : null,
          );
        }).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _latestDocs = _fallbackDocs;
        _loading = false;
      });
    }
  }

  int _getDocCountForLabel(String label) {
    final list = _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs;
    if (label == 'Tất cả') {
      return list.where((doc) => doc.type != 'Video').length;
    }
    return list.where((doc) => doc.matchesCategory(label)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Combine Header & Overlapping body in 1 Sliver to ensure correct paint order ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                Transform.translate(
                  offset: Offset(0, -24.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 20.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16.r,
                              offset: Offset(0, -4.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCategoryTabs(),
                            _buildFeaturedSection(),
                            _buildLatestSection(),
                          ],
                        ),
                      ),
                      // Search Bar (drawn on top of container)
                      Positioned(
                        left: 20.w,
                        top: -56.h,
                        child: _buildSearchBar(),
                      ),
                      // Mascot sitting on top of the curved edge
                      Positioned(
                        right: -48.w,
                        top: -182.h,
                        child: IgnorePointer(
                          child: Image.asset(
                            'image/Voi thư viện.png',
                            width: 245.w,
                            height: 245.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════
  // SEARCH BAR (Premium White Style)
  // ═══════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      width: 200.w,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1256A8).withValues(alpha: 0.15),
            blurRadius: 12.r, offset: Offset(0, 4.h)),
        ],
      ),
      child: Row(children: [
        Icon(Icons.search_rounded,
          color: const Color(0xFF2B7DD9), size: 22.sp),
        SizedBox(width: 8.w),
        Expanded(child: TextField(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp, color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp, fontWeight: FontWeight.w500,
              color: const Color(0xFF8896AB)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h)),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // HEADER — Premium Gradient + Decorative Accents
  // ═══════════════════════════════════════════════════
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.8), end: Alignment(1, 1.2),
          colors: [
            Color(0xFF1256A8),
            Color(0xFF2B7DD9),
            Color(0xFF4DA0F0),
            Color(0xFF6BB8F7),
          ]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1256A8).withValues(alpha: 0.35),
            blurRadius: 28.r, offset: Offset(0, 10.h)),
          BoxShadow(
            color: const Color(0xFF4DA0F0).withValues(alpha: 0.15),
            blurRadius: 50.r, offset: Offset(0, 4.h)),
        ],
      ),
      child: Stack(children: [
        // ── Decorative background elements ──
        // Large glow circle top-right
        Positioned(right: -50.w, top: -40.h,
          child: Container(width: 180.w, height: 180.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.0),
              ])))),
        // Medium circle bottom-left
        Positioned(left: -35.w, bottom: 10.h,
          child: Container(width: 100.w, height: 100.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Small circle center-left
        Positioned(left: 60.w, top: topPad + 10.h,
          child: Container(width: 20.w, height: 20.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        // Floating sparkle dots
        Positioned(left: 30.w, top: topPad + 35.h,
          child: Container(width: 5.w, height: 5.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25)))),
        Positioned(left: 100.w, bottom: 65.h,
          child: Container(width: 4.w, height: 4.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18)))),
        Positioned(right: 60.w, top: topPad + 15.h,
          child: Container(width: 6.w, height: 6.w,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20)))),
        // Star accents
        Positioned(left: 15.w, top: topPad + 52.h,
          child: Icon(Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.10), size: 16.sp)),
        Positioned(right: 150.w, bottom: 55.h,
          child: Icon(Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.07), size: 12.sp)),

        // ── Main Content ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + subtitle row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main title
                        Text('Thư viện 📚',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          )),
                        SizedBox(height: 6.h),
                        // Subtitle
                        Text('Khám phá kho tài liệu học tập thú vị',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.3)),
                      ],
                    )),
                    // Reserved space for bookshelf image
                    SizedBox(width: 110.w),
                  ],
                ),
                SizedBox(height: 92.h), // Create extra space below the subtitle
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // CATEGORY TABS — Icon + Label + Count
  // ═══════════════════════════════════════════════════
  Widget _buildCategoryTabs() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8.h, 0, 6.h),
      child: SizedBox(
        height: 88.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: _tabs.length,
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final selected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 76.w,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: selected ? tab.color.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: selected ? tab.color : const Color(0xFFE2E8F0),
                    width: selected ? 2.w : 1.5.w,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: tab.color.withValues(alpha: 0.15),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          )
                        ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 26.sp,
                        color: tab.color,
                      ),
                      SizedBox(height: 6.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tab.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: selected ? tab.color : const Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${_getDocCountForLabel(tab.label)} tài liệu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w600,
                            color: selected
                              ? tab.color.withValues(alpha: 0.8)
                              : const Color(0xFF8896AB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FEATURED CATEGORIES — Horizontal Scroll Cards
  // ═══════════════════════════════════════════════════
  Widget _buildFeaturedSection() {
    final selectedLabel = _tabs[_selectedTab].label;

    if (selectedLabel == 'Tất cả') {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 14.h),
            child: Row(children: [
              Text('Danh mục nổi bật',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19.sp, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryListScreen(
                        categoryTitle: 'Tất cả danh mục',
                        customItems: _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs,
                      ),
                    ),
                  );
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Xem tất cả',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp, fontWeight: FontWeight.w600,
                      color: const Color(0xFF4580C4))),
                  SizedBox(width: 2.w),
                  Icon(Icons.chevron_right_rounded,
                    size: 18.sp, color: const Color(0xFF4580C4)),
                ]),
              ),
            ]),
          ),
          SizedBox(
            height: 155.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _featuredCategories.length,
              itemBuilder: (context, index) {
                final cat = _featuredCategories[index];
                final count = _getDocCountForLabel(cat.title);
                final countStr = '$count tài liệu';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryListScreen(
                          categoryTitle: cat.title,
                          customItems: _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 110.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: cat.gradient),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: cat.gradient.first.withValues(alpha: 0.12),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Stack(children: [
                      // Decorative circle
                      Positioned(right: -15.w, top: -15.h,
                        child: Container(width: 60.w, height: 60.w,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08)))),
                      // Music notes for songs
                      if (cat.title == 'Bài hát' || cat.title == 'Audio') ...[
                        Positioned(left: 10.w, top: 15.h,
                          child: Icon(Icons.music_note_rounded,
                            color: Colors.white.withValues(alpha: 0.15), size: 16.sp)),
                        Positioned(right: 30.w, bottom: 50.h,
                          child: Icon(Icons.music_note_rounded,
                            color: Colors.white.withValues(alpha: 0.10), size: 12.sp)),
                      ],
                      Padding(
                        padding: EdgeInsets.fromLTRB(6.w, 10.h, 6.w, 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // Image
                             Expanded(
                               child: Center(
                                 child: FadeInImage.assetNetwork(
                                   placeholder: 'assets/images/splash_bg.png',
                                   image: DocItem.optimizeUrl(cat.image, width: 200),
                                   width: 95.w, height: 95.w, fit: BoxFit.contain,
                                   fadeInDuration: const Duration(milliseconds: 200),
                                   imageErrorBuilder: (_, _, _) => Icon(
                                     Icons.image_rounded, size: 40.sp,
                                     color: Colors.white.withValues(alpha: 0.5)),
                                 )),
                             ),
                             SizedBox(height: 4.h),
                            // Title
                            Text(cat.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp, fontWeight: FontWeight.w800,
                                color: Colors.white, height: 1.2)),
                            SizedBox(height: 4.h),
                            // Count + Arrow
                            Row(children: [
                              Text(countStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp, fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.80))),
                              const Spacer(),
                              Container(
                                width: 20.w, height: 20.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  shape: BoxShape.circle),
                                child: Icon(Icons.chevron_right_rounded,
                                  size: 14.sp, color: Colors.white),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    final list = _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs;
    final selectedDocs = list.where((doc) => doc.matchesCategory(selectedLabel)).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 14.h),
          child: Row(children: [
            Text('$selectedLabel nổi bật',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19.sp, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryListScreen(
                      categoryTitle: selectedLabel,
                      customItems: _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs,
                    ),
                  ),
                );
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Xem tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w600,
                    color: const Color(0xFF4580C4))),
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right_rounded,
                  size: 18.sp, color: const Color(0xFF4580C4)),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: 165.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: selectedDocs.length,
            itemBuilder: (context, index) {
              final doc = selectedDocs[index];
              return GestureDetector(
                onTap: () {
                  if (doc.type == 'Sách') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => doc.isStory
                            ? BookReaderScreen(
                                title: doc.title,
                                imagePath: doc.image,
                              )
                            : BookDetailScreen(
                                title: doc.title,
                                imagePath: doc.image,
                              ),
                      ),
                    );
                  } else if (doc.type == 'Audio') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongPlayerScreen(
                          initialSongTitle: doc.title,
                        ),
                      ),
                    );
                  } else if (doc.type == 'Video') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoDetailScreen(
                          title: doc.title,
                          description: doc.desc,
                          imagePath: doc.image,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: doc.type == 'Video' ? 180.w : 115.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: doc.type == 'Sách'
                          ? const [Color(0xFFE8F0FE), Color(0xFFC2D7FA)]
                          : doc.type == 'Audio'
                              ? const [Color(0xFFF3E8FF), Color(0xFFD8B4FE)]
                              : const [Color(0xFFFFF3E0), Color(0xFFFFCC80)]),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                doc.image.startsWith('http')
                                    ? Image.network(
                                        DocItem.optimizeUrl(doc.image, width: 300),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        doc.image,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                if (doc.type == 'Video') ...[
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    child: Center(
                                      child: Container(
                                        width: 28.w,
                                        height: 28.w,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (doc.duration != null && doc.duration!.isNotEmpty)
                                    Positioned(
                                      bottom: 4.h,
                                      right: 4.w,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(3.r),
                                        ),
                                        child: Text(
                                          doc.duration!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // LATEST DOCUMENTS — List Cards
  // ═══════════════════════════════════════════════════
  Widget _buildLatestSection() {
    final selectedLabel = _tabs[_selectedTab].label;
    final list = _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs;
    var filteredDocs = list.where((doc) => doc.matchesCategory(selectedLabel)).toList();
    if (selectedLabel == 'Tất cả') {
      filteredDocs = filteredDocs.where((doc) => doc.type != 'Video').toList();
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 14.h),
          child: Row(children: [
            Text(selectedLabel == 'Tất cả' ? 'Tài liệu mới nhất' : 'Tài liệu $selectedLabel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19.sp, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryListScreen(
                      categoryTitle: selectedLabel == 'Tất cả' ? 'Tất cả tài liệu' : selectedLabel,
                      customItems: _latestDocs.isNotEmpty ? _latestDocs : _fallbackDocs,
                    ),
                  ),
                );
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Xem tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp, fontWeight: FontWeight.w600,
                    color: const Color(0xFF4580C4))),
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right_rounded,
                  size: 18.sp, color: const Color(0xFF4580C4)),
              ]),
            ),
          ]),
        ),
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (filteredDocs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: Text(
              'Chưa có tài liệu nào trong danh mục này',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...filteredDocs.map((doc) => _buildDocCard(doc)),
      ],
    );
  }

  Widget _buildDocCard(DocItem doc) {
    return GestureDetector(
      onTap: () {
        if (doc.type == 'Sách') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => doc.isStory
                  ? BookReaderScreen(
                      title: doc.title,
                      imagePath: doc.image,
                    )
                  : BookDetailScreen(
                      title: doc.title,
                      imagePath: doc.image,
                    ),
            ),
          );
        } else if (doc.type == 'Audio') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongPlayerScreen(
                initialSongTitle: doc.title,
              ),
            ),
          );
        } else if (doc.type == 'Video') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(
                title: doc.title,
                description: doc.desc,
                imagePath: doc.image,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16.r, offset: Offset(0, 4.h)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4.r, offset: Offset(0, 1.h)),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Thumbnail
          Container(
            width: doc.type == 'Video' ? 120.w : 80.w,
            height: doc.type == 'Video' ? 90.h : 105.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  doc.image.startsWith('http')
                      ? Image.network(DocItem.optimizeUrl(doc.image, width: 300), fit: BoxFit.cover)
                      : Image.asset(doc.image, fit: BoxFit.cover),
                  if (doc.type == 'Video') ...[
                    Container(
                      color: Colors.black.withValues(alpha: 0.15),
                      child: Center(
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ),
                    if (doc.duration != null && doc.duration!.isNotEmpty)
                      Positioned(
                        bottom: 6.h,
                        right: 6.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            doc.duration!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Heart
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(doc.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary))),
                SizedBox(width: 6.w),
                // "Mới" badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r)),
                  child: Text('Mới',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp, fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF6B6B))),
                ),
              ]),
              SizedBox(height: 4.h),
              // Description
              Text(doc.desc,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp, fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.25)),
              SizedBox(height: 6.h),
              // Type badge (colored capsule)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: doc.displayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(doc.displayIcon, size: 11.sp, color: doc.displayColor),
                    SizedBox(width: 4.w),
                    Text(
                      doc.displayType,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: doc.displayColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              // Bottom Row: Rating/Views on the left, Action button on the right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rating & Views
                  Icon(Icons.star_rounded, size: 13.sp, color: const Color(0xFFF0A030)),
                  SizedBox(width: 2.w),
                  Text('${doc.rating}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5.sp, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  SizedBox(width: 5.w),
                  Text('•', style: TextStyle(
                    fontSize: 9.sp, color: AppColors.textHint)),
                  SizedBox(width: 5.w),
                  Icon(Icons.visibility_rounded, size: 11.sp,
                    color: AppColors.textHint),
                  SizedBox(width: 3.w),
                  Text(
                    doc.views.replaceAll(' lượt xem', '').replaceAll(' lượt nghe', ''),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5.sp, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                  const Spacer(),
                  // Action Button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: doc.btnColor,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [BoxShadow(
                        color: doc.btnColor.withValues(alpha: 0.2),
                        blurRadius: 6.r, offset: Offset(0, 2.h))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(doc.btnIcon, size: 12.sp, color: Colors.white),
                      SizedBox(width: 5.w),
                      Text(doc.btnLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5.sp, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ],
          )),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
              _buildNavItem(1, Icons.school_outlined, Icons.school_rounded, 'Học tập'),
              _buildNavItem(2, Icons.sports_esports_outlined, Icons.sports_esports_rounded, 'Trò chơi'),
              _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Hồ sơ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, IconData activeIcon, String label) {
    final bool isSelected = index == 0; // Library Screen is opened from the Home screen (Trang chủ)
    final Color color = isSelected ? AppColors.primary : AppColors.navInactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
          if (index != 0) {
            MainScreenState.of(context)?.switchTab(index);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 26.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                height: 1.1,
              ),
            ),
            SizedBox(height: 3.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 20.w : 0.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════
class _TabData {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _TabData({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
}

class _FeaturedCat {
  final String title, image;
  final List<Color> gradient;
  const _FeaturedCat({
    required this.title,
    required this.image,
    required this.gradient,
  });
}

// ═══════════════════════════════════════════════════
// CUSTOM WAVE CLIPPER FOR HEADER OVERLAP
// ═══════════════════════════════════════════════════
class LibraryHeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Start at left edge
    path.moveTo(0, 32.r);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, 32.r, 0);

    // Flat line under the search bar
    path.lineTo(195.w, 0);

    // Smooth curve down to valley (center at 245.w, depth 12.h)
    path.cubicTo(
      215.w, 0,
      225.w, 12.h,
      245.w, 12.h,
    );

    // Smooth curve up to mascot shelf (peaks at 295.w, y = 0)
    path.cubicTo(
      265.w, 12.h,
      275.w, 0,
      295.w, 0,
    );

    // Flat line under mascot
    path.lineTo(w - 32.r, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(w, 0, w, 32.r);

    // Right edge down to bottom
    path.lineTo(w, h);
    // Bottom edge to left
    path.lineTo(0, h);
    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
