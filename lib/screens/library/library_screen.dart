import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../main_screen.dart';
import 'book_detail_screen.dart';
import 'audio_detail_screen.dart';
import 'video_detail_screen.dart';
import 'category_list_screen.dart';

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
    _TabData(icon: Icons.auto_stories_rounded, label: 'Tất cả', count: 128, color: Color(0xFF1E6DEB)),
    _TabData(icon: Icons.menu_book_rounded, label: 'Sách', count: 45, color: Color(0xFF27AE60)),
    _TabData(icon: Icons.headphones_rounded, label: 'Audio', count: 32, color: Color(0xFF733AEB)),
    _TabData(icon: Icons.play_circle_rounded, label: 'Video', count: 28, color: Color(0xFFF2994A)),
    _TabData(icon: Icons.favorite_rounded, label: 'Yêu thích', count: 12, color: Color(0xFFE25C5C)),
  ];

  static final _featuredCategories = [
    _FeaturedCat(
      title: 'Sách', count: '20 cuốn',
      image: 'image/Tập đọc.png',
      gradient: const [Color(0xFF4DA0F0), Color(0xFF1E6DEB)]),
    _FeaturedCat(
      title: 'Truyện', count: '15 cuốn',
      image: 'image/Sách.png',
      gradient: const [Color(0xFF76D69B), Color(0xFF2FB369)]),
    _FeaturedCat(
      title: 'Bài hát', count: '18 bài',
      image: 'image/Nghe.png',
      gradient: const [Color(0xFFB392F0), Color(0xFF733AEB)]),
    _FeaturedCat(
      title: 'Kiến thức', count: '25 bài',
      image: 'image/Học.png',
      gradient: const [Color(0xFFFBD075), Color(0xFFF79E2E)]),
  ];

  static final _latestDocs = [
    _DocItem(
      title: 'Khám phá Angkor Wat', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: const Color(0xFF5B8FD4),
      desc: 'Tìm hiểu về kỳ quan thế giới Angkor Wat',
      rating: 4.8, views: '1.2K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: const Color(0xFF5B8FD4),
      image: 'image/Khám phá văn hóa.png'),
    _DocItem(
      title: 'Chú thỏ thông minh', type: 'Audio', typeIcon: Icons.headphones_rounded,
      typeColor: const Color(0xFF733AEB),
      desc: 'Câu chuyện kể bằng tiếng Khmer',
      rating: 4.9, views: '856 lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.headphones_rounded,
      btnColor: const Color(0xFF733AEB),
      image: 'image/Sách.png'),
    _DocItem(
      title: 'Học nguyên âm tiếng Khmer', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: const Color(0xFFF2994A),
      desc: 'Học nguyên âm qua video hoạt hình',
      rating: 4.7, views: '2.1K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: const Color(0xFFF2994A),
      image: 'image/Nguyên âm.png'),
    _DocItem(
      title: 'Rùa và Thỏ', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: const Color(0xFF27AE60),
      desc: 'Truyện ngụ ngôn ý nghĩa cho bé',
      rating: 4.8, views: '1.1K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: const Color(0xFF27AE60),
      image: 'image/Khám phá văn hóa.png'),
    _DocItem(
      title: 'Bài ca đi học', type: 'Audio', typeIcon: Icons.headphones_rounded,
      typeColor: const Color(0xFF733AEB),
      desc: 'Bài hát tiếng Khmer vui nhộn',
      rating: 4.9, views: '2.4K lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.headphones_rounded,
      btnColor: const Color(0xFF733AEB),
      image: 'image/Nghe.png'),
    _DocItem(
      title: 'Đếm số 1-10', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: const Color(0xFFF2994A),
      desc: 'Nhận diện chữ số Khmer qua bài hát',
      rating: 4.9, views: '3.2K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: const Color(0xFFF2994A),
      image: 'image/Tập đọc.png'),
  ];

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
                        right: -55.w,
                        top: -190.h,
                        child: Image.asset(
                          'image/Voi header.png',
                          width: 275.w,
                          height: 275.w,
                          fit: BoxFit.contain,
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
            contentPadding: EdgeInsets.symmetric(vertical: 11.h)),
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
                width: 72.w,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: selected
                      ? const Color(0xFF1E6DEB)
                      : const Color(0xFFE2E8F0),
                    width: selected ? 2.w : 1.5.w,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E6DEB).withValues(alpha: 0.12),
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
                        color: selected ? const Color(0xFF1E6DEB) : tab.color,
                      ),
                      SizedBox(height: 6.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tab.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: selected ? const Color(0xFF1E6DEB) : const Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${tab.count} tài liệu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w600,
                            color: selected
                              ? const Color(0xFF1E6DEB).withValues(alpha: 0.7)
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
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryListScreen(
                        categoryTitle: cat.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: cat.gradient),
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [BoxShadow(
                      color: cat.gradient.first.withValues(alpha: 0.30),
                      blurRadius: 14.r, offset: Offset(0, 6.h))],
                  ),
                  child: Stack(children: [
                    // Decorative circle
                    Positioned(right: -15.w, top: -15.h,
                      child: Container(width: 60.w, height: 60.w,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08)))),
                    // Music notes for songs
                    if (index == 2) ...[
                      Positioned(left: 10.w, top: 15.h,
                        child: Icon(Icons.music_note_rounded,
                          color: Colors.white.withValues(alpha: 0.15), size: 16.sp)),
                      Positioned(right: 30.w, bottom: 50.h,
                        child: Icon(Icons.music_note_rounded,
                          color: Colors.white.withValues(alpha: 0.10), size: 12.sp)),
                    ],
                    Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image
                          Expanded(
                            child: Center(
                              child: Image.asset(cat.image,
                                width: 80.w, height: 80.w, fit: BoxFit.contain)),
                          ),
                          SizedBox(height: 8.h),
                          // Title
                          Text(cat.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1.2)),
                          SizedBox(height: 4.h),
                          // Count + Arrow
                          Row(children: [
                            Text(cat.count,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.80))),
                            const Spacer(),
                            Container(
                              width: 22.w, height: 22.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                shape: BoxShape.circle),
                              child: Icon(Icons.chevron_right_rounded,
                                size: 16.sp, color: Colors.white),
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

  // ═══════════════════════════════════════════════════
  // LATEST DOCUMENTS — List Cards
  // ═══════════════════════════════════════════════════
  Widget _buildLatestSection() {
    final selectedLabel = _tabs[_selectedTab].label;
    final filteredDocs = _latestDocs.where((doc) {
      if (selectedLabel == 'Tất cả') return true;
      if (selectedLabel == 'Yêu thích') {
        return doc.rating >= 4.8;
      }
      return doc.type == selectedLabel;
    }).toList();

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
        if (filteredDocs.isEmpty)
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

  Widget _buildDocCard(_DocItem doc) {
    return GestureDetector(
      onTap: () {
        if (doc.type == 'Sách') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(
                title: doc.title,
                imagePath: doc.image,
              ),
            ),
          );
        } else if (doc.type == 'Audio') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioDetailScreen(
                title: doc.title,
                description: doc.desc,
                imagePath: doc.image,
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
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16.r, offset: Offset(0, 4.h)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4.r, offset: Offset(0, 1.h)),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          Container(
            width: 85.w, height: 95.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(doc.image, fit: BoxFit.cover)),
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
                    borderRadius: BorderRadius.circular(6.r)),
                  child: Text('Mới',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp, fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF6B6B))),
                ),
              ]),
              SizedBox(height: 4.h),
              // Type badge
              Row(children: [
                Icon(doc.typeIcon, size: 14.sp, color: doc.typeColor),
                SizedBox(width: 4.w),
                Text(doc.type,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp, fontWeight: FontWeight.w600,
                    color: doc.typeColor)),
              ]),
              SizedBox(height: 4.h),
              // Description
              Text(doc.desc,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
              SizedBox(height: 8.h),
              // Rating + Views + Button
              Row(children: [
                Icon(Icons.star_rounded, size: 14.sp, color: const Color(0xFFF0A030)),
                SizedBox(width: 3.w),
                Text('${doc.rating}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                SizedBox(width: 6.w),
                Text('•', style: TextStyle(
                  fontSize: 10.sp, color: AppColors.textHint)),
                SizedBox(width: 6.w),
                Icon(Icons.visibility_rounded, size: 12.sp,
                  color: AppColors.textHint),
                SizedBox(width: 3.w),
                Expanded(child: Text(doc.views,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp, fontWeight: FontWeight.w500,
                    color: AppColors.textHint))),
                // Action button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: doc.btnColor,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [BoxShadow(
                      color: doc.btnColor.withValues(alpha: 0.30),
                      blurRadius: 8.r, offset: Offset(0, 3.h))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(doc.btnIcon, size: 14.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(doc.btnLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ]),
                ),
              ]),
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
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16.r, offset: Offset(0, -2.h))],
      ),
      child: SafeArea(
        child: ClipRect(
          child: BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              Navigator.pop(context);
              MainScreenState.of(context)?.switchTab(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.navInactive,
            selectedFontSize: 12.sp,
            unselectedFontSize: 12.sp,
            selectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w500),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.home_outlined, size: 26.sp)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.home_rounded, size: 26.sp)),
                label: 'Trang chủ'),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.school_outlined, size: 26.sp)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.school_rounded, size: 26.sp)),
                label: 'Học'),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.sports_esports_outlined, size: 26.sp)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.sports_esports_rounded, size: 26.sp)),
                label: 'Chơi'),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.person_outline_rounded, size: 26.sp)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(Icons.person_rounded, size: 26.sp)),
                label: 'Hồ sơ'),
            ],
          ),
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
  final String title, count, image;
  final List<Color> gradient;
  const _FeaturedCat({
    required this.title, required this.count,
    required this.image, required this.gradient});
}

class _DocItem {
  final String title, type, desc, views, btnLabel, image;
  final IconData typeIcon, btnIcon;
  final Color typeColor, btnColor;
  final double rating;
  const _DocItem({
    required this.title, required this.type, required this.typeIcon,
    required this.typeColor, required this.desc,
    required this.rating, required this.views,
    required this.btnLabel, required this.btnIcon, required this.btnColor,
    required this.image});
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
