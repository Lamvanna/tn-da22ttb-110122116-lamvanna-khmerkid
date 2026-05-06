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

/// 20 bài đánh vần cơ bản
class KhmerSpellingData {
  KhmerSpellingData._();

  static final List<KhmerSpelling> lessons = [
    // ══ Nhóm 1: Nguyên âm អា (aa) ══
    KhmerSpelling(
      consonant: 'ក', vowelSign: 'ា', combined: 'កា',
      romanized: 'kaa', meaning: 'quạ',
      starRating: 3, isLearned: true),
    KhmerSpelling(
      consonant: 'ខ', vowelSign: 'ា', combined: 'ខា',
      romanized: 'khaa', meaning: 'gió',
      starRating: 3, isLearned: true),
    KhmerSpelling(
      consonant: 'គ', vowelSign: 'ា', combined: 'គា',
      romanized: 'koo', meaning: 'bò',
      starRating: 2, isLearned: true),
    KhmerSpelling(
      consonant: 'ច', vowelSign: 'ា', combined: 'ចា',
      romanized: 'chaa', meaning: 'già'),
    KhmerSpelling(
      consonant: 'ដ', vowelSign: 'ា', combined: 'ដា',
      romanized: 'daa', meaning: 'đặt'),

    // ══ Nhóm 2: Nguyên âm អិ (i) ══
    KhmerSpelling(
      consonant: 'ក', vowelSign: 'ិ', combined: 'កិ',
      romanized: 'ke', meaning: 'công việc'),
    KhmerSpelling(
      consonant: 'ម', vowelSign: 'ិ', combined: 'មិ',
      romanized: 'mi', meaning: 'không'),
    KhmerSpelling(
      consonant: 'ន', vowelSign: 'ិ', combined: 'និ',
      romanized: 'ni', meaning: 'và'),
    KhmerSpelling(
      consonant: 'ស', vowelSign: 'ិ', combined: 'សិ',
      romanized: 'se', meaning: 'học'),

    // ══ Nhóm 3: Nguyên âm អី (ii) ══
    KhmerSpelling(
      consonant: 'ក', vowelSign: 'ី', combined: 'កី',
      romanized: 'kei', meaning: 'bẩn'),
    KhmerSpelling(
      consonant: 'ម', vowelSign: 'ី', combined: 'មី',
      romanized: 'mei', meaning: 'mì'),
    KhmerSpelling(
      consonant: 'ដ', vowelSign: 'ី', combined: 'ដី',
      romanized: 'dei', meaning: 'đất'),

    // ══ Nhóm 4: Nguyên âm អុ (u) ══
    KhmerSpelling(
      consonant: 'ក', vowelSign: 'ុ', combined: 'កុ',
      romanized: 'ko', meaning: 'cò'),
    KhmerSpelling(
      consonant: 'ម', vowelSign: 'ុ', combined: 'មុ',
      romanized: 'mo', meaning: 'trước'),
    KhmerSpelling(
      consonant: 'រ', vowelSign: 'ុ', combined: 'រុ',
      romanized: 'ro', meaning: 'mùa'),

    // ══ Nhóm 5: Nguyên âm អូ (uu) ══
    KhmerSpelling(
      consonant: 'ក', vowelSign: 'ូ', combined: 'កូ',
      romanized: 'kou', meaning: 'con'),
    KhmerSpelling(
      consonant: 'ម', vowelSign: 'ូ', combined: 'មូ',
      romanized: 'mou', meaning: 'chuột'),
    KhmerSpelling(
      consonant: 'គ', vowelSign: 'ូ', combined: 'គូ',
      romanized: 'kou', meaning: 'đôi'),
    KhmerSpelling(
      consonant: 'ប', vowelSign: 'ូ', combined: 'បូ',
      romanized: 'bou', meaning: 'cộng'),
    KhmerSpelling(
      consonant: 'ល', vowelSign: 'ូ', combined: 'លូ',
      romanized: 'lou', meaning: 'nuốt'),
  ];
}
