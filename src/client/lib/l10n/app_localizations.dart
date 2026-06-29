import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Lớp xử lý dịch thuật (Localization) chính của ứng dụng
/// Sử dụng file JSON để tải nội dung dịch động và hỗ trợ các tiện ích định dạng từ package `intl`
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, dynamic> _localizedStrings;

  /// Tải file dịch thuật JSON từ thư mục assets/translations/
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _localizedStrings = jsonMap;
      return true;
    } catch (e) {
      debugPrint("⚠️ [i18n] Error loading translation file for '${locale.languageCode}': $e");
      // Fallback về tiếng Việt nếu file không tồn tại hoặc bị lỗi
      try {
        debugPrint("🔄 [i18n] Falling back to 'vi' translation");
        String fallbackString = await rootBundle.loadString('assets/translations/vi.json');
        _localizedStrings = jsonDecode(fallbackString);
        return true;
      } catch (ex) {
        debugPrint("🚨 [i18n] Critical error loading fallback translation: $ex");
        _localizedStrings = {};
        return false;
      }
    }
  }

  /// Dịch chuỗi thông thường theo khóa (key)
  /// Hỗ trợ Nested Key dạng `settings.title`
  /// Hỗ trợ truyền tham số dạng `{"name": "Bé"}` để thay thế `{name}` trong chuỗi dịch
  String translate(String key, {Map<String, dynamic>? args}) {
    dynamic value = _getValue(key);
    if (value == null) {
      debugPrint("🔍 [i18n] Missing translation key: '$key' for locale '${locale.languageCode}'");
      return key;
    }
    
    String text = value.toString();
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }

  /// Lấy giá trị từ chuỗi JSON thông qua đường dẫn lồng nhau
  dynamic _getValue(String key) {
    List<String> keys = key.split('.');
    dynamic current = _localizedStrings;
    for (String k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Dịch số nhiều (Pluralization)
  /// JSON định nghĩa dạng:
  /// "stars_count": {
  ///   "zero": "0 ngôi sao",
  ///   "one": "1 ngôi sao",
  ///   "other": "{count} ngôi sao"
  /// }
  String translatePlural(String key, num count, {Map<String, dynamic>? args}) {
    dynamic value = _getValue(key);
    if (value == null) {
      debugPrint("🔍 [i18n] Missing plural translation key: '$key'");
      return key;
    }

    if (value is! Map) {
      // Nếu key không phải là Map, trả về chuỗi thông thường
      return translate(key, args: args);
    }

    String pluralRule;
    if (count == 0) {
      pluralRule = 'zero';
    } else if (count == 1) {
      pluralRule = 'one';
    } else {
      pluralRule = 'other';
    }

    // Fallback sang 'other' nếu rule cụ thể (ví dụ: zero, one) không được khai báo trong JSON
    dynamic textValue = value[pluralRule] ?? value['other'] ?? key;
    String text = textValue.toString();

    // Thay thế `{count}` mặc định
    text = text.replaceAll('{count}', count.toString());

    // Thay thế các tham số khác nếu có
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }

  // =========================================================================
  //  ĐỊNH DẠNG HÓA (LOCALIZATION FORMATTING) SỬ DỤNG PACKAGE INTL
  // =========================================================================

  /// Định dạng Ngày giờ theo Locale hiện tại
  /// [format] là chuỗi định dạng (ví dụ: 'yMMMd', 'EEEE', 'dd/MM/yyyy'...)
  String formatDate(DateTime dateTime, {String format = 'yMMMd'}) {
    try {
      return DateFormat(format, locale.toString()).format(dateTime);
    } catch (_) {
      // Dự phòng nếu locale string chưa được khởi tạo trong intl
      return DateFormat(format, 'vi').format(dateTime);
    }
  }

  /// Định dạng Số theo Locale hiện tại (phân cách hàng nghìn, hàng thập phân)
  String formatNumber(num number, {String? pattern}) {
    try {
      final formatter = pattern != null 
          ? NumberFormat(pattern, locale.toString())
          : NumberFormat.decimalPattern(locale.toString());
      return formatter.format(number);
    } catch (_) {
      final formatter = pattern != null 
          ? NumberFormat(pattern, 'vi')
          : NumberFormat.decimalPattern('vi');
      return formatter.format(number);
    }
  }

  /// Định dạng Tiền tệ theo Locale hiện tại
  /// [currencyCode] ví dụ: 'VND', 'USD', 'KHR' (Riel Khmer)
  String formatCurrency(num amount, {String? currencyCode}) {
    try {
      final formatter = NumberFormat.simpleCurrency(
        locale: locale.toString(),
        name: currencyCode,
      );
      return formatter.format(amount);
    } catch (_) {
      final formatter = NumberFormat.simpleCurrency(
        locale: 'vi',
        name: currencyCode,
      );
      return formatter.format(amount);
    }
  }
}

/// Delegate chịu trách nhiệm khởi tạo AppLocalizations
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Trả về true để chấp nhận tất cả các locales được cấu hình động từ JSON.
    // Việc xử lý lỗi load/fallback sẽ được thực hiện bên trong hàm load() của AppLocalizations.
    return true;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

/// Helper extension để gọi nhanh hơn trong giao diện: `context.translate('key')` hoặc `context.l10n.translate('key')`
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n {
    return AppLocalizations.of(this) ?? AppLocalizations(const Locale('vi'));
  }

  String translate(String key, {Map<String, dynamic>? args}) {
    return l10n.translate(key, args: args);
  }

  String translatePlural(String key, num count, {Map<String, dynamic>? args}) {
    return l10n.translatePlural(key, count, args: args);
  }

  String translateBadgeName(String name) {
    switch (name) {
      case 'Bước đầu tiên': return translate('achievements.first_step');
      case 'Nhà ngôn ngữ nhí': return translate('achievements.young_linguist');
      case 'Bậc thầy phụ âm': return translate('achievements.consonant_master');
      case 'Khám phá nguyên âm': return translate('achievements.vowel_explorer');
      case 'Vua nguyên âm': return translate('achievements.vowel_king');
      case 'Chính tả giỏi': return translate('achievements.good_spelling');
      case 'Phát âm chuẩn': return translate('achievements.correct_pronunciation');
      case 'Tai thính': return translate('achievements.sharp_hearing');
      case 'Viết chữ đẹp': return translate('achievements.beautiful_writing');
      case 'Ngôi sao đầu tiên': return translate('achievements.first_star');
      case 'Sao sáng': return translate('achievements.bright_star');
      case 'Siêu sao': return translate('achievements.super_star');
      case 'Chăm chỉ': return translate('achievements.hard_working');
      case 'Kiên trì': return translate('achievements.persistent');
      case 'Game thủ nhí': return translate('achievements.young_gamer');
      case 'Vô địch mini game': return translate('achievements.mini_game_champion');
      case 'Tốc độ ánh sáng': return translate('achievements.speed_of_light');
      case 'Hoàn hảo': return translate('achievements.perfect');
      case 'Nhà vô địch': return translate('achievements.champion');
      case 'Bậc thầy Khmer': return translate('achievements.khmer_master');
      case 'Kiên trì học tập': return translate('achievements.streak_5');
      case 'Nhà sưu tầm sao': return translate('achievements.star_collector');
      case 'Bậc thầy trò chơi': return translate('achievements.game_master');
      default: return name;
    }
  }

  String translateBadgeDesc(String name, String desc) {
    switch (name) {
      case 'Bước đầu tiên': return translate('achievements.first_step_desc');
      case 'Nhà ngôn ngữ nhí': return translate('achievements.young_linguist_desc');
      case 'Bậc thầy phụ âm': return translate('achievements.consonant_master_desc');
      case 'Khám phá nguyên âm': return translate('achievements.vowel_explorer_desc');
      case 'Vua nguyên âm': return translate('achievements.vowel_king_desc');
      case 'Chính tả giỏi': return translate('achievements.good_spelling_desc');
      case 'Phát âm chuẩn': return translate('achievements.correct_pronunciation_desc');
      case 'Tai thính': return translate('achievements.sharp_hearing_desc');
      case 'Viết chữ đẹp': return translate('achievements.beautiful_writing_desc');
      case 'Ngôi sao đầu tiên': return translate('achievements.first_star_desc');
      case 'Sao sáng': return translate('achievements.bright_star_desc');
      case 'Siêu sao': return translate('achievements.super_star_desc');
      case 'Chăm chỉ': return translate('achievements.hard_working_desc');
      case 'Kiên trì': return translate('achievements.persistent_desc');
      case 'Game thủ nhí': return translate('achievements.young_gamer_desc');
      case 'Vô địch mini game': return translate('achievements.mini_game_champion_desc');
      case 'Tốc độ ánh sáng': return translate('achievements.speed_of_light_desc');
      case 'Hoàn hảo': return translate('achievements.perfect_desc');
      case 'Nhà vô địch': return translate('achievements.champion_desc');
      case 'Bậc thầy Khmer': return translate('achievements.khmer_master_desc');
      case 'Kiên trì học tập': return translate('achievements.streak_5_desc');
      case 'Nhà sưu tầm sao': return translate('achievements.star_collector_desc');
      case 'Bậc thầy trò chơi': return translate('achievements.game_master_desc');
      default: return desc;
    }
  }

  String translateQuestTitle(String title) {
    if (title.contains('Nhà thông thái nhí')) return translate('tasks.mock_d1_title');
    if (title.contains('Luyện viết chữ đẹp')) return translate('tasks.mock_d2_title');
    if (title.contains('Đôi tai nhạy bén')) return translate('tasks.mock_d3_title');
    if (title.contains('Giọng ca oanh vàng')) return translate('tasks.mock_d4_title');
    if (title.contains('Vừa học vừa chơi')) return translate('tasks.mock_d5_title');
    if (title.contains('Điểm số hoàn hảo')) return translate('tasks.mock_d6_title');
    if (title.contains('Khởi đầu ngày mới')) return translate('tasks.mock_d7_title');
    if (title.contains('Thợ săn sao vàng')) return translate('tasks.mock_d8_title');
    if (title.contains('Trí nhớ siêu đỉnh')) return translate('tasks.mock_d9_title');
    if (title.contains('Gặp gỡ bạn bè')) return translate('tasks.mock_d10_title');
    if (title.contains('Chuỗi ngày vàng')) return translate('tasks.mock_w1_title');
    if (title.contains('Đại sứ vựng')) return translate('tasks.mock_w2_title');
    if (title.contains('Cao thủ trò chơi')) return translate('tasks.mock_w3_title');
    if (title.contains('Cơn mưa quà tặng')) return translate('tasks.mock_w4_title');
    if (title.contains('Bàn tay khéo léo')) return translate('tasks.mock_w5_title');
    return title;
  }

  String translateQuestDesc(String title, String defaultDesc) {
    if (title.contains('Nhà thông thái nhí')) return translate('tasks.mock_d1_desc');
    if (title.contains('Luyện viết chữ đẹp')) return translate('tasks.mock_d2_desc');
    if (title.contains('Đôi tai nhạy bén')) return translate('tasks.mock_d3_desc');
    if (title.contains('Giọng ca oanh vàng')) return translate('tasks.mock_d4_desc');
    if (title.contains('Vừa học vừa chơi')) return translate('tasks.mock_d5_desc');
    if (title.contains('Điểm số hoàn hảo')) return translate('tasks.mock_d6_desc');
    if (title.contains('Khởi đầu ngày mới')) return translate('tasks.mock_d7_desc');
    if (title.contains('Thợ săn sao vàng')) return translate('tasks.mock_d8_desc');
    if (title.contains('Trí nhớ siêu đỉnh')) return translate('tasks.mock_d9_desc');
    if (title.contains('Gặp gỡ bạn bè')) return translate('tasks.mock_d10_desc');
    if (title.contains('Chuỗi ngày vàng')) return translate('tasks.mock_w1_desc');
    if (title.contains('Đại sứ vựng')) return translate('tasks.mock_w2_desc');
    if (title.contains('Cao thủ trò chơi')) return translate('tasks.mock_w3_desc');
    if (title.contains('Cơn mưa quà tặng')) return translate('tasks.mock_w4_desc');
    if (title.contains('Bàn tay khéo léo')) return translate('tasks.mock_w5_desc');
    return defaultDesc;
  }

  String translateShopItemName(String id, String defaultName) {
    final key = 'shop.item_name_$id';
    final translated = translate(key);
    return translated != key ? translated : defaultName;
  }

  String translateShopItemDesc(String id, String defaultDesc) {
    final key = 'shop.item_desc_$id';
    final translated = translate(key);
    return translated != key ? translated : defaultDesc;
  }
}

