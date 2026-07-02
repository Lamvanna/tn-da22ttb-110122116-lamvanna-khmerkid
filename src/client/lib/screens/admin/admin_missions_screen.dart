import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';
import 'package:image_picker/image_picker.dart';

/// Màn hình Quản lý Nhiệm vụ — Admin (Premium Redesigned UI)
class AdminMissionsScreen extends StatefulWidget {
  const AdminMissionsScreen({super.key});

  @override
  State<AdminMissionsScreen> createState() => _AdminMissionsScreenState();
}

class _AdminMissionsScreenState extends State<AdminMissionsScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _missions = [];
  bool _loading = true;
  String? _filterType;

  static const _typeLabels = {'daily': 'Hàng ngày', 'weekly': 'Hàng tuần'};
  static const _actionLabels = {
    'complete_lesson': 'Hoàn thành bài học',
    'listen_lesson': 'Nghe bài',
    'speak_lesson': 'Nói bài',
    'write_lesson': 'Viết bài',
    'play_game': 'Chơi game',
    'daily_login': 'Đăng nhập hàng ngày',
    'read_lesson': 'Đọc bài',
  };

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchMissions(
      page: 1,
      limit: 50,
      type: _filterType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _missions = result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Row
        _buildSearchAndFilterRow(),

        // Mission Count Banner
        _buildMissionCountBanner(),

        // Mission List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _missions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_outlined, size: 64.sp, color: AppColors.textHint),
                          SizedBox(height: 12.h),
                          Text(
                            'Chưa có nhiệm vụ nào',
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
                      onRefresh: _loadMissions,
                      color: AppColors.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _missions.length,
                        itemBuilder: (context, index) => _buildMissionCard(_missions[index]),
                      ),
                    ),
        ),

        // Add Button
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
                onSubmitted: (_) => _loadMissions(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm nhiệm vụ...',
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
                            _loadMissions();
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
      null: 'Tất cả nhiệm vụ',
      'daily': 'Hàng ngày',
      'weekly': 'Hàng tuần',
    };
    final colors = {
      null: const Color(0xFF0084FF),
      'daily': const Color(0xFF0084FF),
      'weekly': const Color(0xFF0084FF),
    };
    final icons = {
      null: Icons.flag_rounded,
      'daily': Icons.today_rounded,
      'weekly': Icons.date_range_rounded,
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
              final color = colors[type] ?? AppColors.primary;
              final icon = icons[type] ?? Icons.flag_rounded;

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
            final color = colors[type] ?? AppColors.primary;
            final icon = icons[type] ?? Icons.flag_rounded;

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
            _loadMissions();
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
        ),
      ),
    );
  }

  Widget _buildMissionCountBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0084FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Tổng số: ${_missions.length} nhiệm vụ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0084FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final title = mission['title'] ?? '';
    final desc = mission['description'] ?? '';
    final type = mission['type'] ?? 'daily';
    final action = mission['action'] ?? '';
    final requirement = mission['requirement'] ?? 0;
    final reward = mission['reward'] as Map<String, dynamic>? ?? {};
    final rewardXp = reward['xp'] ?? 0;
    final rewardStars = reward['stars'] ?? 0;
    final isActive = mission['isActive'] ?? true;
    final id = mission['_id']?.toString() ?? mission['id']?.toString() ?? '';

    final isDaily = type == 'daily';
    final color = const Color(0xFF0084FF);

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
                       // Icon Container
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          image: (mission['iconUrl']?.toString() ?? '').trim().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(mission['iconUrl'].toString().trim()),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (mission['iconUrl']?.toString() ?? '').trim().isEmpty
                            ? Center(
                                child: Icon(
                                  isDaily ? Icons.today_rounded : Icons.date_range_rounded,
                                  color: color,
                                  size: 22.sp,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 14.w),

                      // Info
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
                                _tag(_typeLabels[type] ?? type, color,
                                    icon: isDaily ? Icons.today_rounded : Icons.date_range_rounded),
                                _tag(_actionLabels[action] ?? action, const Color(0xFF0084FF),
                                    icon: Icons.play_arrow_rounded),
                                _tag('Yêu cầu: x$requirement', AppColors.textHint,
                                    icon: Icons.playlist_add_check_rounded),
                                if (rewardXp > 0)
                                  _tag('🎯 +$rewardXp XP', AppColors.violet),
                                if (rewardStars > 0)
                                  _tag('⭐ +$rewardStars sao', AppColors.secondary),
                                if (!isActive)
                                  _tag('Ẩn', AppColors.errorRed, icon: Icons.visibility_off_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions Button
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
                                  'Sửa nhiệm vụ',
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
                                  'Xóa nhiệm vụ',
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
                          if (v == 'edit') _showMissionForm(mission);
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

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 140.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
                onTap: () => _showMissionForm(null),
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm nhiệm vụ mới',
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

  void _showMissionForm(Map<String, dynamic>? mission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MissionFormPage(
          mission: mission,
          onSaved: _loadMissions,
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
        title: Text('Xóa nhiệm vụ?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$title"?\nHành động không thể hoàn tác.',
          textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
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
    final result = await AdminService().deleteMission(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa nhiệm vụ' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadMissions();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}

class _MissionFormPage extends StatefulWidget {
  final Map<String, dynamic>? mission;
  final VoidCallback onSaved;

  const _MissionFormPage({
    required this.mission,
    required this.onSaved,
  });

  @override
  State<_MissionFormPage> createState() => _MissionFormPageState();
}

class _MissionFormPageState extends State<_MissionFormPage> {
  late final bool _isEdit;
  bool _saving = false;
  late bool _isActive;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _requirementCtrl;
  late final TextEditingController _rewardXpCtrl;
  late final TextEditingController _rewardStarsCtrl;
  late final TextEditingController _iconUrlCtrl;
  bool _uploadingImg = false;

  late String _selectedType;
  late String _selectedAction;

  static const _typeLabels = {'daily': 'Hàng ngày', 'weekly': 'Hàng tuần'};
  static const _actionLabels = {
    'complete_lesson': 'Hoàn thành bài học',
    'listen_lesson': 'Nghe bài',
    'speak_lesson': 'Nói bài',
    'write_lesson': 'Viết bài',
    'play_game': 'Chơi game',
    'daily_login': 'Đăng nhập hàng ngày',
    'read_lesson': 'Đọc bài',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.mission != null;
    final m = widget.mission;

    _titleCtrl = TextEditingController(text: m?['title'] ?? '');
    _descCtrl = TextEditingController(text: m?['description'] ?? '');
    _requirementCtrl = TextEditingController(text: '${m?['requirement'] ?? 1}');

    final reward = m?['reward'] as Map<String, dynamic>? ?? {};
    _rewardXpCtrl = TextEditingController(text: '${reward['xp'] ?? 0}');
    _rewardStarsCtrl = TextEditingController(text: '${reward['stars'] ?? 0}');
    _iconUrlCtrl = TextEditingController(text: m?['iconUrl'] ?? '');

    _selectedType = m?['type'] ?? 'daily';
    _selectedAction = m?['action'] ?? 'complete_lesson';
    _isActive = m?['isActive'] ?? true;

    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
    _requirementCtrl.addListener(() => setState(() {}));
    _rewardXpCtrl.addListener(() => setState(() {}));
    _rewardStarsCtrl.addListener(() => setState(() {}));
    _iconUrlCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _requirementCtrl.dispose();
    _rewardXpCtrl.dispose();
    _rewardStarsCtrl.dispose();
    _iconUrlCtrl.dispose();
    super.dispose();
  }

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 140.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Text(text,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5.sp,
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
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: textStyle ??
              GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500),
            prefixIcon:
                Icon(icon, color: color.withValues(alpha: 0.7), size: 20.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.8),
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
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: color.withValues(alpha: 0.7), size: 20.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.8),
            ),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22.sp),
          borderRadius: BorderRadius.circular(14.r),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewMissionCard(Color color) {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final isDaily = _selectedType == 'daily';
    final activeIcon = isDaily ? Icons.today_rounded : Icons.date_range_rounded;
    final requirement = _requirementCtrl.text.trim();
    final rewardXp = _rewardXpCtrl.text.trim();
    final rewardStars = _rewardStarsCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: _isActive
              ? color.withValues(alpha: 0.35)
              : AppColors.errorRed.withValues(alpha: 0.25),
          width: 1.5,
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
                color: _isActive ? color : AppColors.errorRed,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          image: _iconUrlCtrl.text.trim().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_iconUrlCtrl.text.trim()),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _iconUrlCtrl.text.trim().isEmpty
                            ? Center(
                                child: Icon(
                                  activeIcon,
                                  color: color,
                                  size: 22.sp,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 14.w),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'Tiêu đề nhiệm vụ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: title.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
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
                                _tag(_typeLabels[_selectedType] ?? _selectedType, color, icon: activeIcon),
                                _tag(_actionLabels[_selectedAction] ?? _selectedAction, AppColors.primary,
                                    icon: Icons.play_arrow_rounded),
                                _tag('Yêu cầu: x${requirement.isNotEmpty ? requirement : "0"}',
                                    AppColors.textHint, icon: Icons.playlist_add_check_rounded),
                                if ((int.tryParse(rewardXp) ?? 0) > 0)
                                  _tag('🎯 +$rewardXp XP', AppColors.violet),
                                if ((int.tryParse(rewardStars) ?? 0) > 0)
                                  _tag('⭐ +$rewardStars sao', AppColors.secondary),
                                if (!_isActive)
                                  _tag('Ẩn', AppColors.errorRed, icon: Icons.visibility_off_rounded),
                              ],
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
        ),
      ),
    );
  }

  Future<void> _save() async {
    final titleText = _titleCtrl.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (titleText.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập tiêu đề nhiệm vụ'),
            backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _saving = true);
    final req = int.tryParse(_requirementCtrl.text) ?? 1;
    final xp = int.tryParse(_rewardXpCtrl.text) ?? 0;
    final stars = int.tryParse(_rewardStarsCtrl.text) ?? 0;

    final body = {
      'title': titleText,
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'action': _selectedAction,
      'requirement': req,
      'reward': {
        'xp': xp,
        'stars': stars,
      },
      'iconUrl': _iconUrlCtrl.text.trim(),
      'isActive': _isActive,
    };

    final result = _isEdit
        ? await AdminService().updateMission(
            widget.mission!['_id'] ?? widget.mission!['id'], body)
        : await AdminService().createMission(body);

    if (!mounted) return;
    setState(() => _saving = false);

    scaffoldMessenger.showSnackBar(
      SnackBar(
          content: Text(result['success'] == true
              ? (_isEdit ? 'Đã cập nhật nhiệm vụ' : 'Đã tạo nhiệm vụ mới')
              : (result['message'] ?? 'Lỗi')),
          backgroundColor: result['success'] == true
              ? AppColors.tertiary
              : AppColors.errorRed,
          behavior: SnackBarBehavior.floating),
    );

    if (result['success'] == true) {
      widget.onSaved();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formColor = const Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 24.sp),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: formColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.flag_rounded, color: formColor, size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              _isEdit ? 'Sửa nhiệm vụ' : 'Thêm nhiệm vụ mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
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
                        child: CircularProgressIndicator(
                            color: formColor, strokeWidth: 2.w),
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
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h +
                  MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIVE PREVIEW HEADER
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 16.sp, color: formColor),
                        SizedBox(width: 6.w),
                        Text(
                          'XEM TRƯỚC NHIỆM VỤ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: formColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LIVE PREVIEW CARD
                  _buildPreviewMissionCard(_selectedType == 'daily' ? AppColors.tertiary : AppColors.violet),
                  SizedBox(height: 20.h),

                  // SECTION 1: BASIC INFO
                  _sectionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Thông tin cơ bản',
                    color: formColor,
                    children: [
                      _prettyField(
                        label: 'Tiêu đề nhiệm vụ',
                        ctrl: _titleCtrl,
                        hint: 'Nhập tiêu đề nhiệm vụ...',
                        icon: Icons.title_rounded,
                        color: formColor,
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Mô tả nhiệm vụ',
                        ctrl: _descCtrl,
                        hint: 'Mô tả chi tiết cách thực hiện...',
                        icon: Icons.description_outlined,
                        color: formColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // SECTION: HÌNH ẢNH NHIỆM VỤ
                  _sectionCard(
                    icon: Icons.image_outlined,
                    title: 'Hình ảnh / Biểu tượng',
                    color: formColor,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _uploadingImg ? null : () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 500,
                                maxHeight: 500,
                                imageQuality: 85,
                              );
                              if (image == null) return;
                              setState(() => _uploadingImg = true);
                              try {
                                final url = await AdminService().uploadImage(image.path);
                                if (url != null) {
                                  _iconUrlCtrl.text = url;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải ảnh lên thành công!'), backgroundColor: AppColors.tertiary),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải ảnh thất bại!'), backgroundColor: AppColors.errorRed),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorRed),
                                );
                              } finally {
                                setState(() => _uploadingImg = false);
                              }
                            },
                            child: Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                              ),
                              child: _uploadingImg
                                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)))
                                  : _iconUrlCtrl.text.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14.r),
                                          child: Image.network(_iconUrlCtrl.text, fit: BoxFit.cover),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_rounded, size: 24.sp, color: formColor),
                                            SizedBox(height: 4.h),
                                            Text('Chọn ảnh', style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: formColor)),
                                          ],
                                        ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _prettyField(
                              label: 'URL hình ảnh nhiệm vụ',
                              ctrl: _iconUrlCtrl,
                              hint: 'Dán link hình ảnh hoặc bấm chọn ảnh',
                              icon: Icons.link_rounded,
                              color: formColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // SECTION 2: CONFIGURATION
                  _sectionCard(
                    icon: Icons.settings_outlined,
                    title: 'Cấu hình nhiệm vụ',
                    color: formColor,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownField(
                              label: 'Loại nhiệm vụ',
                              value: _selectedType,
                              items: _typeLabels.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedType = val);
                                }
                              },
                              icon: Icons.category_outlined,
                              color: formColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _dropdownField(
                              label: 'Hành động yêu cầu',
                              value: _selectedAction,
                              items: _actionLabels.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedAction = val);
                                }
                              },
                              icon: Icons.play_arrow_outlined,
                              color: formColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Số lần yêu cầu hoàn thành',
                        ctrl: _requirementCtrl,
                        hint: 'Nhập số lần (ví dụ: 1, 3, 5...)',
                        icon: Icons.playlist_add_check_rounded,
                        color: formColor,
                        keyboard: TextInputType.number,
                      ),
                    ],
                  ),

                  // SECTION 3: REWARDS
                  _sectionCard(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Phần thưởng nhiệm vụ',
                    color: formColor,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _prettyField(
                              label: 'Điểm kinh nghiệm (XP)',
                              ctrl: _rewardXpCtrl,
                              hint: 'Ví dụ: 20',
                              icon: Icons.bolt_rounded,
                              color: formColor,
                              keyboard: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _prettyField(
                              label: 'Số sao nhận được',
                              ctrl: _rewardStarsCtrl,
                              hint: 'Ví dụ: 2',
                              icon: Icons.star_rounded,
                              color: formColor,
                              keyboard: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // SECTION 4: STATUS
                  _sectionCard(
                    icon: Icons.visibility_rounded,
                    title: 'Trạng thái hiển thị',
                    color: formColor,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? AppColors.tertiary.withValues(alpha: 0.1)
                                  : AppColors.errorRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isActive
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 16.sp,
                              color: _isActive ? AppColors.tertiary : AppColors.errorRed,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái hiển thị',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _isActive
                                      ? 'Học sinh có thể nhận nhiệm vụ này'
                                      : 'Đang ẩn khỏi danh sách nhiệm vụ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: Colors.white,
                            activeTrackColor: formColor,
                            inactiveThumbColor: AppColors.textHint,
                            inactiveTrackColor: AppColors.outlineVariant,
                            onChanged: (v) => setState(() => _isActive = v),
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
