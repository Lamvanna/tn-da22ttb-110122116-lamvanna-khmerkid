import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';

/// Greeting card — mascot + speech bubble Khmer (tươi sáng, gọn gàng)
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: AppColors.ambientShadow,
        border: Border.all(color: const Color(0xFFEEF1F8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mascot
              SizedBox(
                width: 95.w, height: 95.h,
                child: Image.asset('image/Vật chào.png', fit: BoxFit.contain)),
              SizedBox(width: 14.w),
              // Speech bubble
              Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.headerMid, Color(0xFF7EB5EA)]),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [BoxShadow(
                    color: AppColors.headerMid.withValues(alpha: 0.20),
                    blurRadius: 12.r, offset: Offset(0, 4.h))]),
                child: Column(children: [
                  Text('សួស្តី!',
                    style: GoogleFonts.battambang(
                      fontSize: 22.sp, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                  Text('(Xin chào!)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9))),
                ]),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text('Hôm nay bé muốn học gì nhỉ? 🌟',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp, fontWeight: FontWeight.w700,
              color: AppColors.onBackground)),
        ],
      ),
    );
  }
}
