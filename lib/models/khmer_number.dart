/// Model dữ liệu cho số Khmer
class KhmerNumber {
  String? id;           // ID từ MongoDB Atlas
  final String character;     // Ký tự số Khmer (e.g., "០")
  final String value;         // Giá trị số (e.g., "0")
  final String khmerWord;     // Từ Khmer (e.g., "សូន្យ")
  final String romanized;     // Phiên âm Latin (e.g., "soun")
  final String pronunciation; // Phát âm tiếng Việt
  int starRating;       // Số sao (0-5)
  bool isLearned;

  KhmerNumber({
    this.id,
    required this.character,
    required this.value,
    this.khmerWord = '',
    this.romanized = '',
    this.pronunciation = '',
    this.starRating = 0,
    this.isLearned = false,
  });

  factory KhmerNumber.fromJson(Map<String, dynamic> json) {
    return KhmerNumber(
      id: json['_id'] ?? json['id'],
      character: json['khmerText'] ?? json['character'] ?? '',
      value: json['value'] ?? json['romanized'] ?? '',
      khmerWord: json['khmerWord'] ?? '',
      romanized: json['romanized'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      starRating: json['starRating'] ?? 0,
      isLearned: json['isLearned'] ?? false,
    );
  }
}

/// 10 số Khmer (0-9) + dữ liệu mẫu
class KhmerNumberData {
  KhmerNumberData._();

  static final List<KhmerNumber> numbers = [
    KhmerNumber(character: '០', value: '0', khmerWord: 'សូន្យ', romanized: 'soun', pronunciation: 'soun'),
    KhmerNumber(character: '១', value: '1', khmerWord: 'មួយ', romanized: 'muəj', pronunciation: 'muəj'),
    KhmerNumber(character: '២', value: '2', khmerWord: 'ពីរ', romanized: 'piː', pronunciation: 'piː'),
    KhmerNumber(character: '៣', value: '3', khmerWord: 'បី', romanized: 'bəj', pronunciation: 'bəj'),
    KhmerNumber(character: '៤', value: '4', khmerWord: 'បួន', romanized: 'buən', pronunciation: 'buən'),
    KhmerNumber(character: '៥', value: '5', khmerWord: 'ប្រាំ', romanized: 'pram', pronunciation: 'pram'),
    KhmerNumber(character: '៦', value: '6', khmerWord: 'ប្រាំមួយ', romanized: 'pram muəj', pronunciation: 'pram muəj'),
    KhmerNumber(character: '៧', value: '7', khmerWord: 'ប្រាំពីរ', romanized: 'pram piː', pronunciation: 'pram piː'),
    KhmerNumber(character: '៨', value: '8', khmerWord: 'ប្រាំបី', romanized: 'pram bəj', pronunciation: 'pram bəj'),
    KhmerNumber(character: '៩', value: '9', khmerWord: 'ប្រាំបួន', romanized: 'pram buən', pronunciation: 'pram buən'),
  ];
}
