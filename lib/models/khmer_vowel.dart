/// Model dữ liệu cho nguyên âm Khmer
/// Bao gồm dạng phụ thuộc (dependent) và dạng độc lập
class KhmerVowel {
  final String character;      // Ký tự nguyên âm Khmer
  final String dependent;      // Dạng phụ thuộc (gắn phụ âm)
  final String romanized;      // Phiên âm Latin
  final String pronunciation;  // Phát âm tiếng Việt
  final String example;        // Ví dụ kết hợp phụ âm
  final String exampleMeaning; // Nghĩa ví dụ
  int starRating;
  bool isLearned;

  KhmerVowel({
    required this.character,
    this.dependent = '',
    required this.romanized,
    this.pronunciation = '',
    this.example = '',
    this.exampleMeaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// Nguyên âm Khmer cơ bản — 18 nguyên âm chính
/// Chia thành: nguyên âm ngắn, nguyên âm dài, nguyên âm đặc biệt
class KhmerVowelData {
  KhmerVowelData._();

  static final List<KhmerVowel> vowels = [
    // ══════ NGUYÊN ÂM NGẮN ══════
    KhmerVowel(
      character: 'អ',
      dependent: 'ក',
      romanized: 'a',
      pronunciation: 'a',
      example: 'កា',
      exampleMeaning: 'quạ',
      starRating: 5,
      isLearned: true,
    ),
    KhmerVowel(
      character: 'អិ',
      dependent: 'កិ',
      romanized: 'e',
      pronunciation: 'i ngắn',
      example: 'កិន',
      exampleMeaning: 'công việc',
      starRating: 4,
      isLearned: true,
    ),
    KhmerVowel(
      character: 'អុ',
      dependent: 'កុ',
      romanized: 'o',
      pronunciation: 'u ngắn',
      example: 'កុក',
      exampleMeaning: 'con cò',
      starRating: 3,
      isLearned: true,
    ),
    KhmerVowel(
      character: 'អែ',
      dependent: 'កែ',
      romanized: 'ae',
      pronunciation: 'e',
      example: 'កែ',
      exampleMeaning: 'sửa',
      starRating: 4,
      isLearned: true,
    ),

    // ══════ NGUYÊN ÂM DÀI ══════
    KhmerVowel(
      character: 'អា',
      dependent: 'កា',
      romanized: 'aa',
      pronunciation: 'a dài',
      example: 'កា',
      exampleMeaning: 'quạ',
      starRating: 5,
      isLearned: true,
    ),
    KhmerVowel(
      character: 'អី',
      dependent: 'កី',
      romanized: 'ei',
      pronunciation: 'i dài',
      example: 'កី',
      exampleMeaning: 'khó chịu',
      starRating: 3,
      isLearned: true,
    ),
    KhmerVowel(
      character: 'អូ',
      dependent: 'កូ',
      romanized: 'ou',
      pronunciation: 'u dài',
      example: 'កូន',
      exampleMeaning: 'con',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ ĐANG HỌC (current) ══════
    KhmerVowel(
      character: 'អើ',
      dependent: 'កើ',
      romanized: 'ae',
      pronunciation: 'ơ',
      example: 'កើត',
      exampleMeaning: 'sinh ra',
      starRating: 0,
      isLearned: false,
    ),

    // ══════ CHƯA MỞ KHÓA ══════
    KhmerVowel(
      character: 'អៀ',
      dependent: 'កៀ',
      romanized: 'ie',
      pronunciation: 'ia',
      example: 'កៀក',
      exampleMeaning: 'gần',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អឿ',
      dependent: 'កឿ',
      romanized: 'ue',
      pronunciation: 'ưa',
      example: 'ជឿ',
      exampleMeaning: 'tin',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អួ',
      dependent: 'កួ',
      romanized: 'uo',
      pronunciation: 'ua',
      example: 'កួច',
      exampleMeaning: 'xoắn',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អំ',
      dependent: 'កំ',
      romanized: 'om',
      pronunciation: 'ôm',
      example: 'កំពង់',
      exampleMeaning: 'bến cảng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អាំ',
      dependent: 'កាំ',
      romanized: 'am',
      pronunciation: 'am',
      example: 'កាំ',
      exampleMeaning: 'tia',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អោ',
      dependent: 'កោ',
      romanized: 'ao',
      pronunciation: 'ao',
      example: 'កោង',
      exampleMeaning: 'cong',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៅ',
      dependent: 'កៅ',
      romanized: 'au',
      pronunciation: 'au',
      example: 'កៅអី',
      exampleMeaning: 'ghế',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អុំ',
      dependent: 'កុំ',
      romanized: 'om',
      pronunciation: 'um',
      example: 'កុំ',
      exampleMeaning: 'đừng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អាំង',
      dependent: 'កាំង',
      romanized: 'ang',
      pronunciation: 'ang',
      example: 'កាំង',
      exampleMeaning: 'nướng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អះ',
      dependent: 'កះ',
      romanized: 'ah',
      pronunciation: 'ah',
      example: 'កះ',
      exampleMeaning: 'cắt',
      starRating: 0,
      isLearned: false,
    ),
  ];
}
