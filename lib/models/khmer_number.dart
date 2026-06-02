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

  /// Số đọc bằng TIẾNG VIỆT theo [value] (vd "1" → "một").
  /// Dùng để chấp nhận khi bé đọc số bằng tiếng Việt lúc luyện nói.
  String get vietnameseWord {
    const map = {
      '0': 'không',
      '1': 'một',
      '2': 'hai',
      '3': 'ba',
      '4': 'bốn',
      '5': 'năm',
      '6': 'sáu',
      '7': 'bảy',
      '8': 'tám',
      '9': 'chín',
    };
    return map[value.trim()] ?? '';
  }

  /// Danh sách các từ đồng âm tiếng Việt thường gặp khi phát âm tiếng Khmer của số này,
  /// giúp tránh việc Google STT nhận nhầm dấu thanh tiếng Việt (ví dụ: đọc "muôi" thành "mùi/mũi/muỗi")
  List<String> get acceptedPronunciations {
    switch (value.trim()) {
      case '0': return ['sôn', 'sơn', 'xôn', 'son', 'sông'];
      case '1': return ['muôi', 'mùi', 'mũi', 'muỗi', 'muối', 'mui', 'mủi'];
      case '2': return ['pi', 'pin', 'bi', 'py', 'phí', 'phi'];
      case '3': return ['bây', 'bay', 'bẩy', 'bẫy', 'bày', 'bầy', 'bấy'];
      case '4': return ['buôn', 'buồn', 'buốn', 'buộn', 'buồng'];
      case '5': return ['prăm', 'băm', 'răm', 'trăm', 'phăm', 'păm', 'chăm', 'dăm', 'nhăm', 'tăm', 'thăm', 'xăm', 'lăm'];
      case '6':
        const prefixes = ['prăm', 'băm', 'răm', 'trăm', 'phăm', 'păm', 'chăm', 'dăm', 'nhăm'];
        const suffixes = ['muôi', 'mùi', 'mũi', 'muỗi', 'muối', 'mui', 'mủi'];
        final list = <String>[];
        for (final p in prefixes) {
          for (final s in suffixes) {
            list.add('$p-$s');
            list.add('$p $s');
          }
        }
        return list;
      case '7':
        const prefixes = ['prăm', 'băm', 'răm', 'trăm', 'phăm', 'păm', 'chăm', 'dăm', 'nhăm'];
        const suffixes = ['pi', 'bi', 'py', 'phi', 'phí', 'pin', 'bị', 'bỉ', 'phì', 'phỉ', 'tì', 'ti'];
        final list = <String>[];
        for (final p in prefixes) {
          for (final s in suffixes) {
            list.add('$p-$s');
            list.add('$p $s');
          }
        }
        return list;
      case '8':
        const prefixes = ['prăm', 'băm', 'răm', 'trăm', 'phăm', 'păm', 'chăm', 'dăm', 'nhăm'];
        const suffixes = ['bây', 'bay', 'bẩy', 'bẫy', 'bày', 'bầy', 'bấy', 'vây', 'vẩy', 'vẫy', 'mây', 'mẩy', 'mấy'];
        final list = <String>[];
        for (final p in prefixes) {
          for (final s in suffixes) {
            list.add('$p-$s');
            list.add('$p $s');
          }
        }
        return list;
      case '9':
        const prefixes = ['prăm', 'băm', 'răm', 'trăm', 'phăm', 'păm', 'chăm', 'dăm', 'nhăm'];
        const suffixes = ['buôn', 'buồn', 'buốn', 'buộn', 'buồng', 'muôn', 'muộn'];
        final list = <String>[];
        for (final p in prefixes) {
          for (final s in suffixes) {
            list.add('$p-$s');
            list.add('$p $s');
          }
        }
        return list;
      default: return [pronunciation];
    }
  }
}

/// 10 số Khmer (0-9) + dữ liệu mẫu
class KhmerNumberData {
  KhmerNumberData._();

  static final List<KhmerNumber> numbers = [
    KhmerNumber(character: '០', value: '0', khmerWord: 'សូន្យ', romanized: 'soun', pronunciation: 'sôn'),
    KhmerNumber(character: '១', value: '1', khmerWord: 'មួយ', romanized: 'muəj', pronunciation: 'muôi'),
    KhmerNumber(character: '២', value: '2', khmerWord: 'ពីរ', romanized: 'piː', pronunciation: 'pi'),
    KhmerNumber(character: '៣', value: '3', khmerWord: 'បី', romanized: 'bəj', pronunciation: 'bây'),
    KhmerNumber(character: '៤', value: '4', khmerWord: 'បួន', romanized: 'buən', pronunciation: 'buôn'),
    KhmerNumber(character: '៥', value: '5', khmerWord: 'ប្រាំ', romanized: 'pram', pronunciation: 'prăm'),
    KhmerNumber(character: '៦', value: '6', khmerWord: 'ប្រាំមួយ', romanized: 'pram muəj', pronunciation: 'prăm-muôi'),
    KhmerNumber(character: '៧', value: '7', khmerWord: 'ប្រាំពីរ', romanized: 'pram piː', pronunciation: 'prăm-pi'),
    KhmerNumber(character: '៨', value: '8', khmerWord: 'ប្រាំបី', romanized: 'pram bəj', pronunciation: 'prăm-bây'),
    KhmerNumber(character: '៩', value: '9', khmerWord: 'ប្រាំបួន', romanized: 'pram buən', pronunciation: 'prăm-buôn'),
  ];
}
