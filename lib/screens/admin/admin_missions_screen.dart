import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Nhiệm vụ — Admin
class AdminMissionsScreen extends StatefulWidget {
  const AdminMissionsScreen({super.key});
  @override
  State<AdminMissionsScreen> createState() => _AdminMissionsScreenState();
}

class _AdminMissionsScreenState extends State<AdminMissionsScreen> {
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

  Future<void> _loadMissions() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchMissions(page: 1, limit: 50, type: _filterType);
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
        // ── Filter Tabs ──
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Row(
            children: [
              _filterChip(null, 'Tất cả'),
              SizedBox(width: 8.w),
              _filterChip('daily', '📅 Hàng ngày'),
              SizedBox(width: 8.w),
              _filterChip('weekly', '📆 Hàng tuần'),
            ],
          ),
        ),

        // ── Mission List ──
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
                      Text('Chưa có nhiệm vụ nào',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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

        // ── Add Button ──
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showMissionForm(null),
                icon: Icon(Icons.add_rounded, size: 22.sp),
                label: Text('Thêm nhiệm vụ mới',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
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

  Widget _filterChip(String? type, String label) {
    final selected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        _loadMissions();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.tertiary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.tertiary : AppColors.outlineVariant,
          ),
        ),
        child: Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          )),
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

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppColors.cardShadowList,
        border: !isActive ? Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48.w, height: 48.w,
            decoration: BoxDecoration(
              color: (isDaily ? AppColors.tertiary : AppColors.violet).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              isDaily ? Icons.today_rounded : Icons.date_range_rounded,
              color: isDaily ? AppColors.tertiary : AppColors.violet,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Info
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
                if (desc.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(desc,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    _miniTag(_typeLabels[type] ?? type, isDaily ? AppColors.tertiary : AppColors.violet),
                    _miniTag(_actionLabels[action] ?? action, AppColors.primary),
                    _miniTag('x$requirement', AppColors.secondary),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (rewardXp > 0)
                      Text('🎯 $rewardXp XP  ', style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.violet)),
                    if (rewardStars > 0)
                      Text('⭐ $rewardStars sao', style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.secondary)),
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
                Icon(Icons.edit_rounded, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w), const Text('Sửa'),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 20.sp, color: AppColors.errorRed),
                SizedBox(width: 8.w), Text('Xóa', style: TextStyle(color: AppColors.errorRed)),
              ])),
            ],
            onSelected: (v) {
              if (v == 'edit') _showMissionForm(mission);
              if (v == 'delete') _confirmDelete(id, title);
            },
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
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

  void _showMissionForm(Map<String, dynamic>? mission) {
    final isEdit = mission != null;
    final titleCtrl = TextEditingController(text: mission?['title'] ?? '');
    final descCtrl = TextEditingController(text: mission?['description'] ?? '');
    final reqCtrl = TextEditingController(text: '${mission?['requirement'] ?? 1}');
    final xpCtrl = TextEditingController(text: '${mission?['reward']?['xp'] ?? 0}');
    final starsCtrl = TextEditingController(text: '${mission?['reward']?['stars'] ?? 0}');
    final orderCtrl = TextEditingController(text: '${mission?['order'] ?? 0}');
    String selectedType = mission?['type'] ?? 'daily';
    String selectedAction = mission?['action'] ?? 'complete_lesson';

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
                      Text(isEdit ? '✏️ Sửa nhiệm vụ' : '➕ Thêm nhiệm vụ',
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
                          'daily': AppColors.tertiary,
                          'weekly': AppColors.violet,
                        };
                        final formColor = typeColors[selectedType] ?? AppColors.primary;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formField(
                              label: 'Tiêu đề',
                              ctrl: titleCtrl,
                              hint: 'Nhập tiêu đề nhiệm vụ',
                              icon: Icons.title_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Mô tả',
                              ctrl: descCtrl,
                              hint: 'Nhập mô tả (tùy chọn)',
                              icon: Icons.description_rounded,
                              color: formColor,
                            ),
                            SizedBox(height: 14.h),
                            _formField(
                              label: 'Yêu cầu (số lần)',
                              ctrl: reqCtrl,
                              hint: '1',
                              icon: Icons.track_changes_rounded,
                              color: formColor,
                              keyboard: TextInputType.number,
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
                              label: 'Loại',
                              value: selectedType,
                              icon: Icons.calendar_month_rounded,
                              color: formColor,
                              items: {'daily': 'Hàng ngày', 'weekly': 'Hàng tuần'},
                              onChanged: (v) => setSheetState(() => selectedType = v!),
                            ),
                            SizedBox(height: 14.h),
                            _dropdownField(
                              label: 'Hành động',
                              value: selectedAction,
                              icon: Icons.play_arrow_rounded,
                              color: formColor,
                              items: _actionLabels,
                              onChanged: (v) => setSheetState(() => selectedAction = v!),
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
                                    'action': selectedAction,
                                    'requirement': int.tryParse(reqCtrl.text) ?? 1,
                                    'reward': {
                                      'xp': int.tryParse(xpCtrl.text) ?? 0,
                                      'stars': int.tryParse(starsCtrl.text) ?? 0,
                                    },
                                    'order': int.tryParse(orderCtrl.text) ?? 0,
                                  };
                                  if (data['title']!.toString().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Tiêu đề là bắt buộc'), backgroundColor: AppColors.errorRed));
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  final result = isEdit
                                    ? await AdminService().updateMission(mission['_id']?.toString() ?? mission['id']?.toString() ?? '', data)
                                    : await AdminService().createMission(data);
                                  if (!mounted) return;
                                  _showSnack(
                                    result['success'] == true ? (isEdit ? 'Đã cập nhật' : 'Đã tạo nhiệm vụ') : (result['message'] ?? 'Lỗi'),
                                    result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
                                  if (result['success'] == true) _loadMissions();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: formColor,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                                child: Text(isEdit ? 'Cập nhật' : 'Tạo nhiệm vụ',
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
    required Map<String, String> items,
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
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
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
        title: Text('Xóa nhiệm vụ?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$title"?', textAlign: TextAlign.center,
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
    final result = await AdminService().deleteMission(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadMissions();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}
