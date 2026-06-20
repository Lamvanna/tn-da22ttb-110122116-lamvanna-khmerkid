import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Khởi tạo hệ thống thông báo local
  Future<void> init() async {
    if (_isInitialized) return;

    // Khởi tạo cơ sở dữ liệu múi giờ và cấu hình múi giờ Việt Nam
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      debugPrint('⚠️ [LocalNotificationService] Timezone fallback to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // Cấu hình cho Android
    // Sử dụng ic_launcher làm icon mặc định cho thông báo
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình cho iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('🔔 [LocalNotificationService] Notification tapped: ${details.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('✅ [LocalNotificationService] Initialized successfully');
      
      // Yêu cầu quyền thông báo (đặc biệt cho Android 13+)
      await requestPermissions();
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Initialization error: $e');
    }
  }

  /// Yêu cầu quyền gửi thông báo
  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? grantedNotification = await androidImplementation.requestNotificationsPermission();
        final bool? grantedExactAlarm = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('🔔 [LocalNotificationService] Android Permissions - Notification: $grantedNotification, ExactAlarm: $grantedExactAlarm');
      }

      final iosImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('🔔 [LocalNotificationService] iOS Permissions: $granted');
      }
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error requesting permissions: $e');
    }
  }

  /// Hiển thị thông báo ngay lập tức
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminder_channel', // id
      'Nhắc học', // name
      channelDescription: 'Thông báo nhắc nhở bé học tập hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      largeIcon: const DrawableResourceAndroidBitmap('app_logo'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
      debugPrint('🔔 [LocalNotificationService] Showed notification: $title');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error showing notification: $e');
    }
  }

  /// Lên lịch thông báo tại một thời điểm cụ thể
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('⚠️ [LocalNotificationService] Scheduled date $scheduledDate is in the past. Skip scheduling.');
      return;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminder_channel',
      'Nhắc học',
      channelDescription: 'Thông báo nhắc nhở bé học tập hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: const DrawableResourceAndroidBitmap('app_logo'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    try {
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      await _localNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('🔔 [LocalNotificationService] Scheduled notification "$title" at $scheduledDate');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error scheduling notification: $e');
    }
  }

  /// Hủy một thông báo theo ID
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotificationsPlugin.cancel(id: id);
      debugPrint('🔔 [LocalNotificationService] Cancelled notification ID: $id');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error cancelling notification: $e');
    }
  }

  /// Hủy tất cả các thông báo nhắc nhở
  Future<void> cancelAllReminders() async {
    try {
      await _localNotificationsPlugin.cancelAll();
      debugPrint('🔔 [LocalNotificationService] Cancelled all local notifications');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error cancelling all notifications: $e');
    }
  }

  /// Lên lịch nhắc nhở học tập offline hàng ngày (chạy dự phòng khi không có mạng)
  Future<void> scheduleDailyReminders({required bool studiedToday}) async {
    if (!_isInitialized) await init();

    // 1. Hủy toàn bộ thông báo nhắc học cũ tránh bị lặp hoặc sai lệch
    await cancelAllReminders();

    final now = DateTime.now();

    // Nếu hôm nay bé chưa học, lên lịch nhắc cho buổi tối hôm nay
    if (!studiedToday) {
      // 18:00 hôm nay
      final reminder1 = DateTime(now.year, now.month, now.day, 18, 0);
      if (reminder1.isAfter(now)) {
        await scheduleNotification(
          id: 1800,
          title: '🐘 Voi con đợi bé',
          body: 'Bé ơi, đến giờ cùng Voi con học chữ Khmer rồi nè! 💕',
          scheduledDate: reminder1,
        );
      }

      // 20:00 hôm nay
      final reminder2 = DateTime(now.year, now.month, now.day, 20, 0);
      if (reminder2.isAfter(now)) {
        await scheduleNotification(
          id: 2000,
          title: '🌟 Chỉ 5 phút thôi',
          body: 'Học một chút trước khi ngủ để nhận thật nhiều sao nhé bé yêu! 🚀',
          scheduledDate: reminder2,
        );
      }
    }

    // Luôn lên lịch nhắc cho ngày mai (18:00 và 20:00)
    final tomorrow = now.add(const Duration(days: 1));
    
    // 18:00 ngày mai
    await scheduleNotification(
      id: 1801,
      title: '🐘 Bạn Voi con đợi bé',
      body: 'Voi con đang chờ học cùng bé đó! Mình học một chút nha. 🍀',
      scheduledDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0),
    );

    // 20:00 ngày mai
    await scheduleNotification(
      id: 2001,
      title: '🚀 Cuộc phiêu lưu học tập',
      body: 'Sẵn sàng chưa? Cuộc phiêu lưu học tập đang chờ bé đó! ✨',
      scheduledDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 0),
    );
  }
}
