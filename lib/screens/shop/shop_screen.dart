import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/app_header.dart';

/// Màn hình Cửa hàng - Shop Screen
/// 3 tab: Đồ ăn, Vật phẩm, Trang trí
/// Mua vật phẩm bằng sao, hiệu ứng mua thành công
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTab = 0;
  int _starBalance = 1000;
  final Set<String> _purchasedItems = {};

  final List<_ShopTab> _tabs = [
    _ShopTab(
      label: AppStrings.shopFood,
      icon: Icons.restaurant_rounded,
      color: AppColors.shopFood,
      items: [
        _ShopItem(name: 'Táo', description: 'Táo tươi', price: 15, emoji: '🍎'),
        _ShopItem(name: 'Cá tươi', description: 'Cá hồi', price: 30, emoji: '🐟'),
        _ShopItem(name: 'Burger', description: 'Hamburger', price: 45, emoji: '🍔'),
        _ShopItem(name: 'Bánh ngọt', description: 'Bánh kem', price: 50, emoji: '🎂'),
        _ShopItem(name: 'Sữa', description: 'Sữa tươi', price: 20, emoji: '🥛'),
        _ShopItem(name: 'Kẹo', description: 'Kẹo ngọt', price: 10, emoji: '🍬'),
      ],
    ),
    _ShopTab(
      label: AppStrings.shopItems,
      icon: Icons.shopping_bag_rounded,
      color: AppColors.primaryPurple,
      items: [
        _ShopItem(name: 'Bóng', description: 'Bóng đá', price: 50, emoji: '⚽'),
        _ShopItem(name: 'Nón', description: 'Nón xinh', price: 80, emoji: '🧢'),
        _ShopItem(name: 'Kính', description: 'Kính mát', price: 60, emoji: '🕶️'),
        _ShopItem(name: 'Giày', description: 'Giày thể thao', price: 100, emoji: '👟'),
      ],
    ),
    _ShopTab(
      label: AppStrings.shopDecor,
      icon: Icons.home_rounded,
      color: AppColors.accentOrange,
      items: [
        _ShopItem(name: 'Nhà cấp 2', description: 'Cao cấp', price: 200, emoji: '🏠'),
        _ShopItem(name: 'Cây cảnh', description: 'Trang trí', price: 40, emoji: '🌳'),
        _ShopItem(name: 'Đèn', description: 'Đèn ngủ', price: 35, emoji: '💡'),
        _ShopItem(name: 'Thảm', description: 'Thảm mềm', price: 55, emoji: '🧶'),
      ],
    ),
  ];

  void _buyItem(_ShopItem item) {
    final itemKey = '${_selectedTab}_${item.name}';
    if (_purchasedItems.contains(itemKey)) {
      _showSnack('Bạn đã mua ${item.name} rồi! ✅');
      return;
    }
    if (_starBalance < item.price) {
      _showSnack('Không đủ sao! Cần ${item.price}⭐');
      return;
    }

    // Hiện dialog xác nhận
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mua ${item.name}?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Giá: ${item.price} ⭐',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentOrange)),
            const SizedBox(height: 4),
            Text('Còn lại: ${_starBalance - item.price} ⭐',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF757575))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF757575))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _starBalance -= item.price;
                _purchasedItems.add(itemKey);
              });
              _showPurchaseSuccess(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Mua',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccess(_ShopItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Mua thành công!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32))),
              const SizedBox(height: 8),
              Text('${item.emoji} ${item.name}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF616161))),
              const SizedBox(height: 4),
              Text('Đã thêm vào kho đồ!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF9E9E9E))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Tuyệt vời!',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, color: Colors.white)),
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
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF7E57C2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildItemGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: '🛒 Cửa hàng',
      onBack: () => Navigator.pop(context),
      gradientColors: const [Color(0xFFD4A430), Color(0xFFE8BE55)],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text('$_starBalance', style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == _tabs.length - 1 ? 0 : 4,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? tab.color : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? tab.color
                        : AppColors.textHint.withValues(alpha: 0.2),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: tab.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon,
                        size: 18,
                        color: isSelected
                            ? AppColors.textWhite
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(tab.label,
                        style: AppTextStyles.buttonTextSmall.copyWith(
                          color: isSelected
                              ? AppColors.textWhite
                              : AppColors.textSecondary,
                        )),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
          color: purchased
              ? const Color(0xFFE8F5E9)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: purchased
              ? Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(item.name,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(item.description, style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: purchased
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : canAfford
                            ? AppColors.accentYellow.withValues(alpha: 0.12)
                            : const Color(0xFFEF5350).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (purchased)
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: Color(0xFF4CAF50))
                      else
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.accentYellow),
                      const SizedBox(width: 4),
                      Text(
                        purchased ? 'Đã mua' : '${item.price}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: purchased
                              ? const Color(0xFF4CAF50)
                              : canAfford
                                  ? AppColors.accentOrange
                                  : const Color(0xFFEF5350),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (purchased)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 22),
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
  const _ShopTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _ShopItem {
  final String name;
  final String description;
  final int price;
  final String emoji;
  const _ShopItem({
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
  });
}
