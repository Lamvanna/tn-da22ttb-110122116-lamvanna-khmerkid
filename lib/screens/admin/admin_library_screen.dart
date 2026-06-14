import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Thư viện — Admin
class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});

  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _filterType;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _typeLabels = {
    'Sách': 'Sách 📚',
    'Audio': 'Audio 🎧',
    'Video': 'Video 🎥',
  };

  static const _typeColors = {
    'Sách': Color(0xFF27AE60),
    'Audio': Color(0xFF733AEB),
    'Video': Color(0xFFF2994A),
  };

  static const _typeIcons = {
    'Sách': Icons.menu_book_rounded,
    'Audio': Icons.headphones_rounded,
    'Video': Icons.play_circle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchLibraryItems(
      page: 1,
      limit: 100,
      type: _filterType,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (!mounted) return;
    setState(() {
      _items = result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search & Filter Row ──
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textHint, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm tài liệu...',
                            hintStyle: TextStyle(color: AppColors.textHint),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            setState(() => _searchQuery = val.trim());
                            _loadItems();
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18.sp),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                            _loadItems();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Filter Chips ──
        SizedBox(
          height: 52.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            children: [
              _chipItem(null, 'Tất cả', Icons.grid_view_rounded),
              ..._typeLabels.entries.map((e) =>
                _chipItem(e.key, e.value, _typeIcons[e.key] ?? Icons.star_rounded)),
            ],
          ),
        ),

        // ── Library Items List ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 64.sp, color: AppColors.textHint),
                      SizedBox(height: 12.h),
                      Text('Không tìm thấy tài liệu nào',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildItemCard(_items[index]),
                  ),
                ),
        ),

        // ── Add Button ──
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showItemForm(null),
                icon: Icon(Icons.add_rounded, size: 22.sp),
                label: Text('Thêm tài liệu mới',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipItem(String? type, String label, IconData icon) {
    final selected = _filterType == type;
    final color = type != null ? (_typeColors[type] ?? AppColors.primary) : AppColors.primary;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () {
          setState(() => _filterType = type);
          _loadItems();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: selected ? color : AppColors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: selected ? Colors.white : AppColors.textSecondary),
              SizedBox(width: 6.w),
              Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final desc = item['description'] ?? '';
    final type = item['type'] ?? 'Sách';
    final views = item['views'] ?? 0;
    final rating = item['rating'] ?? 5.0;
    final isActive = item['isActive'] ?? true;
    final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
    final color = _typeColors[type] ?? AppColors.primary;
    final icon = _typeIcons[type] ?? Icons.book_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppColors.cardShadowList,
        border: !isActive ? Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            width: 48.w, height: 48.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 12.w),

          // Core Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp, fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textHint,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                if (desc.isNotEmpty) ...[
                  Text(desc,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                ],
                Row(
                  children: [
                    _miniTag(type, color),
                    SizedBox(width: 8.w),
                    Icon(Icons.star_rounded, size: 12.sp, color: const Color(0xFFF0A030)),
                    SizedBox(width: 2.w),
                    Text('$rating', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8.w),
                    Icon(Icons.visibility_rounded, size: 12.sp, color: AppColors.textHint),
                    SizedBox(width: 2.w),
                    Text('$views', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(Icons.edit_rounded, size: 18.sp, color: AppColors.primary),
                SizedBox(width: 8.w), const Text('Sửa'),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 18.sp, color: AppColors.errorRed),
                SizedBox(width: 8.w), Text('Xóa', style: TextStyle(color: AppColors.errorRed)),
              ])),
            ],
            onSelected: (v) {
              if (v == 'edit') _showItemForm(item);
              if (v == 'delete') _confirmDelete(id, title);
            },
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(text,
        style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _showItemForm(Map<String, dynamic>? item) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final imgCtrl = TextEditingController(text: item?['image'] ?? '');
    final contentUrlCtrl = TextEditingController(text: item?['contentUrl'] ?? '');
    final ratingCtrl = TextEditingController(text: '${item?['rating'] ?? 5.0}');
    String selectedType = item?['type'] ?? 'Sách';
    bool isActive = item?['isActive'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              children: [
                // Pull Bar
                Container(
                  width: 40.w, height: 4.h,
                  margin: EdgeInsets.only(top: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Text(isEdit ? '✏️ Sửa tài liệu' : '➕ Thêm tài liệu',
                        style: GoogleFonts.plusJakartaSans(fontSize: 20.sp, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, size: 24.sp)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Builder(
                      builder: (context) {
                        final typeColors = {
                          'Sách': const Color(0xFF1E88E5),
                          'Audio': const Color(0xFF43A047),
                          'Video': const Color(0xFFFFB300),
                        };
                        final formColor = typeColors[selectedType] ?? AppColors.primary;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formField(
                              label: 'Tiêu đề tài liệu',
                              ctrl: titleCtrl,
                              hint: 'Nhập tiêu đề sách/bài học',
                              icon: Icons.title_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Mô tả ngắn',
                              ctrl: descCtrl,
                              hint: 'Tóm tắt nội dung tài liệu',
                              icon: Icons.description_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _dropdownField(
                              label: 'Loại tài liệu',
                              value: selectedType,
                              icon: Icons.category_rounded,
                              color: formColor,
                              items: ['Sách', 'Audio', 'Video']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                              onChanged: (v) => setSheetState(() => selectedType = v!),
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Đường dẫn ảnh bìa (image)',
                              ctrl: imgCtrl,
                              hint: 'Có thể dùng image/Tập đọc.png hoặc link URL',
                              icon: Icons.image_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Đường dẫn tệp/nội dung (contentUrl)',
                              ctrl: contentUrlCtrl,
                              hint: 'Nhập link tệp PDF hoặc link video/audio (tùy chọn)',
                              icon: Icons.link_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _formField(
                                    label: 'Đánh giá (0 - 5.0)',
                                    ctrl: ratingCtrl,
                                    hint: '5.0',
                                    icon: Icons.star_rounded,
                                    color: formColor,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.visibility_rounded, size: 16.sp, color: formColor.withValues(alpha: 0.8)),
                                        SizedBox(width: 6.w),
                                        Text('Trạng thái hiển thị', style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Switch(
                                      value: isActive,
                                      activeColor: formColor,
                                      onChanged: (val) => setSheetState(() => isActive = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  final data = {
                                    'title': titleCtrl.text.trim(),
                                    'description': descCtrl.text.trim(),
                                    'type': selectedType,
                                    'image': imgCtrl.text.trim(),
                                    'contentUrl': contentUrlCtrl.text.trim(),
                                    'rating': double.tryParse(ratingCtrl.text) ?? 5.0,
                                    'isActive': isActive,
                                  };
                                  if (data['title']!.toString().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Tiêu đề tài liệu là bắt buộc'), backgroundColor: AppColors.errorRed));
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  final result = isEdit
                                    ? await AdminService().updateLibraryItem(item['_id']?.toString() ?? item['id']?.toString() ?? '', data)
                                    : await AdminService().createLibraryItem(data);
                                  if (!mounted) return;
                                  _showSnack(
                                    result['success'] == true ? (isEdit ? 'Đã cập nhật' : 'Đã thêm tài liệu') : (result['message'] ?? 'Lỗi'),
                                    result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
                                  if (result['success'] == true) _loadItems();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                                child: Text(isEdit ? 'Cập nhật' : 'Thêm tài liệu',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 6.w),
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 6.w),
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22.sp),
              style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              borderRadius: BorderRadius.circular(14.r),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Xóa tài liệu?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$title"?\nHành động này không thể hoàn tác.', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Xóa', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await AdminService().deleteLibraryItem(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa tài liệu' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadItems();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}
