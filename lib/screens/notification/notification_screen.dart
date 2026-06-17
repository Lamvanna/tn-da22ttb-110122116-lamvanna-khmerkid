import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await NotificationService().fetchNotifications();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _notifications = res['data'] as List<AppNotification>;
        } else {
          _errorMessage = res['message'] ?? 'Không thể tải thông báo';
        }
      });
    }
  }

  Future<void> _markAsRead(AppNotification note) async {
    if (note.isRead) return;

    // Optimistically update UI
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: note.id,
          userId: note.userId,
          title: note.title,
          message: note.message,
          type: note.type,
          isRead: true,
          createdAt: note.createdAt,
        );
      }
    });

    final res = await NotificationService().markAsRead(note.id);
    if (res['success'] != true && mounted) {
      // Revert if failed
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notifications[index] = note;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty || _notifications.every((n) => n.isRead)) return;

    final original = List<AppNotification>.from(_notifications);

    // Optimistically update UI
    setState(() {
      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
    });

    final res = await NotificationService().markAllAsRead();
    if (res['success'] != true && mounted) {
      // Revert if failed
      setState(() {
        _notifications = original;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Có lỗi xảy ra')),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative) {
      return 'Vừa xong';
    }
    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1E293B), size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông báo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Đọc tất cả',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0084FF),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF0084FF),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 150.h),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Hộp thư trống',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Bạn không có thông báo nào lúc này.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 14.h, bottom: 40.h),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final note = _notifications[index];
        return _buildNotificationItem(note);
      },
    );
  }

  Widget _buildNotificationItem(AppNotification note) {
    bool isRead = note.isRead;
    return GestureDetector(
      onTap: () => _markAsRead(note),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h, left: 16.w, right: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF4F9FF),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isRead ? const Color(0xFFF1F5F9) : const Color(0xFFBFDBFE),
            width: isRead ? 1.w : 1.5.w,
          ),
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
            _buildIcon(note.type),
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
                          note.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5.sp,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            color: isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: EdgeInsets.only(left: 8.w, top: 4.h),
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0084FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0084FF).withValues(alpha: 0.4),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    note.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5.sp,
                      color: isRead ? const Color(0xFF64748B) : const Color(0xFF475569),
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
                        _formatTime(note.createdAt),
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
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData iconData;
    Color color;
    Color bgColor;

    switch (type) {
      case 'level_up':
        iconData = Icons.rocket_launch_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'daily_reminder':
      case 'reminder':
        iconData = Icons.access_alarm_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'reward':
      case 'quest':
        iconData = Icons.check_circle_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case 'badge_unlocked':
      case 'badge':
        iconData = Icons.military_tech_rounded;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case 'unlock':
        iconData = Icons.lock_open_rounded;
        color = const Color(0xFFEC4899);
        bgColor = const Color(0xFFFCE7F3);
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        color = const Color(0xFF0084FF);
        bgColor = const Color(0xFFE5F3FF);
    }

    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Icon(iconData, color: color, size: 26.sp),
    );
  }
}
