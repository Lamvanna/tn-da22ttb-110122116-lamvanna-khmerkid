import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';

/// Màn hình Thư viện - Library Screen
/// Hiển thị bộ sưu tập bài học/truyện theo danh mục
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = AppStrings.allCategory;

  final List<String> _categories = [
    AppStrings.allCategory,
    AppStrings.alphabetCategory,
    AppStrings.storyCategory,
    AppStrings.musicCategory,
  ];

  final List<_LibraryItem> _items = [
    _LibraryItem(
      title: 'Nhà cấp 2',
      description: 'Cao cấp',
      bonus: '+10% vui vẻ',
      price: 200,
      icon: Icons.house_rounded,
      color: const Color(0xFF42A5F5),
      category: 'Truyện',
    ),
    _LibraryItem(
      title: 'Động vật',
      description: 'Con Chuột Nhỏ',
      bonus: 'Bảng chữ',
      price: 0,
      icon: Icons.pets_rounded,
      color: const Color(0xFFFF7043),
      category: 'Bảng chữ',
    ),
    _LibraryItem(
      title: 'Bóng đá',
      description: 'Quả bóng',
      bonus: 'Vật phẩm',
      price: 50,
      icon: Icons.sports_soccer_rounded,
      color: const Color(0xFF66BB6A),
      category: 'Truyện',
    ),
    _LibraryItem(
      title: 'Bài hát Khmer',
      description: 'Nhạc thiếu nhi',
      bonus: 'Nhạc',
      price: 0,
      icon: Icons.music_note_rounded,
      color: const Color(0xFFFFD700),
      category: 'Nhạc',
    ),
    _LibraryItem(
      title: 'Phụ âm cơ bản',
      description: '33 phụ âm',
      bonus: 'Bảng chữ',
      price: 0,
      icon: Icons.abc_rounded,
      color: const Color(0xFF5C6BC0),
      category: 'Bảng chữ',
    ),
    _LibraryItem(
      title: 'Truyện cổ tích',
      description: 'Truyện thỏ và rùa',
      bonus: 'Truyện',
      price: 0,
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFFEF5350),
      category: 'Truyện',
    ),
  ];

  List<_LibraryItem> get _filteredItems {
    if (_selectedCategory == AppStrings.allCategory) return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context),

          // ── Search ──
          _buildSearchBar(),

          // ── Category filters ──
          _buildCategoryChips(),

          const SizedBox(height: 12),

          // ── Item grid ──
          Expanded(
            child: _buildItemGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFFD700)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textWhite,
                iconSize: 28,
              ),
              Expanded(
                child: Text(
                  AppStrings.libraryTitle,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.textHint.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid() {
    final items = _filteredItems;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildLibraryCard(items[index]);
      },
    );
  }

  Widget _buildLibraryCard(_LibraryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(item.icon, size: 48, color: item.color),
                  ),
                  // Category badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: AppTextStyles.badge.copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (item.price > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accentYellow),
                        const SizedBox(width: 2),
                        Text(
                          '${item.price}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Miễn phí',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
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
}

class _LibraryItem {
  final String title;
  final String description;
  final String bonus;
  final int price;
  final IconData icon;
  final Color color;
  final String category;

  const _LibraryItem({
    required this.title,
    required this.description,
    required this.bonus,
    required this.price,
    required this.icon,
    required this.color,
    required this.category,
  });
}
