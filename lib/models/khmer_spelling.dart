/// Model dữ liệu cho bài đánh vần Khmer
/// Ghép phụ âm + nguyên âm thành từ
class KhmerSpelling {
  final String consonant;       // Phụ âm
  final String vowelSign;       // Dấu nguyên âm (dạng phụ thuộc)
  final String combined;        // Kết quả ghép
  final String romanized;       // Phiên âm Latin
  final String meaning;         // Nghĩa tiếng Việt
  int starRating;
  bool isLearned;

  KhmerSpelling({
    required this.consonant,
    required this.vowelSign,
    required this.combined,
    required this.romanized,
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 100 bài đánh vần — 10 phụ âm × 10 nguyên âm
/// 10 phụ âm phổ biến: ក ខ គ ច ដ ត ន ប ម រ
/// 10 nguyên âm: ា, ិ, ី, ុ, ូ, ួ, ើ, ឿ, ៀ, េ
class KhmerSpellingData {
  KhmerSpellingData._();

  static final List<KhmerSpelling> lessons = [
    for (var c in [
      // 33 Phụ âm tiếng Khmer
      'ក', 'ខ', 'គ', 'ឃ', 'ង', // Nhóm 1
      'ច', 'ឆ', 'ជ', 'ឈ', 'ញ', // Nhóm 2
      'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ', // Nhóm 3
      'ត', 'ថ', 'ទ', 'ធ', 'ន', // Nhóm 4
      'ប', 'ផ', 'ព', 'ភ', 'ម', // Nhóm 5
      'យ', 'រ', 'ល', 'វ',      // Nhóm 6
      'ស', 'ហ', 'ឡ', 'អ'       // Nhóm 7
    ]) ...[
      KhmerSpelling(consonant: c, vowelSign: 'ា', combined: '$cា', romanized: '...', starRating: 3, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ិ', combined: '$cិ', romanized: '...', starRating: 2, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ី', combined: '$cី', romanized: '...', starRating: 3, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ុ', combined: '$cុ', romanized: '...', starRating: 1, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ូ', combined: '$cូ', romanized: '...', starRating: 2, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ួ', combined: '$cួ', romanized: '...', starRating: 3, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ើ', combined: '$cើ', romanized: '...', starRating: 2, isLearned: true),
      KhmerSpelling(consonant: c, vowelSign: 'ឿ', combined: '$cឿ', romanized: '...', starRating: 0, isLearned: false),
      KhmerSpelling(consonant: c, vowelSign: 'ៀ', combined: '$cៀ', romanized: '...', starRating: 0, isLearned: false),
      KhmerSpelling(consonant: c, vowelSign: 'េ', combined: '$cេ', romanized: '...', starRating: 0, isLearned: false),
    ]
  ];
}
