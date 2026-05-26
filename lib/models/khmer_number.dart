/// Model dữ liệu cho số Khmer
class KhmerNumber {
  final String character;     // Ký tự số Khmer (e.g., "០")
  final String value;         // Giá trị số (e.g., "0")
  final String khmerWord;     // Từ Khmer (e.g., "សូន្យ")
  final String romanized;     // Phiên âm Latin (e.g., "soun")
  final String pronunciation; // Phát âm tiếng Việt
  int starRating;       // Số sao (0-5)
  bool isLearned;

  KhmerNumber({
    required this.character,
    required this.value,
    this.khmerWord = '',
    this.romanized = '',
    this.pronunciation = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 10 số Khmer (0-9) + dữ liệu mẫu
class KhmerNumberData {
  KhmerNumberData._();

  static final List<KhmerNumber> numbers = [
    KhmerNumber(character: '០', value: '0', khmerWord: 'សូន្យ', romanized: 'soun', pronunciation: 'soun', starRating: 5, isLearned: true),
    KhmerNumber(character: '១', value: '1', khmerWord: 'មួយ', romanized: 'muoy', pronunciation: 'muôi', starRating: 4, isLearned: true),
    KhmerNumber(character: '២', value: '2', khmerWord: 'ពីរ', romanized: 'pii', pronunciation: 'pi', starRating: 3, isLearned: true),
    KhmerNumber(character: '៣', value: '3', khmerWord: 'បី', romanized: 'bei', pronunciation: 'bây', starRating: 5, isLearned: true),
    KhmerNumber(character: '៤', value: '4', khmerWord: 'បួន', romanized: 'buon', pronunciation: 'buôn', starRating: 2, isLearned: true),
    KhmerNumber(character: '៥', value: '5', khmerWord: 'ប្រាំ', romanized: 'pram', pronunciation: 'pram', starRating: 0, isLearned: false),
    KhmerNumber(character: '៦', value: '6', khmerWord: 'ប្រាំមួយ', romanized: 'pram muoy', pronunciation: 'pram muôi', starRating: 0, isLearned: false),
    KhmerNumber(character: '៧', value: '7', khmerWord: 'ប្រាំពីរ', romanized: 'pram pii', pronunciation: 'pram pi', starRating: 0, isLearned: false),
    KhmerNumber(character: '៨', value: '8', khmerWord: 'ប្រាំបី', romanized: 'pram bei', pronunciation: 'pram bây', starRating: 0, isLearned: false),
    KhmerNumber(character: '៩', value: '9', khmerWord: 'ប្រាំបួន', romanized: 'pram buon', pronunciation: 'pram buôn', starRating: 0, isLearned: false),
  ];
}
