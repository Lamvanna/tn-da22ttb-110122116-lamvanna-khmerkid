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
  final _searchCtrl = TextEditingController();


  static const _typeColors = {
    'Sách': Color(0xFF10B981),
    'Audio': Color(0xFF8B5CF6),
    'Video': Color(0xFFF97316),
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchLibraryItems(
      page: 1,
      limit: 100,
      type: _filterType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
        _buildSearchAndFilterRow(),

        // ── Library Items List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 64.sp, color: AppColors.textHint),
                          SizedBox(height: 12.h),
                          Text(
                            'Không tìm thấy tài liệu nào',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      color: const Color(0xFF0084FF),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _buildItemCard(_items[index]),
                      ),
                    ),
        ),

        // ── Add Button ──
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppColors.cardShadowList,
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _loadItems(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm tài liệu...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF0084FF), size: 20.sp),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16.sp, color: AppColors.textHint),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadItems();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.8),
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // Dropdown Combobox Filter
          _buildFilterSelector(),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    final labels = {
      null: 'Tất cả tài liệu',
      'Sách': 'Sách 📚',
      'Audio': 'Audio 🎧',
      'Video': 'Video 🎥',
    };
    final colors = {
      null: const Color(0xFF0084FF),
      'Sách': const Color(0xFF10B981),
      'Audio': const Color(0xFF8B5CF6),
      'Video': const Color(0xFFF97316),
    };
    final icons = {
      null: Icons.grid_view_rounded,
      'Sách': Icons.menu_book_rounded,
      'Audio': Icons.headphones_rounded,
      'Video': Icons.play_circle_rounded,
    };

    return Container(
      width: 155.w,
      height: 46.h,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _filterType,
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ),
          selectedItemBuilder: (context) {
            return labels.entries.map((entry) {
              final type = entry.key;
              final label = entry.value;
              final color = colors[type] ?? const Color(0xFF0084FF);
              final icon = icons[type] ?? Icons.grid_view_rounded;

              return Row(
                children: [
                  SizedBox(width: 10.w),
                  Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: labels.entries.map((entry) {
            final type = entry.key;
            final label = entry.value;
            final color = colors[type] ?? const Color(0xFF0084FF);
            final icon = icons[type] ?? Icons.grid_view_rounded;

            return DropdownMenuItem<String?>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _filterType = v;
            });
            _loadItems();
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
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
    final color = _typeColors[type] ?? const Color(0xFF0084FF);
    final icon = _typeIcons[type] ?? Icons.book_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: isActive
              ? AppColors.outlineVariant.withValues(alpha: 0.4)
              : AppColors.errorRed.withValues(alpha: 0.25),
          width: isActive ? 1.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Side colored accent bar
              Container(
                width: 6.w,
                color: isActive ? color : AppColors.errorRed,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(icon, color: color, size: 24.sp),
                      ),
                      SizedBox(width: 14.w),

                      // Core Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isActive ? AppColors.textPrimary : AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (desc.isNotEmpty) ...[
                              SizedBox(height: 3.h),
                              Text(
                                desc,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                _miniTag(type, color),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E8),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: const Color(0xFFFDEBB8)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 10.sp, color: const Color(0xFFF0A030)),
                                      SizedBox(width: 2.w),
                                      Text(
                                        '$rating',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFB88A20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: AppColors.outlineVariant),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 10.sp, color: AppColors.textHint),
                                      SizedBox(width: 2.w),
                                      Text(
                                        '$views',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isActive)
                                  _miniTag('Ẩn', AppColors.errorRed),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 4,
                        color: AppColors.cardWhite,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18.sp, color: color),
                                SizedBox(width: 10.w),
                                Text(
                                  'Sửa tài liệu',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18.sp, color: AppColors.errorRed),
                                SizedBox(width: 10.w),
                                Text(
                                  'Xóa tài liệu',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showItemForm(item);
                          if (v == 'delete') _confirmDelete(id, title);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0084FF).withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showItemForm(null),
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm tài liệu mới',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showItemForm(Map<String, dynamic>? item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LibraryFormPage(
          item: item,
          onSaved: _loadItems,
        ),
      ),
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

class _LibraryFormPage extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const _LibraryFormPage({
    required this.item,
    required this.onSaved,
  });

  @override
  State<_LibraryFormPage> createState() => _LibraryFormPageState();
}

class _LibraryFormPageState extends State<_LibraryFormPage> {
  late final bool _isEdit;
  bool _saving = false;
  bool _isActive = true;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imgCtrl;
  late final TextEditingController _contentUrlCtrl;
  late final TextEditingController _ratingCtrl;
  late String _selectedType;


  static const _typeColors = {
    'Sách': Color(0xFF10B981),
    'Audio': Color(0xFF8B5CF6),
    'Video': Color(0xFFF97316),
  };

