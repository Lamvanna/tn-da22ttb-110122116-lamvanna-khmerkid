import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'category_list_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? videoUrl;

  const VideoDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.videoUrl,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  bool _isPlaying = false;
  bool _isFavorited = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSaved = false;
  int _likeCount = 128;
  int _dislikeCount = 12;

  late String _activeTitle;
  late String _activeDescription;
  late String _activeImagePath;
  late String _activeViews;
  late String _activeDate;

  double _currentSliderValue = 135.0; // Initial mock seek position (02:15)
  double _totalDuration = 525.0; // Initial total duration (08:45)
  Timer? _playbackTimer;

  final List<_RelatedVideo> _relatedVideos = [
    const _RelatedVideo(
      title: 'Học chữ ខ (Kho) – Phụ âm thứ 2',
      duration: '07:50',
      views: '1.1K lượt xem',
      time: '1 ngày trước',
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781827/khmerkid/library/fytoyjalak42cfisfg3d.png',
      description: 'Video tiếp theo giúp bé làm quen với chữ ខ (Kho) – phụ âm thứ hai trong bảng chữ cái Khmer. Bé sẽ được học cách ghép vần và phát âm chuẩn xác từ các ví dụ sinh động.',
    ),
    const _RelatedVideo(
      title: 'Học chữ គ (Go) – Phụ âm thứ 3',
      duration: '08:20',
      views: '1.3K lượt xem',
      time: '3 ngày trước',
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781833/khmerkid/library/c42qxbcimdhz4am2ywes.png',
      description: 'Học chữ cái thứ ba trong bảng phụ âm tiếng Khmer: chữ គ (Go). Nhận biết mặt chữ nhanh chóng thông qua các hình ảnh con vật minh họa trực quan sinh động.',
    ),
    const _RelatedVideo(
      title: 'Học chữ ង (Ngo)',
      duration: '07:40',
      views: '953 lượt xem',
      time: '5 ngày trước',
      imagePath: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
      description: 'Cùng làm quen với phụ âm ង (Ngo) trong tiếng Khmer. Bé sẽ được luyện nghe phát âm của người bản xứ và chơi các trò chơi ghép chữ vô cùng lý thú.',
    ),
  ];

  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _activeTitle = widget.title;
    _activeDescription = widget.description;
    _activeImagePath = widget.imagePath;
    _activeViews = '1.2K lượt xem';
    _activeDate = '2 ngày trước';
    _initVideoPlayer(widget.videoUrl);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(String? url) async {
    if (url == null || url.trim().isEmpty) {
      setState(() {
        _videoController?.removeListener(_videoListener);
        _videoController?.dispose();
        _videoController = null;
        _isInitialized = false;
      });
      return;
    }
    
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.dispose();
    }
    
    setState(() {
      _isInitialized = false;
      _isPlaying = false;
    });
    
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _totalDuration = _videoController!.value.duration.inSeconds.toDouble();
        });
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final value = _videoController!.value;
    setState(() {
      _currentSliderValue = value.position.inSeconds.toDouble();
      _isPlaying = value.isPlaying;
      if (value.position >= value.duration) {
        _isPlaying = false;
        _videoController?.pause();
      }
    });
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentSliderValue < _totalDuration) {
          _currentSliderValue += 1.0;
        } else {
          _isPlaying = false;
          _currentSliderValue = 0.0;
          _playbackTimer?.cancel();
        }
      });
    });
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
  }

  void _togglePlay() {
    if (_videoController != null && _isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
        if (_isPlaying) {
          _startPlaybackTimer();
        } else {
          _stopPlaybackTimer();
        }
      });
    }
  }

  String _formatDuration(double seconds) {
    final int m = (seconds / 60).floor();
    final int s = (seconds % 60).round();
    final String mStr = m.toString().padLeft(2, '0');
    final String sStr = s.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  double _parseDuration(String d) {
    try {
      final parts = d.split(':');
      if (parts.length == 2) {
        final m = int.parse(parts[0]);
        final s = int.parse(parts[1]);
        return (m * 60 + s).toDouble();
      }
    } catch (_) {}
    return 300.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Transparent Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16.sp,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Heart Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFavorited = !_isFavorited;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorited ? 'Đã thích video! ❤️' : 'Đã bỏ thích video!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18.sp,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // More Button
                  GestureDetector(
                    onTap: () {
                      _showOptionsSheet();
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20.sp,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content Area ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player Mockup
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        width: double.infinity,
                        height: 200.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16.r,
                              offset: Offset(0, 6.h),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Thumbnail image / Video Player
                            _videoController != null && _isInitialized
                                ? Center(
                                    child: AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  )
                                : (_activeImagePath.startsWith('http')
                                    ? Image.network(
                                        DocItem.optimizeUrl(_activeImagePath, width: 600),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        _activeImagePath,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )),

                            // Translucent Play/Pause Overlay Button
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 60.w,
                                height: 60.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                              ),
                            ),

                            // Video Bottom seek bar & time overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Time Left text
                                    Text(
                                      _formatDuration(_currentSliderValue),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Seekbar slider
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3.h,
                                          activeTrackColor: const Color(0xFF2563EB),
                                          inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
                                          thumbColor: Colors.white,
                                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                                        ),
                                        child: Slider(
                                          value: _currentSliderValue.clamp(0.0, _totalDuration),
                                          max: _totalDuration,
                                          onChanged: (val) {
                                            setState(() {
                                              _currentSliderValue = val;
                                            });
                                            if (_videoController != null && _isInitialized) {
                                              _videoController!.seekTo(Duration(seconds: val.toInt()));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Time Right text
                                    Text(
                                      _formatDuration(_totalDuration),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Fullscreen Icon
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Chế độ toàn màn hình đang được phát triển! 📺'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 20.sp,
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
                    SizedBox(height: 14.h),

                    // Badge Pill
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Học chữ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Video Title
                    Text(
                      _activeTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Views & Upload Date
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 14.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 4.w),
                        Text(
                          _activeViews,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('•', style: TextStyle(color: const Color(0xFF64748B), fontSize: 12.sp)),
                        SizedBox(width: 8.w),
                        Icon(Icons.calendar_today_outlined, size: 13.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 4.w),
                        Text(
                          _activeDate,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // ── 5 Action Badges Row ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            label: '$_likeCount',
                            isActive: _isLiked,
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                                if (_isLiked) {
                                  _likeCount++;
                                  if (_isDisliked) {
                                    _isDisliked = false;
                                    _dislikeCount--;
                                  }
                                } else {
                                  _likeCount--;
                                }
                              });
                            },
                          ),
                          SizedBox(width: 6.w),
                          _buildActionButton(
                            icon: _isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                            label: '$_dislikeCount',
                            isActive: _isDisliked,
                            onTap: () {
                              setState(() {
                                _isDisliked = !_isDisliked;
                                if (_isDisliked) {
                                  _dislikeCount++;
                                  if (_isLiked) {
                                    _isLiked = false;
                                    _likeCount--;
                                  }
                                } else {
                                  _dislikeCount--;
                                }
                              });
                            },
                          ),
                          SizedBox(width: 6.w),
                          _buildActionButton(
                            icon: Icons.download_rounded,
                            label: 'Tải về',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đang tải xuống video về máy... 📥'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 6.w),
                          _buildActionButton(
                            icon: Icons.share_rounded,
                            label: 'Chia sẻ',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép liên kết chia sẻ! 🔗'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 6.w),
                          _buildActionButton(
                            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            label: 'Lưu',
                            isActive: _isSaved,
                            onTap: () {
                              setState(() {
                                _isSaved = !_isSaved;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isSaved ? 'Đã lưu video vào danh sách! 💾' : 'Đã hủy lưu video!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Video Description Card ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nội dung video',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _activeDescription,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Playlist Card ("Danh sách phát") ──
                    Text(
                      'Danh sách phát',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._relatedVideos.map((item) => _buildRelatedVideoItem(item)),
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF475569),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedVideoItem(_RelatedVideo item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTitle = item.title;
          _activeDescription = item.description;
          _activeImagePath = item.imagePath;
          _activeViews = item.views;
          _activeDate = item.time;
          _isPlaying = false;
          _currentSliderValue = 0.0;
          _totalDuration = _parseDuration(item.duration);
        });
        _initVideoPlayer(null);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with duration badge
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                children: [
                  Container(
                    width: 120.w,
                    height: 72.h,
                    color: const Color(0xFFF1F5F9),
                    child: item.imagePath.startsWith('http')
                        ? Image.network(
                            DocItem.optimizeUrl(item.imagePath, width: 200),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            item.imagePath,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    bottom: 4.h,
                    right: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        item.duration,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Title & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${item.views} • ${item.time}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // More menu icon
            Icon(
              Icons.more_horiz_rounded,
              color: const Color(0xFF94A3B8),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Báo cáo vi phạm'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cảm ơn con đã báo cáo! Chúng tôi sẽ xem xét.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed_rounded),
                title: const Text('Tốc độ phát'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng thay đổi tốc độ đang được cập nhật!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.subtitles_outlined),
                title: const Text('Phụ đề'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RelatedVideo {
  final String title;
  final String duration;
  final String views;
  final String time;
  final String imagePath;
  final String description;

  const _RelatedVideo({
    required this.title,
    required this.duration,
    required this.views,
    required this.time,
    required this.imagePath,
    required this.description,
  });
}
