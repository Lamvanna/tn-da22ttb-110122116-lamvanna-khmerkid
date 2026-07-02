import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_header.dart';
import 'category_list_screen.dart';

class SongItem {
  final String titleKhmer;
  final String titleVietnamese;
  final String category;
  final String duration;
  final String image;
  final String lyrics;
  final Color categoryColor;

  const SongItem({
    required this.titleKhmer,
    required this.titleVietnamese,
    required this.category,
    required this.duration,
    required this.image,
    required this.lyrics,
    required this.categoryColor,
  });
}

class SongPlayerScreen extends StatefulWidget {
  final String? initialSongTitle;
  final List<SongItem>? playlist;

  const SongPlayerScreen({
    super.key,
    this.initialSongTitle,
    this.playlist,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> with TickerProviderStateMixin {
  late List<SongItem> _songs;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLooping = false;
  double _playbackSpeed = 1.0;
  double _sliderValue = 45.0; // Starts at 00:45 mock
  late double _maxDurationInSeconds;
  Timer? _playbackTimer;

  // Favorites tracking
  final Set<int> _favorites = {};

  // Animation controller for visualizer
  late AnimationController _visualizerCtrl;

  @override
  void initState() {
    super.initState();
    _initPlaylist();
    _initVisualizer();
    _selectInitialSong();
  }

  void _initPlaylist() {
    _songs = [
      const SongItem(
        titleKhmer: 'ក្មេងៗ ច្រៀងលេង',
        titleVietnamese: 'Trẻ em ca hát vui đùa',
        category: 'Vui nhộn',
        duration: '02:35',
        image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png',
        categoryColor: Color(0xFF4CAF50),
        lyrics: 'ក្មេងៗ ច្រៀងលេង ច្រៀងលេង\nសប្បាយ សប្បាយ សប្បាយណាស់\nយើងរាំ យើងច្រៀង\nសប្បាយណាស់ថ្ងៃនេះ!',
      ),
      const SongItem(
        titleKhmer: 'ដំរីតូច',
        titleVietnamese: 'Chú voi con',
        category: 'Động vật',
        duration: '01:58',
        image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
        categoryColor: Color(0xFF2196F3),
        lyrics: 'ដំរី ដំរី ដំរីតូច\nមានច្រមុះវែង ត្រចៀកធំ\nដើរលេងក្នុងព្រៃជ្រៅ\nសប្បាយរីករាយណាស់!',
      ),
      const SongItem(
        titleKhmer: 'គេងលក់ យប់នេះ',
        titleVietnamese: 'Đi ngủ nào bé ơi',
        category: 'Giấc ngủ',
        duration: '02:12',
        image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png',
        categoryColor: Color(0xFF9C27B0),
        lyrics: 'គេងលក់ គេងលក់ កូនសម្លាញ់\nយប់នេះមានផ្កាយភ្លឺល្អ\nបិទភ្នែកគេងលក់ទៅ\nយល់សប្តិឃើញរឿងល្អ។',
      ),
      const SongItem(
        titleKhmer: 'ខ្ញុំស្រឡាញ់គ្រួសារ',
        titleVietnamese: 'Em yêu gia đình',
        category: 'Gia đình',
        duration: '02:48',
        image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png',
        categoryColor: Color(0xFFFF9800),
        lyrics: 'ខ្ញុំស្រឡាញ់ប៉ាម៉ាក់\nខ្ញុំស្រឡាញ់បងប្អូន\nគ្រួសារយើងសប្បាយ\nរស់នៅក្បែរគ្នានិច្ច។',
      ),
    ];
  }

  void _initVisualizer() {
    _visualizerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _selectInitialSong() {
    if (widget.initialSongTitle != null) {
      final idx = _songs.indexWhere((s) =>
          s.titleVietnamese.toLowerCase().contains(widget.initialSongTitle!.toLowerCase()) ||
          s.titleKhmer.toLowerCase().contains(widget.initialSongTitle!.toLowerCase()));
      if (idx != -1) {
        _currentIndex = idx;
      }
    }
    _updateMaxDuration();
  }

  void _updateMaxDuration() {
    final durParts = _songs[_currentIndex].duration.split(':');
    final min = int.parse(durParts[0]);
    final sec = int.parse(durParts[1]);
    _maxDurationInSeconds = (min * 60 + sec).toDouble();
    _sliderValue = 0.0;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _visualizerCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _visualizerCtrl.repeat(reverse: true);
        _startTimer();
      } else {
        _visualizerCtrl.stop();
        _playbackTimer?.cancel();
      }
    });
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(Duration(milliseconds: (1000 / _playbackSpeed).round()), (timer) {
      if (!mounted) return;
      setState(() {
        if (_sliderValue < _maxDurationInSeconds) {
          _sliderValue += 1.0;
        } else {
          if (_isLooping) {
            _sliderValue = 0.0;
          } else {
            _isPlaying = false;
            _visualizerCtrl.stop();
            _playbackTimer?.cancel();
            _nextSong();
          }
        }
      });
    });
  }

  void _nextSong() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _songs.length;
      _updateMaxDuration();
      if (_isPlaying) {
        _startTimer();
      }
    });
  }

  void _prevSong() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
      _updateMaxDuration();
      if (_isPlaying) {
        _startTimer();
      }
    });
  }

  void _changeSpeed(double change) {
    setState(() {
      _playbackSpeed = (_playbackSpeed + change).clamp(0.5, 2.0);
      if (_isPlaying) {
        _startTimer(); // Restart timer with new speed
      }
    });
  }

  String _formatDuration(double totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _songs[_currentIndex];
    final isFav = _favorites.contains(_currentIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F2FD), // Premium soft lavender background
      body: Column(
        children: [
          AppHeader(
            title: 'Bài hát thiếu nhi 🎵',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  // ── Top Player Card ──
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h), // Optimized horizontal spacing
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                          blurRadius: 24.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Row: Image + Text info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover art - PERFECT SQUARE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: Container(
                                width: 120.w,
                                height: 120.w, // Perfect square container
                                color: const Color(0xFFEFF6FF),
                                child: Image.network(
                                  DocItem.optimizeUrl(currentSong.image, width: 300),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Text info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + Star Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          currentSong.titleKhmer,
                                          style: GoogleFonts.battambang(
                                            fontSize: 20.sp, // Standout Khmer title
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF6C5CE7),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isFav) {
                                              _favorites.remove(_currentIndex);
                                            } else {
                                              _favorites.add(_currentIndex);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 4.w, top: 2.h),
                                          child: Icon(
                                            isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: isFav ? const Color(0xFFFFD700) : const Color(0xFFCBD5E1),
                                            size: 24.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '(${currentSong.titleVietnamese})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8896AB),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  // Metadata pills
                                  Row(
                                    children: [
                                      // Category badge
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: currentSong.categoryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Text(
                                          currentSong.category,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w800,
                                            color: currentSong.categoryColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      // Duration
                                      Icon(Icons.access_time_rounded, size: 13.sp, color: const Color(0xFF94A3B8)),
                                      SizedBox(width: 4.w),
                                      Text(
                                        currentSong.duration,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  // Lyrics preview
                                  Text(
                                    currentSong.lyrics,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.battambang(
                                      fontSize: 12.sp,
                                      height: 1.55,
                                      color: const Color(0xFF334155),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h), // Better breathing room
                        // Slider + Timers Row
                        Row(
                          children: [
                            Text(
                              _formatDuration(_sliderValue),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6C5CE7),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 5.h,
                                  activeTrackColor: const Color(0xFF6C5CE7),
                                  inactiveTrackColor: const Color(0xFFE2E8F0),
                                  thumbColor: const Color(0xFF6C5CE7),
                                  overlayColor: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                                ),
                                child: Slider(
                                  value: _sliderValue.clamp(0.0, _maxDurationInSeconds),
                                  min: 0.0,
                                  max: _maxDurationInSeconds,
                                  onChanged: (val) {
                                    setState(() {
                                      _sliderValue = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Text(
                              currentSong.duration,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8896AB),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Loop/Repeat
                            _buildControlIcon(
                              icon: _isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                              label: 'Lặp lại',
                              active: _isLooping,
                              onTap: () {
                                setState(() {
                                  _isLooping = !_isLooping;
                                });
                              },
                            ),
                            // Lyrics toggle mock
                            _buildControlIcon(
                              icon: Icons.lyrics_rounded,
                              label: 'Nghe lời',
                              active: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đang phát lời tiếng Khmer 🎙️')),
                                );
                              },
                            ),
                            // Previous
                            GestureDetector(
                              onTap: _prevSong,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                                child: Icon(Icons.skip_previous_rounded, size: 32.sp, color: const Color(0xFF6C5CE7)),
                              ),
                            ),
                            // Play/Pause circular - Standout Size
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF6C5CE7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                              ),
                            ),
                            // Next
                            GestureDetector(
                              onTap: _nextSong,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                                child: Icon(Icons.skip_next_rounded, size: 32.sp, color: const Color(0xFF6C5CE7)),
                              ),
                            ),
                            // Slow speed
                            _buildControlIcon(
                              icon: Icons.slow_motion_video_rounded,
                              label: 'Chậm lại',
                              active: _playbackSpeed < 1.0,
                              onTap: () => _changeSpeed(-0.1),
                            ),
                            // Fast speed
                            _buildControlIcon(
                              icon: Icons.speed_rounded,
                              label: 'Nhanh hơn',
                              active: _playbackSpeed > 1.0,
                              onTap: () => _changeSpeed(0.1),
                            ),
                          ],
                        ),
                        if (_playbackSpeed != 1.0)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              'Tốc độ phát: ${_playbackSpeed.toStringAsFixed(1)}x',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6C5CE7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Bottom List Section ──
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                          blurRadius: 24.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row Header
                        Row(
                          children: [
                            Text(
                              '🎵 Danh sách bài hát',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Xem tất cả',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6C5CE7),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(Icons.chevron_right_rounded, size: 16.sp, color: const Color(0xFF6C5CE7)),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // List of items
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            final isCurrent = _currentIndex == index;
                            final isSongFav = _favorites.contains(index);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentIndex = index;
                                  _updateMaxDuration();
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFFF3F1FF) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  children: [
                                    // Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Container(
                                        width: 55.w,
                                        height: 55.w,
                                        color: const Color(0xFFEFF6FF),
                                        child: Image.network(
                                          DocItem.optimizeUrl(song.image, width: 150),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.titleKhmer,
                                            style: GoogleFonts.battambang(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2C3E50),
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            '(${song.titleVietnamese})',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF8896AB),
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              // Category Tag
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: song.categoryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Text(
                                                  song.category,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 8.5.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: song.categoryColor,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              // Duration
                                              Icon(Icons.access_time_rounded, size: 10.sp, color: const Color(0xFF8896AB)),
                                              SizedBox(width: 3.w),
                                              Text(
                                                song.duration,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9.5.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF8896AB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Visualizer if currently playing
                                    if (isCurrent && _isPlaying)
                                      Padding(
                                        padding: EdgeInsets.only(right: 12.w),
                                        child: AnimatedVisualizer(controller: _visualizerCtrl),
                                      )
                                    else if (isCurrent && !_isPlaying)
                                      Padding(
                                        padding: EdgeInsets.only(right: 12.w),
                                        child: Icon(Icons.equalizer_rounded, color: const Color(0xFF6C5CE7), size: 18.sp),
                                      ),
                                    // Favorite Star
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSongFav) {
                                            _favorites.remove(index);
                                          } else {
                                            _favorites.add(index);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        isSongFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: isSongFav ? const Color(0xFFFFD700) : const Color(0xFFCBD5E1),
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Play icon
                                    Container(
                                      width: 28.w,
                                      height: 28.w,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF6C5CE7),
                                      ),
                                      child: Icon(
                                        isCurrent && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  Widget _buildControlIcon({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22.sp, // Taller and cleaner
            color: active ? const Color(0xFF6C5CE7) : const Color(0xFF94A3B8), // Tailind slate-400
          ),
          SizedBox(height: 4.h), // Better vertical offset
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.sp, // Extremely legible 9.sp (reduced to prevent overlap)
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF6C5CE7) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Visualizer Widget ──
class AnimatedVisualizer extends StatelessWidget {
  final AnimationController controller;

  const AnimatedVisualizer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(15.h, 0.4, 0.8),
            SizedBox(width: 2.w),
            _buildBar(18.h, 0.2, 0.9),
            SizedBox(width: 2.w),
            _buildBar(12.h, 0.5, 0.7),
          ],
        );
      },
    );
  }

  Widget _buildBar(double maxH, double minVal, double speed) {
    // Generate simple dynamic height using controller
    final double animVal = (controller.value * speed) % 1.0;
    final double currentH = minVal * maxH + (1.0 - minVal) * maxH * (0.5 + 0.5 * (animVal * 2.0 - 1.0).abs());

    return Container(
      width: 3.w,
      height: currentH.clamp(2.h, maxH),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7),
        borderRadius: BorderRadius.circular(1.5.r),
      ),
    );
  }
}