  static const _typeIcons = {
    'Sách': Icons.menu_book_rounded,
    'Audio': Icons.headphones_rounded,
    'Video': Icons.play_circle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.item != null;
    final item = widget.item;

    _titleCtrl = TextEditingController(text: item?['title'] ?? '');
    _descCtrl = TextEditingController(text: item?['description'] ?? '');
    _imgCtrl = TextEditingController(text: item?['image'] ?? '');
    _contentUrlCtrl = TextEditingController(text: item?['contentUrl'] ?? '');
    _ratingCtrl = TextEditingController(text: '${item?['rating'] ?? 5.0}');
    _selectedType = item?['type'] ?? 'Sách';
    _isActive = item?['isActive'] ?? true;

    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
    _imgCtrl.addListener(() => setState(() {}));
    _contentUrlCtrl.addListener(() => setState(() {}));
    _ratingCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _contentUrlCtrl.dispose();
    _ratingCtrl.dispose();
    super.dispose();
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(text,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _prettyField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
    TextStyle? textStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: textStyle ?? GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
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
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22.sp),
              style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              borderRadius: BorderRadius.circular(14.r),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final titleText = _titleCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (titleText.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề tài liệu là bắt buộc'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'title': titleText,
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'image': _imgCtrl.text.trim(),
      'contentUrl': _contentUrlCtrl.text.trim(),
      'rating': double.tryParse(_ratingCtrl.text) ?? 5.0,
      'isActive': _isActive,
    };

    final result = _isEdit
        ? await AdminService().updateLibraryItem(
            widget.item!['_id']?.toString() ?? widget.item!['id']?.toString() ?? '', data)
        : await AdminService().createLibraryItem(data);

    if (!mounted) return;
    setState(() => _saving = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? (_isEdit ? 'Đã cập nhật tài liệu' : 'Đã thêm tài liệu')
            : (result['message'] ?? 'Lỗi')),
        backgroundColor: result['success'] == true ? AppColors.tertiary : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (result['success'] == true) {
      widget.onSaved();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formColor = const Color(0xFF0084FF);
    final previewColor = _typeColors[_selectedType] ?? const Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24.sp),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w, height: 32.w,
              decoration: BoxDecoration(
                color: formColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.auto_stories_rounded, color: formColor, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                _isEdit ? 'Sửa tài liệu' : 'Thêm tài liệu mới',
                style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _saving
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(color: formColor, strokeWidth: 2.w),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Lưu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: formColor,
                      ),
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LIVE PREVIEW CARD ──
                  Container(
                    margin: EdgeInsets.only(bottom: 20.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppColors.cardShadowList,
                      border: Border.all(
                        color: previewColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 14.sp, color: formColor),
                            SizedBox(width: 4.w),
                            Text(
                              'XEM TRƯỚC TRỰC TIẾP TÀI LIỆU',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: formColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _isActive ? AppColors.tertiary.withValues(alpha: 0.1) : AppColors.errorRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                _isActive ? 'Kích hoạt' : 'Ẩn',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _isActive ? AppColors.tertiary : AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        const Divider(height: 1, color: AppColors.outlineVariant),
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48.w, height: 48.w,
                              decoration: BoxDecoration(
                                color: previewColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(_typeIcons[_selectedType] ?? Icons.menu_book_rounded, color: previewColor, size: 24.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Chưa có tiêu đề',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _isActive ? AppColors.textPrimary : AppColors.textHint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_descCtrl.text.isNotEmpty) ...[
                                    SizedBox(height: 3.h),
                                    Text(
                                      _descCtrl.text,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      _tag(_selectedType, previewColor),
                                      SizedBox(width: 8.w),
                                      Icon(Icons.star_rounded, size: 12.sp, color: const Color(0xFFF0A030)),
                                      SizedBox(width: 2.w),
                                      Text(
                                        _ratingCtrl.text.isNotEmpty ? _ratingCtrl.text : '5.0',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── SECTION 1: CONTENT INFO ──
                  _sectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Thông tin tài liệu',
                    color: formColor,
                    children: [
                      _prettyField(
                        label: 'Tiêu đề tài liệu',
                        ctrl: _titleCtrl,
                        hint: 'Nhập tiêu đề sách/bài học',
                        icon: Icons.title_rounded,
                        color: formColor,
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Mô tả ngắn',
                        ctrl: _descCtrl,
                        hint: 'Tóm tắt nội dung tài liệu',
                        icon: Icons.description_rounded,
                        color: formColor,
                      ),
                    ],
                  ),

                  // ── SECTION 2: CONFIGURATION ──
                  _sectionCard(
                    icon: Icons.tune_rounded,
                    title: 'Phân loại & Liên kết',
                    color: formColor,
                    children: [
                      _dropdownField(
                        label: 'Loại tài liệu',
                        value: _selectedType,
                        icon: Icons.category_rounded,
                        color: formColor,
                        items: ['Sách', 'Audio', 'Video']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedType = v!;
                        }),
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Đường dẫn ảnh bìa (image)',
                        ctrl: _imgCtrl,
                        hint: 'Có thể dùng image/Tập đọc.png hoặc link URL',
                        icon: Icons.image_rounded,
                        color: formColor,
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Đường dẫn tệp/nội dung (contentUrl)',
                        ctrl: _contentUrlCtrl,
                        hint: 'Nhập link tệp PDF hoặc link video/audio (tùy chọn)',
                        icon: Icons.link_rounded,
                        color: formColor,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _prettyField(
                              label: 'Đánh giá (0 - 5.0)',
                              ctrl: _ratingCtrl,
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
                                  Text(
                                    'Trạng thái hiển thị',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Switch(
                                value: _isActive,
                                activeThumbColor: formColor,
                                onChanged: (val) => setState(() {
                                  _isActive = val;
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
