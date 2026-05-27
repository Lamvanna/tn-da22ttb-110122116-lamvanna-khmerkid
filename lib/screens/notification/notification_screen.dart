import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Sample data cho thông báo
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Chúc mừng lên cấp! 🎉',
      'body': 'Bạn đã đạt Cấp 6. Hãy tiếp tục giữ vững phong độ nhé!',
      'time': '5 phút trước',
      'isRead': false,
      'type': 'level_up',
    },
    {
      'title': 'Nhắc nhở học tập',
      'body': 'Đã đến giờ luyện tập rồi! Vào làm vài bài tập để duy trì chuỗi ngày học nhé.',
      'time': '2 giờ trước',
      'isRead': false,
      'type': 'reminder',
    },
    {
      'title': 'Nhiệm vụ hàng ngày hoàn thành',
      'body': 'Bạn đã hoàn thành tất cả nhiệm vụ ngày hôm nay và nhận được 50 XP.',
      'time': 'Hôm qua',
      'isRead': true,
      'type': 'quest',
    },
    {
      'title': 'Mở khóa bài học mới 🔓',
      'body': 'Bài học "Nguyên âm mới" đã được mở. Khám phá ngay nào!',
      'time': 'Hôm qua',
      'isRead': true,
      'type': 'unlock',
    },
    {
      'title': 'Huy hiệu mới đạt được 🌟',
      'body': 'Bạn vừa nhận được huy hiệu "Chăm chỉ tuần này". Tuyệt vời!',
      'time': '3 ngày trước',
      'isRead': true,
      'type': 'badge',
    },
  ];

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
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isRead'] = true;
                }
              });
            },
            child: Text(
              'Đọc tất cả',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF3B82F6),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(top: 10.h, bottom: 40.h),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final note = _notifications[index];
          return _buildNotificationItem(note);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> note) {
    bool isRead = note['isRead'];
    return GestureDetector(
      onTap: () {
        if (!isRead) {
          setState(() {
            note['isRead'] = true;
          });
        }
      },
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
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(note['type']),
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
                          note['title'],
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
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.4),
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
                    note['body'],
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
                        note['time'],
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
      case 'reminder':
        iconData = Icons.access_alarm_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'quest':
        iconData = Icons.check_circle_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        break;
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
      default:
        iconData = Icons.notifications_rounded;
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Icon(iconData, color: color, size: 26.sp),
    );
  }
}
