import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'data/local/local_database.dart';
import 'services/connectivity_service.dart';
import 'services/sync_manager.dart';
import 'services/auth_service.dart';

/// Điểm khởi đầu ứng dụng KhmerKid
/// Học chữ Khmer cho trẻ em tiểu học
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Khởi tạo Hybrid Offline-First Architecture ──────────────
  // 0. Dò tìm IP máy chủ đang hoạt động (IP đã lưu → danh sách → quét subnet).
  //    Bọc timeout tổng để không kẹt splash khi mạng không có server.
  await AuthService.detectActiveServer().timeout(
    const Duration(seconds: 8),
    onTimeout: () {
      debugPrint('⏱️ [main] Dò server quá lâu, tiếp tục khởi động app.');
    },
  );

  // 1. Mở Isar local database + migrate từ SharedPreferences
  await LocalDatabase.init();
  // 2. Khởi tạo connectivity monitoring
  await ConnectivityService.instance.init();
  // 3. Khởi tạo SyncManager (auto sync khi online)
  await SyncManager.instance.init();

  // Cố định hướng màn hình dọc
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cấu hình thanh trạng thái
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const KhmerKidApp());
}

class KhmerKidApp extends StatelessWidget {
  const KhmerKidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'KhmerKid - Học chữ Khmer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

