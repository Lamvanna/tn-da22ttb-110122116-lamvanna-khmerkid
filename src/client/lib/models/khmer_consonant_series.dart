/// Model dữ liệu cho phụ âm hàng o và hàng ô Khmer
class KhmerConsonantSeries {
  final String character;      // Ký tự phụ âm
  final String romanized;      // Phiên âm Latin
  final String pronunciation;  // Phát âm tiếng Việt
  final String series;         // 'o' hoặc 'ô'
  final String example;        // Ví dụ từ
  final String exampleMeaning; // Nghĩa
  int starRating;
  bool isLearned;

  KhmerConsonantSeries({
    required this.character,
    required this.romanized,
    this.pronunciation = '',
    required this.series,
    this.example = '',
    this.exampleMeaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// Phụ âm Khmer chia theo 2 hàng: hàng o (អ) và hàng ô (អូ)
class KhmerConsonantSeriesData {
  KhmerConsonantSeriesData._();

  static final List<KhmerConsonantSeries> consonants = [
    // ══════ HÀNG O (អ series - first series) ══════
    KhmerConsonantSeries(character: 'ក', romanized: 'Co', pronunciation: 'co', series: 'o',
      example: 'កា', exampleMeaning: 'quạ'),
    KhmerConsonantSeries(character: 'ខ', romanized: 'Kho', pronunciation: 'kho', series: 'o',
      example: 'ខា', exampleMeaning: 'gió'),
    KhmerConsonantSeries(character: 'ច', romanized: 'Cho', pronunciation: 'cho', series: 'o',
      example: 'ចាន', exampleMeaning: 'đĩa'),
    KhmerConsonantSeries(character: 'ឆ', romanized: 'Chho', pronunciation: 'chho', series: 'o',
      example: 'ឆ្កែ', exampleMeaning: 'chó', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ដ', romanized: 'Đo', pronunciation: 'đo', series: 'o',
      example: 'ដី', exampleMeaning: 'đất', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឋ', romanized: 'Tho', pronunciation: 'tho', series: 'o',
      example: 'ឋាន', exampleMeaning: 'nơi', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ណ', romanized: 'No', pronunciation: 'no', series: 'o',
      example: 'ណា', exampleMeaning: 'nào', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ត', romanized: 'To', pronunciation: 'to', series: 'o',
      example: 'តា', exampleMeaning: 'ông', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ថ', romanized: 'Tho', pronunciation: 'tho', series: 'o',
      example: 'ថា', exampleMeaning: 'nói', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ប', romanized: 'Bo', pronunciation: 'bo', series: 'o',
      example: 'បាយ', exampleMeaning: 'cơm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ផ', romanized: 'Pho', pronunciation: 'pho', series: 'o',
      example: 'ផ្កា', exampleMeaning: 'hoa', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ស', romanized: 'So', pronunciation: 'so', series: 'o',
      example: 'សាលា', exampleMeaning: 'trường', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ហ', romanized: 'Ho', pronunciation: 'ho', series: 'o',
      example: 'ហត់', exampleMeaning: 'mệt', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឡ', romanized: 'Lo', pronunciation: 'lo', series: 'o',
      example: 'ឡាន', exampleMeaning: 'xe', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'អ', romanized: 'O', pronunciation: 'o', series: 'o',
      example: 'អា', exampleMeaning: 'a', starRating: 0, isLearned: false),

    // ══════ HÀNG Ô (អូ series - second series) ══════
    KhmerConsonantSeries(character: 'គ', romanized: 'Cô', pronunciation: 'cô', series: 'ô',
      example: 'គេ', exampleMeaning: 'họ', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឃ', romanized: 'Khô', pronunciation: 'khô', series: 'ô',
      example: 'ឃើញ', exampleMeaning: 'thấy', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ង', romanized: 'Ngô', pronunciation: 'ngô', series: 'ô',
      example: 'ងូត', exampleMeaning: 'tắm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ជ', romanized: 'Chô', pronunciation: 'chô', series: 'ô',
      example: 'ជួប', exampleMeaning: 'gặp', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឈ', romanized: 'Chhô', pronunciation: 'chhô', series: 'ô',
      example: 'ឈឺ', exampleMeaning: 'đau', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ញ', romanized: 'Nhô', pronunciation: 'nhô', series: 'ô',
      example: 'ញ៉ាំ', exampleMeaning: 'ăn', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឌ', romanized: 'Đô', pronunciation: 'đô', series: 'ô',
      example: 'ឌី', exampleMeaning: 'tên riêng', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឍ', romanized: 'Thô', pronunciation: 'thô', series: 'ô',
      example: 'ឍើង', exampleMeaning: 'cầu thang', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ទ', romanized: 'Tô', pronunciation: 'tô', series: 'ô',
      example: 'ទឹក', exampleMeaning: 'nước', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ធ', romanized: 'Thô', pronunciation: 'thô', series: 'ô',
      example: 'ធម្មតា', exampleMeaning: 'bình thường', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ន', romanized: 'Nô', pronunciation: 'nô', series: 'ô',
      example: 'នំ', exampleMeaning: 'bánh', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ព', romanized: 'Pô', pronunciation: 'pô', series: 'ô',
      example: 'ពណ៌', exampleMeaning: 'màu', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ភ', romanized: 'Phô', pronunciation: 'phô', series: 'ô',
      example: 'ភាសា', exampleMeaning: 'ngôn ngữ', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ម', romanized: 'Mô', pronunciation: 'mô', series: 'ô',
      example: 'មាន់', exampleMeaning: 'gà', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'យ', romanized: 'Dô', pronunciation: 'dô', series: 'ô',
      example: 'យប់', exampleMeaning: 'đêm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'រ', romanized: 'Rô', pronunciation: 'rô', series: 'ô',
      example: 'រៀន', exampleMeaning: 'học', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ល', romanized: 'Lô', pronunciation: 'lô', series: 'ô',
      example: 'លេង', exampleMeaning: 'chơi', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'វ', romanized: 'Vô', pronunciation: 'vô', series: 'ô',
      example: 'វត្ត', exampleMeaning: 'chùa', starRating: 0, isLearned: false),
  ];
}
