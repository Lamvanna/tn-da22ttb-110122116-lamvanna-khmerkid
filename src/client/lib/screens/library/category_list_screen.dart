import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_header.dart';
import 'book_detail_screen.dart';
import 'book_reader_screen.dart';
import 'video_detail_screen.dart';
import 'song_player_screen.dart';
import '../../l10n/app_localizations.dart';

class CategoryListScreen extends StatelessWidget {
  final String categoryTitle;
  final List<DocItem>? customItems;

  const CategoryListScreen({
    super.key,
    required this.categoryTitle,
    this.customItems,
  });

  String _translateCategory(BuildContext context, String label) {
    switch (label) {
      case 'Tất cả':
        return context.translate('library.all');
      case 'Sách':
        return context.translate('library.books');
      case 'Truyện':
        return context.translate('library.stories');
      case 'Bài hát':
        return context.translate('library.songs');
      case 'Video':
        return context.translate('library.videos');
      case 'Kiến thức':
        return context.translate('library.knowledge');
      case 'Yêu thích':
        return context.translate('library.favorites');
      default:
        return label;
    }
  }

  String _translateBtnLabel(BuildContext context, String btnLabel) {
    switch (btnLabel) {
      case 'Đọc ngay':
        return context.translate('library.read_now');
      case 'Nghe ngay':
        return context.translate('library.listen_now');
      case 'Xem ngay':
        return context.translate('library.watch_now');
      default:
        return btnLabel;
    }
  }

  List<_FeaturedCat> get _featuredCategories => [
    const _FeaturedCat(
      title: 'Sách',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810872/khmerkid/library/l1lba7h2swazdzwlnp4m.png',
      gradient: [Color(0xFF7EB1FF), Color(0xFF568FFF)]),
    const _FeaturedCat(
      title: 'Truyện',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810866/khmerkid/library/ea7hwynods7uehxiwjyk.png',
      gradient: [Color(0xFF7EE79D), Color(0xFF52BF76)]),
    const _FeaturedCat(
      title: 'Bài hát',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810869/khmerkid/library/k2ddww6pnnw93cj5mcjo.png',
      gradient: [Color(0xFFD39BFF), Color(0xFFAD6BFF)]),
    const _FeaturedCat(
      title: 'Video',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810867/khmerkid/library/video.png',
      gradient: [Color(0xFFFFB37E), Color(0xFFF88F48)]),
    const _FeaturedCat(
      title: 'Kiến thức',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810870/khmerkid/library/fitdcgqfto7135no5aat.png',
      gradient: [Color(0xFFFFE07D), Color(0xFFF2BC3F)]),
    const _FeaturedCat(
      title: 'Yêu thích',
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781810868/khmerkid/library/lqlngfhcifbpvqcdygmm.png',
      gradient: [Color(0xFFFF9EC3), Color(0xFFE86F9C)]),
  ];

