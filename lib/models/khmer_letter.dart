/// Model dữ liệu cho chữ cái Khmer
/// Mutable để có thể cập nhật trạng thái học
class KhmerLetter {
  final String character;     // Ký tự Khmer (e.g., "ក")
  final String romanized;     // Phiên âm Latin (e.g., "ko")
  final String pronunciation; // Phát âm tiếng Việt (e.g., "ka")
  final String meaning;       // Ý nghĩa / liên tưởng (e.g., "con cò")
  int starRating;             // Số sao đã đạt (0-5)
  bool isLearned;             // Đã học chưa
  final bool isTest;          // Bài kiểm tra
  final String testRange;     // Phạm vi kiểm tra (e.g., "1-5")

  KhmerLetter({
    required this.character,
    required this.romanized,
    this.pronunciation = '',
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
    this.isTest = false,
    this.testRange = '',
  });
}

/// 33 phụ âm + 8 bài kiểm tra = 41 bài
/// Bài 6,12,18,24,30,35,40: kiểm tra nhóm trước đó
/// Bài 41: kiểm tra tổng
class KhmerLetterData {
  KhmerLetterData._();

  static final List<KhmerLetter> consonants = [
    // ══════ NHÓM 1: Bài 1-5 (đã học) ══════
    KhmerLetter(character: 'ក', romanized: 'ko', pronunciation: 'ka', meaning: 'con cò', starRating: 5, isLearned: true),
    KhmerLetter(character: 'ខ', romanized: 'kho', pronunciation: 'kha', meaning: 'con hổ', starRating: 4, isLearned: true),
    KhmerLetter(character: 'គ', romanized: 'ko', pronunciation: 'kô', meaning: 'con gà', starRating: 3, isLearned: true),
    KhmerLetter(character: 'ឃ', romanized: 'kho', pronunciation: 'khô', meaning: 'con bò', starRating: 5, isLearned: true),
    KhmerLetter(character: 'ង', romanized: 'ngo', pronunciation: 'ngô', meaning: 'con ngỗng', starRating: 4, isLearned: true),
    // ── Bài 6: Kiểm tra bài 1-5 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '1-5', starRating: 3, isLearned: true),

    // ══════ NHÓM 2: Bài 7-11 (đã học) ══════
    KhmerLetter(character: 'ច', romanized: 'co', pronunciation: 'cha', meaning: 'con chó', starRating: 3, isLearned: true),
    KhmerLetter(character: 'ឆ', romanized: 'cho', pronunciation: 'chha', meaning: 'con mèo', starRating: 4, isLearned: true),
    KhmerLetter(character: 'ជ', romanized: 'co', pronunciation: 'chô', meaning: 'con cá', starRating: 2, isLearned: true),
    // ══════ ĐANG HỌC ══════
    KhmerLetter(character: 'ឈ', romanized: 'cho', pronunciation: 'chhô', meaning: 'con hươu', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ញ', romanized: 'nyo', pronunciation: 'nhô', meaning: 'con thỏ', starRating: 0, isLearned: false),
    // ── Bài 12: Kiểm tra bài 7-11 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '7-11', starRating: 0, isLearned: false),

    // ══════ NHÓM 3: Bài 13-17 ══════
    KhmerLetter(character: 'ដ', romanized: 'do', pronunciation: 'đa', meaning: 'con voi', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឋ', romanized: 'tho', pronunciation: 'tha', meaning: 'con rùa', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឌ', romanized: 'do', pronunciation: 'đô', meaning: 'con ong', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឍ', romanized: 'tho', pronunciation: 'thô', meaning: 'con cua', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ណ', romanized: 'no', pronunciation: 'na', meaning: 'con rắn', starRating: 0, isLearned: false),
    // ── Bài 18: Kiểm tra bài 13-17 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '13-17', starRating: 0, isLearned: false),

    // ══════ NHÓM 4: Bài 19-23 ══════
    KhmerLetter(character: 'ត', romanized: 'to', pronunciation: 'ta', meaning: 'con hổ', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ថ', romanized: 'tho', pronunciation: 'tha', meaning: 'con ngựa', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ទ', romanized: 'to', pronunciation: 'tô', meaning: 'con vịt', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ធ', romanized: 'tho', pronunciation: 'thô', meaning: 'con bướm', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ន', romanized: 'no', pronunciation: 'nô', meaning: 'con cọp', starRating: 0, isLearned: false),
    // ── Bài 24: Kiểm tra bài 19-23 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '19-23', starRating: 0, isLearned: false),

    // ══════ NHÓM 5: Bài 25-29 ══════
    KhmerLetter(character: 'ប', romanized: 'bo', pronunciation: 'ba', meaning: 'con ếch', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ផ', romanized: 'pho', pronunciation: 'pha', meaning: 'con ốc', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ព', romanized: 'po', pronunciation: 'pô', meaning: 'con công', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ភ', romanized: 'pho', pronunciation: 'phô', meaning: 'con sóc', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ម', romanized: 'mo', pronunciation: 'ma', meaning: 'con kiến', starRating: 0, isLearned: false),
    // ── Bài 30: Kiểm tra bài 25-29 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '25-29', starRating: 0, isLearned: false),

    // ══════ NHÓM 6: Bài 31-34 ══════
    KhmerLetter(character: 'យ', romanized: 'yo', pronunciation: 'ya', meaning: 'con dê', starRating: 0, isLearned: false),
    KhmerLetter(character: 'រ', romanized: 'ro', pronunciation: 'ra', meaning: 'con sư tử', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ល', romanized: 'lo', pronunciation: 'la', meaning: 'con heo', starRating: 0, isLearned: false),
    KhmerLetter(character: 'វ', romanized: 'vo', pronunciation: 'va', meaning: 'con chim', starRating: 0, isLearned: false),
    // ── Bài 35: Kiểm tra bài 31-34 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '31-34', starRating: 0, isLearned: false),

    // ══════ NHÓM 7: Bài 36-39 ══════
    KhmerLetter(character: 'ស', romanized: 'so', pronunciation: 'sa', meaning: 'con tôm', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ហ', romanized: 'ho', pronunciation: 'ha', meaning: 'con chuột', starRating: 0, isLearned: false),
    KhmerLetter(character: 'ឡ', romanized: 'lo', pronunciation: 'la', meaning: 'con gấu', starRating: 0, isLearned: false),
    KhmerLetter(character: 'អ', romanized: 'a', pronunciation: 'a', meaning: 'con khỉ đột', starRating: 0, isLearned: false),
    // ── Bài 40: Kiểm tra bài 36-39 ──
    KhmerLetter(character: '📝', romanized: 'Kiểm tra', isTest: true, testRange: '36-39', starRating: 0, isLearned: false),

    // ══════ BÀI 41: KIỂM TRA TỔNG ══════
    KhmerLetter(character: '🏆', romanized: 'Tổng KT', isTest: true, testRange: '1-40', starRating: 0, isLearned: false),
  ];
}
