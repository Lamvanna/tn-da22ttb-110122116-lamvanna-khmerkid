/// Model dữ liệu cho nguyên âm Khmer
/// Bao gồm dạng phụ thuộc (dependent) và dạng độc lập
class KhmerVowel {
  String? id;            // ID từ MongoDB Atlas
  final String character;      // Ký tự nguyên âm Khmer
  final String dependent;      // Dạng phụ thuộc (gắn phụ âm)
  final String romanized;      // Phiên âm Latin
  final String pronunciation;  // Phát âm tiếng Việt
  final String example;        // Ví dụ kết hợp phụ âm
  final String exampleMeaning; // Nghĩa ví dụ
  int starRating;
  bool isLearned;

  KhmerVowel({
    this.id,
    required this.character,
    this.dependent = '',
    required this.romanized,
    this.pronunciation = '',
    this.example = '',
    this.exampleMeaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });

  factory KhmerVowel.fromJson(Map<String, dynamic> json) {
    return KhmerVowel(
      id: json['_id'] ?? json['id'],
      character: json['khmerText'] ?? json['character'] ?? '',
      dependent: json['dependent'] ?? '',
      romanized: json['romanized'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      example: json['example'] ?? '',
      exampleMeaning: json['exampleMeaning'] ?? json['meaning'] ?? '',
      starRating: json['starRating'] ?? 0,
      isLearned: json['isLearned'] ?? false,
    );
  }

  String get displayCharacter => character.startsWith('អ') ? character.replaceFirst('អ', '◌') : character;
}

/// Nguyên âm Khmer cơ bản — 18 nguyên âm chính
/// Chia thành: nguyên âm ngắn, nguyên âm dài, nguyên âm đặc biệt
class KhmerVowelData {
  KhmerVowelData._();

  static final List<KhmerVowel> vowels = [
    // ══════ NGUYÊN ÂM ══════
    KhmerVowel(
      character: 'អា',
      dependent: 'កា',
      romanized: 'a',
      pronunciation: 'a',
      example: 'កា',
      exampleMeaning: 'quạ',
    ),
    KhmerVowel(
      character: 'អិ',
      dependent: 'កិ',
      romanized: 'ek',
      pronunciation: 'êk',
      example: 'កិន',
      exampleMeaning: 'công việc',
    ),
    KhmerVowel(
      character: 'អី',
      dependent: 'កី',
      romanized: 'ey',
      pronunciation: 'ây',
      example: 'កី',
      exampleMeaning: 'khó chịu',
    ),
    KhmerVowel(
      character: 'អឹ',
      dependent: 'កឹ',
      romanized: 'euk',
      pronunciation: 'ưk',
      example: 'កឹប',
      exampleMeaning: 'kẹp/ghim',
    ),
    KhmerVowel(
      character: 'អឺ',
      dependent: 'កឺ',
      romanized: 'eu',
      pronunciation: 'ư',
      example: 'កឺ',
      exampleMeaning: 'tiếng ồn',
    ),
    KhmerVowel(
      character: 'អុ',
      dependent: 'កុ',
      romanized: 'o',
      pronunciation: 'ô',
      example: 'កុក',
      exampleMeaning: 'con cò',
    ),
    KhmerVowel(
      character: 'អូ',
      dependent: 'កូ',
      romanized: 'au',
      pronunciation: 'ao',
      example: 'កូន',
      exampleMeaning: 'con',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អួ',
      dependent: 'កួ',
      romanized: 'uo',
      pronunciation: 'uô',
      example: 'កួច',
      exampleMeaning: 'xoắn',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អើ',
      dependent: 'កើ',
      romanized: 'aoe',
      pronunciation: 'ơ',
      example: 'កើត',
      exampleMeaning: 'sinh ra',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អឿ',
      dependent: 'កឿ',
      romanized: 'oeu',
      pronunciation: 'ưa',
      example: 'ជឿ',
      exampleMeaning: 'tin',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៀ',
      dependent: 'កៀ',
      romanized: 'ear',
      pronunciation: 'ia',
      example: 'កៀក',
      exampleMeaning: 'gần',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អេ',
      dependent: 'កេ',
      romanized: 'e',
      pronunciation: 'ê',
      example: 'កេ',
      exampleMeaning: 'thừa kế',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អែ',
      dependent: 'កែ',
      romanized: 'eo',
      pronunciation: 'e',
      example: 'កែ',
      exampleMeaning: 'sửa',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៃ',
      dependent: 'កៃ',
      romanized: 'ai',
      pronunciation: 'ai',
      example: 'កៃ',
      exampleMeaning: 'cò súng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អោ',
      dependent: 'កោ',
      romanized: 'ow',
      pronunciation: 'ao',
      example: 'កោង',
      exampleMeaning: 'cong',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៅ',
      dependent: 'កៅ',
      romanized: 'ao',
      pronunciation: 'ao',
      example: 'កៅអី',
      exampleMeaning: 'ghế',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អំ',
      dependent: 'កំ',
      romanized: 'orm',
      pronunciation: 'om',
      example: 'កំពង់',
      exampleMeaning: 'bến cảng',
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
      character: 'អះ',
      dependent: 'កះ',
      romanized: 'ah',
      pronunciation: 'ah',
      example: 'កះ',
      exampleMeaning: 'cắt',
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
      character: 'អិះ',
      dependent: 'កិះ',
      romanized: 'eh',
      pronunciation: 'ih',
      example: 'កិះ',
      exampleMeaning: 'gẩy nhẹ',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អុះ',
      dependent: 'កុះ',
      romanized: 'oh',
      pronunciation: 'ôh',
      example: 'កុះ',
      exampleMeaning: 'đông đúc',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អេះ',
      dependent: 'កេះ',
      romanized: 'es',
      pronunciation: 'êh',
      example: 'កេះ',
      exampleMeaning: 'khều/gãi',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អោះ',
      dependent: 'កោះ',
      romanized: 'oah',
      pronunciation: 'oah',
      example: 'កោះ',
      exampleMeaning: 'đảo',
      starRating: 0,
      isLearned: false,
    ),
  ];
}
