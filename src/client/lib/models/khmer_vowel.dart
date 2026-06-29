/// Model dữ liệu cho nguyên âm Khmer
/// Bao gồm dạng phụ thuộc (dependent) và dạng độc lập
class KhmerVowel {
  String? id;            // ID từ MongoDB Atlas
  final String character;      // Ký tự nguyên âm Khmer
  final String dependent;      // Dạng phụ thuộc (gắn phụ âm)
  final String romanized;      // Phiên âm Latin
  final String pronunciation;  // Phát âm tiếng Việt (âm thuần, vd "a")
  final String spokenName;     // Tên nguyên âm đọc khi nghe (vd "srăk a" = ស្រៈ + âm)
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
    this.spokenName = '',
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
      spokenName: json['spokenName'] ?? '',
      example: json['example'] ?? '',
      exampleMeaning: json['exampleMeaning'] ?? json['meaning'] ?? '',
      starRating: json['starRating'] ?? 0,
      isLearned: json['isLearned'] ?? false,
    );
  }

  String get displayCharacter => character.startsWith('អ') ? character.replaceFirst('អ', '◌') : character;

  /// Âm thuần dùng để CHẤM ĐIỂM nói + hiển thị prompt (bỏ chú thích trong ngoặc).
  /// Vd "a (dài)" → "a", "i (ngắn)" → "i". Nếu rỗng thì trả pronunciation gốc.
  String get pronunciationClean {
    final base = pronunciation.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    return base.isNotEmpty ? base : pronunciation.trim();
  }

  /// Tên đọc khi nghe — ưu tiên spokenName ("srăk a"), nếu trống thì ghép "srăk " + âm thuần.
  /// Bỏ phần chú thích trong ngoặc của pronunciation (vd "a (dài)" → "a") để đọc tự nhiên.
  String get listenText {
    if (spokenName.trim().isNotEmpty) return spokenName;
    final base = pronunciationClean;
    return base.isNotEmpty ? 'srăk $base' : 'srăk';
  }

  /// Danh sách tổng hợp TẤT CẢ các cách đọc hợp lệ cho nguyên âm này.
  /// Gộp từ: pronunciationClean, pronunciation gốc, romanized, dependent,
  /// và các biến thể tiếng Việt không dấu phổ biến mà STT hay nhận.
  /// Dùng làm acceptedAnswers cho KhmerSpeakWidget để tăng độ chính xác.
  List<String> get allAcceptedPronunciations {
    final Set<String> forms = {};

    // Âm thuần đã loại chú thích (vd "a", "ơ", "ê")
    if (pronunciationClean.isNotEmpty) forms.add(pronunciationClean);

    // Pronunciation gốc có chú thích (vd "a (dài)", "i (ngắn)")
    if (pronunciation.isNotEmpty) forms.add(pronunciation);

    // Phiên âm Latin/IPA (vd "aa", "ei", "ə")
    if (romanized.isNotEmpty) forms.add(romanized);

    // Dạng phụ thuộc (vd "កា", "កិ") — STT đôi khi nhận Khmer trực tiếp
    if (dependent.isNotEmpty) forms.add(dependent);

    // Ký tự gốc (vd "អា", "អិ")
    forms.add(character);

    // Biến thể âm không dấu phổ biến từ pronunciationClean
    final clean = pronunciationClean.toLowerCase();
    // Xóa dấu thanh tiếng Việt đơn giản
    const diacriticMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'ơ': 'ơ', 'ờ': 'ơ', 'ớ': 'ơ', 'ở': 'ơ', 'ỡ': 'ơ', 'ợ': 'ơ',
      'ô': 'ô', 'ồ': 'ô', 'ố': 'ô', 'ổ': 'ô', 'ỗ': 'ô', 'ộ': 'ô',
      'ê': 'ê', 'ề': 'ê', 'ế': 'ê', 'ể': 'ê', 'ễ': 'ê', 'ệ': 'ê',
      'ư': 'ư', 'ừ': 'ư', 'ứ': 'ư', 'ử': 'ư', 'ữ': 'ư', 'ự': 'ư',
      'â': 'â', 'ầ': 'â', 'ấ': 'â', 'ẩ': 'â', 'ẫ': 'â', 'ậ': 'â',
      'ă': 'ă', 'ằ': 'ă', 'ắ': 'ă', 'ẳ': 'ă', 'ẵ': 'ă', 'ặ': 'ă',
    };
    String noDiacritics = '';
    for (int i = 0; i < clean.length; i++) {
      noDiacritics += diacriticMap[clean[i]] ?? clean[i];
    }
    if (noDiacritics != clean && noDiacritics.isNotEmpty) {
      forms.add(noDiacritics);
    }

    return forms.toList();
  }
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
      romanized: 'aa',
      pronunciation: 'a (dài)',
      example: 'កា',
      exampleMeaning: 'quạ',
    ),
    KhmerVowel(
      character: 'អិ',
      dependent: 'កិ',
      romanized: 'e',
      pronunciation: 'i (ngắn)',
      example: 'កិន',
      exampleMeaning: 'công việc',
    ),
    KhmerVowel(
      character: 'អី',
      dependent: 'កី',
      romanized: 'ei',
      pronunciation: 'ây',
      example: 'កី',
      exampleMeaning: 'khó chịu',
    ),
    KhmerVowel(
      character: 'អឹ',
      dependent: 'កឹ',
      romanized: 'ə',
      pronunciation: 'ơ (ngắn)',
      example: 'កឹប',
      exampleMeaning: 'kẹp/ghim',
    ),
    KhmerVowel(
      character: 'អឺ',
      dependent: 'កឺ',
      romanized: 'əə',
      pronunciation: 'ơ (dài)',
      example: 'កឺ',
      exampleMeaning: 'tiếng ồn',
    ),
    KhmerVowel(
      character: 'អុ',
      dependent: 'កុ',
      romanized: 'o',
      pronunciation: 'ô (ngắn)',
      example: 'កុក',
      exampleMeaning: 'con cò',
    ),
    KhmerVowel(
      character: 'អូ',
      dependent: 'កូ',
      romanized: 'oo',
      pronunciation: 'u (dài)',
      example: 'កូន',
      exampleMeaning: 'con',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អួ',
      dependent: 'កួ',
      romanized: 'uə',
      pronunciation: 'ua',
      example: 'កួច',
      exampleMeaning: 'xoắn',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អើ',
      dependent: 'កើ',
      romanized: 'əə',
      pronunciation: 'ơ',
      example: 'កើត',
      exampleMeaning: 'sinh ra',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អឿ',
      dependent: 'កឿ',
      romanized: 'ɨə',
      pronunciation: 'ưa',
      example: 'ជឿ',
      exampleMeaning: 'tin',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៀ',
      dependent: 'កៀ',
      romanized: 'iə',
      pronunciation: 'ia',
      example: 'កៀក',
      exampleMeaning: 'gần',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អេ',
      dependent: 'កេ',
      romanized: 'ee',
      pronunciation: 'ê',
      example: 'កេ',
      exampleMeaning: 'thừa kế',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អែ',
      dependent: 'កែ',
      romanized: 'ae',
      pronunciation: 'e',
      example: 'កែ',
      exampleMeaning: 'sửa',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អៃ',
      dependent: 'កៃ',
      romanized: 'aj',
      pronunciation: 'ai',
      example: 'កៃ',
      exampleMeaning: 'cò súng',
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
      romanized: 'aw',
      pronunciation: 'au',
      example: 'កៅអី',
      exampleMeaning: 'ghế',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អំ',
      dependent: 'កំ',
      romanized: 'ɑm',
      pronunciation: 'ăm',
      example: 'កំពង់',
      exampleMeaning: 'bến cảng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អុំ',
      dependent: 'កុំ',
      romanized: 'om',
      pronunciation: 'ôm',
      example: 'កុំ',
      exampleMeaning: 'đừng',
      starRating: 0,
      isLearned: false,
    ),
    KhmerVowel(
      character: 'អះ',
      dependent: 'កះ',
      romanized: 'ah',
      pronunciation: 'ăh',
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
      romanized: 'eh',
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
      pronunciation: 'oăh',
      example: 'កោះ',
      exampleMeaning: 'đảo',
      starRating: 0,
      isLearned: false,
    ),
  ];
}
