import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Thông báo — Admin (Premium UI)
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  static const _typeLabels = {
    'system': 'Hệ thống',
    'daily_reminder': 'Nhắc nhở ngày',
    'reward': 'Phần thưởng',
    'badge_unlocked': 'Huy hiệu',
    'level_up': 'Lên cấp',
    'streak_update': 'Chuỗi ngày',
    'rank_update': 'Xếp hạng',
  };

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _currentPage = page;
    });

    final result = await AdminService().fetchAdminNotifications(
      page: page,
      limit: 15,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _notifications = result['data'] ?? [];
      final pag = result['pagination'];
      if (pag != null) {
        _totalPages = pag['totalPages'] ?? 1;
        _currentPage = pag['currentPage'] ?? 1;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Row
        _buildSearchAndFilterRow(),

        // Status Header
        _buildCountBanner(),

        // Main List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => _loadNotifications(page: 1),
                      color: const Color(0xFF0084FF),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
                      ),
                    ),
        ),

        // Pagination Controls
        if (_totalPages > 1 && !_loading) _buildPaginationControls(),

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
                onSubmitted: (_) => _loadNotifications(page: 1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm tiêu đề hoặc nội dung...',
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
                            _loadNotifications(page: 1);
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
        ],
      ),
    );
  }

  Widget _buildCountBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0084FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Tổng gửi: ${_notifications.length} bản ghi',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64.sp, color: AppColors.textHint),
          SizedBox(height: 12.h),
          Text(
            'Chưa gửi thông báo nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Hãy nhấn nút bên dưới để bắt đầu gửi thông báo.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> note) {
    final title = note['title'] ?? '';
    final message = note['message'] ?? note['body'] ?? '';
    final type = note['type'] ?? 'system';
    final target = note['target'] ?? 'specific';
    final recipientCount = note['recipientCount'] ?? 1;
    final user = note['userId'] as Map<String, dynamic>?;
    final recipientName = user?['name'] ?? '';
    final recipientEmail = user?['email'] ?? '';
    final id = note['_id']?.toString() ?? note['id']?.toString() ?? '';
    final createdAt = note['createdAt'] != null
        ? DateTime.parse(note['createdAt'].toString()).toLocal()
        : DateTime.now();

    final timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6.w,
                color: const Color(0xFF0084FF),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      _buildTypeIcon(type),
                      SizedBox(width: 14.w),
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
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              message,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                _tag(_typeLabels[type] ?? type, const Color(0xFF0084FF), icon: Icons.tag_rounded),
                                _tag(
                                  target == 'all'
                                      ? 'Gửi cho tất cả ($recipientCount)'
                                      : recipientName.isNotEmpty
                                          ? 'Người nhận: $recipientName'
                                          : 'Đang gửi...',
                                  AppColors.textSecondary,
                                  icon: target == 'all' ? Icons.group_rounded : Icons.person_rounded,
                                ),
                                _tag(timeStr, AppColors.textHint, icon: Icons.access_time_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 4,
                        color: AppColors.cardWhite,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18.sp, color: AppColors.errorRed),
                                SizedBox(width: 10.w),
                                Text(
                                  'Thu hồi / Xóa',
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
                        onSelected: (val) {
                          if (val == 'delete') {
                            _confirmDelete(id, title);
                          }
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

  Widget _buildTypeIcon(String type) {
    IconData iconData;
    Color color = const Color(0xFF0084FF);

    switch (type) {
      case 'level_up':
        iconData = Icons.rocket_launch_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'daily_reminder':
        iconData = Icons.access_alarm_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'reward':
        iconData = Icons.stars_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'badge_unlocked':
        iconData = Icons.military_tech_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case 'streak_update':
        iconData = Icons.local_fire_department_rounded;
        color = Colors.orange;
        break;
      case 'rank_update':
        iconData = Icons.workspace_premium_rounded;
        color = Colors.amber;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        color = const Color(0xFF0084FF);
    }

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: color,
          size: 22.sp,
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 4.w),
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

  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _loadNotifications(page: _currentPage - 1) : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            iconSize: 16.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            'Trang $_currentPage / $_totalPages',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _loadNotifications(page: _currentPage + 1) : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            iconSize: 16.sp,
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _NotificationFormPage(
                        onSaved: () => _loadNotifications(page: 1),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm thông báo mới',
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

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Xóa/Thu hồi thông báo?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa thông báo "$title"?\nHành động này sẽ gỡ thông báo khỏi hộp thư của người dùng.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await AdminService().deleteNotification(id);
    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo thành công')),
        );
      }
      _loadNotifications(page: _currentPage);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại: ${res['message']}')),
        );
      }
    }
  }
}

