/// Model biểu diễn cấu trúc của một ngôn ngữ được hỗ trợ
class LanguageModel {
  final String code;
  final String flag;
  final String name;
  final String nativeName;
  final String fontFamily;
  final bool isRtl;

  LanguageModel({
    required this.code,
    required this.flag,
    required this.name,
    required this.nativeName,
    required this.fontFamily,
    required this.isRtl,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] as String? ?? 'en',
      flag: json['flag'] as String? ?? '🇺🇸',
      name: json['name'] as String? ?? 'English',
      nativeName: json['nativeName'] as String? ?? 'English',
      fontFamily: json['fontFamily'] as String? ?? 'Plus Jakarta Sans',
      isRtl: json['isRtl'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'flag': flag,
      'name': name,
      'nativeName': nativeName,
      'fontFamily': fontFamily,
      'isRtl': isRtl,
    };
  }

  @override
  String toString() => 'LanguageModel($code - $nativeName)';
}
