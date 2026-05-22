/// Model dữ liệu cho bài ghép phụ âm có chân (Coeng ្)
/// Ghép phụ âm trên + ្ + phụ âm dưới + nguyên âm
class KhmerCoeng {
  final String upperConsonant;   // Phụ âm trên
  final String lowerConsonant;   // Phụ âm dưới (chân)
  final String vowel;            // Nguyên âm
  final String combined;         // Kết quả ghép
  final String romanized;        // Phiên âm Latin
  final String meaning;          // Nghĩa tiếng Việt
  int starRating;
  bool isLearned;

  KhmerCoeng({
    required this.upperConsonant,
    required this.lowerConsonant,
    required this.vowel,
    required this.combined,
    required this.romanized,
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 75 bài phụ âm có chân — 15 cụm phụ âm kép × 5 nguyên âm
/// 15 cụm phụ âm kép phổ biến nhất trong tiếng Khmer
/// 5 nguyên âm: ា ិ ី ុ េ
class KhmerCoengData {
  KhmerCoengData._();

  /// Danh sách 15 cặp phụ âm kép phổ biến: (phụ âm trên, phụ âm dưới)
  static const _clusters = [
    ('ក', 'រ'),   // ក្រ - kr
    ('ក', 'ល'),   // ក្ល - kl
    ('ខ', 'ល'),   // ខ្ល - khl
    ('គ', 'រ'),   // គ្រ - kr
    ('ច', 'រ'),   // ច្រ - chr
    ('ដ', 'រ'),   // ដ្រ - dr (ish)
    ('ត', 'រ'),   // ត្រ - tr
    ('ប', 'រ'),   // ប្រ - pr
    ('ផ', 'ក'),   // ផ្ក - phk
    ('ព', 'រ'),   // ព្រ - pr
    ('ព', 'យ'),   // ព្យ - py
    ('ម', 'ល'),   // ម្ល - ml (ish)
    ('ស', 'រ'),   // ស្រ - sr
    ('ស', 'ត'),   // ស្ត - st
    ('ស', 'ព'),   // ស្ព - sp
  ];

  static final List<KhmerCoeng> lessons = [
    for (var cluster in _clusters)
      for (var v in ['ា', 'ិ', 'ី', 'ុ', 'េ'])
        KhmerCoeng(
          upperConsonant: cluster.$1,
          lowerConsonant: cluster.$2,
          vowel: v,
          combined: '${cluster.$1}្${cluster.$2}$v',
          romanized: '...',
        ),
  ];
}