/// Trang soạn và gửi thông báo mới (Full Screen)
class _NotificationFormPage extends StatefulWidget {
  final VoidCallback onSaved;

  const _NotificationFormPage({required this.onSaved});

  @override
  State<_NotificationFormPage> createState() => _NotificationFormPageState();
}

class _NotificationFormPageState extends State<_NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _userSearchCtrl = TextEditingController();

  String _type = 'system';
  String _target = 'all'; // 'all' or 'specific'

  // Specific user states
  Map<String, dynamic>? _selectedUser;
  List<dynamic> _matchingUsers = [];
  bool _searchingUsers = false;
  bool _submitting = false;

  final List<Map<String, String>> _types = [
    {'value': 'system', 'label': 'Hệ thống / Thông báo chung'},
    {'value': 'daily_reminder', 'label': 'Nhắc nhở học tập hàng ngày'},
    {'value': 'reward', 'label': 'Phần thưởng XP / Sao'},
    {'value': 'badge_unlocked', 'label': 'Huy hiệu mới'},
    {'value': 'level_up', 'label': 'Lên cấp'},
    {'value': 'streak_update', 'label': 'Cập nhật Streak'},
    {'value': 'rank_update', 'label': 'Xếp hạng tuần/tháng'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _matchingUsers = [];
        _searchingUsers = false;
      });
      return;
    }

    setState(() => _searchingUsers = true);

    final res = await AdminService().fetchUsers(
      page: 1,
      limit: 10,
      search: query.trim(),
      role: 'user',
    );

    if (!mounted) return;

    setState(() {
      _matchingUsers = res['data'] ?? [];
      _searchingUsers = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_target == 'specific' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tìm và chọn học sinh nhận thông báo')),
      );
      return;
    }

    setState(() => _submitting = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'message': _msgCtrl.text.trim(),
      'type': _type,
      'target': _target,
      if (_target == 'specific' && _selectedUser != null) 'userId': _selectedUser!['_id'],
    };

    final res = await AdminService().sendNotification(data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_target == 'all'
              ? 'Đã gửi thông báo thành công tới tất cả học sinh'
              : 'Đã gửi thông báo thành công tới ${_selectedUser!['name']}'),
        ),
      );
      widget.onSaved();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi thất bại: ${res['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0084FF);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final List<Widget> formFields = [
      _buildSectionTitle('1. Thông tin nội dung'),
      SizedBox(height: 12.h),

      // Tiêu đề
      Text('Tiêu đề thông báo',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      SizedBox(height: 6.h),
      TextFormField(
        controller: _titleCtrl,
        validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
        decoration: _inputDeco('Nhập tiều đề hấp dẫn...'),
      ),
      SizedBox(height: 16.h),

      // Nội dung
      Text('Nội dung chi tiết',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      SizedBox(height: 6.h),
      TextFormField(
        controller: _msgCtrl,
        validator: (v) => v == null || v.trim().isEmpty ? 'Không được để trống' : null,
        maxLines: 4,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
        decoration: _inputDeco('Nhập thông điệp gửi tới người dùng...'),
      ),
      SizedBox(height: 24.h),

      _buildSectionTitle('2. Loại & Đối tượng'),
      SizedBox(height: 12.h),

      // Loại thông báo
      Text('Loại thông báo',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      SizedBox(height: 6.h),
      DropdownButtonFormField<String>(
        value: _type,
        items: _types
            .map((t) => DropdownMenuItem(
                  value: t['value'],
                  child: Text(t['label']!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.w600)),
                ))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _type = val);
          }
        },
        decoration: _inputDeco('Chọn loại'),
      ),
      SizedBox(height: 16.h),

      // Đối tượng nhận
      Text('Đối tượng nhận',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      SizedBox(height: 6.h),
      isMobile
          ? Column(
              children: [
                RadioListTile<String>(
                  value: 'all',
                  groupValue: _target,
                  title: Text('Tất cả học sinh',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  activeColor: activeColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _target = val;
                        _selectedUser = null;
                        _matchingUsers = [];
                        _userSearchCtrl.clear();
                      });
                    }
                  },
                ),
                RadioListTile<String>(
                  value: 'specific',
                  groupValue: _target,
                  title: Text('Chọn một học sinh',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  activeColor: activeColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _target = val);
                    }
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'all',
                    groupValue: _target,
                    title: Text('Tất cả học sinh',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    activeColor: activeColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _target = val;
                          _selectedUser = null;
                          _matchingUsers = [];
                          _userSearchCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'specific',
                    groupValue: _target,
                    title: Text('Chọn một học sinh',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    activeColor: activeColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _target = val);
                      }
                    },
                  ),
                ),
              ],
            ),

      if (_target == 'specific') ...[
        SizedBox(height: 14.h),
        Text('Tìm kiếm học sinh',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        SizedBox(height: 6.h),

        if (_selectedUser != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: activeColor.withValues(alpha: 0.2), width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: activeColor, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUser!['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        _selectedUser!['email'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.cancel_rounded, color: AppColors.errorRed, size: 20.sp),
                  onPressed: () {
                    setState(() {
                      _selectedUser = null;
                    });
                  },
                ),
              ],
            ),
          )
        else ...[
          TextFormField(
            controller: _userSearchCtrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600),
            decoration: _inputDeco('Nhập tên hoặc email học sinh...').copyWith(
              suffixIcon: _searchingUsers
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: activeColor)),
                    )
                  : const Icon(Icons.search_rounded, color: AppColors.textHint),
            ),
            onChanged: (val) => _searchUsers(val),
          ),
          if (_matchingUsers.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
                boxShadow: AppColors.cardShadowList,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _matchingUsers.length,
                itemBuilder: (context, idx) {
                  final u = _matchingUsers[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16.r,
                      backgroundColor: activeColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded, size: 16.sp, color: activeColor),
                    ),
                    title: Text(u['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    subtitle: Text(u['email'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            color: AppColors.textSecondary)),
                    onTap: () {
                      setState(() {
                        _selectedUser = u;
                        _matchingUsers = [];
                        _userSearchCtrl.clear();
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ],
    ];

    final actionButtons = Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text('Hủy',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text('Gửi thông báo',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
            ),
          ),
        ),
      ],
    );

    // Mobile layout
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Gửi thông báo mới',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Container(height: 1.h, color: AppColors.outlineVariant),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...formFields,
                SizedBox(height: 24.h),
                Text('XEM TRƯỚC GIAO DIỆN HỌC SINH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textHint,
                    )),
                SizedBox(height: 12.h),
                _buildPreviewCard(),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.outlineVariant, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: activeColor, size: 18.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Thông báo sẽ hiển thị trực quan trong hộp thư của học sinh ngay lập tức sau khi gửi nhờ kết nối Socket realtime.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                actionButtons,
              ],
            ),
          ),
        ),
      );
    }

    // Wide Layout (Row with form on left and preview on right)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gửi thông báo mới',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.outlineVariant),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Form (Scrollable)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...formFields,
                    SizedBox(height: 24.h),
                    actionButtons,
                  ],
                ),
              ),
            ),
          ),

          // Right side: Visual Live Preview
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFFF1F5F9),
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XEM TRƯỚC GIAO DIỆN HỌC SINH',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.textHint,
                      )),
                  SizedBox(height: 24.h),
                  _buildPreviewCard(),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: activeColor, size: 20.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Thông báo sẽ hiển thị trực quan trong hộp thư của học sinh ngay lập tức sau khi gửi nhờ kết nối Socket realtime.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
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

  Widget _buildPreviewCard() {
    final title = _titleCtrl.text.isEmpty ? 'Tiêu đề thông báo...' : _titleCtrl.text;
    final message = _msgCtrl.text.isEmpty
        ? 'Nội dung thông báo sẽ xuất hiện tại đây khi bạn nhập vào biểu mẫu...'
        : _msgCtrl.text;

    IconData iconData;
    Color color = const Color(0xFF0084FF);
    Color bgColor = const Color(0xFFE5F3FF);

    switch (_type) {
      case 'level_up':
        iconData = Icons.rocket_launch_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'daily_reminder':
        iconData = Icons.access_alarm_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'reward':
        iconData = Icons.stars_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case 'badge_unlocked':
        iconData = Icons.military_tech_rounded;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case 'streak_update':
        iconData = Icons.local_fire_department_rounded;
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'rank_update':
        iconData = Icons.workspace_premium_rounded;
        color = Colors.amber;
        bgColor = Colors.amber.withValues(alpha: 0.1);
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        color = const Color(0xFF0084FF);
        bgColor = const Color(0xFFE5F3FF);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9FF), // Simulated unread color
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 26.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8.w, top: 4.h),
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0084FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Vừa xong',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0084FF),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: 40.w,
          height: 3.h,
          decoration: BoxDecoration(
            color: const Color(0xFF0084FF),
            borderRadius: BorderRadius.circular(1.5.r),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.sp,
        color: AppColors.textHint,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.8),
      ),
    );
  }
}
