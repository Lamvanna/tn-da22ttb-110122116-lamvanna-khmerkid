import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  int _starBalance = 0;
  Set<String> _purchasedItems = {};
  bool _isLoading = true;
  late ScoreService _scoreService;

  final List<_ShopTab> _tabs = [
    _ShopTab(
      label: 'Đồ ăn',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFF06292),
      items: [
        _ShopItem(name: 'Táo', description: 'Táo tươi', price: 15, emoji: '🍎'),
        _ShopItem(name: 'Burger', description: 'Hamburger', price: 45, emoji: '🍔'),
        _ShopItem(name: 'Bánh ngọt', description: 'Bánh kem', price: 50, emoji: '🎂'),
        _ShopItem(name: 'Kẹo', description: 'Kẹo ngọt', price: 10, emoji: '🍬'),
      ],
    ),
    _ShopTab(
      label: 'Vật phẩm',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFF7E57C2),
      items: [
        _ShopItem(name: 'Bóng', description: 'Bóng đá', price: 50, emoji: '⚽'),
        _ShopItem(name: 'Nón', description: 'Nón xinh', price: 80, emoji: '🧢'),
        _ShopItem(name: 'Kính', description: 'Kính mát', price: 60, emoji: '🕶️'),
        _ShopItem(name: 'Giày', description: 'Giày thể thao', price: 100, emoji: '👟'),
      ],
    ),
    _ShopTab(
      label: 'Trang trí',
      icon: Icons.home_rounded,
      color: const Color(0xFFFF9800),
      items: [
        _ShopItem(name: 'Nhà cấp 2', description: 'Nhà ngói', price: 200, emoji: '🏠'),
        _ShopItem(name: 'Cây cảnh', description: 'Trang trí', price: 40, emoji: '🌳'),
        _ShopItem(name: 'Lều', description: 'Cắm trại', price: 80, emoji: '⛺'),
        _ShopItem(name: 'Đài phun nước', description: 'Sang trọng', price: 150, emoji: '⛲'),
      ],
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

  Future<void> _buyItem(_ShopItem item) async {
    final itemKey = '${_selectedTab}_${item.name}';
    if (_purchasedItems.contains(itemKey)) {
      _showSnack('Bạn đã sở hữu ${item.name} rồi! ✅');
      return;
    }
    if (_starBalance < item.price) {
      _showSnack('Chưa đủ sao! Bạn cần thêm ${item.price - _starBalance}⭐');
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
              Text(item.emoji, style: TextStyle(fontSize: 64.sp)),
              SizedBox(height: 16.h),
              Text('Mua ${item.name}?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF2D3142))),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Giá: ', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, color: const Color(0xFF9098A9))),
                  Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 20.sp),
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
                      child: Text('Hủy', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF9098A9))),
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
                      child: Text('Mua ngay', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
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
        await _scoreService.addPurchasedItem(itemKey);
        setState(() {
          _starBalance -= item.price;
          _purchasedItems.add(itemKey);
        });
        if (mounted) _showPurchaseSuccess(item);
      } else {
        _showSnack('Có lỗi xảy ra khi mua hàng!');
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
              Text('Mua thành công!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF43A047))),
              SizedBox(height: 8.h),
              Text('Bạn đã sở hữu ${item.name} ${item.emoji}',
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
                  child: Text('Tuyệt vời!', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white)),
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
        backgroundColor: Color(0xFFF4F7F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          _buildHeader(context),
          SizedBox(height: 16.h),
          _buildTabBar(),
          SizedBox(height: 20.h),
          Expanded(child: _buildItemGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, MediaQuery.of(context).padding.top + 20.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3F51B5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text('Cửa hàng',
                style: GoogleFonts.plusJakartaSans(fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_starBalance', style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(width: 4.w),
                Icon(Icons.star_rounded, color: const Color(0xFFFFD54F), size: 18.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? tab.color : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: isSelected
                    ? [BoxShadow(color: tab.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(tab.icon, size: 20.sp, color: isSelected ? Colors.white : const Color(0xFF9098A9)),
                  SizedBox(width: 8.w),
                  Text(tab.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF9098A9),
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemGrid() {
    final items = _tabs[_selectedTab].items;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildShopItem(items[index]),
    );
  }

  Widget _buildShopItem(_ShopItem item) {
    final itemKey = '${_selectedTab}_${item.name}';
    final purchased = _purchasedItems.contains(itemKey);
    final canAfford = _starBalance >= item.price;

    return GestureDetector(
      onTap: () => _buyItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: purchased ? const Color(0xFF81C784).withValues(alpha: 0.5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Background
                Container(
                  width: 80.w, height: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(item.emoji, style: TextStyle(fontSize: 42.sp))),
                ),
                SizedBox(height: 12.h),
                Text(item.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF2D3142))),
                SizedBox(height: 2.h),
                Text(item.description,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF9098A9))),
                SizedBox(height: 12.h),
                // Price Tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: purchased
                        ? const Color(0xFFE8F5E9)
                        : canAfford
                            ? const Color(0xFFFFF8E1)
                            : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (purchased)
                        Icon(Icons.check_circle_rounded, size: 16.sp, color: const Color(0xFF43A047))
                      else
                        Icon(Icons.star_rounded, size: 16.sp, color: const Color(0xFFFFB300)),
                      SizedBox(width: 4.w),
                      Text(
                        purchased ? 'Đã mua' : '${item.price}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: purchased
                              ? const Color(0xFF43A047)
                              : canAfford
                                  ? const Color(0xFFF57C00)
                                  : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (purchased)
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 14.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopTab {
  final String label;
  final IconData icon;
  final Color color;
  final List<_ShopItem> items;
  const _ShopTab({required this.label, required this.icon, required this.color, required this.items});
}

class _ShopItem {
  final String name;
  final String description;
  final int price;
  final String emoji;
  const _ShopItem({required this.name, required this.description, required this.price, required this.emoji});
}
