import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../report/report_screen.dart';
import '../achievements/achievements_screen.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/game_xp_progress_bar.dart';
import '../notification/notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ScoreService? _score;
  StorageService? _storage;
  String _username = 'Bé Na';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    AuthService().addListener(_onAuthChanged);
    _loadData();
    AuthService().fetchProfile();
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _updateStats();
  }

  Future<void> _loadData() async {
    final s = await ScoreService.getInstance();
    final storage = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _score = s;
        _storage = storage;
      });
      _updateStats();
    }
  }

  void _updateStats() {
    if (!mounted) return;
    final user = AuthService().userProfile;
    setState(() {
      _username = user?['name'] ?? (_storage?.getUsername() ?? 'Bé Na');
      _avatarUrl = user?['avatar'] ?? (_storage?.getAvatarUrl() ?? '');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;

      final path = image.path;
      await AuthService().updateProfile(avatar: path);

      messenger.showSnackBar(
        SnackBar(
          content: const Text('🎉 Đã cập nhật ảnh đại diện mới thành công!'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error picking avatar image: $e');
      messenger.showSnackBar(
        SnackBar(
          content: const Text('⚠️ Không thể mở ảnh. Vui lòng kiểm tra quyền truy cập!'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi tên của bé ✏️',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A237E),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Nhập biệt danh đáng yêu mới cho bé nhé:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 15,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Nhập tên...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppColors.textHint,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF9800),
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'Hủy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        
                        await AuthService().updateProfile(name: newName);
                        
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('🎉 Đã đổi tên thành "$newName" thành công!'),
                            backgroundColor: const Color(0xFF4CAF50),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Lưu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20.r,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Thay đổi ảnh đại diện 📸',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A237E),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Chọn một bức ảnh thật đáng yêu từ điện thoại để làm hình đại diện của bé nhé:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFF90CAF9).withOpacity(0.5),
                          width: 1.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.08),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.photo_library_rounded,
                              size: 28.sp,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Chọn từ thư viện',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Ảnh có sẵn trong máy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1565C0).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFFFFCC80).withOpacity(0.5),
                          width: 1.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withOpacity(0.08),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 28.sp,
                              color: const Color(0xFFF57C00),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Chụp ảnh mới',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF57C00),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Chụp hình bé ngay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE65100).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                ),
                child: Text(
                  'Hủy bỏ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _xp => _score != null ? _score!.totalXp : 0;
  int get _level => _score != null ? _score!.level : 1;
  int get _rank => _score != null ? _score!.rank : 1;
  int get _stars => _score != null ? _score!.totalStars : 0;
  int get _streak => _score != null ? _score!.streak : 0;
  int get _medals => _score != null ? _score!.totalMedals : 0;
  int get _lettersLearned => _score != null ? _score!.lettersLearned : 0;
  int get _vowelsLearned => _score != null ? _score!.vowelsLearned : 0;
  int get _readingLearned => _score != null ? _score!.readingLearned : 0;

  String _levelTitle(int lv) {
    if (lv >= 20) return 'Bậc thầy ngôn ngữ';
    if (lv >= 15) return 'Nhà thông thái';
    if (lv >= 10) return 'Nhà thám hiểm';
    if (lv >= 5) return 'Nhà thám hiểm nhí';
    return 'Mới bắt đầu';
  }

  @override
  Widget build(BuildContext context) {
    // Tải động XP cần thiết từ Backend MongoDB
    final xpInLevel = _score?.currentLevelXp ?? (_xp % 100);
    final xpNeeded = _score?.nextLevelXp ?? 100;
    final xpRemaining = xpNeeded - xpInLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ═══ HEADER ═══
            _buildHeader(xpInLevel, xpNeeded, xpRemaining),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 14.h),
                  _buildProgressSection(),
                  SizedBox(height: 16.h),
                  _buildAchievements(),
                  SizedBox(height: 16.h),
                  _buildSettingsRow(),
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER — Blue → Violet gradient, sky theme (match reference)
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(int xpInLevel, int xpNeeded, int xpRemaining) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 70.h),
          decoration: BoxDecoration(
            gradient: AppColors.appGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ─── Glowing light sources for ultimate depth ───
                  Positioned(
                    left: -40.w,
                    top: -20.h,
                    child: Container(
                      width: 220.w,
                      height: 220.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF818CF8).withValues(alpha: 0.40),
                            const Color(0xFF818CF8).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40.w,
                    top: 0.h,
                    child: Container(
                      width: 240.w,
                      height: 240.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF60A5FA).withValues(alpha: 0.35),
                            const Color(0xFF60A5FA).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Cloud decoration (bottom) ────────────────
                  Positioned(
                    left: -20.w,
                    bottom: 8.h,
                    child: _cloud(width: 110.w, alpha: 0.22),
                  ),
                  Positioned(
                    right: 30.w,
                    bottom: 24.h,
                    child: _cloud(width: 80.w, alpha: 0.18),
                  ),
                  Positioned(
                    left: 140.w,
                    bottom: 50.h,
                    child: _cloud(width: 60.w, alpha: 0.14),
                  ),

                  // ─── Star sparkles ────────────────────────────
                  Positioned(
                    left: 30.w,
                    top: 16.h,
                    child: _spark(14.sp, 0.45, color: const Color(0xFFFFF176)),
                  ),
                  Positioned(left: 90.w, top: 8.h, child: _spark(8.sp, 0.35)),
                  Positioned(
                    right: 120.w,
                    top: 12.h,
                    child: _spark(12.sp, 0.40, color: const Color(0xFFFFF176)),
                  ),
                  Positioned(
                    right: 180.w,
                    top: 48.h,
                    child: _spark(9.sp, 0.30),
                  ),
                  Positioned(
                    left: 170.w,
                    top: 62.h,
                    child: _spark(10.sp, 0.35, color: const Color(0xFFFFF176)),
                  ),

                  // ─── Notification Bell ───
                  Positioned(
                    right: 20.w,
                    top: 16.h,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(page: const NotificationScreen()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46.w,
                            height: 46.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: const Color(0xFF3B82F6),
                              size: 26.sp,
                            ),
                          ),
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: Container(
                            padding: EdgeInsets.all(5.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.w),
                            ),
                            child: Text(
                              '3',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),

                  // ─── Main content ────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 44.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Avatar (left) + Name + chip
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarWithBadges(),
                            SizedBox(
                              width: 10.w,
                            ), // Xích cột tên và cấp độ sang bên trái nhiều hơn
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                ), // Căn giữa thẳng hàng
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize:
                                                  27.sp, // Lớn và nổi bật hơn nhiều
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                              height: 1.1,
                                              shadows: [
                                                Shadow(
                                                  color: const Color(
                                                    0xFF1E1B4B,
                                                  ).withOpacity(0.40),
                                                  blurRadius: 8.r,
                                                  offset: Offset(0, 3.h),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        GestureDetector(
                                          onTap: _showRenameDialog,
                                          child: Container(
                                            padding: EdgeInsets.all(5.w),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.22),
                                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.w),
                                            ),
                                            child: Icon(
                                              Icons.edit_rounded,
                                              color: Colors.white,
                                              size: 13.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    _buildLevelChip(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),

                        // ─── XP Bar (dịch lên trên) ─────────────────
                        // ─── XP Bar (dịch xuống dưới và sang phải một chút) ───
                        Transform.translate(
                          offset: Offset(0, -22.h),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 102.w,
                              right: 70.w,
                            ),
                            child: _buildXpBar(xpInLevel, xpNeeded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ═══ STATS CARD (overlap) ═══
        Positioned(left: 12.w, right: 12.w, bottom: 0, child: _buildStatsRow()),
      ],
    );
  }

  // ─── Helper: cloud shape (3 overlapping circles) ──────────────
  Widget _cloud({required double width, required double alpha}) {
    final color = Colors.white.withValues(alpha: alpha);
    return SizedBox(
      width: width,
      height: width * 0.55,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: width * 0.55,
              height: width * 0.55,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          Positioned(
            left: width * 0.30,
            bottom: width * 0.10,
            child: Container(
              width: width * 0.50,
              height: width * 0.50,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: width * 0.45,
              height: width * 0.45,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper: small star sparkle ───────────────────────────────
  Widget _spark(double size, double alpha, {Color color = Colors.white}) =>
      Icon(
        Icons.star_rounded,
        color: color.withValues(alpha: alpha),
        size: size,
      );

  // ─── Avatar with star badge (top-right) + edit button (bottom-right)
  Widget _buildAvatarWithBadges() {
    return GestureDetector(
      onTap: _showAvatarPicker,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90.w,
        height: 90.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3.5.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withOpacity(0.28),
                    blurRadius: 16.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: ClipOval(
                child: _avatarUrl.isNotEmpty
                    ? (_avatarUrl.startsWith('http')
                        ? Image.network(
                            _avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                          )
                        : (_avatarUrl.startsWith('image/') || _avatarUrl.startsWith('assets/')
                            ? Image.asset(
                                _avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                              )
                            : Image.file(
                                File(_avatarUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('image/Đại diện.png', fit: BoxFit.cover),
                              )))
                    : Image.asset('image/Đại diện.png', fit: BoxFit.cover),
              ),
            ),
            // Edit pencil (bottom-right)
            Positioned(
              right: -2.w,
              bottom: -2.h,
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFAB40), // Bright shiny orange
                      Color(0xFFFF6D00), // Rich warm orange
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6D00).withOpacity(0.35),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Level chip (shield + level title) ────────────────────────
  Widget _buildLevelChip() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 2.h, 12.w, 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'image/Cấp ${_level.clamp(1, 5)}.png',
            width: 16.sp,
            height: 16.sp,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'Cấp $_level • ${_levelTitle(_level)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── XP Bar (yellow fill, dark blue track, STAR badge — match ref) ──
  Widget _buildXpBar(int xpInLevel, int xpNeeded) {
    return GameXpProgressBar(
      xpInLevel: xpInLevel,
      xpNeeded: xpNeeded,
      height: 30,
      trackHeight: 18,
      starSize: 24,
      fontSize: 9.2,
      animationDuration: const Duration(milliseconds: 1200),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STATS ROW: 4 items — Label trên, Value lớn dưới (match ref)
  // ══════════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.08),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2.w),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _statItem(
              iconIndex: 0,
              label: 'Tổng số sao',
              value: '$_stars',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 1,
              label: 'Chuỗi ngày',
              value: '$_streak',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 2,
              label: 'Huy hiệu',
              value: '$_medals',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
            _divider(),
            _statItem(
              iconIndex: 3,
              label: 'Thứ hạng',
              value: 'Top $_rank',
              labelColor: const Color(0xFF64748B),
              valueColor: const Color(0xFF1E293B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1.5.w,
      height: 48.h,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildStatIcon(int index) {
    switch (index) {
      case 0:
        return Image.asset('image/sao.png', width: 40.sp, height: 40.sp, fit: BoxFit.contain);
      case 1:
        return Image.asset('image/Lửa chuổi.png', width: 40.sp, height: 40.sp, fit: BoxFit.contain);
      case 2:
        return Image.asset('image/Huy hiệu.png', width: 40.sp, height: 40.sp, fit: BoxFit.contain);
      case 3:
        return Image.asset('image/xếp hạng hồ sơ.png', width: 40.sp, height: 40.sp, fit: BoxFit.contain);
      default:
        return Icon(Icons.help_rounded, size: 40.sp, color: Colors.grey);
    }
  }

  Widget _statItem({
    required int iconIndex,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44.h,
              alignment: Alignment.center,
              child: _buildStatIcon(iconIndex),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: labelColor,
                height: 1.2,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17.5.sp,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LEARNING PROGRESS
  // ══════════════════════════════════════════════════════════════
  Widget _buildProgressSection() {
    final letters = _lettersLearned;
    final spelling = _vowelsLearned;
    final writing = _lettersLearned;
    final reading = _readingLearned;

    final totalProg = (((letters / 33) + (spelling / 24) + (reading / 15)) / 3 * 100)
        .clamp(0, 100)
        .toInt();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header row ──
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.headerMid.withValues(alpha: 0.15),
                      AppColors.headerMid.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.headerMid.withValues(alpha: 0.20),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 18.sp,
                  color: AppColors.headerMid,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Tiến độ học tập',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(page: const ReportScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                  child: Row(
                    children: [
                      Text(
                        'Chi tiết',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerMid,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: AppColors.headerMid,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // ─── Body: circular + bars ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress with gradient ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalProg / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, val, _) => Container(
                  width: 98.w,
                  height: 98.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                        blurRadius: 16.r,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer premium border plate
                      Container(
                        width: 98.w,
                        height: 98.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFEEF2F6),
                            width: 1.5.w,
                          ),
                        ),
                      ),
                      // Track
                      SizedBox(
                        width: 90.w,
                        height: 90.w,
                        child: Padding(
                          padding: EdgeInsets.all(5.w),
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8.w,
                            color: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                      // Active ring with beautiful SweepGradient ShaderMask!
                      SizedBox(
                        width: 90.w,
                        height: 90.w,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const SweepGradient(
                            colors: [
                              Color(0xFF66BB6A), // light vibrant green
                              Color(0xFF388E3C), // deep emerald green
                            ],
                            stops: [0.0, 1.0],
                          ).createShader(bounds),
                          child: Padding(
                            padding: EdgeInsets.all(5.w),
                            child: CircularProgressIndicator(
                              value: val,
                              strokeWidth: 8.w,
                              color: Colors.white,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(val * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Tổng tiến độ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Subject bars
              Expanded(
                child: Column(
                  children: [
                    _progressBar(
                      'Học chữ cái',
                      letters,
                      33,
                      const Color(0xFF4CAF50),
                      'image/Phụ âm.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Đánh vần',
                      spelling,
                      24,
                      const Color(0xFF2196F3),
                      'image/Đánh vần.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Luyện viết',
                      writing,
                      33,
                      const Color(0xFFFF9800),
                      'image/Tập viết.png',
                    ),
                    SizedBox(height: 12.h),
                    _progressBar(
                      'Tập đọc',
                      reading,
                      15,
                      const Color(0xFF9C27B0),
                      'image/Tập đọc.png',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBar(
    String label,
    int done,
    int total,
    Color color,
    String img,
  ) {
    final pct = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 40.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.16),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.2.w,
            ),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            img,
            width: 36.w,
            height: 36.w,
            errorBuilder: (_, _, _) =>
                Icon(Icons.book_rounded, size: 24.sp, color: color),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  Text(
                    '$done/$total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.80),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.24),
                          blurRadius: 4.r,
                          offset: Offset(0, 1.h),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACHIEVEMENTS (Dynamic từ MongoDB)
  // ══════════════════════════════════════════════════════════════
  Widget _buildAchievements() {
    // Lấy badges từ MongoDB user profile
    final profile = AuthService().userProfile;
    final backendBadges = profile?['badges'] as List? ?? [];
    
    // Nếu có badges từ MongoDB thì dùng dynamic, nếu không thì dùng fallback
    final bool useDynamic = backendBadges.isNotEmpty && backendBadges.first is Map;
    
    // Fallback static badges (khi chưa có data từ MongoDB)
    final fallbackBadges = [
      {
        'icon': Icons.star_rounded,
        'label': 'Siêu nhân\nchăm chỉ',
        'color': const Color(0xFFFFB300),
        'unlocked': _streak >= 5,
      },
      {
        'icon': Icons.edit_rounded,
        'label': 'Bút vàng',
        'color': const Color(0xFFFB8C00),
        'unlocked': _lettersLearned >= 5,
      },
      {
        'icon': Icons.auto_stories_rounded,
        'label': 'Siêu nhân\nbài tập',
        'color': const Color(0xFF1E88E5),
        'unlocked': _lettersLearned >= 1,
      },
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Tập đọc',
        'color': const Color(0xFF8E24AA),
        'unlocked': _readingLearned >= 1,
      },
      {
        'icon': Icons.spellcheck_rounded,
        'label': 'Đánh vần\nnhanh',
        'color': const Color(0xFFE53935),
        'unlocked': _vowelsLearned >= 1,
      },
      {
        'icon': Icons.explore_rounded,
        'label': 'Nhà thám\nhiểm',
        'color': const Color(0xFF00897B),
        'unlocked': _xp >= 100,
      },
    ];

    // Sử dụng badges từ MongoDB nếu có, nếu không dùng fallback
    final List<Map<String, dynamic>> badges;
    if (useDynamic) {
      // Xây dựng badges list từ MongoDB data
      badges = backendBadges.map<Map<String, dynamic>>((b) {
        final badgeMap = b as Map<String, dynamic>;
        final String type = badgeMap['type']?.toString() ?? 'learning';
        Color badgeColor = const Color(0xFF4CAF50);
        IconData badgeIcon = Icons.stars_rounded;
        if (type == 'level') { badgeColor = const Color(0xFFFF9800); badgeIcon = Icons.rocket_launch_rounded; }
        else if (type == 'pronunciation') { badgeColor = const Color(0xFFFF5722); badgeIcon = Icons.record_voice_over_rounded; }
        else if (type == 'streak') { badgeColor = const Color(0xFFE91E63); badgeIcon = Icons.local_fire_department_rounded; }
        else if (type == 'learning') { badgeColor = const Color(0xFF4CAF50); badgeIcon = Icons.auto_stories_rounded; }
        else if (type == 'ranking') { badgeColor = const Color(0xFFFFCA28); badgeIcon = Icons.emoji_events_rounded; }
        return {
          'icon': badgeIcon,
          'label': badgeMap['name']?.toString() ?? 'Huy chương',
          'color': badgeColor,
          'unlocked': true, // Backend badges đã unlock
        };
      }).toList();
    } else {
      badges = fallbackBadges;
    }

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──
          Row(
            children: [
              Image.asset(
                'image/cúp hồ sơ.png',
                width: 34.w,
                height: 34.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10.w),
              Text(
                'Thành tích',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8.w),
              // Gold Gradient Capsule Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.30),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Text(
                  '$_medals/${badges.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(page: const AchievementsScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                  child: Row(
                    children: [
                      Text(
                        'Tất cả',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerMid,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: AppColors.headerMid,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ─── Badges list ──
          SizedBox(
            height: 106.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (_, _) => SizedBox(width: 14.w),
              itemBuilder: (_, i) {
                final b = badges[i];
                final color = b['color'] as Color;
                final unlocked = b['unlocked'] as bool;
                return SizedBox(
                  width: 64.w,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Outer double-border ring
                          Container(
                            width: 58.w,
                            height: 58.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: unlocked
                                    ? color.withValues(alpha: 0.35)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5.w,
                              ),
                            ),
                            padding: EdgeInsets.all(2.w),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: unlocked
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.80),
                                        ],
                                      )
                                    : null,
                                color: unlocked ? null : const Color(0xFFF1F5F9),
                                border: unlocked
                                    ? Border.all(
                                        color: Colors.white.withValues(alpha: 0.60),
                                        width: 1.5.w,
                                      )
                                    : null,
                                boxShadow: unlocked
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 8.r,
                                          offset: Offset(0, 3.h),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                b['icon'] as IconData,
                                color: unlocked ? Colors.white : const Color(0xFF94A3B8),
                                size: 26.sp,
                              ),
                            ),
                          ),
                          // Lock indicator
                          if (!unlocked)
                            Positioned(
                              right: -1.w,
                              bottom: -1.w,
                              child: Container(
                                width: 18.w,
                                height: 18.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5.w,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 10.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        b['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? AppColors.textPrimary
                              : const Color(0xFF94A3B8),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SYSTEM SETTINGS ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildSettingsRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            AppPageRoute(page: const SettingsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF94A3B8),
                        Color(0xFF64748B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.20),
                        blurRadius: 8.r,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.settings_rounded,
                    size: 22.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt hệ thống',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Âm thanh, thông báo & tài khoản',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF64748B),
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

