import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/score_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_page_route.dart';
import '../home/daily_quest_screen.dart';
import '../../l10n/app_localizations.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTab = 0; // 0: Tất cả, 1: Nhân vật, 2: Vật phẩm, 3: Khác
  int _starBalance = 0;
  Set<String> _purchasedItems = {};
  bool _isLoading = true;
  late ScoreService _scoreService;

  static const Map<String, String> _cloudinaryImageMap = {
    'Hộp quà kim cương thần kỳ.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895791/khmerkid/badges/H%E1%BB%99p%20qu%C3%A0%20kim%20c%C6%B0%C6%A1ng%20th%E1%BA%A7n%20k%E1%BB%B3.png',
    'Huy hiệu siêu sao học tập.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895789/khmerkid/badges/Huy%20hi%E1%BB%87u%20si%C3%AAu%20sao%20h%E1%BB%8Dc%20t%E1%BA%ADp.png',
    'Quả cầu tuyết phép thuật.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895804/khmerkid/badges/Qu%E1%BA%A3%20c%E1%BA%A7u%20tuy%E1%BA%BFt%20ph%C3%A9p%20thu%E1%BA%ADt.png',
    'Quyển sách tri thức hoàng gia.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895804/khmerkid/badges/Quy%E1%BB%83n%20s%C3%A1ch%20tri%20th%E1%BB%A9c%20ho%C3%A0ng%20gia.png',
    'hú voi con hiếu học.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/h%C3%BA%20voi%20con%20hi%E1%BA%BFu%20h%E1%BB%8Dc.png',
    'Cô khỉ con tinh nghịch.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895783/khmerkid/badges/C%C3%B4%20kh%E1%BB%89%20con%20tinh%20ngh%E1%BB%8Bch.png',
    'Chú hổ con dũng cảm.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895779/khmerkid/badges/Ch%C3%BA%20h%E1%BB%95%20con%20d%C5%A9ng%20c%E1%BA%A3m.png',
    'Chú rùa con kiên trì.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895780/khmerkid/badges/Ch%C3%BA%20r%C3%B9a%20con%20ki%C3%AAn%20tr%C3%AC.png',
    'Thầy giáo cú mèo thông thái.png': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895810/khmerkid/badges/Th%E1%BA%A7y%20gi%C3%A1o%20c%C3%BA%20m%C3%A8o%20th%C3%B4ng%20th%C3%A1i.png',
  };

  String? _getCloudinaryUrl(String? path) {
    if (path == null) return null;
    final filename = path.split('/').last;
    return _cloudinaryImageMap[filename];
  }

  final List<_ShopItem> _allItems = [
    // Featured Rewards
    const _ShopItem(
      id: 'ruong_kim_cuong',
      name: 'Rương kim cương 💎',
      description: 'Hộp quà kim cương thần kỳ',
      price: 300,
      imagePath: 'image/Ảnh nhiệm vụ/Hộp quà kim cương thần kỳ.png',
      badge: 'Nổi bật',
      category: 'vat_pham',
      isFeatured: true,
    ),
    const _ShopItem(
      id: 'huy_hieu_sieu_sao',
      name: 'Huy hiệu siêu sao 🏅',
      description: 'Huy hiệu siêu sao học tập',
      price: 200,
      imagePath: 'image/Ảnh nhiệm vụ/Huy hiệu siêu sao học tập.png',
      badge: 'Mới',
      category: 'vat_pham',
      isFeatured: true,
    ),
    const _ShopItem(
      id: 'qua_cau_tuyet',
      name: 'Quả cầu tuyết 🔮',
      description: 'Quả cầu tuyết phép thuật',
      price: 250,
      imagePath: 'image/Ảnh nhiệm vụ/Quả cầu tuyết phép thuật.png',
      category: 'vat_pham',
      isFeatured: true,
    ),
    const _ShopItem(
      id: 'sach_tri_thuc',
      name: 'Sách tri thức 👑',
      description: 'Quyển sách tri thức hoàng gia',
      price: 400,
      imagePath: 'image/Ảnh nhiệm vụ/Quyển sách tri thức hoàng gia.png',
      category: 'vat_pham',
      isFeatured: true,
    ),
    const _ShopItem(
      id: 'khinh_khi_cau',
      name: 'Khinh khí cầu 🎈',
      description: 'Khinh khí cầu vinh quang',
      price: 500,
      emoji: '🎈',
      category: 'vat_pham',
      isFeatured: true,
    ),

    // Characters
    const _ShopItem(
      id: 'voi_hieu_hoc',
      name: 'Voi hiếu học 🐘',
      description: 'Chú voi con hiếu học',
      price: 500,
      imagePath: 'image/Ảnh nhiệm vụ/hú voi con hiếu học.png',
      category: 'nhan_vat',
    ),
    const _ShopItem(
      id: 'khi_tinh_nghich',
      name: 'Khỉ tinh nghịch 🐒',
      description: 'Cô khỉ con tinh nghịch',
      price: 450,
      imagePath: 'image/Ảnh nhiệm vụ/Cô khỉ con tinh nghịch.png',
      category: 'nhan_vat',
    ),
    const _ShopItem(
      id: 'ho_dung_cam',
      name: 'Hổ dũng cảm 🐯',
      description: 'Chú hổ con dũng cảm',
      price: 600,
      imagePath: 'image/Ảnh nhiệm vụ/Chú hổ con dũng cảm.png',
      category: 'nhan_vat',
    ),
    const _ShopItem(
      id: 'rua_kien_tri',
      name: 'Rùa kiên trì 🐢',
      description: 'Chú rùa con kiên trì',
      price: 400,
      imagePath: 'image/Ảnh nhiệm vụ/Chú rùa con kiên trì.png',
      category: 'nhan_vat',
    ),
    const _ShopItem(
      id: 'cu_thong_thai',
      name: 'Cú thông thái 🦉',
      description: 'Thầy giáo cú mèo thông thái',
      price: 550,
      imagePath: 'image/Ảnh nhiệm vụ/Thầy giáo cú mèo thông thái.png',
      category: 'nhan_vat',
    ),

    // Items
    const _ShopItem(
      id: 'pu_hint',
      name: 'Kính lúp gợi ý 🔍',
      description: 'Gợi ý đáp án',
      price: 80,
      emoji: '🔍',
      category: 'vat_pham',
      isConsumable: true,
    ),
    const _ShopItem(
      id: 'pu_time',
      name: 'Đồng hồ thời gian ⏳',
      description: 'Đóng băng thời gian',
      price: 100,
      emoji: '⏳',
      category: 'vat_pham',
      isConsumable: true,
    ),
    const _ShopItem(
      id: 'pu_live',
      name: 'Bình sữa trái tim 💖',
      description: 'Thêm lượt chơi',
      price: 120,
      emoji: '💖',
      category: 'vat_pham',
      isConsumable: true,
    ),
    const _ShopItem(
      id: 'pu_double',
      name: 'Ngôi sao nhân đôi 🌟',
      description: 'Nhân đôi điểm số',
      price: 150,
      emoji: '🌟',
      category: 'vat_pham',
      isConsumable: true,
    ),
    const _ShopItem(
      id: 'but_than_ky',
      name: 'Bút thần kỳ ✒️',
      description: 'Tự viết nét',
      price: 200,
      emoji: '✒️',
      category: 'vat_pham',
      isConsumable: false,
    ),
    const _ShopItem(
      id: 'streak_freeze',
      name: 'Chuỗi dự phòng 🧊',
      description: 'Bảo vệ chuỗi ngày',
      price: 150,
      emoji: '🧊',
      category: 'vat_pham',
      isConsumable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _scoreService = await ScoreService.getInstance();
    setState(() {
      _starBalance = _scoreService.totalStars;
      _purchasedItems = _scoreService.purchasedItems;
      _isLoading = false;
    });
  }

  int _getOwnedCount(String id) {
    if (id == 'pu_hint') return _scoreService.hintsLeft;
    if (id == 'pu_time') return _scoreService.timePowerupsLeft;
    if (id == 'pu_live') return _scoreService.livesPowerupsLeft;
    if (id == 'pu_double') return _scoreService.doubleScorePowerupsLeft;
    return 0;
  }

  Future<void> _buyItem(_ShopItem item) async {
    if (!item.isConsumable && _purchasedItems.contains(item.id)) {
      _showSnack(context.translate('shop.already_owned', args: {'name': context.translateShopItemName(item.id, item.name)}));
      return;
    }
    if (_starBalance < item.price) {
      _showSnack(context.translate('shop.not_enough_stars', args: {'count': item.price - _starBalance}));
      return;
    }

    // Xác nhận mua
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: () {
                  final cloudinaryUrl = _getCloudinaryUrl(item.imagePath);
                  if (cloudinaryUrl != null) {
                    return Image.network(
                      AuthService.getOptimizedImageUrl(cloudinaryUrl, width: 150),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return item.imagePath != null
                            ? Image.asset(item.imagePath!, fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(child: Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 52.sp))))
                            : Center(child: Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 52.sp)));
                      },
                    );
                  }
                  return item.imagePath != null
                      ? Image.asset(item.imagePath!, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 52.sp))))
                      : Center(child: Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 52.sp)));
                }(),
              ),
              SizedBox(height: 16.h),
              Text(context.translate('shop.buy_confirm_title', args: {'name': context.translateShopItemName(item.id, item.name)}),
                  style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF2D3142))),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.translate('shop.buy_confirm_price'), style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, color: const Color(0xFF9098A9))),
                  Image.asset('image/sao.png', width: 20.w, height: 20.w),
                  SizedBox(width: 4.w),
                  Text('${item.price}', style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFFFFB300))),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: Text(context.translate('common.cancel'), style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF9098A9))),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Text(context.translate('shop.buy_now'), style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final success = await _scoreService.spendStars(item.price);
      if (success) {
        // Tăng chỉ số tương ứng nếu là consumable
        if (item.isConsumable) {
          if (item.id == 'pu_hint') {
            await _scoreService.addHints(1);
          } else if (item.id == 'pu_time') {
            await _scoreService.addTimePowerups(1);
          } else if (item.id == 'pu_live') {
            await _scoreService.addLivesPowerups(5);
          } else if (item.id == 'pu_double') {
            await _scoreService.addDoubleScorePowerups(1);
          }
        } else {
          await _scoreService.addPurchasedItem(item.id);
          _purchasedItems.add(item.id);
        }

        setState(() {
          _starBalance -= item.price;
        });
        if (mounted) _showPurchaseSuccess(item);
      } else {
        _showSnack(context.translate('shop.error_buy'));
      }
    }
  }

  void _showPurchaseSuccess(_ShopItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: Text('🎉', style: TextStyle(fontSize: 48.sp)),
              ),
              SizedBox(height: 20.h),
              Text(context.translate('shop.buy_success_title'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF43A047))),
              SizedBox(height: 8.h),
              Text(context.translate('shop.buy_success_desc', args: {'name': context.translateShopItemName(item.id, item.name)}),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF9098A9))),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text(context.translate('shop.great_btn'), style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2D3142),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FD),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: Column(
        children: [
          _buildHeader(context),
          SizedBox(height: 14.h),
          _buildTabBar(),
          SizedBox(height: 8.h),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40.w,
            top: -30.h,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -25.w,
            bottom: -20.h,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content Row
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.translate('shop.title'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 21.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.translate('shop.subtitle'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Star balance pill on the right
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('image/sao.png', width: 14.w, height: 14.w),
                        SizedBox(width: 4.w),
                        Text(
                          '$_starBalance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildTabBar() {
    final List<Map<String, dynamic>> tabs = [
      {'label': context.translate('shop.tab_all'), 'icon': Icons.card_giftcard_rounded},
      {'label': context.translate('shop.tab_characters'), 'icon': Icons.face_rounded},
      {'label': context.translate('shop.tab_items'), 'icon': Icons.science_rounded},
      {'label': context.translate('shop.tab_others'), 'icon': Icons.local_play_rounded},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEBF4FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF9098A9),
                      size: 22.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      tabs[index]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF9098A9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 0) {
      // "Tất cả"
      final featuredItems = _allItems.where((item) => item.isFeatured).toList();
      final characterItems = _allItems.where((item) => item.category == 'nhan_vat' && !item.isFeatured).toList();
      final itemItems = _allItems.where((item) => item.category == 'vat_pham' && !item.isFeatured).toList();

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured rewards
            _buildSectionHeader(context.translate('shop.featured_rewards'), 0),
            SizedBox(
              height: 215.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                physics: const BouncingScrollPhysics(),
                itemCount: featuredItems.length,
                itemBuilder: (context, index) => _buildShopItemCard(featuredItems[index], width: 140.w),
              ),
            ),

            // Characters
            _buildSectionHeader(context.translate('shop.characters'), 1),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                physics: const BouncingScrollPhysics(),
                itemCount: characterItems.length,
                itemBuilder: (context, index) => _buildShopItemCard(characterItems[index], width: 125.w),
              ),
            ),

            // Items
            _buildSectionHeader(context.translate('shop.items'), 2),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                physics: const BouncingScrollPhysics(),
                itemCount: itemItems.length,
                itemBuilder: (context, index) => _buildShopItemCard(itemItems[index], width: 125.w),
              ),
            ),

            SizedBox(height: 12.h),
            // Bottom banner
            _buildBottomBanner(),
          ],
        ),
      );
    } else {
      // Filtered categories
      String category = 'nhan_vat';
      if (_selectedTab == 2) category = 'vat_pham';
      if (_selectedTab == 3) category = 'khac';

      final items = _allItems.where((item) => item.category == category).toList();
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.74,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildShopItemCard(items[index]),
      );
    }
  }

  Widget _buildSectionHeader(String title, int tabIndex) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3142),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = tabIndex),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.translate('shop.view_all'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7E8CA0),
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF7E8CA0),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemCard(_ShopItem item, {double? width}) {
    final purchased = !item.isConsumable && _purchasedItems.contains(item.id);
    final canAfford = _starBalance >= item.price;
    final showCount = item.isConsumable && (item.id.startsWith('pu_'));
    final ownedCount = showCount ? _getOwnedCount(item.id) : 0;

    return GestureDetector(
      onTap: () => _buyItem(item),
      child: Container(
        width: width ?? 140.w,
        margin: EdgeInsets.only(bottom: 8.h, top: 4.h, left: 6.w, right: 6.w),
        decoration: BoxDecoration(
          color: _getItemTheme(item.id).bg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: purchased
                ? const Color(0xFF81C784).withValues(alpha: 0.4)
                : _getItemTheme(item.id).border,
            width: 1.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Image/Emoji Container
                  Expanded(
                    child: Center(
                      child: () {
                        final cloudinaryUrl = _getCloudinaryUrl(item.imagePath);
                        if (cloudinaryUrl != null) {
                          return Image.network(
                            AuthService.getOptimizedImageUrl(cloudinaryUrl, width: 150),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return item.imagePath != null
                                  ? Image.asset(item.imagePath!, fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 40.sp)))
                                  : Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 40.sp));
                            },
                          );
                        }
                        return item.imagePath != null
                            ? Image.asset(item.imagePath!, fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 40.sp)))
                            : Text(item.emoji ?? '🎁', style: TextStyle(fontSize: 40.sp));
                      }(),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Name
                  Text(
                    context.translateShopItemName(item.id, item.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  // Subtitle / Description & Count Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.translateShopItemDesc(item.id, item.description),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9098A9),
                        ),
                      ),
                      if (showCount) ...[
                        SizedBox(height: 2.h),
                        Text(
                          context.translate('shop.owned_count', args: {'count': ownedCount}),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Price Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: purchased
                          ? const Color(0xFFE8F5E9)
                          : canAfford
                              ? const Color(0xFFFFF8E1)
                              : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (purchased) ...[
                          Icon(Icons.check_circle_rounded, size: 14.sp, color: const Color(0xFF43A047)),
                          SizedBox(width: 4.w),
                          Text(
                            context.translate('shop.already_purchased'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF43A047),
                            ),
                          ),
                        ] else ...[
                          if (item.originalPrice != null) ...[
                            Text(
                              '${item.originalPrice}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB5BAC9),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 4.w),
                          ],
                          Image.asset('image/sao.png', width: 14.w, height: 14.w),
                          SizedBox(width: 4.w),
                          Text(
                            '${item.price}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: canAfford
                                  ? const Color(0xFFF57C00)
                                  : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Badge (Hot, -20% etc)
            if (item.badge != null)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: item.badge!.contains('%')
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    item.badge == 'Nổi bật'
                        ? context.translate('shop.badge_featured')
                        : (item.badge == 'Mới'
                            ? context.translate('shop.badge_new')
                            : item.badge!),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFDCE9FF), width: 1.5),
      ),
      child: Row(
        children: [
          // Elephant Icon
          Image.asset(
            'image/Nhiệm vụ.png',
            width: 56.w,
            height: 56.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('shop.bottom_banner_title'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.translate('shop.bottom_banner_desc'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                AppPageRoute(page: const DailyQuestScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.translate('shop.bottom_banner_btn'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right_rounded, size: 14.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final int? originalPrice;
  final String? imagePath;
  final String? emoji;
  final String? badge;
  final String category;
  final bool isFeatured;
  final bool isConsumable;

  const _ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.imagePath,
    this.emoji,
    this.badge,
    required this.category,
    this.isFeatured = false,
    this.isConsumable = false,
  });
}

class _ItemColorTheme {
  final Color bg;
  final Color border;
  const _ItemColorTheme({required this.bg, required this.border});
}

_ItemColorTheme _getItemTheme(String id) {
  switch (id) {
    // Featured Rewards
    case 'ruong_kim_cuong':
      return _ItemColorTheme(
        bg: const Color(0xFF00BCD4).withValues(alpha: 0.05),
        border: const Color(0xFF00BCD4).withValues(alpha: 0.15),
      );
    case 'huy_hieu_sieu_sao':
      return _ItemColorTheme(
        bg: const Color(0xFFFFB300).withValues(alpha: 0.05),
        border: const Color(0xFFFFB300).withValues(alpha: 0.15),
      );
    case 'qua_cau_tuyet':
      return _ItemColorTheme(
        bg: const Color(0xFF3F51B5).withValues(alpha: 0.05),
        border: const Color(0xFF3F51B5).withValues(alpha: 0.15),
      );
    case 'sach_tri_thuc':
      return _ItemColorTheme(
        bg: const Color(0xFF9C27B0).withValues(alpha: 0.05),
        border: const Color(0xFF9C27B0).withValues(alpha: 0.15),
      );
    case 'khinh_khi_cau':
      return _ItemColorTheme(
        bg: const Color(0xFFE53935).withValues(alpha: 0.05),
        border: const Color(0xFFE53935).withValues(alpha: 0.15),
      );
    
    // Characters
    case 'voi_hieu_hoc':
      return _ItemColorTheme(
        bg: const Color(0xFF2196F3).withValues(alpha: 0.05),
        border: const Color(0xFF2196F3).withValues(alpha: 0.15),
      );
    case 'khi_tinh_nghich':
      return _ItemColorTheme(
        bg: const Color(0xFFFF9800).withValues(alpha: 0.05),
        border: const Color(0xFFFF9800).withValues(alpha: 0.15),
      );
    case 'ho_dung_cam':
      return _ItemColorTheme(
        bg: const Color(0xFFFF5722).withValues(alpha: 0.05),
        border: const Color(0xFFFF5722).withValues(alpha: 0.15),
      );
    case 'rua_kien_tri':
      return _ItemColorTheme(
        bg: const Color(0xFF4CAF50).withValues(alpha: 0.05),
        border: const Color(0xFF4CAF50).withValues(alpha: 0.15),
      );
    case 'cu_thong_thai':
      return _ItemColorTheme(
        bg: const Color(0xFF9C27B0).withValues(alpha: 0.05),
        border: const Color(0xFF9C27B0).withValues(alpha: 0.15),
      );
    
    // Items
    case 'pu_hint':
      return _ItemColorTheme(
        bg: const Color(0xFF009688).withValues(alpha: 0.05),
        border: const Color(0xFF009688).withValues(alpha: 0.15),
      );
    case 'pu_time':
      return _ItemColorTheme(
        bg: const Color(0xFFFFD54F).withValues(alpha: 0.07),
        border: const Color(0xFFFFD54F).withValues(alpha: 0.18),
      );
    case 'pu_live':
      return _ItemColorTheme(
        bg: const Color(0xFFE91E63).withValues(alpha: 0.05),
        border: const Color(0xFFE91E63).withValues(alpha: 0.15),
      );
    case 'pu_double':
      return _ItemColorTheme(
        bg: const Color(0xFFFFB300).withValues(alpha: 0.05),
        border: const Color(0xFFFFB300).withValues(alpha: 0.15),
      );
    case 'but_than_ky':
      return _ItemColorTheme(
        bg: const Color(0xFF9C27B0).withValues(alpha: 0.05),
        border: const Color(0xFF9C27B0).withValues(alpha: 0.15),
      );
    case 'streak_freeze':
      return _ItemColorTheme(
        bg: const Color(0xFF00BCD4).withValues(alpha: 0.05),
        border: const Color(0xFF00BCD4).withValues(alpha: 0.15),
      );
    
    default:
      return const _ItemColorTheme(bg: Color(0xFFFFFFFF), border: Color(0xFFF1F5F9));
  }
}


