import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/tts_service.dart';

/// Greeting card — mascot + speech bubble Khmer (tươi sáng, gọn gàng, tương tác sinh động)
class GreetingCard extends StatefulWidget {
  const GreetingCard({super.key});

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> with TickerProviderStateMixin {
  late AnimationController _mascotController;
  late Animation<double> _mascotScaleAnimation;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleScaleAnimation;

  static const Map<String, String> _cloudinaryMascotMap = {
    'voi_hieu_hoc': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/h%C3%BA%20voi%20con%20hi%E1%BA%BFu%20h%E1%BB%8Dc.png',
    'khi_tinh_nghich': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/C%C3%B4%20kh%E1%BB%89%20con%20tinh%20ngh%E1%BB%8Bch.png',
    'ho_dung_cam': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/Ch%C3%BA%20h%E1%BB%95%20con%20d%C5%A9ng%20c%E1%BA%A3m.png',
    'rua_kien_tri': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/Ch%C3%BA%20r%C3%B9a%20con%20ki%C3%AAn%20tr%C3%AC.png',
    'cu_thong_thai': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/Th%E1%BA%A7y%20gi%C3%A1o%20c%C3%BA%20m%C3%A8o%20th%C3%B4ng%20th%C3%A1i.png',
  };

  @override
  void initState() {
    super.initState();
    // Controller cho Mascot
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _mascotScaleAnimation = Tween<double>(begin: 1.0, end: 1.20).animate(
      CurvedAnimation(
        parent: _mascotController,
        curve: Curves.easeOutBack,
      ),
    );

    // Controller cho Bong bóng thoại
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _bubbleScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _triggerMascotBounce() {
    if (_mascotController.isAnimating) return;
    _mascotController.forward().then((_) {
      _mascotController.reverse();
    });
  }

  void _triggerBubbleBounce() {
    if (_bubbleController.isAnimating) return;
    _bubbleController.forward().then((_) {
      _bubbleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? userAvatar = AuthService().userProfile?['avatar'];
    final bool isDefault = userAvatar == null || userAvatar == '' || userAvatar == 'default_mascot' || userAvatar == 'voi_hieu_hoc';
    final String? mascotUrl = isDefault ? null : _cloudinaryMascotMap[userAvatar];

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
              // Mascot (Click tương tác nảy phồng vui nhộn)
              GestureDetector(
                onTap: _triggerMascotBounce,
                child: ScaleTransition(
                  scale: _mascotScaleAnimation,
                  child: SizedBox(
                    width: 95.w,
                    height: 95.h,
                    child: mascotUrl != null
                        ? Image.network(
                            mascotUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset('image/Vật chào.png', fit: BoxFit.contain),
                          )
                        : Image.asset('image/Vật chào.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Speech bubble (Nhấp tương tác nảy phồng + Phát âm thanh tiếng Khmer)
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    _triggerBubbleBounce();
                    TtsService.instance.speak('សួស្តី', fallbackText: 'soustey');
                  },
                  child: ScaleTransition(
                    scale: _bubbleScaleAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.headerMid, Color(0xFF7EB5EA)]),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [BoxShadow(
                          color: AppColors.headerMid.withValues(alpha: 0.20),
                          blurRadius: 12.r, offset: Offset(0, 4.h))]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('សួស្តី!',
                            style: GoogleFonts.battambang(
                              fontSize: 22.sp, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                          Text('(${context.translate('home.welcome_mascot')})',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp, fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(context.translate('home.mascot_ask'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp, fontWeight: FontWeight.w700,
              color: AppColors.onBackground)),
        ],
      ),
    );
  }
}
