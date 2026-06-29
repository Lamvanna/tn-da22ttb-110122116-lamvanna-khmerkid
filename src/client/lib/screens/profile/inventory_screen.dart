import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../widgets/app_page_route.dart';
import '../shop/shop_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  ScoreService? _score;
  late TabController _tabController;

  // Cloudinary map cho ảnh nhân vật & phần thưởng
  static const Map<String, String> _cloudinaryImageMap = {
    'voi_hieu_hoc': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895790/khmerkid/badges/h%C3%BA%20voi%20con%20hi%E1%BA%BFu%20h%E1%BB%8Dc.png',
    'khi_tinh_nghich': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895783/khmerkid/badges/C%C3%B4%20kh%E1%BB%89%20con%20tinh%20ngh%E1%BB%8Bch.png',
    'ho_dung_cam': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895779/khmerkid/badges/Ch%C3%BA%20h%E1%BB%95%20con%20d%C5%A9ng%20c%E1%BA%A3m.png',
    'rua_kien_tri': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895780/khmerkid/badges/Ch%C3%BA%20r%C3%B9a%20con%20ki%C3%AAn%20tr%C3%AC.png',
    'cu_thong_thai': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895810/khmerkid/badges/Th%E1%BA%A7y%20gi%C3%A1o%20c%C3%BA%20m%C3%A8o%20th%C3%B4ng%20th%C3%A1i.png',
    'ruong_kim_cuong': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895791/khmerkid/badges/H%E1%BB%99p%20qu%C3%A0%20kim%20c%C6%B0%C6%A1ng%20th%E1%BA%A7n%20k%E1%BB%B3.png',
    'huy_hieu_sieu_sao': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895789/khmerkid/badges/Huy%20hi%E1%BB%87u%20si%C3%AAu%20sao%20h%E1%BB%8Dc%20t%E1%BA%ADp.png',
    'qua_cau_tuyet': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895804/khmerkid/badges/Qu%E1%BA%A3%20c%E1%BA%A7u%20tuy%E1%BA%BFt%20ph%C3%A9p%20thu%E1%BA%ADt.png',
    'sach_tri_thuc': 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781895804/khmerkid/badges/Quy%E1%BB%83n%20s%C3%A1ch%20tri%20th%E1%BB%A9c%20ho%C3%A0ng%20gia.png',
  };

  // Tất cả nhân vật & phần thưởng (permanent items) từ shop
  static const List<_PermanentItem> _allPermanentItems = [
    // ── Nhân vật ──
    _PermanentItem(id: 'voi_hieu_hoc',  name: 'Voi hiếu học',     emoji: '🐘', category: 'nhan_vat',  color: Color(0xFF8E24AA)),
    _PermanentItem(id: 'khi_tinh_nghich', name: 'Khỉ tinh nghịch', emoji: '🐒', category: 'nhan_vat',  color: Color(0xFFFF7043)),
    _PermanentItem(id: 'ho_dung_cam',    name: 'Hổ dũng cảm',     emoji: '🐯', category: 'nhan_vat',  color: Color(0xFFFFA000)),
    _PermanentItem(id: 'rua_kien_tri',   name: 'Rùa kiên trì',    emoji: '🐢', category: 'nhan_vat',  color: Color(0xFF43A047)),
    _PermanentItem(id: 'cu_thong_thai',  name: 'Cú thông thái',   emoji: '🦉', category: 'nhan_vat',  color: Color(0xFF5C6BC0)),
    // ── Phần thưởng ──
    _PermanentItem(id: 'ruong_kim_cuong',   name: 'Rương kim cương',   emoji: '💎', category: 'phan_thuong', color: Color(0xFF1E88E5)),
    _PermanentItem(id: 'huy_hieu_sieu_sao', name: 'Huy hiệu siêu sao', emoji: '🏅', category: 'phan_thuong', color: Color(0xFFEF6C00)),
    _PermanentItem(id: 'qua_cau_tuyet',     name: 'Quả cầu tuyết',    emoji: '🔮', category: 'phan_thuong', color: Color(0xFF7E57C2)),
    _PermanentItem(id: 'sach_tri_thuc',     name: 'Sách tri thức',     emoji: '👑', category: 'phan_thuong', color: Color(0xFFD4AF37)),
    _PermanentItem(id: 'khinh_khi_cau',     name: 'Khinh khí cầu',    emoji: '🎈', category: 'phan_thuong', color: Color(0xFFE53935)),
    // ── Vật phẩm vĩnh viễn ──
    _PermanentItem(id: 'but_than_ky',    name: 'Bút thần kỳ',      emoji: '✒️', category: 'vat_pham',  color: Color(0xFF9C27B0)),
    _PermanentItem(id: 'streak_freeze',  name: 'Chuỗi dự phòng',   emoji: '🧊', category: 'vat_pham',  color: Color(0xFF00BCD4)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await ScoreService.getInstance();
    if (mounted) setState(() => _score = s);
  }

  @override
  Widget build(BuildContext context) {
    // ─── Consumable items (power-ups) ───
    final consumables = [
      _InvItem(emoji: '🔍', color: const Color(0xFFF59E0B), name: 'Gợi ý',    count: _score?.hintsLeft ?? 0),
      _InvItem(emoji: '⏳', color: const Color(0xFF3B82F6), name: 'Đóng băng', count: _score?.timePowerupsLeft ?? 0),
      _InvItem(emoji: '💖', color: const Color(0xFFEF4444), name: 'Thêm lượt', count: _score?.livesPowerupsLeft ?? 0),
      _InvItem(emoji: '🌟', color: const Color(0xFF8B5CF6), name: 'Nhân đôi',  count: _score?.doubleScorePowerupsLeft ?? 0),
    ].where((i) => i.count > 0).toList();

    // ─── Purchased permanent items ───
    final purchased = _score?.purchasedItems ?? {};
    final ownedCharacters = _allPermanentItems
        .where((p) => p.category == 'nhan_vat' && purchased.contains(p.id))
        .toList();
    final ownedRewards = _allPermanentItems
        .where((p) => p.category != 'nhan_vat' && purchased.contains(p.id))
        .toList();

    final totalItems = consumables.length + ownedCharacters.length + ownedRewards.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: _score == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(totalItems),
                // Tab bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F8),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    labelColor: const Color(0xFF1565C0),
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    tabs: [
                      Tab(text: 'Nhân vật (${ownedCharacters.length})'),
                      Tab(text: 'Phần thưởng (${ownedRewards.length})'),
                      Tab(text: 'Vật phẩm (${consumables.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Nhân vật
                      _buildPermanentGrid(ownedCharacters, 'nhan_vat'),
                      // Tab 2: Phần thưởng
                      _buildPermanentGrid(ownedRewards, 'phan_thuong'),
                      // Tab 3: Vật phẩm tiêu hao
                      _buildConsumableGrid(consumables),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  child: _buildShopButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(int itemCount) {
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vật phẩm của tôi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 21.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Bạn có $itemCount vật phẩm',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
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

  // ─── Grid cho Nhân vật & Phần thưởng (permanent items with images) ───
  Widget _buildPermanentGrid(List<_PermanentItem> items, String emptyCategory) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emptyCategory == 'nhan_vat' ? '🐘' : '🎁',
              style: TextStyle(fontSize: 48.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              emptyCategory == 'nhan_vat'
                  ? 'Chưa có nhân vật nào'
                  : 'Chưa có phần thưởng nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Ghé cửa hàng để sưu tầm nhé!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildPermanentCard(items[index]),
    );
  }

  Widget _buildPermanentCard(_PermanentItem item) {
    final imageUrl = _cloudinaryImageMap[item.id];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: item.color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.10),
            blurRadius: 16.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Image container ──
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.06),
                    item.color.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(item.emoji, style: TextStyle(fontSize: 40.sp)),
                        ),
                      )
                    : Center(
                        child: Text(item.emoji, style: TextStyle(fontSize: 40.sp)),
                      ),
              ),
            ),
          ),
          // ── Name + badge ──
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
            child: Column(
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    item.category == 'nhan_vat' ? '🎭 Nhân vật' : '🎁 Sở hữu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid cho vật phẩm tiêu hao ───
  Widget _buildConsumableGrid(List<_InvItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎒', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 12.h),
            Text(
              'Chưa có vật phẩm nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Ghé cửa hàng để mua vật phẩm nhé!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildConsumableCard(items[index]),
    );
  }

  Widget _buildConsumableCard(_InvItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.10),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Name
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            // Quantity badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '×${item.count}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(context, AppPageRoute(page: const ShopScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF1E88E5).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        icon: const Icon(Icons.storefront_rounded, size: 20),
        label: Text(
          'Đổi thưởng',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InvItem {
  final String emoji;
  final Color color;
  final String name;
  final int count;

  _InvItem({
    required this.emoji,
    required this.color,
    required this.name,
    required this.count,
  });
}

class _PermanentItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final Color color;

  const _PermanentItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.color,
  });
}
