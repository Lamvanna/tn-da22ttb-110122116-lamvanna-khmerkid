import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'data/local/local_database.dart';
import 'services/connectivity_service.dart';
import 'services/sync_manager.dart';
import 'services/auth_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_manager.dart';
import 'services/local_notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'repositories/progress_repository.dart';

/// Điểm khởi đầu ứng dụng KhmerKid
/// Học chữ Khmer cho trẻ em tiểu học
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi chạy các tác vụ khởi tạo độc lập song song để tối ưu hóa thời gian khởi động
  await Future.wait([
    LocalDatabase.init(),
    ConnectivityService.instance.init(),
    LanguageManager.instance.init(),
    LocalNotificationService().init(),
  ]);

  // 2. Khởi tạo SyncManager sau khi Database và Connectivity đã sẵn sàng
  await SyncManager.instance.init();

  // 3. Dò tìm máy chủ và tiến hành tự động đăng nhập nhanh trước khi khởi chạy giao diện
  bool isLoggedIn = false;
  bool isAdmin = false;
  
  // Dò tìm máy chủ trong thời gian ngắn (tối đa 1200ms), không chặn luồng chính nếu lỗi hoặc quá hạn
  try {
    await AuthService.detectActiveServer().timeout(
      const Duration(milliseconds: 1200),
    ).catchError((e) {
      debugPrint('⚠️ Dò tìm máy chủ quá thời gian hoặc gặp lỗi: $e');
      return null;
    });
  } catch (e) {
    debugPrint('⚠️ Lỗi dò tìm máy chủ: $e');
  }

  // Tiến hành tự động đăng nhập (hỗ trợ chế độ offline tự động nếu máy chủ không hoạt động)
  try {
    isLoggedIn = await AuthService().tryAutoLogin();
    if (isLoggedIn) {
      final profile = AuthService().userProfile;
      isAdmin = profile?['role'] == 'admin';

      if (!isAdmin) {
        try {
          final studied = await ProgressRepository.instance.hasStudiedToday();
          await LocalNotificationService().scheduleDailyReminders(studiedToday: studied);
        } catch (e) {
          debugPrint('⚠️ Lỗi lên lịch nhắc học: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ Lỗi tự động đăng nhập khi khởi động: $e');
  }

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

  runApp(KhmerKidApp(isLoggedIn: isLoggedIn, isAdmin: isAdmin));
}

class KhmerKidApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isAdmin;

  const KhmerKidApp({
    super.key,
    required this.isLoggedIn,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: LanguageManager.instance,
          builder: (context, _) {
            final manager = LanguageManager.instance;
            return MaterialApp(
              title: 'KhmerKid - Học chữ Khmer',
              debugShowCheckedModeBanner: false,
              locale: manager.currentLocale,
              supportedLocales: manager.supportedLanguages
                  .map((lang) => Locale(lang.code))
                  .toList(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.lightTheme.copyWith(
                textTheme: GoogleFonts.getTextTheme(
                  manager.fontFamily,
                  AppTheme.lightTheme.textTheme,
                ),
              ),
              home: isLoggedIn
                  ? (isAdmin ? const AdminMainScreen() : const MainScreen())
                  : const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
