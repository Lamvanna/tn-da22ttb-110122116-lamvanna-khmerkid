import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_list_screen.dart';
import 'book_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final String title;
  final String imagePath;

  const BookDetailScreen({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorited = false;
  
  _BookDetailInfo? _detailInfoCached;
  _BookDetailInfo get _detailInfo => _detailInfoCached ??= _getBookDetailData(widget.title);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant BookDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _detailInfoCached = null;
    }
  }

  _BookDetailInfo _getBookDetailData(String title) {
    final t = title.toLowerCase();
    final isStory = t.contains('truyện') ||
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

    if (isStory) {
      String desc = 'Câu chuyện ngụ ngôn ý nghĩa dạy cho bé bài học sâu sắc về sự kiên trì, nỗ lực hết mình và tinh thần không chủ quan trước mọi đối thủ.';
      String khmerWord = 'ទន្សាយ';
      String spelling = 'Tên: Tonsay';
      String meaning = 'Con thỏ';

      if (t.contains('ដំរី') || t.contains('voi')) {
        desc = 'Câu chuyện về lòng dũng cảm của chú voi nhỏ Mambo sẵn sàng bảo vệ các bạn muông thú trong rừng xanh.';
        khmerWord = 'ដំរី';
        spelling = 'Tên: Domrey';
        meaning = 'Con voi';
      } else if (t.contains('ស្វា') || t.contains('khỉ')) {
        desc = 'Câu chuyện thông minh và dí dỏm về chú khỉ con vượt qua các thử thách khó khăn một cách khéo léo.';
        khmerWord = 'ស្វា';
        spelling = 'Tên: Sva';
        meaning = 'Con khỉ';
      }

      return _BookDetailInfo(
        title: title.split('(').first.trim(),
        subtitle: title.contains('(') ? title.split('(').last.replaceAll(')', '').trim() : 'Truyện thiếu nhi',
        category: 'Truyện đọc',
        categoryColor: const Color(0xFF22C55E),
        description: desc,
        pagesCount: '12 trang',
        format: 'Trực tuyến',
        updated: 'Cập nhật: 01/2026',
        author: 'Tác giả: Nhóm Na Khmer',
        chapters: [
          _ChapterItem(title: 'Chương 1', subtitle: 'Khởi đầu cuộc đua', pagesRange: '1 - 4', badgeColor: const Color(0xFFC084FC)),
          _ChapterItem(title: 'Chương 2', subtitle: 'Sự kiêu ngạo của Thỏ', pagesRange: '5 - 8', badgeColor: const Color(0xFF4ADE80)),
          _ChapterItem(title: 'Chương 3', subtitle: 'Rùa vượt qua giới hạn', pagesRange: '9 - 11', badgeColor: const Color(0xFFFDBA74)),
          _ChapterItem(title: 'Chương 4', subtitle: 'Bài học ý nghĩa', pagesRange: '12 - 12', badgeColor: const Color(0xFF60A5FA)),
        ],
        preview: _PreviewItem(
          khmerWord: khmerWord,
          khmerSpelling: spelling,
          vietnameseMeaning: meaning,
          exampleVoice: khmerWord,
          meaningVoice: meaning,
        ),
        relatedBooks: [
          _RelatedBook(title: 'Hành Trình Tìm Cầu Vồng Của Bé Sóc', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781827/khmerkid/library/fytoyjalak42cfisfg3d.png'),
          _RelatedBook(title: 'ដំរីតូចក្លាហាន (Voi con dũng cảm)', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png'),
          _RelatedBook(title: 'ស្វាតូចឆ្លាតវៃ (Khỉ con thông minh)', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781833/khmerkid/library/c42qxbcimdhz4am2ywes.png'),
          _RelatedBook(title: 'Thỏ Trắng Và Ngôi Sao May Mắn', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png'),
        ],
      );
    } else {
      // It is a consonant/alphabet learning book
      return _BookDetailInfo(
        title: title.split('(').first.trim(),
        subtitle: title.contains('(') ? title.split('(').last.replaceAll(')', '').trim() : 'Sách học chữ cái',
        category: 'Sách học',
        categoryColor: const Color(0xFF7C3AED),
        description: 'Cuốn sách giúp bé làm quen với 33 chữ phụ âm trong tiếng Khmer qua hình ảnh minh họa sinh động, dễ nhớ và dễ tập đọc.',
        pagesCount: '45 trang',
        format: 'Định dạng: PDF',
        updated: 'Cập nhật: 01/2026',
        author: 'Tác giả: Nhóm Na Khmer',
        chapters: [
          _ChapterItem(title: 'Chương 1', subtitle: 'Giới thiệu phụ âm Khmer', pagesRange: '1 - 5', badgeColor: const Color(0xFFC084FC)),
          _ChapterItem(title: 'Chương 2', subtitle: 'Nhóm phụ âm A', pagesRange: '6 - 15', badgeColor: const Color(0xFF4ADE80)),
          _ChapterItem(title: 'Chương 3', subtitle: 'Nhóm phụ âm O', pagesRange: '16 - 30', badgeColor: const Color(0xFFFDBA74)),
          _ChapterItem(title: 'Chương 4', subtitle: 'Ôn tập', pagesRange: '31 - 45', badgeColor: const Color(0xFF60A5FA)),
        ],
        preview: _PreviewItem(
          khmerWord: 'ក',
          khmerSpelling: 'Tên: Ko',
          vietnameseMeaning: 'Con gà',
          exampleVoice: 'ក',
          meaningVoice: 'Con gà',
        ),
        relatedBooks: [
          _RelatedBook(title: 'Sách Nguyên Âm Khmer', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781825/khmerkid/library/eddtrctzrddpea2mtfx1.png'),
          _RelatedBook(title: 'Sách Ghép Vần Khmer', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png'),
          _RelatedBook(title: 'Sách Tập Viết Khmer', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781835/khmerkid/library/fof6w2jwtpitzj32vqus.png'),
          _RelatedBook(title: 'Sách Số Đếm Khmer', image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781822/khmerkid/library/zx2pibowpd287plq34sn.png'),
        ],
      );
    }
  }

  void _downloadPdf() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.download_done_rounded, color: const Color(0xFF22C55E), size: 28.sp),
            SizedBox(width: 10.w),
            Text(
              'Tải thành công',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          'Tài liệu PDF của "${_detailInfo.title}" đã được lưu về bộ nhớ thiết bị của con! 📥✨',
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tuyệt vời',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverImage = widget.imagePath;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header app bar
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16.sp,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFavorited = !_isFavorited;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorited ? 'Đã lưu vào yêu thích!' : 'Đã bỏ lưu yêu thích'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18.sp,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            title: Text(
              'Chi tiết tài liệu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            centerTitle: true,
          ),

          // Main body
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Info Section (Row with 3D cover + Details list)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Book Cover Card
                      Container(
                        width: 145.w,
                        height: 205.h,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16.r,
                              spreadRadius: 1.r,
                              offset: Offset(4.w, 8.h),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6.r),
                            bottomLeft: Radius.circular(6.r),
                            topRight: Radius.circular(16.r),
                            bottomRight: Radius.circular(16.r),
                          ),
                          child: Stack(
                            children: [
                              coverImage.startsWith('http')
                                  ? Image.network(
                                      DocItem.optimizeUrl(coverImage, width: 400),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Image.asset(
                                      coverImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                              // Book Spine Overlay shadow
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 14.w,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.22),
                                        Colors.black.withValues(alpha: 0.04),
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.35, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // 4-8 Age Badge at bottom left
                              Positioned(
                                left: 8.w,
                                bottom: 10.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'DÀNH CHO BÉ\n4-8 TUỔI',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 6.5.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 18.w),

                      // Details Info list
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detailInfo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            // Category Badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: _detailInfo.categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                _detailInfo.category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _detailInfo.categoryColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Details rows
                            _buildDetailRow(Icons.menu_book_rounded, _detailInfo.title, const Color(0xFF3B82F6)),
                            _buildDetailRow(Icons.description_rounded, _detailInfo.pagesCount, const Color(0xFF64748B)),
                            _buildDetailRow(Icons.picture_as_pdf_rounded, _detailInfo.format, const Color(0xFFEF4444)),
                            _buildDetailRow(Icons.calendar_month_rounded, _detailInfo.updated, const Color(0xFFF59E0B)),
                            _buildDetailRow(Icons.person_rounded, _detailInfo.author, const Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),

                  // Introduction Box (Lavender banner)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
                            SizedBox(width: 6.w),
                            Text(
                              'Giới thiệu',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _detailInfo.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Buttons Row: Đọc sách & Tải PDF
                  Row(
                    children: [
                      // Nút Đọc sách
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookReaderScreen(
                                  title: widget.title,
                                  imagePath: widget.imagePath,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded, color: Colors.white, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Đọc sách',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Nút Tải PDF
                      Expanded(
                        child: GestureDetector(
                          onTap: _downloadPdf,
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: const Color(0xFF7C3AED), width: 1.5.w),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded, color: const Color(0xFF7C3AED), size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Tải PDF',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),

                  // Related Books Section (Sách liên quan)
                  Row(
                    children: [
                      Text(
                        'Sách liên quan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Xem tất cả',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4580C4),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: const Color(0xFF4580C4),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Related books list (Horizontal Scroll View)
                  SizedBox(
                    height: 145.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _detailInfo.relatedBooks.length,
                      itemBuilder: (context, index) {
                        final rel = _detailInfo.relatedBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(
                                  title: rel.title,
                                  imagePath: rel.image,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 95.w,
                            margin: EdgeInsets.only(right: 12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(6.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: rel.image.startsWith('http')
                                          ? Image.network(
                                              DocItem.optimizeUrl(rel.image, width: 250),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              rel.image,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    rel.title.split('(').first.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E293B),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: iconColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }


}

class _BookDetailInfo {
  final String title;
  final String subtitle;
  final String category;
  final Color categoryColor;
  final String description;
  final String pagesCount;
  final String format;
  final String updated;
  final String author;
  final List<_ChapterItem> chapters;
  final _PreviewItem preview;
  final List<_RelatedBook> relatedBooks;

  _BookDetailInfo({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.categoryColor,
    required this.description,
    required this.pagesCount,
    required this.format,
    required this.updated,
    required this.author,
    required this.chapters,
    required this.preview,
    required this.relatedBooks,
  });
}

class _ChapterItem {
  final String title;
  final String subtitle;
  final String pagesRange;
  final Color badgeColor;

  _ChapterItem({
    required this.title,
    required this.subtitle,
    required this.pagesRange,
    required this.badgeColor,
  });
}

class _PreviewItem {
  final String khmerWord;
  final String khmerSpelling;
  final String vietnameseMeaning;
  final String exampleVoice;
  final String meaningVoice;

  String get exampleImage {
    if (khmerWord == 'ក') {
      return 'image/Hình phần thư viện/Sách.png';
    } else if (khmerWord == 'ដំរី') {
      return 'image/Hình phần thư viện/Kiến thức.png';
    } else if (khmerWord == 'ស្វា') {
      return 'image/Hình phần thư viện/video.png';
    }
    return 'image/Hình phần thư viện/Truyện.png';
  }

  _PreviewItem({
    required this.khmerWord,
    required this.khmerSpelling,
    required this.vietnameseMeaning,
    required this.exampleVoice,
    required this.meaningVoice,
  });
}

class _RelatedBook {
  final String title;
  final String image;

  _RelatedBook({
    required this.title,
    required this.image,
  });
}

