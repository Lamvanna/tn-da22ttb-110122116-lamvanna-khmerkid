import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Người dùng — Admin
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<dynamic> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _page = 1; });
    final result = await AdminService().fetchUsers(
      page: 1,
      limit: 15,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _users = result['data'] ?? [];
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    _page++;
    final result = await AdminService().fetchUsers(
      page: _page,
      limit: 15,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _users.addAll(result['data'] ?? []);
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search Bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _loadUsers(),
            style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc email...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                color: AppColors.textHint,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 22.sp),
              suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, size: 20.sp, color: AppColors.textHint),
                    onPressed: () {
                      _searchCtrl.clear();
                      _loadUsers();
                    },
                  )
                : null,
              filled: true,
              fillColor: AppColors.cardWhite,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // ── User Count ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Text(
                '${_users.length} người dùng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_loading)
                SizedBox(
                  width: 16.w, height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // ── User List ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64.sp, color: AppColors.textHint),
                      SizedBox(height: 12.h),
                      Text('Không tìm thấy người dùng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    itemCount: _users.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _users.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.h),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _buildUserCard(_users[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Không tên';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'user';
    final level = user['level'] ?? 1;
    final xp = user['xp'] ?? 0;
    final stars = user['stars'] ?? 0;
    final avatar = user['avatar']?.toString() ?? '';
    final userId = user['_id']?.toString() ?? user['id']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppColors.cardShadowList,
        border: role == 'admin'
          ? Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.5)
          : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('http')
              ? null
              : Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (role == 'admin') ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text('ADMIN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          )),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    _miniStat('Lv.$level', AppColors.primary),
                    _miniStat('⭐ $stars', AppColors.secondary),
                    _miniStat('$xp XP', AppColors.violet),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_role',
                child: Row(
                  children: [
                    Icon(
                      role == 'admin' ? Icons.person_rounded : Icons.admin_panel_settings_rounded,
                      size: 20.sp,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(role == 'admin' ? 'Hạ cấp User' : 'Nâng Admin'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20.sp, color: AppColors.errorRed),
                    SizedBox(width: 8.w),
                    Text('Xóa', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'toggle_role') {
                _toggleRole(userId, name, role);
              } else if (value == 'delete') {
                _confirmDelete(userId, name);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _toggleRole(String userId, String name, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondary, size: 40.sp),
        title: Text('Đổi Role?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Đổi "$name" từ $currentRole thành $newRole?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final result = await AdminService().updateUserRole(userId, newRole);
    if (!mounted) return;
    _showSnack(result['message'] ?? (result['success'] == true ? 'Thành công' : 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadUsers();
  }

  Future<void> _confirmDelete(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Xóa người dùng?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "$name"?\nHành động này không thể hoàn tác.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
        ),
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
    final result = await AdminService().deleteUser(userId);
    if (!mounted) return;
    _showSnack(result['message'] ?? (result['success'] == true ? 'Đã xóa' : 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadUsers();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}
