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
    KhmerConsonantSeries(character: 'ក', romanized: 'ka', pronunciation: 'ka', series: 'o',
      example: 'កា', exampleMeaning: 'quạ'),
    KhmerConsonantSeries(character: 'ខ', romanized: 'kha', pronunciation: 'kha', series: 'o',
      example: 'ខា', exampleMeaning: 'gió'),
    KhmerConsonantSeries(character: 'ច', romanized: 'cha', pronunciation: 'cha', series: 'o',
      example: 'ចាន', exampleMeaning: 'đĩa'),
    KhmerConsonantSeries(character: 'ឆ', romanized: 'chha', pronunciation: 'chha', series: 'o',
      example: 'ឆ្កែ', exampleMeaning: 'chó', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ដ', romanized: 'da', pronunciation: 'đa', series: 'o',
      example: 'ដី', exampleMeaning: 'đất', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឋ', romanized: 'tha', pronunciation: 'tha', series: 'o',
      example: 'ឋាន', exampleMeaning: 'nơi', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ណ', romanized: 'na', pronunciation: 'na', series: 'o',
      example: 'ណា', exampleMeaning: 'nào', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ត', romanized: 'ta', pronunciation: 'ta', series: 'o',
      example: 'តា', exampleMeaning: 'ông', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ថ', romanized: 'tha', pronunciation: 'tha', series: 'o',
      example: 'ថា', exampleMeaning: 'nói', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ប', romanized: 'ba', pronunciation: 'ba', series: 'o',
      example: 'បាយ', exampleMeaning: 'cơm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ផ', romanized: 'pha', pronunciation: 'pha', series: 'o',
      example: 'ផ្កា', exampleMeaning: 'hoa', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ស', romanized: 'sa', pronunciation: 'sa', series: 'o',
      example: 'សាលា', exampleMeaning: 'trường', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ហ', romanized: 'ha', pronunciation: 'ha', series: 'o',
      example: 'ហត់', exampleMeaning: 'mệt', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឡ', romanized: 'la', pronunciation: 'la', series: 'o',
      example: 'ឡាន', exampleMeaning: 'xe', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'អ', romanized: 'a', pronunciation: 'a', series: 'o',
      example: 'អា', exampleMeaning: 'a', starRating: 0, isLearned: false),

    // ══════ HÀNG Ô (អូ series - second series) ══════
    KhmerConsonantSeries(character: 'គ', romanized: 'ko', pronunciation: 'kô', series: 'ô',
      example: 'គេ', exampleMeaning: 'họ', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឃ', romanized: 'kho', pronunciation: 'khô', series: 'ô',
      example: 'ឃើញ', exampleMeaning: 'thấy', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ង', romanized: 'ngo', pronunciation: 'ngô', series: 'ô',
      example: 'ងូត', exampleMeaning: 'tắm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ជ', romanized: 'cho', pronunciation: 'chô', series: 'ô',
      example: 'ជួប', exampleMeaning: 'gặp', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឈ', romanized: 'chho', pronunciation: 'chhô', series: 'ô',
      example: 'ឈឺ', exampleMeaning: 'đau', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ញ', romanized: 'nyo', pronunciation: 'nhô', series: 'ô',
      example: 'ញ៉ាំ', exampleMeaning: 'ăn', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឌ', romanized: 'do', pronunciation: 'đô', series: 'ô',
      example: 'ឌី', exampleMeaning: 'tên riêng', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ឍ', romanized: 'tho', pronunciation: 'thô', series: 'ô',
      example: 'ឍើង', exampleMeaning: 'cầu thang', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ទ', romanized: 'to', pronunciation: 'tô', series: 'ô',
      example: 'ទឹក', exampleMeaning: 'nước', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ធ', romanized: 'tho', pronunciation: 'thô', series: 'ô',
      example: 'ធម្មតា', exampleMeaning: 'bình thường', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ន', romanized: 'no', pronunciation: 'nô', series: 'ô',
      example: 'នំ', exampleMeaning: 'bánh', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ព', romanized: 'po', pronunciation: 'pô', series: 'ô',
      example: 'ពណ៌', exampleMeaning: 'màu', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ភ', romanized: 'pho', pronunciation: 'phô', series: 'ô',
      example: 'ភាសា', exampleMeaning: 'ngôn ngữ', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ម', romanized: 'mo', pronunciation: 'mô', series: 'ô',
      example: 'មាន់', exampleMeaning: 'gà', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'យ', romanized: 'yo', pronunciation: 'yô', series: 'ô',
      example: 'យប់', exampleMeaning: 'đêm', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'រ', romanized: 'ro', pronunciation: 'rô', series: 'ô',
      example: 'រៀន', exampleMeaning: 'học', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'ល', romanized: 'lo', pronunciation: 'lô', series: 'ô',
      example: 'លេង', exampleMeaning: 'chơi', starRating: 0, isLearned: false),
    KhmerConsonantSeries(character: 'វ', romanized: 'vo', pronunciation: 'vô', series: 'ô',
      example: 'វត្ត', exampleMeaning: 'chùa', starRating: 0, isLearned: false),
  ];
}
