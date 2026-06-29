/// Model dữ liệu cho bài đánh vần Khmer
/// Ghép phụ âm + nguyên âm thành từ
class KhmerSpelling {
  final String consonant; // Phụ âm
  final String vowelSign; // Dấu nguyên âm (dạng phụ thuộc)
  final String combined; // Kết quả ghép
  final String romanized; // Phiên âm Latin
  final String meaning; // Nghĩa tiếng Việt
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

/// 330 bài đánh vần — 33 phụ âm × 10 nguyên âm
/// 33 phụ âm tiếng Khmer với phiên âm chuẩn
/// 10 nguyên âm: ា, ិ, ី, ុ, ូ, ួ, ើ, ឿ, ៀ, េ
class KhmerSpellingData {
  KhmerSpellingData._();

  // Bảng phiên âm phụ âm Khmer (theo chuẩn phát âm thực tế)
  // Series 1 (a-series): kết thúc bằng 'a'
  // Series 2 (o-series): kết thúc bằng 'o' hoặc 'ea'
  static const Map<String, String> _consonantRoman = {
    'ក': 'ka',
    'ខ': 'kha',
    'គ': 'ko',
    'ឃ': 'kho',
    'ង': 'ngo',
    'ច': 'cha',
    'ឆ': 'chho',
    'ជ': 'cho',
    'ឈ': 'chhô',
    'ញ': 'nho',
    'ដ': 'da',
    'ឋ': 'tha',
    'ឌ': 'do',
    'ឍ': 'tho',
    'ណ': 'na',
    'ត': 'ta',
    'ថ': 'tha',
    'ទ': 'to',
    'ធ': 'tho',
    'ន': 'no',
    'ប': 'ba',
    'ផ': 'pha',
    'ព': 'po',
    'ភ': 'pho',
    'ម': 'mo',
    'យ': 'yo',
    'រ': 'ro',
    'ល': 'lo',
    'វ': 'vo',
    'ស': 'sa',
    'ហ': 'ha',
    'ឡ': 'la',
    'អ': 'a',
  };

  // Bảng phiên âm nguyên âm Khmer
  static const Map<String, String> _vowelRoman = {
    'ា': 'aa', // -aa (dài)
    'ិ': 'e', // -e (ngắn)
    'ី': 'ei', // -ei (dài)
    'ុ': 'o', // -o (ngắn)
    'ូ': 'oo', // -oo (dài)
    'ួ': 'uor', // -uor
    'ើ': 'aeu', // -aeu
    'ឿ': 'oeu', // -oeu
    'ៀ': 'ie', // -ie
    'េ': 'e', // -e
  };

  static String _getRomanized(String consonant, String vowel) {
    final c = _consonantRoman[consonant] ?? consonant;
    final v = _vowelRoman[vowel] ?? vowel;

    // Ghép phụ âm + nguyên âm
    // Nếu phụ âm kết thúc bằng 'a' và nguyên âm không phải 'aa', bỏ 'a' cuối
    if (c.endsWith('a') && v != 'aa') {
      return c.substring(0, c.length - 1) + v;
    }
    // Nếu phụ âm kết thúc bằng 'o' và nguyên âm là 'o' hoặc 'oo', giữ nguyên
    if (c.endsWith('o') && (v == 'o' || v == 'oo')) {
      return c + v;
    }
    return c + v;
  }

  static final List<KhmerSpelling> lessons = [
    for (var c in [
      // 33 Phụ âm tiếng Khmer
      'ក', 'ខ', 'គ', 'ឃ', 'ង', // Nhóm 1
      'ច', 'ឆ', 'ជ', 'ឈ', 'ញ', // Nhóm 2
      'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ', // Nhóm 3
      'ត', 'ថ', 'ទ', 'ធ', 'ន', // Nhóm 4
      'ប', 'ផ', 'ព', 'ភ', 'ម', // Nhóm 5
      'យ', 'រ', 'ល', 'វ', // Nhóm 6
      'ស', 'ហ', 'ឡ', 'អ', // Nhóm 7
    ])
      for (var v in ['ា', 'ិ', 'ី', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ'])
        KhmerSpelling(
          consonant: c,
          vowelSign: v,
          combined: '$c$v',
          romanized: _getRomanized(c, v),
        ),
  ];
}