  List<DocItem> _getItemsForCategory() {
    final list = customItems ?? DocItem.fallbackDocs;
    if (categoryTitle == 'Tất cả danh mục' || categoryTitle == 'Tất cả') {
      return list.where((doc) => doc.type != 'Video').toList();
    }
    return list.where((doc) => doc.matchesCategory(categoryTitle)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTitle == 'Tất cả danh mục') {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AppHeader(
              title: context.translate('library.all_categories'),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 16.w,
                  childAspectRatio: 0.78,
                ),
                itemCount: _featuredCategories.length,
                itemBuilder: (context, index) {
                  final cat = _featuredCategories[index];
                  final count = (customItems ?? DocItem.fallbackDocs)
                      .where((doc) => doc.matchesCategory(cat.title))
                      .length;
                  final countStr = context.translatePlural('library.documents_count', count);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryListScreen(
                            categoryTitle: cat.title,
                            customItems: customItems,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: cat.gradient),
                        borderRadius: BorderRadius.circular(22.r),
                        boxShadow: [
                          BoxShadow(
                            color: cat.gradient.first.withValues(alpha: 0.12),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -15.w, top: -15.h,
                            child: Container(
                              width: 60.w, height: 60.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: FadeInImage.assetNetwork(
                                      placeholder: 'assets/images/splash_bg.png',
                                      image: DocItem.optimizeUrl(cat.image, width: 250),
                                      width: 120.w, height: 120.w, fit: BoxFit.contain,
                                      fadeInDuration: const Duration(milliseconds: 200),
                                      imageErrorBuilder: (_, _, _) => Icon(
                                        Icons.image_rounded, size: 48.sp,
                                        color: Colors.white.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _translateCategory(context, cat.title),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.sp, fontWeight: FontWeight.w800,
                                    color: Colors.white, height: 1.2),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Text(
                                      countStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp, fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.80)),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 22.w, height: 22.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.20),
                                        shape: BoxShape.circle),
                                      child: Icon(Icons.chevron_right_rounded,
                                        size: 16.sp, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    final items = _getItemsForCategory();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppHeader(
            title: categoryTitle == 'Tất cả danh mục' || categoryTitle == 'Tất cả'
                ? context.translate('library.latest_documents')
                : _translateCategory(context, categoryTitle),
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final doc = items[index];
                return _buildDocCard(context, doc);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, DocItem doc) {
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
                  child: Text(context.translate('library.new_badge'),
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
                      _translateCategory(context, doc.displayType),
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
                      Text(_translateBtnLabel(context, doc.btnLabel),
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
}

class DocItem {
  final String title, type, desc, views, btnLabel, image;
  final IconData typeIcon, btnIcon;
  final Color typeColor, btnColor;
  final double rating;
  final String? duration;

  const DocItem({
    required this.title,
    required this.type,
    required this.typeIcon,
    required this.typeColor,
    required this.desc,
    required this.rating,
    required this.views,
    required this.btnLabel,
    required this.btnIcon,
    required this.btnColor,
    required this.image,
    this.duration,
  });

  bool get isStory {
    if (type != 'Sách') return false;
    final t = title.toLowerCase();
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

  String get displayType {
    if (type == 'Audio') return 'Bài hát';
    if (isStory) return 'Truyện';
    return type;
  }

  Color get displayColor {
    if (isStory) return const Color(0xFF22C55E);
    return typeColor;
  }

  IconData get displayIcon {
    if (isStory) return Icons.auto_stories_rounded;
    return typeIcon;
  }

  static String optimizeUrl(String url, {int width = 300}) {
    if (url.startsWith('https://res.cloudinary.com/')) {
      if (url.contains('/image/upload/') && !url.contains('f_auto')) {
        return url.replaceFirst('/image/upload/', '/image/upload/f_auto,q_auto,w_$width/');
      }
    }
    return url;
  }

  bool matchesCategory(String label) {
    if (label == 'Tất cả') return true;
    if (label == 'Yêu thích') return rating >= 4.8;
    if (label == 'Truyện') {
      // Truyện tab: bao gồm cả items có type='Truyện' lẫn Sách có isStory=true
      return type == 'Truyện' || isStory;
    }
    if (label == 'Sách') {
      // Tab Sách: chỉ hiển thị Sách KHÔNG phải truyện
      return type == 'Sách' && !isStory;
    }
    if (label == 'Bài hát') {
      return type == 'Audio';
    }
    if (label == 'Kiến thức') {
      return type == 'Video' || 
        title.contains('Học') || 
        title.contains('Đếm') || 
        title.contains('Bảng') || 
        title.contains('chữ') || 
        title.toLowerCase().contains('học') || 
        title.toLowerCase().contains('chữ') ||
        title.toLowerCase().contains('kiến thức');
    }
    return type == label;
  }

  static List<DocItem> get fallbackDocs => [
    const DocItem(
      title: 'Học chữ khmer', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Học bảng chữ cái và cách phát âm cơ bản',
      rating: 4.8, views: '1.2K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781825/khmerkid/library/eddtrctzrddpea2mtfx1.png'),
    const DocItem(
      title: 'TRuyện thiếu nhi', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Các câu chuyện ý nghĩa cho bé học tập',
      rating: 4.9, views: '850 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png'),
    const DocItem(
      title: 'Bé Tập Viết Chữ Khmer', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Tập tô nét chữ Khmer chuẩn tiểu học',
      rating: 4.7, views: '950 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781835/khmerkid/library/fof6w2jwtpitzj32vqus.png'),
    const DocItem(
      title: 'Học Từ Vựng Khmer Qua Hình Ảnh', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Học từ vựng trực quan sinh động qua tranh vẽ',
      rating: 4.8, views: '1.1K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781824/khmerkid/library/mtcq0mpsgjw65ey8fsbg.png'),
    const DocItem(
      title: 'ដំរីតូចក្លាហាន', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Câu chuyện về lòng dũng cảm của chú voi nhỏ',
      rating: 4.9, views: '720 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png'),
    const DocItem(
      title: 'Thỏ Trắng Và Ngôi Sao May Mắn', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Câu chuyện thỏ trắng tìm ngôi sao may mắn',
      rating: 4.8, views: '640 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png'),
    const DocItem(
      title: 'Hành Trình Tìm Cầu Vồng Của Bé Sóc', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Cuộc phiêu lưu kỳ thú của chú sóc nhỏ',
      rating: 4.7, views: '580 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781827/khmerkid/library/fytoyjalak42cfisfg3d.png'),
    const DocItem(
      title: 'ស្វាតូចឆ្លាតវៃ', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Câu chuyện thông minh dí dỏm về chú khỉ con',
      rating: 4.9, views: '890 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781833/khmerkid/library/c42qxbcimdhz4am2ywes.png'),
    const DocItem(
      title: 'ទន្សាយនិងអណ្តើក', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Truyện ngụ ngôn Rùa và Thỏ bằng tiếng Khmer',
      rating: 4.8, views: '1.2K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png'),
    const DocItem(
      title: 'Bảng Chữ Cái Khmer Vui Nhộn', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Học chữ cái qua các bài hát vui nhộn',
      rating: 4.8, views: '910 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781822/khmerkid/library/zx2pibowpd287plq34sn.png'),
    const DocItem(
      title: 'Hành Trình 33 Chữ Cái Khmer', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Khám phá thế giới 33 chữ cái phụ âm',
      rating: 4.9, views: '1.5K lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781823/khmerkid/library/sh5oitnbnr3hhregxnor.png'),
    const DocItem(
      title: 'Bé Học Từ Vựng', type: 'Sách', typeIcon: Icons.menu_book_rounded,
      typeColor: Color(0xFF27AE60),
      desc: 'Phát triển vốn từ vựng Khmer cơ bản hằng ngày',
      rating: 4.7, views: '830 lượt xem',
      btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
      btnColor: Color(0xFF27AE60),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png'),
    const DocItem(
      title: 'ក្មេងៗ ច្រៀងលេង (Trẻ em ca hát vui đùa)', type: 'Audio', typeIcon: Icons.music_note_rounded,
      typeColor: Color(0xFFFD79A8),
      desc: 'Bài hát tiếng Khmer vui nhộn dành cho bé',
      rating: 4.9, views: '2.5K lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.music_note_rounded,
      btnColor: Color(0xFFFD79A8),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png'),
    const DocItem(
      title: 'ដំរីតូច (Chú voi con)', type: 'Audio', typeIcon: Icons.music_note_rounded,
      typeColor: Color(0xFFFD79A8),
      desc: 'Bài hát tiếng Khmer về chú voi con ngộ nghĩnh',
      rating: 4.8, views: '1.9K lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.music_note_rounded,
      btnColor: Color(0xFFFD79A8),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png'),
    const DocItem(
      title: 'គេងលក់ យប់index (Đi ngủ nào bé ơi)', type: 'Audio', typeIcon: Icons.music_note_rounded,
      typeColor: Color(0xFFFD79A8),
      desc: 'Bài hát tiếng Khmer ru bé giấc ngủ êm đềm',
      rating: 4.7, views: '2.1K lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.music_note_rounded,
      btnColor: Color(0xFFFD79A8),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png'),
    const DocItem(
      title: ' ខ្ញុំស្រឡាញ់គ្រួសារ (Em yêu gia đình)', type: 'Audio', typeIcon: Icons.music_note_rounded,
      typeColor: Color(0xFFFD79A8),
      desc: 'Bài hát tiếng Khmer ý nghĩa ca ngợi gia đình thân thương',
      rating: 4.9, views: '2.4K lượt nghe',
      btnLabel: 'Nghe ngay', btnIcon: Icons.music_note_rounded,
      btnColor: Color(0xFFFD79A8),
      image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png'),
    const DocItem(
      title: 'Học nguyên âm tiếng Khmer', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Học nguyên âm qua video hoạt hình',
      rating: 4.7, views: '2.1K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Nguyên âm.png',
      duration: '08:45'),
    const DocItem(
      title: 'Đếm số 1-10', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Nhận diện chữ số Khmer qua bài hát',
      rating: 4.9, views: '3.2K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Tập đọc.png',
      duration: '05:30'),
    const DocItem(
      title: 'Giải cứu thú rừng', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Học từ vựng Khmer qua cuộc chiến bảo vệ rừng xanh',
      rating: 4.8, views: '1.5K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Giải cứu thú rừng.png',
      duration: '10:15'),
    const DocItem(
      title: 'Đảo quốc Ngữ pháp', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Khám phá thế giới ngữ pháp Khmer qua chuyến đi phiêu lưu',
      rating: 4.9, views: '2.3K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Đảo quốc Ngữ pháp.png',
      duration: '12:40'),
    const DocItem(
      title: 'Cờ tỷ phú Khmer kỳ thú', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Vừa chơi cờ vừa học giao tiếp tiếng Khmer thực tế',
      rating: 4.7, views: '980 lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Cờ tỷ phú Khmer kỳ thú.png',
      duration: '15:20'),
    const DocItem(
      title: 'Nhà khảo cổ nhí', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Khám phá lịch sử cổ xưa qua các chữ cái Khmer',
      rating: 4.8, views: '1.1K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Nhà khảo cổ nhí.png',
      duration: '09:50'),
    const DocItem(
      title: 'Bắt chữ Khmer', type: 'Video', typeIcon: Icons.play_circle_rounded,
      typeColor: Color(0xFFF2994A),
      desc: 'Đố vui đoán chữ Khmer cực nhanh cho các bé học từ',
      rating: 4.9, views: '3.0K lượt xem',
      btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
      btnColor: Color(0xFFF2994A),
      image: 'image/Bắt chữ Khmer.png',
      duration: '11:05'),
  ];
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
