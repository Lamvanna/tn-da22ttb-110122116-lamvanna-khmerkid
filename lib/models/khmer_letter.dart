/// Model dữ liệu cho chữ cái Khmer
/// Mutable để có thể cập nhật trạng thái học
class KhmerLetter {
  final String character;     // Ký tự Khmer (e.g., "ក")
  final String romanized;     // Phiên âm Latin (e.g., "ko")
  final String pronunciation; // Phát âm tiếng Việt (e.g., "ka")
  final String meaning;       // Ý nghĩa / liên tưởng (e.g., "con cò")
  int starRating;             // Số sao đã đạt (0-5)
  bool isLearned;             // Đã học chưa

  KhmerLetter({
    required this.character,
    required this.romanized,
    this.pronunciation = '',
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 33 phụ âm cơ bản - THỨ TỰ LOGIC:
/// Chữ 1→8: đã học (có sao)
/// Chữ 9: đang học (chưa hoàn thành = current)
/// Chữ 10→33: chưa mở khóa (locked)
class KhmerLetterData {
  KhmerLetterData._();

  static final List<KhmerLetter> consonants = [
    // ══════ ĐÃ HỌC (theo thứ tự) ══════
    KhmerLetter(character: 'ក', romanized: 'ko', pronunciation: 'ka', meaning: 'con cò', starRating: 5, isLearned: true),
    KhmerLetter(character: 'ខ', romanized: 'kho', pronunciation: 'kha', meaning: 'con khỉ', starRating: 4, isLearned: true),
    KhmerLetter(character: 'គ', romanized: 'ko', pronunciation: 'kô', meaning: 'con gà', starRating: 3, isLearned: true),
    KhmerLetter(character: 'ឃ', romanized: 'kho', pronunciation: 'khô', meaning: '', starRating: 5, isLearned: true),
    KhmerLetter(character: 'ង', romanized: 'ngo', pronunciation: 'ngô', meaning: 'con ngỗng', starRating: 4, isLearned: true),
    KhmerLetter(character: 'ច', romanized: 'co', pronunciation: 'cha', meaning: 'con chó', starRating: 3, isLearned: true),
    KhmerLetter(character: 'ឆ', romanized: 'cho', pronunciation: 'chha', meaning: '', starRating: 4, isLearned: true),
    KhmerLetter(character: 'ជ', romanized: 'co', pronunciation: 'chô', meaning: '', starRating: 2, isLearned: true),

    // ══════ ĐANG HỌC (current - chưa hoàn thành) ══════
    KhmerLetter(character: 'ឈ', romanized: 'cho', pronunciation: 'chhô', meaning: '', starRating: 0, isLearned: false),

    // ══════ CHƯA MỞ KHÓA (locked) ══════
    KhmerLetter(character: 'ញ', romanized: 'nyo', pronunciation: 'nhô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ដ', romanized: 'do', pronunciation: 'đa', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឋ', romanized: 'tho', pronunciation: 'tha', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឌ', romanized: 'do', pronunciation: 'đô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឍ', romanized: 'tho', pronunciation: 'thô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ណ', romanized: 'no', pronunciation: 'na', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ត', romanized: 'to', pronunciation: 'ta', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ថ', romanized: 'tho', pronunciation: 'tha', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ទ', romanized: 'to', pronunciation: 'tô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ធ', romanized: 'tho', pronunciation: 'thô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ន', romanized: 'no', pronunciation: 'nô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ប', romanized: 'bo', pronunciation: 'ba', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ផ', romanized: 'pho', pronunciation: 'pha', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ព', romanized: 'po', pronunciation: 'pô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ភ', romanized: 'pho', pronunciation: 'phô', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ម', romanized: 'mo', pronunciation: 'ma', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'យ', romanized: 'yo', pronunciation: 'ya', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'រ', romanized: 'ro', pronunciation: 'ra', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ល', romanized: 'lo', pronunciation: 'la', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'វ', romanized: 'vo', pronunciation: 'va', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ស', romanized: 'so', pronunciation: 'sa', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ហ', romanized: 'ho', pronunciation: 'ha', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឡ', romanized: 'lo', pronunciation: 'la', meaning: '', starRating: 0, isLearned: false),
    KhmerLetter(character: 'អ', romanized: 'a', pronunciation: 'a', meaning: '', starRating: 0, isLearned: false),
  ];
}
