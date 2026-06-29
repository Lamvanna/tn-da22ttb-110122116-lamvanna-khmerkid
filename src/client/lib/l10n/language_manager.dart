import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/storage_service.dart';
import 'models/language_model.dart';

/// Quản lý trạng thái Đa ngôn ngữ (i18n) cho ứng dụng
/// Hỗ trợ nạp ngôn ngữ động từ JSON, lưu/khôi phục tùy chọn người dùng và thay đổi realtime
class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  static LanguageManager get instance => _instance;

  Locale _currentLocale = const Locale('vi');
  List<LanguageModel> _supportedLanguages = [];
  bool _initialized = false;

  Locale get currentLocale => _currentLocale;
  List<LanguageModel> get supportedLanguages => _supportedLanguages;
  bool get isInitialized => _initialized;

  /// Lấy cấu hình ngôn ngữ hiện tại
  LanguageModel get currentLanguage {
    return _supportedLanguages.firstWhere(
      (lang) => lang.code == _currentLocale.languageCode,
      orElse: () => LanguageModel(
        code: 'vi',
        flag: '🇻🇳',
        name: 'Vietnamese',
        nativeName: 'Tiếng Việt',
        fontFamily: 'Plus Jakarta Sans',
        isRtl: false,
      ),
    );
  }

  /// Kiểm tra xem ngôn ngữ hiện tại có hướng viết Right-to-Left (RTL) hay không
  bool get isRtl => currentLanguage.isRtl;

  /// Lấy Font Family thích hợp cho ngôn ngữ hiện tại
  String get fontFamily => currentLanguage.fontFamily;

  /// Khởi tạo LanguageManager
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Tải danh sách ngôn ngữ động từ file cấu hình JSON
      String langJsonStr = await rootBundle.loadString('assets/translations/languages.json');
      List<dynamic> langList = jsonDecode(langJsonStr);
      _supportedLanguages = langList.map((item) => LanguageModel.fromJson(item)).toList();
      
      if (_supportedLanguages.isEmpty) {
        throw Exception("No languages parsed from languages.json");
      }

      // 2. Khởi tạo định dạng ngày tháng của gói intl
      await initializeDateFormatting();

      // 3. Khôi phục ngôn ngữ đã lưu từ StorageService (SharedPreferences)
      final storage = await StorageService.getInstance();
      String savedLangCode = storage.getLanguage(); // Mặc định là 'vi' trong storage_service
      
      // Kiểm tra xem ngôn ngữ đã lưu có trong danh sách hỗ trợ không
      bool isSupported = _supportedLanguages.any((lang) => lang.code == savedLangCode);
      if (!isSupported) {
        savedLangCode = 'vi'; // Fallback về vi
      }

      _currentLocale = Locale(savedLangCode);
      _initialized = true;
      debugPrint("🚀 [i18n] LanguageManager initialized with language: $savedLangCode");
    } catch (e) {
      debugPrint("🚨 [i18n] Failed to initialize LanguageManager: $e");
      // Fallback cứng nếu có lỗi nghiêm trọng khi đọc file config
      _supportedLanguages = [
        LanguageModel(code: 'vi', flag: '🇻🇳', name: 'Vietnamese', nativeName: 'Tiếng Việt', fontFamily: 'Plus Jakarta Sans', isRtl: false),
        LanguageModel(code: 'km', flag: '🇰🇭', name: 'Khmer', nativeName: 'ភាសាខ្មែរ', fontFamily: 'Kantumruy Pro', isRtl: false),
        LanguageModel(code: 'en', flag: '🇺🇸', name: 'English', nativeName: 'English', fontFamily: 'Plus Jakarta Sans', isRtl: false),
      ];
      _currentLocale = const Locale('vi');
      _initialized = true;
    }
  }

  /// Thay đổi ngôn ngữ hiện tại của ứng dụng
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;

    // Kiểm tra xem ngôn ngữ có nằm trong danh sách được hỗ trợ không
    final isSupported = _supportedLanguages.any((lang) => lang.code == languageCode);
    if (!isSupported) {
      debugPrint("⚠️ [i18n] Language code '$languageCode' is not supported.");
      return;
    }

    _currentLocale = Locale(languageCode);

    // Lưu vào SharedPreferences qua StorageService
    final storage = await StorageService.getInstance();
    await storage.setLanguage(languageCode);

    // Thông báo cho tất cả widget đang lắng nghe rebuild realtime
    notifyListeners();
    debugPrint("🔄 [i18n] Language changed to: $languageCode");
  }
}
