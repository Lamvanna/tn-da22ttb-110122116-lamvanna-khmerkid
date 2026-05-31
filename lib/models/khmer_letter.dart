/// Model dữ liệu cho chữ cái Khmer
/// Mutable để có thể cập nhật trạng thái học
class KhmerLetter {
  String? id; // ID từ MongoDB Atlas
  final String character; // Ký tự Khmer (e.g., "ក")
  final String romanized; // Phiên âm Latin (e.g., "ko")
  final String pronunciation; // Phát âm tiếng Việt (e.g., "ka")
  final String meaning; // Ý nghĩa / liên tưởng (e.g., "con cò")
  int starRating; // Số sao đã đạt (0-5)
  bool isLearned; // Đã học chưa
  final bool isTest; // Bài kiểm tra
  final String testRange; // Phạm vi kiểm tra (e.g., "1-5")

  KhmerLetter({
    this.id,
    required this.character,
    required this.romanized,
    this.pronunciation = '',
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
    this.isTest = false,
    this.testRange = '',
  });

  factory KhmerLetter.fromJson(Map<String, dynamic> json) {
    return KhmerLetter(
      id: json['_id'] ?? json['id'],
      character: json['khmerText'] ?? json['character'] ?? '',
      romanized: json['romanized'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      meaning: json['meaning'] ?? '',
      starRating: json['starRating'] ?? 0,
      isLearned: json['isLearned'] ?? false,
      isTest: json['isTest'] ?? false,
      testRange: json['testRange'] ?? '',
    );
  }
}

/// 33 phụ âm + 8 bài kiểm tra = 41 bài
/// Bài 6,12,18,24,30,35,40: kiểm tra nhóm trước đó
/// Bài 41: kiểm tra tổng
class KhmerLetterData {
  KhmerLetterData._();

  static final List<KhmerLetter> consonants = [
    // ══════ NHÓM 1: Bài 1-5 ══════
    KhmerLetter(
      character: 'ក',
      romanized: 'ka',
      pronunciation: 'ka',
      meaning: 'con cò',
    ),
    KhmerLetter(
      character: 'ខ',
      romanized: 'kha',
      pronunciation: 'kha',
      meaning: 'con hổ',
    ),
    KhmerLetter(
      character: 'គ',
      romanized: 'ko',
      pronunciation: 'ko',
      meaning: 'con gà',
    ),
    KhmerLetter(
      character: 'ឃ',
      romanized: 'kho',
      pronunciation: 'kho',
      meaning: 'con bò',
    ),
    KhmerLetter(
      character: 'ង',
      romanized: 'ngo',
      pronunciation: 'ngo',
      meaning: 'con ngỗng',
    ),
    // ── Bài 6: ច (cho) ──
    KhmerLetter(
      character: 'ច',
      romanized: 'cho',
      pronunciation: 'cho',
      meaning: 'con chó',
    ),
    // ── Bài 7: ឆ (chhor) ──
    KhmerLetter(
      character: 'ឆ',
      romanized: 'chhor',
      pronunciation: 'chhor',
      meaning: 'con mèo',
    ),
    KhmerLetter(
      character: 'ជ',
      romanized: 'cho',
      pronunciation: 'cho',
      meaning: 'con cá',
    ),
    // ── Bài 8: ជ (cho) ──
    KhmerLetter(
      character: 'ជ',
      romanized: 'cho',
      pronunciation: 'cho',
      meaning: 'con cá',
    ),
    // ── Bài 9: ឈ (chhor) ──
    KhmerLetter(
      character: 'ឈ',
      romanized: 'chhor',
      pronunciation: 'chhor',
      meaning: 'con hươu',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 10: ញ (nhor) ──
    KhmerLetter(
      character: 'ញ',
      romanized: 'nhor',
      pronunciation: 'nhor',
      meaning: 'con thỏ',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 11: Kiểm tra bài 6-10 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '6-10',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ NHÓM 3: Bài 13-17 ══════
    KhmerLetter(
      character: 'ដ',
      romanized: 'da',
      pronunciation: 'da',
      meaning: 'con voi',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ឋ',
      romanized: 'tha',
      pronunciation: 'tha',
      meaning: 'con rùa',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ឌ',
      romanized: 'do',
      pronunciation: 'do',
      meaning: 'con ong',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ឍ',
      romanized: 'tho',
      pronunciation: 'tho',
      meaning: 'con cua',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ណ',
      romanized: 'na',
      pronunciation: 'na',
      meaning: 'con rắn',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 18: Kiểm tra bài 13-17 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '13-17',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ NHÓM 4: Bài 19-23 ══════
    KhmerLetter(
      character: 'ត',
      romanized: 'ta',
      pronunciation: 'ta',
      meaning: 'con hổ',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ថ',
      romanized: 'tha',
      pronunciation: 'tha',
      meaning: 'con ngựa',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ទ',
      romanized: 'to',
      pronunciation: 'to',
      meaning: 'con vịt',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ធ',
      romanized: 'tho',
      pronunciation: 'tho',
      meaning: 'con bướm',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ន',
      romanized: 'no',
      pronunciation: 'no',
      meaning: 'con cọp',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 24: Kiểm tra bài 19-23 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '19-23',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ NHÓM 5: Bài 25-29 ══════
    KhmerLetter(
      character: 'ប',
      romanized: 'ba',
      pronunciation: 'ba',
      meaning: 'con ếch',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ផ',
      romanized: 'pha',
      pronunciation: 'pha',
      meaning: 'con ốc',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ព',
      romanized: 'po',
      pronunciation: 'po',
      meaning: 'con công',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ភ',
      romanized: 'pho',
      pronunciation: 'pho',
      meaning: 'con sóc',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ម',
      romanized: 'mo',
      pronunciation: 'mo',
      meaning: 'con kiến',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 30: Kiểm tra bài 25-29 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '25-29',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ NHÓM 6: Bài 31-34 ══════
    KhmerLetter(
      character: 'យ',
      romanized: 'yo',
      pronunciation: 'yo',
      meaning: 'con dê',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'រ',
      romanized: 'ro',
      pronunciation: 'ro',
      meaning: 'con sư tử',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ល',
      romanized: 'lo',
      pronunciation: 'lo',
      meaning: 'con heo',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'វ',
      romanized: 'vo',
      pronunciation: 'vo',
      meaning: 'con chim',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 35: Kiểm tra bài 31-34 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '31-34',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ NHÓM 7: Bài 36-39 ══════
    KhmerLetter(
      character: 'ស',
      romanized: 'sa',
      pronunciation: 'sa',
      meaning: 'con tôm',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ហ',
      romanized: 'ha',
      pronunciation: 'ha',
      meaning: 'con chuột',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'ឡ',
      romanized: 'la',
      pronunciation: 'la',
      meaning: 'con gấu',
      starRating: 0,
      isLearned: false,
    ),
    KhmerLetter(
      character: 'អ',
      romanized: 'a',
      pronunciation: 'a',
      meaning: 'con khỉ đột',
      starRating: 0,
      isLearned: false,
    ),
    // ── Bài 40: Kiểm tra bài 36-39 ──
    KhmerLetter(
      character: '📝',
      romanized: 'Kiểm tra',
      isTest: true,
      testRange: '36-39',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ BÀI 41: KIỂM TRA TỔNG ══════
    KhmerLetter(
      character: '🏆',
      romanized: 'Tổng KT',
      isTest: true,
      testRange: '1-40',
      starRating: 0,
      isLearned: false,
    ),
  ];
}
