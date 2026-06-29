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
  final _searchCtrl = TextEditingController();
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
    'learning': Color(0xFF0084FF),
    'ranking': AppColors.violet,
  };

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchBadges(
      page: 1,
      limit: 50,
      type: _filterType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
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
        // ── Search & Filter Row ──
        _buildSearchAndFilterRow(),

        // ── Badge List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _badges.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64.sp, color: AppColors.textHint),
                          SizedBox(height: 12.h),
                          Text(
                            'Chưa có huy hiệu nào',
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
                      onRefresh: _loadBadges,
                      color: const Color(0xFF0084FF),
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: _badges.length,
                        itemBuilder: (context, index) => _buildBadgeCard(_badges[index]),
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
                onSubmitted: (_) => _loadBadges(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm huy hiệu...',
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
                            _loadBadges();
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
      null: 'Tất cả huy hiệu',
      'level': 'Cấp độ',
      'pronunciation': 'Phát âm',
      'streak': 'Chuỗi ngày',
      'learning': 'Học tập',
      'ranking': 'Xếp hạng',
    };
    final colors = {
      null: const Color(0xFF0084FF),
      'level': AppColors.secondary,
      'pronunciation': AppColors.coral,
      'streak': AppColors.tertiary,
      'learning': const Color(0xFF0084FF),
      'ranking': AppColors.violet,
    };
    final icons = {
      null: Icons.grid_view_rounded,
      'level': Icons.military_tech_rounded,
      'pronunciation': Icons.mic_rounded,
      'streak': Icons.local_fire_department_rounded,
      'learning': Icons.school_rounded,
      'ranking': Icons.emoji_events_rounded,
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
            _loadBadges();
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
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
    final color = _typeColors[type] ?? const Color(0xFF0084FF);
    final icon = _typeIcons[type] ?? Icons.star_rounded;

    return Container(
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
        child: Stack(
          children: [
            // Top right indicator or label for badge type
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 9.sp, color: color),
                    SizedBox(width: 2.w),
                    Text(
                      _typeLabels[type] ?? type,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!isActive)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Ẩn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.errorRed,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 14.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 12.h),
                  // Badge icon
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: iconUrl.startsWith('http')
                        ? ClipOval(
                            child: Image.network(
                              AuthService.getOptimizedImageUrl(iconUrl, width: 150),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(icon, color: Colors.white, size: 24.sp),
                            ),
                          )
                        : Icon(icon, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(height: 10.h),

                  // Name
                  Flexible(
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.textPrimary : AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Description
                  SizedBox(
                    height: 28.h,
                    child: Text(
                      desc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),

                  // Rewards Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (xpReward > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: AppColors.violet.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🎯',
                                style: TextStyle(fontSize: 9.sp),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$xpReward XP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.violet,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (starsReward > 0) SizedBox(width: 4.w),
                      ],
                      if (starsReward > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '⭐',
                                style: TextStyle(fontSize: 9.sp),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$starsReward sao',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showBadgeForm(badge),
                          child: Container(
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0084FF).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 12.sp, color: const Color(0xFF0084FF)),
                                SizedBox(width: 4.w),
                                Text(
                                  'Sửa',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0084FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _confirmDelete(id, name),
                          child: Container(
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 12.sp, color: AppColors.errorRed),
                                SizedBox(width: 4.w),
                                Text(
                                  'Xóa',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                onTap: () => _showBadgeForm(null),
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm huy hiệu mới',
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

  void _showBadgeForm(Map<String, dynamic>? badge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BadgeFormPage(
          badge: badge,
          onSaved: _loadBadges,
        ),
      ),
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
        content: Text('Xóa "$name"?\nHành động này không thể hoàn tác.', textAlign: TextAlign.center,
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

class _BadgeFormPage extends StatefulWidget {
  final Map<String, dynamic>? badge;
  final VoidCallback onSaved;

  const _BadgeFormPage({
    required this.badge,
    required this.onSaved,
  });

  @override
  State<_BadgeFormPage> createState() => _BadgeFormPageState();
}

class _BadgeFormPageState extends State<_BadgeFormPage> {
  late final bool _isEdit;
  bool _saving = false;
  bool _uploadingImg = false;
  bool _isActive = true;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _starsCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _iconUrlCtrl;

  late String _selectedType;

  static const _typeLabels = {
    'level': 'Cấp độ 🎖️',
    'pronunciation': 'Phát âm 🎙️',
    'streak': 'Chuỗi ngày 🔥',
    'learning': 'Học tập 🎓',
    'ranking': 'Xếp hạng 🏆',
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
    'learning': Color(0xFF0084FF),
    'ranking': AppColors.violet,
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.badge != null;
    final b = widget.badge;

    _nameCtrl = TextEditingController(text: b?['name'] ?? '');
    _descCtrl = TextEditingController(text: b?['description'] ?? '');
    _xpCtrl = TextEditingController(text: '${b?['xpReward'] ?? 0}');
    _starsCtrl = TextEditingController(text: '${b?['starsReward'] ?? 0}');
    _orderCtrl = TextEditingController(text: '${b?['order'] ?? 0}');
    _iconUrlCtrl = TextEditingController(text: b?['iconUrl'] ?? '');
    _selectedType = b?['type'] ?? 'level';
    _isActive = b?['isActive'] ?? true;

    _nameCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
    _xpCtrl.addListener(() => setState(() {}));
    _starsCtrl.addListener(() => setState(() {}));
    _orderCtrl.addListener(() => setState(() {}));
    _iconUrlCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _xpCtrl.dispose();
    _starsCtrl.dispose();
    _orderCtrl.dispose();
    _iconUrlCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
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
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      _showSnack('Tên và mô tả huy hiệu là bắt buộc', AppColors.errorRed);
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': name,
      'description': desc,
      'type': _selectedType,
      'xpReward': int.tryParse(_xpCtrl.text) ?? 0,
      'starsReward': int.tryParse(_starsCtrl.text) ?? 0,
      'order': int.tryParse(_orderCtrl.text) ?? 0,
      'iconUrl': _iconUrlCtrl.text.trim(),
      'isActive': _isActive,
    };

    final result = _isEdit
        ? await AdminService().updateBadge(widget.badge!['_id']?.toString() ?? widget.badge!['id']?.toString() ?? '', data)
        : await AdminService().createBadge(data);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      _showSnack(_isEdit ? 'Đã cập nhật huy hiệu' : 'Đã tạo huy hiệu mới', AppColors.tertiary);
      widget.onSaved();
      Navigator.pop(context);
    } else {
      _showSnack(result['message'] ?? 'Lỗi xảy ra', AppColors.errorRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formColor = const Color(0xFF0084FF);
    final previewColor = _typeColors[_selectedType] ?? const Color(0xFF0084FF);
    final activeIcon = _typeIcons[_selectedType] ?? Icons.star_rounded;

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
              child: Icon(Icons.emoji_events_rounded, color: formColor, size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              _isEdit ? 'Sửa huy hiệu' : 'Thêm huy hiệu mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // ── Live Preview Card ──
            Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(color: previewColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 14.sp, color: formColor),
                      SizedBox(width: 4.w),
                      Text(
                        'Xem trước thời gian thực',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: formColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56.w, height: 56.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [previewColor, previewColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(color: previewColor.withValues(alpha: 0.3), blurRadius: 12.r, offset: Offset(0, 4.h)),
                            ],
                          ),
                          child: _iconUrlCtrl.text.isNotEmpty && _iconUrlCtrl.text.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18.r),
                                child: Image.network(
                                  AuthService.getOptimizedImageUrl(_iconUrlCtrl.text, width: 150),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(activeIcon, color: Colors.white, size: 28.sp),
                                ),
                              )
                            : Icon(activeIcon, color: Colors.white, size: 28.sp),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _nameCtrl.text.isEmpty ? 'Tên huy hiệu' : _nameCtrl.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _isActive ? AppColors.textPrimary : AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _descCtrl.text.isEmpty ? 'Mô tả điều kiện đạt huy hiệu...' : _descCtrl.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if ((int.tryParse(_xpCtrl.text) ?? 0) > 0)
                              Text('🎯 ${_xpCtrl.text} XP  ', style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.violet)),
                            if ((int.tryParse(_starsCtrl.text) ?? 0) > 0)
                              Text('⭐ ${_starsCtrl.text} sao', style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Basic Info Section ──
            _sectionCard(
              icon: Icons.assignment_outlined,
              title: 'Thông tin cơ bản',
              color: AppColors.primary,
              children: [
                _prettyField(
                  label: 'Tên huy hiệu',
                  ctrl: _nameCtrl,
                  hint: 'Nhập tên huy hiệu...',
                  icon: Icons.badge_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16.h),
                _prettyField(
                  label: 'Mô tả',
                  ctrl: _descCtrl,
                  hint: 'Nhập điều kiện / cách nhận...',
                  icon: Icons.description_outlined,
                  color: AppColors.primary,
                ),
              ],
            ),

            // ── Badge Icon Upload Section ──
            _sectionCard(
              icon: Icons.image_outlined,
              title: 'Hình ảnh huy hiệu',
              color: AppColors.tertiary,
              children: [
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

                        setState(() => _uploadingImg = true);
                        try {
                          final url = await AdminService().uploadImage(image.path);
                          if (url != null) {
                            _iconUrlCtrl.text = url;
                            _showSnack('Tải ảnh huy hiệu thành công!', AppColors.tertiary);
                          } else {
                            _showSnack('Tải ảnh thất bại', AppColors.errorRed);
                          }
                        } catch (e) {
                          _showSnack('Có lỗi khi tải ảnh: $e', AppColors.errorRed);
                        } finally {
                          setState(() => _uploadingImg = false);
                        }
                      },
                      child: Container(
                        width: 68.w,
                        height: 68.w,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                        ),
                        child: _uploadingImg
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
                            : _iconUrlCtrl.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: Image.network(
                                      AuthService.getOptimizedImageUrl(_iconUrlCtrl.text, width: 200),
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
                      child: _prettyField(
                        label: 'Đường dẫn ảnh (iconUrl)',
                        ctrl: _iconUrlCtrl,
                        hint: 'Dán link hoặc chọn ảnh để upload',
                        icon: Icons.link_rounded,
                        color: formColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Configuration Section ──
            _sectionCard(
              icon: Icons.settings_outlined,
              title: 'Cấu hình và Phần thưởng',
              color: AppColors.secondary,
              children: [
                _dropdownField(
                  label: 'Loại huy hiệu',
                  value: _selectedType,
                  icon: Icons.category_rounded,
                  color: AppColors.secondary,
                  items: _typeLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _prettyField(
                        label: 'XP thưởng',
                        ctrl: _xpCtrl,
                        hint: '0',
                        icon: Icons.bolt_rounded,
                        color: AppColors.secondary,
                        keyboard: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _prettyField(
                        label: 'Sao thưởng',
                        ctrl: _starsCtrl,
                        hint: '0',
                        icon: Icons.star_rounded,
                        color: AppColors.secondary,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _prettyField(
                  label: 'Thứ tự hiển thị',
                  ctrl: _orderCtrl,
                  hint: '0',
                  icon: Icons.format_list_numbered_rounded,
                  color: AppColors.secondary,
                  keyboard: TextInputType.number,
                ),
              ],
            ),

            // ── Status Section ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppColors.cardShadowList,
              ),
              child: SwitchListTile(
                title: Text(
                  'Hoạt động',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Cho phép người dùng nhìn thấy và mở khóa huy hiệu này',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                activeTrackColor: formColor.withValues(alpha: 0.5),
                activeThumbColor: formColor,
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
