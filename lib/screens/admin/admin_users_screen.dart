import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Người dùng — Admin (Redesigned Premium UI)
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
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: AppColors.cardShadowList,
            ),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadUsers(),
              style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: AppColors.textHint,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF0084FF), size: 22.sp),
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
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                ),
              ),
            ),
          ),
        ),

        // ── User Count ──
        Padding(
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
                  'Tổng số: ${_users.length} người dùng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0084FF),
                  ),
                ),
              ),
              const Spacer(),
              if (_loading)
                SizedBox(
                  width: 16.w, height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // ── User List ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
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
                  color: const Color(0xFF0084FF),
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
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)),
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

    final isAdmin = role == 'admin';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isAdmin ? const Color(0xFFFFFDF5) : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: AppColors.cardShadowList,
            border: Border.all(
              color: isAdmin ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.4),
              width: isAdmin ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAdmin
                        ? [
                            AppColors.secondary.withValues(alpha: 0.18),
                            AppColors.secondary.withValues(alpha: 0.04),
                          ]
                        : [
                            const Color(0xFF0084FF).withValues(alpha: 0.18),
                            const Color(0xFF0084FF).withValues(alpha: 0.04),
                          ],
                  ),
                  border: Border.all(
                    color: isAdmin
                        ? AppColors.secondary.withValues(alpha: 0.3)
                        : const Color(0xFF0084FF).withValues(alpha: 0.25),
                    width: 1.2.w,
                  ),
                  image: avatar.startsWith('http')
                      ? DecorationImage(
                          image: NetworkImage(avatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatar.startsWith('http')
                    ? null
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: isAdmin ? AppColors.secondary : const Color(0xFF0084FF),
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 14.w),

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
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                            ),
                            child: Text('ADMIN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              )),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
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
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        _miniStat('Lv.$level', const Color(0xFF0084FF), icon: Icons.trending_up_rounded),
                        _miniStat('$stars Sao', AppColors.secondary, icon: Icons.star_rounded),
                        _miniStat('$xp XP', AppColors.violet, icon: Icons.bolt_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String text, Color color, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
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
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _UserDetailPage(
          user: user,
          onRoleChanged: () => _loadUsers(),
          onDeleted: () => _loadUsers(),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════
///  FULL-SCREEN DETAILS PAGE — Interactivity & Podium Achievements
/// ════════════════════════════════════════════════════════════════════

class _UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRoleChanged;
  final VoidCallback onDeleted;

  const _UserDetailPage({
    required this.user,
    required this.onRoleChanged,
    required this.onDeleted,
  });

  @override
  State<_UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<_UserDetailPage> {
  late Map<String, dynamic> _currentUser;
  bool _loadingStats = true;
  Map<String, int> _totalLessonsByType = {
    'consonant': 0,
    'vowel': 0,
    'spelling': 0,
    'closed_syllable': 0,
    'vocabulary': 0,
    'sentence': 0,
    'number': 0,
    'coeng': 0,
  };

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadLessonStats();
  }

  Future<void> _loadLessonStats() async {
    try {
      final result = await AdminService().fetchStatistics();
      if (result['success'] == true && result['data'] != null) {
        final stats = result['data']['lessonStats'] as List?;
        if (stats != null) {
          final Map<String, int> totals = {
            'consonant': 0,
            'vowel': 0,
            'spelling': 0,
            'closed_syllable': 0,
            'vocabulary': 0,
            'sentence': 0,
            'number': 0,
            'coeng': 0,
          };
          for (var item in stats) {
            if (item is Map) {
              final type = item['_id']?.toString() ?? '';
              final count = int.tryParse(item['count']?.toString() ?? '0') ?? 0;
              if (type.isNotEmpty && totals.containsKey(type)) {
                totals[type] = count;
              }
            }
          }
          if (mounted) {
            setState(() {
              _totalLessonsByType = totals;
              _loadingStats = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _loadingStats = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentUser['name'] ?? 'Không tên';
    final email = _currentUser['email'] ?? '';
    final role = _currentUser['role'] ?? 'user';
    final level = _currentUser['level'] ?? 1;
    final xp = _currentUser['xp'] ?? 0;
    final stars = _currentUser['stars'] ?? 0;
    final streak = _currentUser['streak'] ?? 0;
    final longestStreak = _currentUser['longestStreak'] ?? 0;
    final rank = _currentUser['rank'] ?? 0;
    final avatar = _currentUser['avatar']?.toString() ?? '';
    final authProvider = _currentUser['authProvider']?.toString() ?? 'local';
    final isEmailVerified = _currentUser['isEmailVerified'] ?? false;

    // Badges & Achievements lists
    final badgesList = _currentUser['badges'] is List ? _currentUser['badges'] as List : [];
    final achievementsList = _currentUser['achievements'] is List ? _currentUser['achievements'] as List : [];
    final totalBadgesCount = _currentUser['totalBadges'] ?? badgesList.length;

    // Learning progress safely nested
    final lp = _currentUser['learningProgress'] is Map ? _currentUser['learningProgress'] : {};
    final completedLessonsCount = lp['totalLessonsCompleted'] ?? 0;
    final gamesPlayedCount = lp['totalGamesPlayed'] ?? 0;
    final studyTimeMinutes = lp['totalStudyTime'] ?? 0;
    final completedLessonsList = lp['completedLessons'] is List ? lp['completedLessons'] as List : [];

    final isAdmin = role == 'admin';

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
        title: Text(
          'Chi tiết tài khoản',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 24.sp),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            onSelected: (val) {
              if (val == 'toggle_role') _toggleRole();
              if (val == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle_role',
                child: Row(
                  children: [
                    Icon(isAdmin ? Icons.person_rounded : Icons.admin_panel_settings_rounded, color: AppColors.secondary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(isAdmin ? 'Hạ cấp User' : 'Nâng Admin'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text('Xóa tài khoản', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ACCENTS CARD ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(
                  color: isAdmin ? AppColors.secondary.withValues(alpha: 0.35) : AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: isAdmin ? 1.8 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isAdmin ? AppColors.secondary : const Color(0xFF0084FF), width: 3.w),
                    ),
                    child: CircleAvatar(
                      radius: 38.r,
                      backgroundColor: isAdmin ? AppColors.secondary.withValues(alpha: 0.1) : const Color(0xFF0084FF).withValues(alpha: 0.08),
                      backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                      child: avatar.startsWith('http')
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              color: isAdmin ? AppColors.secondary : const Color(0xFF0084FF),
                            ),
                          ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  SizedBox(height: 4.h),
                  Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: (isAdmin ? AppColors.secondary : const Color(0xFF0084FF)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: (isAdmin ? AppColors.secondary : const Color(0xFF0084FF)).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          isAdmin ? 'ADMIN' : 'HỌC SINH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: isAdmin ? AppColors.secondary : const Color(0xFF0084FF),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: authProvider == 'google' ? const Color(0xFFEA4335).withValues(alpha: 0.1) : AppColors.outlineVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: authProvider == 'google' ? const Color(0xFFEA4335).withValues(alpha: 0.2) : AppColors.outlineVariant),
                        ),
                        child: Text(
                          authProvider == 'google' ? 'Google Auth' : 'Local Auth',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: authProvider == 'google' ? const Color(0xFFEA4335) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── SECTION 1: PODIUM STATUS GRID (6 stats cards) ──
            _buildSectionHeader('Đấu trường & Thành tích', Icons.emoji_events_rounded, AppColors.secondary),
            SizedBox(height: 10.h),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 2.1,
              ),
              children: [
                _buildDetailStatCard('Cấp độ học', 'Lv.$level', Icons.trending_up_rounded, const Color(0xFF0084FF)),
                _buildDetailStatCard('Kinh nghiệm', '$xp XP', Icons.flash_on_rounded, AppColors.violet),
                _buildDetailStatCard('Chuỗi ngày học', '$streak ngày', Icons.local_fire_department_rounded, AppColors.coral, subtitle: 'Kỷ lục: $longestStreak ngày'),
                _buildDetailStatCard('Sao tích lũy', '$stars Sao', Icons.star_rounded, AppColors.secondary, subtitle: rank > 0 ? 'Hạng: #$rank' : 'Chưa xếp hạng'),
                _buildDetailStatCard('Huy hiệu nhận', '$totalBadgesCount huy hiệu', Icons.verified_user_rounded, AppColors.secondary),
                _buildDetailStatCard('Thành tích đạt', '${achievementsList.length} thành tích', Icons.workspace_premium_rounded, AppColors.violet),
              ],
            ),
            SizedBox(height: 24.h),

            // ── SECTION 2: POPULATED BADGES SECTION ──
            if (badgesList.isNotEmpty) ...[
              _buildBadgesSection(badgesList),
              SizedBox(height: 24.h),
            ],

            // ── SECTION 3: LEARNING SUMMARY ──
            _buildSectionHeader('Tiến độ học tập', Icons.auto_stories_rounded, const Color(0xFF0084FF)),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActivityMetric('Bài học', completedLessonsCount, Icons.menu_book_rounded, AppColors.violet),
                  _buildVerticalDivider(),
                  _buildActivityMetric('Game đã chơi', gamesPlayedCount, Icons.sports_esports_rounded, AppColors.coral),
                  _buildVerticalDivider(),
                  _buildActivityMetric('Thời gian học', '$studyTimeMinutes phút', Icons.timer_rounded, const Color(0xFF0084FF)),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ── SECTION 4: DETAILED COMPLETED LESSONS ──
            _buildSectionHeader('Chi tiết tiến độ học', Icons.assignment_turned_in_rounded, AppColors.violet),
            SizedBox(height: 10.h),
            _buildCompletedLessonsSection(completedLessonsList),
            SizedBox(height: 24.h),

            // ── SECTION 5: ACCOUNT REGISTRY METADATA ──
            _buildSectionHeader('Thông tin đăng ký', Icons.info_outline_rounded, AppColors.textSecondary),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _buildMetadataRow('Ngày đăng ký tài khoản', _formatDate(_currentUser['createdAt'])),
                  const Divider(height: 18, color: AppColors.outlineVariant),
                  _buildMetadataRow('Lần đăng nhập cuối cùng', _formatDateTime(_currentUser['lastLoginDate'])),
                  const Divider(height: 18, color: AppColors.outlineVariant),
                  _buildMetadataRow('Hoạt động gần nhất', _formatDateTime(_currentUser['lastActiveDate'])),
                  const Divider(height: 18, color: AppColors.outlineVariant),
                  _buildMetadataRow('Xác minh email', isEmailVerified ? 'Đã xác minh (✅)' : 'Chưa xác minh (❌)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.sp),
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
    );
  }

  Widget _buildDetailStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle ?? label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetric(String label, dynamic value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 20.sp),
        SizedBox(height: 6.h),
        Text(
          value.toString(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.w,
      height: 36.h,
      color: AppColors.outlineVariant,
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(List<dynamic> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Huy hiệu sở hữu', Icons.verified_user_rounded, AppColors.secondary),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: AppColors.cardShadowList,
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: badges.map((b) {
              final name = b is Map ? b['name']?.toString() ?? 'Huy hiệu' : 'Huy hiệu';
              final icon = b is Map ? b['icon']?.toString() ?? '🏆' : '🏆';
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Chưa rõ';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'Chưa rõ';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Future<void> _toggleRole() async {
    final name = _currentUser['name'] ?? 'Không tên';
    final currentRole = _currentUser['role'] ?? 'user';
    final userId = _currentUser['_id']?.toString() ?? _currentUser['id']?.toString() ?? '';
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
    
    if (result['success'] == true) {
      setState(() {
        _currentUser = {..._currentUser, 'role': newRole};
      });
      widget.onRoleChanged();
    }
  }

  Future<void> _confirmDelete() async {
    final name = _currentUser['name'] ?? 'Không tên';
    final userId = _currentUser['_id']?.toString() ?? _currentUser['id']?.toString() ?? '';

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
    
    if (result['success'] == true) {
      widget.onDeleted();
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildCompletedLessonsSection(List<dynamic> completedLessons) {
    // Group completed lessons by type first to count them and get titles
    final Map<String, List<String>> completedByType = {};
    for (var item in completedLessons) {
      if (item is Map) {
        final typeStr = item['type']?.toString() ?? 'other';
        final titleStr = item['title']?.toString() ?? 'Bài học';
        if (!completedByType.containsKey(typeStr)) {
          completedByType[typeStr] = [];
        }
        completedByType[typeStr]!.add(titleStr);
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingStats)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const CircularProgressIndicator(color: Color(0xFF0084FF)),
              ),
            )
          else
            ..._totalLessonsByType.keys.map((type) {
              final typeLabel = _getLessonTypeLabel(type);
              final typeColor = _getLessonTypeColor(type);
              final completedList = completedByType[type] ?? [];
              final completedCount = completedList.length;
              final totalCount = _totalLessonsByType[type] ?? 0;
              final double ratio = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
              final percent = (ratio * 100).toInt();

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              typeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$completedCount / $totalCount bài ($percent%)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 6.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 6.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(3.r),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withValues(alpha: 0.25),
                                  blurRadius: 3.r,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // List of completed lesson titles if not empty
                    if (completedList.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: completedList.map((title) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: typeColor.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getLessonTypeLabel(String type) {
    switch (type) {
      case 'consonant': return 'Phụ âm';
      case 'vowel': return 'Nguyên âm';
      case 'spelling': return 'Ghép vần';
      case 'closed_syllable': return 'Ghép vần đóng';
      case 'vocabulary': return 'Từ vựng';
      case 'sentence': return 'Câu';
      case 'number': return 'Chữ số';
      case 'coeng': return 'Chữ ghép (Coeng)';
      default: return 'Khác';
    }
  }

  Color _getLessonTypeColor(String type) {
    switch (type) {
      case 'consonant': return const Color(0xFF0084FF);
      case 'vowel': return AppColors.secondary;
      case 'spelling': return AppColors.violet;
      case 'closed_syllable': return AppColors.tertiary;
      case 'vocabulary': return AppColors.coral;
      case 'sentence': return Colors.blue;
      case 'number': return Colors.teal;
      case 'coeng': return Colors.indigo;
      default: return AppColors.textSecondary;
    }
  }
}
