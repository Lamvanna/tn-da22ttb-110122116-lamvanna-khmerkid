import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import '../main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình Xếp hạng - Bảng xếp hạng học sinh
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  ScoreService? _score;
  int _selectedTab = 1; // 0: Tuần, 1: Tháng, 2: Tất cả
  int _myStars = 0;
  bool _loading = false;

  final List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _score = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _myStars = _score?.totalStars ?? 0;
      });
      await _fetchRanking();
    }
  }

  Future<void> _fetchRanking() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final auth = AuthService();
      final storage = await StorageService.getInstance();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? auth.accessToken;
      
      String endpoint = '/rank/top';
      if (_selectedTab == 0) endpoint = '/rank/weekly';
      if (_selectedTab == 1) endpoint = '/rank/monthly';
      
      final url = Uri.parse('${auth.baseUrl}$endpoint');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final List<dynamic> list = resData['data'] ?? [];
        
        List<Map<String, dynamic>> realList = [];
        for (var item in list) {
          final stars = item['stars'] ?? item['totalStars'] ?? 0;
          final itemId = item['_id']?.toString() ?? item['userId']?.toString() ?? '';
          realList.add({
            'id': itemId,
            'name': item['name'] ?? 'Bé học sinh',
            'stars': stars,
            'avatar': item['avatar'] ?? 'image/Đại diện.png',
            'isMe': false,
          });
        }

        // Cập nhật thông tin bé
        final myId = auth.userProfile?['_id']?.toString() ?? auth.userProfile?['id']?.toString() ?? '';
        final myName = storage.getUsername();
        final myAvatar = storage.getAvatarUrl();
        
        // Thêm chính mình vào danh sách để so sánh và sắp xếp
        bool meInList = false;
        for (var item in realList) {
          final isSameId = myId.isNotEmpty && item['id'] == myId;
          final isSameName = myId.isEmpty && item['name'] == myName;
          if (isSameId || isSameName) {
            item['isMe'] = true;
            item['avatar'] = myAvatar;
            // Chỉ ghi đè số sao trọn đời nếu ở tab "Tất cả" (All time), các tab Tuần/Tháng giữ nguyên số sao tích lũy trong kỳ từ server
            if (_selectedTab == 2) {
              item['stars'] = _myStars;
            }
            meInList = true;
            break;
          }
        }
        
        if (!meInList) {
          realList.add({
            'id': myId,
            'name': myName,
            'stars': _selectedTab == 2 ? _myStars : 0,
            'avatar': myAvatar,
            'isMe': true,
          });
        }

        // Sắp xếp giảm dần theo số sao
        realList.sort((a, b) => (b['stars'] as int).compareTo(a['stars'] as int));

        // Gán thứ hạng
        for (int i = 0; i < realList.length; i++) {
          realList[i]['rank'] = i + 1;
        }

        if (mounted) {
          setState(() {
            _leaderboard.clear();
            _leaderboard.addAll(realList);
            _loading = false;
          });
        }
      } else {
        throw Exception('Failed to load ranking');
      }
    } catch (e) {
      debugPrint('Error fetching ranking: $e');
      await _loadFallbackData();
    }
  }

  Future<void> _loadFallbackData() async {
    final storage = await StorageService.getInstance();
    final myName = storage.getUsername();
    final myAvatar = storage.getAvatarUrl();
    
    List<Map<String, dynamic>> mockList = [
      {
        'name': myName,
        'stars': _myStars,
        'avatar': myAvatar,
        'isMe': true,
      }
    ];

    mockList.sort((a, b) => (b['stars'] as int).compareTo(a['stars'] as int));

    for (int i = 0; i < mockList.length; i++) {
      mockList[i]['rank'] = i + 1;
    }

    if (mounted) {
      setState(() {
        _leaderboard.clear();
        _leaderboard.addAll(mockList);
        _loading = false;
      });
    }
  }

  Widget _buildAvatarImage(String avatarPath) {
    if (avatarPath.isEmpty) {
      return Image.asset('image/Đại diện.png', fit: BoxFit.cover);
    }
    if (avatarPath.startsWith('http')) {
      return Image.network(
        avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('image/Đại diện.png', fit: BoxFit.cover),
      );
    }
    if (avatarPath.startsWith('image/') || avatarPath.startsWith('assets/')) {
      return Image.asset(
        avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('image/Đại diện.png', fit: BoxFit.cover),
      );
    }
    return Image.file(
      File(avatarPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset('image/Đại diện.png', fit: BoxFit.cover),
    );
  }

  int get _myRank {
    final idx = _leaderboard.indexWhere((e) => e['isMe'] == true);
    return idx != -1 ? idx + 1 : 9;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: Column(
        children: [
          // ═══ HEADER GRADIENT ═══
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.r),
                bottomRight: Radius.circular(28.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                child: Column(
                  children: [
                    // Back + Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.translate('leaderboard.title'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 36.w),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    // Tab bar
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        children: [
                           _tab(context.translate('leaderboard.weekly'), 0),
                           _tab(context.translate('leaderboard.monthly'), 1),
                           _tab(context.translate('leaderboard.all_time'), 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══ CONTENT (scroll) ═══
          Expanded(
            child: _loading || _leaderboard.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E88E5),
                    ),
                  )
                : SafeArea(
                    top: false,
                    bottom: _myRank <= 8,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                      child: Column(
                        children: [
                          _buildPodium(),
                          SizedBox(height: 16.h),
                          ..._buildRankList(),
                        ],
                      ),
                    ),
                  ),
          ),

          // ═══ MY RANK — CHỈ HIỆN KHI KHÔNG CÓ TRONG LIST ═══
          if (_myRank > 8)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12.r,
                    offset: Offset(0, -4.h),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: _buildMyRank(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != index) {
            setState(() {
              _selectedTab = index;
            });
            _fetchRanking();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: active
                  ? AppColors.headerMid
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP 3 PODIUM
  // ══════════════════════════════════════════════════════════════
  Widget _buildPodium() {
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length >= 2 ? _leaderboard[1] : null;
    final third = _leaderboard.length >= 3 ? _leaderboard[2] : null;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 16.h, 10.w, 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.06),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // #2 — Silver (left)
            Expanded(
              child: _podiumItem(
                rank: 2,
                data: second,
                medalColors: [const Color(0xFFCFD8DC), const Color(0xFF78909C)],
                avatarSize: 60.w,
              ),
            ),
            SizedBox(width: 6.w),
            // #1 — Gold (center, tallest)
            Expanded(
              child: _podiumItem(
                rank: 1,
                data: first,
                medalColors: [const Color(0xFFFFD54F), const Color(0xFFFF8F00)],
                avatarSize: 76.w,
              ),
            ),
            SizedBox(width: 6.w),
            // #3 — Bronze (right)
            Expanded(
              child: _podiumItem(
                rank: 3,
                data: third,
                medalColors: [const Color(0xFFE0A96D), const Color(0xFF8A5A36)],
                avatarSize: 52.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem({
    required int rank,
    required Map<String, dynamic>? data,
    required List<Color> medalColors,
    required double avatarSize,
  }) {
    final bool isEmpty = data == null;
    final String name = isEmpty
        ? context.translate('common.empty_slot')
        : ((data['isMe'] == true) ? context.translate('common.you') : (data['name'] as String));
    final int stars = isEmpty ? 0 : (data['stars'] as int);
    final String avatar = isEmpty ? '' : (data['avatar'] as String);

    // Cấu hình bục (pedestal) của từng hạng
    double pedestalMinHeight = 0;
    List<Color> pedestalColors = [];
    BoxShadow pedestalShadow;
    Border pedestalBorder;

    if (rank == 1) {
      pedestalMinHeight = 115.h;
      pedestalColors = isEmpty 
          ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
          : [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
      pedestalBorder = Border.all(
        color: isEmpty ? const Color(0xFFE2E8F0) : const Color(0xFFFFD700).withOpacity(0.6),
        width: 1.5.w,
      );
      pedestalShadow = BoxShadow(
        color: isEmpty ? Colors.transparent : const Color(0xFFFF8F00).withOpacity(0.22),
        blurRadius: 12.r,
        offset: Offset(0, 6.h),
      );
    } else if (rank == 2) {
      pedestalMinHeight = 85.h;
      pedestalColors = isEmpty
          ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
          : [const Color(0xFFECEFF1), const Color(0xFF90A4AE)];
      pedestalBorder = Border.all(
        color: isEmpty ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.6),
        width: 1.5.w,
      );
      pedestalShadow = BoxShadow(
        color: isEmpty ? Colors.transparent : const Color(0xFF90A4AE).withOpacity(0.18),
        blurRadius: 10.r,
        offset: Offset(0, 4.h),
      );
    } else {
      pedestalMinHeight = 70.h;
      pedestalColors = isEmpty
          ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
          : [const Color(0xFFE0A96D), const Color(0xFF8A5A36)];
      pedestalBorder = Border.all(
        color: isEmpty ? const Color(0xFFE2E8F0) : const Color(0xFFD4915E).withOpacity(0.5),
        width: 1.5.w,
      );
      pedestalShadow = BoxShadow(
        color: isEmpty ? Colors.transparent : const Color(0xFF8A5A36).withOpacity(0.18),
        blurRadius: 8.r,
        offset: Offset(0, 3.h),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vương miện + Avatar
        SizedBox(
          width: avatarSize + 20.w,
          height: avatarSize + 24.h,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Vòng tròn Avatar với viền kim loại đẹp
              Positioned(
                bottom: 0,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isEmpty 
                          ? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]
                          : medalColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isEmpty ? const Color(0xFFCBD5E1) : medalColors[0]).withOpacity(0.35),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(3.w),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.all(1.w),
                    child: ClipOval(
                      child: isEmpty 
                          ? Container(
                              color: const Color(0xFFF1F5F9),
                              child: Icon(
                                Icons.person_rounded,
                                color: const Color(0xFF94A3B8),
                                size: (avatarSize * 0.5).sp,
                              ),
                            )
                          : _buildAvatarImage(avatar),
                    ),
                  ),
                ),
              ),
              // Vương miện nổi bật ở trên
              if (!isEmpty)
                Positioned(
                  top: rank == 1 ? -22.h : -15.h,
                  child: Image.asset(
                    'image/Xếp hạng $rank.png',
                    width: rank == 1 ? 82.w : 66.w,
                    height: rank == 1 ? 82.h : 66.h,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // Bục đứng (Pedestal Step)
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: pedestalMinHeight),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: pedestalColors,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(12.r),
              bottomRight: Radius.circular(12.r),
            ),
            border: pedestalBorder,
            boxShadow: [pedestalShadow],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge tròn ghi thứ hạng bên trong bục
              Container(
                width: rank == 1 ? 26.w : 22.w,
                height: rank == 1 ? 26.w : 22.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3.r,
                      offset: Offset(0, 1.5.h),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: rank == 1 ? 14.sp : 11.sp,
                    fontWeight: FontWeight.w900,
                    color: rank == 1
                        ? const Color(0xFFD48A00)
                        : rank == 2
                            ? const Color(0xFF455A64)
                            : const Color(0xFF8D6E63),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              // Tên bé học sinh
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: rank == 1 ? 12.5.sp : 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3.h),
              // Số sao đạt được
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 13.sp,
                      color: const Color(0xFFFFD54F),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      isEmpty ? '0' : '$stars',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: rank == 1 ? 11.5.sp : 10.5.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // RANK LIST (4+)
  // ══════════════════════════════════════════════════════════════
  List<Widget> _buildRankList() {
    final items = <Widget>[];
    for (int i = 3; i < _leaderboard.length; i++) {
      items.add(_rankRow(i + 1, _leaderboard[i], false));
    }
    return items;
  }

  Widget _rankRow(int rank, Map<String, dynamic> data, bool isMe, {EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isMe
            ? Border.all(color: const Color(0xFFFFB300), width: 1.5.w)
            : Border.all(color: const Color(0xFFF1F5F9), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0xFFFFB300).withOpacity(0.12)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Huy hiệu thứ hạng có màu sắc sinh động
          _buildRankBadge(rank),
          SizedBox(width: 12.w),
          // Ảnh đại diện học sinh
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe ? const Color(0xFFFFCA28) : const Color(0xFFE2E8F0),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarImage(data['avatar'] as String),
            ),
          ),
          SizedBox(width: 12.w),
          // Tên hiển thị + Badge "Bạn" (Nếu là chính mình)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    data['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                      color: isMe ? const Color(0xFF8F6300) : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      context.translate('common.you'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Cục hiển thị số sao dạng Gold Pill cực kỳ chuyên nghiệp
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFFF8E8) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isMe ? const Color(0xFFFFCA28).withOpacity(0.5) : const Color(0xFFE2E8F0),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16.sp,
                  color: const Color(0xFFFFB300),
                ),
                SizedBox(width: 4.w),
                Text(
                  '${data['stars'] ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isMe ? const Color(0xFF8F6300) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor;
    if (rank == 4) {
      bgColor = const Color(0xFFF2F0FF);
      textColor = const Color(0xFF7367D6);
    } else if (rank == 5) {
      bgColor = const Color(0xFFFFF0EF);
      textColor = const Color(0xFFD05A4F);
    } else if (rank == 6) {
      bgColor = const Color(0xFFEDF8F2);
      textColor = const Color(0xFF3DA06A);
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
    }

    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MY RANK ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildMyRank() {
    final myItem = _leaderboard.firstWhere((e) => e['isMe'] == true, orElse: () => {
      'name': context.translate('common.you'),
      'stars': _myStars,
      'avatar': 'image/Đại diện.png',
      'isMe': true,
    });
    return _rankRow(_myRank, myItem, true, margin: EdgeInsets.zero);
  }
}
