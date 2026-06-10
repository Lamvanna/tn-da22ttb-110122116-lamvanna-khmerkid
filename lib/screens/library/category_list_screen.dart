import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_header.dart';
import 'book_detail_screen.dart';
import 'audio_detail_screen.dart';
import 'video_detail_screen.dart';

class CategoryListScreen extends StatelessWidget {
  final String categoryTitle;

  const CategoryListScreen({super.key, required this.categoryTitle});

  List<_DocItem> _getItemsForCategory() {
    if (categoryTitle == 'Sách') {
      return [
        _DocItem(
          title: 'Khám phá Angkor Wat', type: 'Sách', typeIcon: Icons.menu_book_rounded,
          typeColor: const Color(0xFF5B8FD4),
          desc: 'Tìm hiểu về kỳ quan thế giới Angkor Wat',
          rating: 4.8, views: '1.2K lượt xem',
          btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
          btnColor: const Color(0xFF5B8FD4),
          image: 'image/Khám phá văn hóa.png'),
        _DocItem(
          title: 'Học phụ âm Khmer', type: 'Sách', typeIcon: Icons.menu_book_rounded,
          typeColor: const Color(0xFF5B8FD4),
          desc: 'Bảng 33 phụ âm tiếng Khmer cơ bản',
          rating: 4.9, views: '950 lượt xem',
          btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
          btnColor: const Color(0xFF5B8FD4),
          image: 'image/Học.png'),
        _DocItem(
          title: 'Bé học viết chữ', type: 'Sách', typeIcon: Icons.menu_book_rounded,
          typeColor: const Color(0xFF5B8FD4),
          desc: 'Tập tô nét chữ Khmer chuẩn tiểu học',
          rating: 4.7, views: '640 lượt xem',
          btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
          btnColor: const Color(0xFF5B8FD4),
          image: 'image/Đọc hiểu.png'),
      ];
    } else if (categoryTitle == 'Truyện') {
      return [
        _DocItem(
          title: 'Chú thỏ thông minh', type: 'Sách', typeIcon: Icons.menu_book_rounded,
          typeColor: const Color(0xFF27AE60),
          desc: 'Câu chuyện kể bằng tiếng Khmer',
          rating: 4.9, views: '856 lượt nghe',
          btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
          btnColor: const Color(0xFF27AE60),
          image: 'image/Sách.png'),
        _DocItem(
          title: 'Rùa và Thỏ', type: 'Sách', typeIcon: Icons.menu_book_rounded,
          typeColor: const Color(0xFF27AE60),
          desc: 'Truyện ngụ ngôn ý nghĩa cho bé',
          rating: 4.8, views: '1.1K lượt xem',
          btnLabel: 'Đọc ngay', btnIcon: Icons.menu_book_rounded,
          btnColor: const Color(0xFF27AE60),
          image: 'image/Khám phá văn hóa.png'),
      ];
    } else if (categoryTitle == 'Bài hát') {
      return [
        _DocItem(
          title: 'Bài ca đi học', type: 'Audio', typeIcon: Icons.headphones_rounded,
          typeColor: const Color(0xFF733AEB),
          desc: 'Bài hát tiếng Khmer vui nhộn',
          rating: 4.9, views: '2.4K lượt nghe',
          btnLabel: 'Nghe ngay', btnIcon: Icons.headphones_rounded,
          btnColor: const Color(0xFF733AEB),
          image: 'image/Nghe.png'),
        _DocItem(
          title: 'Mặt trời mọc', type: 'Audio', typeIcon: Icons.headphones_rounded,
          typeColor: const Color(0xFF733AEB),
          desc: 'Bài hát thiếu nhi nhẹ nhàng buổi sáng',
          rating: 4.6, views: '780 lượt nghe',
          btnLabel: 'Nghe ngay', btnIcon: Icons.headphones_rounded,
          btnColor: const Color(0xFF733AEB),
          image: 'image/Sách.png'),
      ];
    } else {
      // Kiến thức / Video
      return [
        _DocItem(
          title: 'Học nguyên âm tiếng Khmer', type: 'Video', typeIcon: Icons.play_circle_rounded,
          typeColor: const Color(0xFFF2994A),
          desc: 'Học nguyên âm qua video hoạt hình',
          rating: 4.7, views: '2.1K lượt xem',
          btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
          btnColor: const Color(0xFFF2994A),
          image: 'image/Nguyên âm.png'),
        _DocItem(
          title: 'Đếm số 1-10', type: 'Video', typeIcon: Icons.play_circle_rounded,
          typeColor: const Color(0xFFF2994A),
          desc: 'Nhận diện chữ số Khmer qua bài hát',
          rating: 4.9, views: '3.2K lượt xem',
          btnLabel: 'Xem ngay', btnIcon: Icons.play_circle_rounded,
          btnColor: const Color(0xFFF2994A),
          image: 'image/Tập đọc.png'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItemsForCategory();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppHeader(
            title: categoryTitle,
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

  Widget _buildDocCard(BuildContext context, _DocItem doc) {
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
