import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

/// Màn hình Quản lý Huy hiệu — Admin
class AdminBadgesScreen extends StatefulWidget {
  const AdminBadgesScreen({super.key});
  @override
  State<AdminBadgesScreen> createState() => _AdminBadgesScreenState();
}

class _AdminBadgesScreenState extends State<AdminBadgesScreen> {
  List<dynamic> _badges = [];
  bool _loading = true;
  String? _filterType;

  static const _typeLabels = {
    'level': 'Cấp độ',
    'pronunciation': 'Phát âm',
    'streak': 'Chuỗi ngày',
    'learning': 'Học tập',
    'ranking': 'Xếp hạng',
  };

  static const _typeIcons = {
    'level': Icons.military_tech_rounded,
    'pronunciation': Icons.mic_rounded,
    'streak': Icons.local_fire_department_rounded,
    'learning': Icons.school_rounded,
    'ranking': Icons.emoji_events_rounded,
  };

  static const _typeColors = {
    'level': AppColors.secondary,
    'pronunciation': AppColors.coral,
    'streak': AppColors.tertiary,
    'learning': AppColors.primary,
    'ranking': AppColors.violet,
  };

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchBadges(page: 1, limit: 50, type: _filterType);
    if (!mounted) return;
    setState(() {
      _badges = result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

        // ── Badge List ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _badges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64.sp, color: AppColors.textHint),
                      SizedBox(height: 12.h),
                      Text('Chưa có huy hiệu nào',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBadges,
                  color: AppColors.primary,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _badges.length,
                    itemBuilder: (context, index) => _buildBadgeCard(_badges[index]),
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
                onPressed: () => _showBadgeForm(null),
                icon: Icon(Icons.add_rounded, size: 22.sp),
                label: Text('Thêm huy hiệu mới',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
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
          _loadBadges();
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

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final name = badge['name'] ?? '';
    final desc = badge['description'] ?? '';
    final type = badge['type'] ?? '';
    final xpReward = badge['xpReward'] ?? 0;
    final starsReward = badge['starsReward'] ?? 0;
    final isActive = badge['isActive'] ?? true;
    final id = badge['_id']?.toString() ?? badge['id']?.toString() ?? '';
    final iconUrl = badge['iconUrl']?.toString() ?? '';
    final color = _typeColors[type] ?? AppColors.primary;
    final icon = _typeIcons[type] ?? Icons.star_rounded;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppColors.cardShadowList,
        border: !isActive ? Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Column(
        children: [
          // Badge icon
          Container(
            width: 56.w, height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12.r, offset: Offset(0, 4.h)),
              ],
            ),
            child: iconUrl.startsWith('http')
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: Image.network(AuthService.getOptimizedImageUrl(iconUrl, width: 150), fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Icon(icon, color: Colors.white, size: 28.sp)),
                )
              : Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 10.h),

          // Name
          Text(name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.w700,
              color: isActive ? AppColors.textPrimary : AppColors.textHint,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),

          // Description
          Text(desc,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: AppColors.textSecondary),
            maxLines: 2, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const Spacer(),

          // Rewards
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (xpReward > 0)
                Text('🎯$xpReward ', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.violet)),
              if (starsReward > 0)
                Text('⭐$starsReward', style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.secondary)),
            ],
          ),
          SizedBox(height: 6.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn(Icons.edit_rounded, AppColors.primary, () => _showBadgeForm(badge)),
              SizedBox(width: 8.w),
              _actionBtn(Icons.delete_outline_rounded, AppColors.errorRed, () => _confirmDelete(id, name)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w, height: 32.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 16.sp, color: color),
      ),
    );
  }

  void _showBadgeForm(Map<String, dynamic>? badge) {
    final isEdit = badge != null;
    final nameCtrl = TextEditingController(text: badge?['name'] ?? '');
    final descCtrl = TextEditingController(text: badge?['description'] ?? '');
    final xpCtrl = TextEditingController(text: '${badge?['xpReward'] ?? 0}');
    final starsCtrl = TextEditingController(text: '${badge?['starsReward'] ?? 0}');
    final orderCtrl = TextEditingController(text: '${badge?['order'] ?? 0}');
    final iconUrlCtrl = TextEditingController(text: badge?['iconUrl'] ?? '');
    bool uploadingImg = false;
    String selectedType = badge?['type'] ?? 'level';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              children: [
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
                      Text(isEdit ? '✏️ Sửa huy hiệu' : '➕ Thêm huy hiệu',
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
                        final formColor = _typeColors[selectedType] ?? AppColors.primary;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Badge Icon/Image Upload ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 512,
                                      maxHeight: 512,
                                      imageQuality: 85,
                                    );
                                    if (image == null) return;

                                    setSheetState(() => uploadingImg = true);
                                    try {
                                      final url = await AdminService().uploadImage(image.path);
                                      if (url != null) {
                                        iconUrlCtrl.text = url;
                                        _showSnack('Tải ảnh huy hiệu thành công!', AppColors.tertiary);
                                      } else {
                                        _showSnack('Tải ảnh thất bại', AppColors.errorRed);
                                      }
                                    } catch (e) {
                                      _showSnack('Có lỗi khi tải ảnh: $e', AppColors.errorRed);
                                    } finally {
                                      setSheetState(() => uploadingImg = false);
                                    }
                                  },
                                  child: Container(
                                    width: 68.w,
                                    height: 68.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: uploadingImg
                                        ? Center(
                                            child: SizedBox(
                                              width: 20.w,
                                              height: 20.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: formColor,
                                              ),
                                            ),
                                          )
                                        : iconUrlCtrl.text.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(14.r),
                                                child: Image.network(
                                                  AuthService.getOptimizedImageUrl(iconUrlCtrl.text, width: 200),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, stack) => Icon(
                                                    Icons.broken_image_rounded,
                                                    color: AppColors.textHint,
                                                    size: 26.sp,
                                                  ),
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_photo_alternate_rounded, color: formColor, size: 24.sp),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    'Chọn ảnh',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 9.sp,
                                                      fontWeight: FontWeight.w700,
                                                      color: formColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: _formField(
                                    label: 'Đường dẫn ảnh (iconUrl)',
                                    ctrl: iconUrlCtrl,
                                    hint: 'Dán link hoặc chọn ảnh để upload',
                                    icon: Icons.link_rounded,
                                    color: formColor,
                                    onChanged: (val) => setSheetState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Tên huy hiệu',
                              ctrl: nameCtrl,
                              hint: 'Nhập tên huy hiệu',
                              icon: Icons.badge_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Mô tả',
                              ctrl: descCtrl,
                              hint: 'Nhập mô tả huy hiệu',
                              icon: Icons.description_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _formField(
                                    label: 'XP thưởng',
                                    ctrl: xpCtrl,
                                    hint: '0',
                                    icon: Icons.bolt_rounded,
                                    color: formColor,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _formField(
                                    label: 'Sao thưởng',
                                    ctrl: starsCtrl,
                                    hint: '0',
                                    icon: Icons.star_rounded,
                                    color: formColor,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Thứ tự',
                              ctrl: orderCtrl,
                              hint: '0',
                              icon: Icons.format_list_numbered_rounded,
                              color: formColor,
                              keyboard: TextInputType.number,
                            ),
                            SizedBox(height: 14.h),
                            _dropdownField(
                              label: 'Loại huy hiệu',
                              value: selectedType,
                              icon: Icons.category_rounded,
                              color: formColor,
                              items: _typeLabels.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                              onChanged: (v) => setSheetState(() => selectedType = v!),
                            ),
                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  final data = {
                                    'name': nameCtrl.text.trim(),
                                    'description': descCtrl.text.trim(),
                                    'type': selectedType,
                                    'xpReward': int.tryParse(xpCtrl.text) ?? 0,
                                    'starsReward': int.tryParse(starsCtrl.text) ?? 0,
                                    'order': int.tryParse(orderCtrl.text) ?? 0,
                                    'iconUrl': iconUrlCtrl.text.trim(),
                                  };
                                  if (data['name']!.toString().isEmpty || data['description']!.toString().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Tên và mô tả là bắt buộc'), backgroundColor: AppColors.errorRed));
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  final result = isEdit
                                    ? await AdminService().updateBadge(badge['_id']?.toString() ?? badge['id']?.toString() ?? '', data)
                                    : await AdminService().createBadge(data);
                                  if (!mounted) return;
                                  _showSnack(
                                    result['success'] == true ? (isEdit ? 'Đã cập nhật' : 'Đã tạo huy hiệu') : (result['message'] ?? 'Lỗi'),
                                    result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
                                  if (result['success'] == true) _loadBadges();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: formColor,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                                child: Text(isEdit ? 'Cập nhật' : 'Tạo huy hiệu',
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
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

  Future<void> _confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Xóa huy hiệu?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$name"?', textAlign: TextAlign.center,
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
    final result = await AdminService().deleteBadge(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadBadges();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}
