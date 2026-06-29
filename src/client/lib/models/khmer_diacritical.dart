/// Model dữ liệu cho dấu Khmer
class KhmerDiacritical {
  final String character;      // Ký tự dấu
  final String name;           // Tên dấu (tiếng Khmer)
  final String romanized;      // Phiên âm Latin
  final String description;    // Mô tả chức năng
  final String example;        // Ví dụ kết hợp
  final String exampleMeaning; // Nghĩa
  int starRating;
  bool isLearned;

  KhmerDiacritical({
    required this.character,
    required this.name,
    required this.romanized,
    this.description = '',
    this.example = '',
    this.exampleMeaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// Các dấu Khmer thường dùng
class KhmerDiacriticalData {
  KhmerDiacriticalData._();

  static final List<KhmerDiacritical> diacriticals = [
    KhmerDiacritical(
      character: '់', name: 'បន្តក់', romanized: 'Bantoc',
      description: 'Dấu ngắn - rút gọn nguyên âm',
      example: 'កក់', exampleMeaning: 'gội',
    ),
    KhmerDiacritical(
      character: 'ំ', name: 'និគ្គហិត', romanized: 'Nikahit',
      description: 'Dấu âm mũi - thêm âm "m"',
      example: 'កំ', exampleMeaning: 'nắm',
    ),
    KhmerDiacritical(
      character: 'ះ', name: 'រះមុក', romanized: 'Reahmuk',
      description: 'Dấu hơi thở - thêm âm "h"',
      example: 'សះ', exampleMeaning: 'lành',
    ),
    KhmerDiacritical(
      character: 'ៈ', name: 'យុគលពិន្ទុ', romanized: 'Yukolpintu',
      description: 'Dấu hai chấm - ngắn hóa nguyên âm',
      example: 'នៈ', exampleMeaning: 'ấy',
    ),
    KhmerDiacritical(
      character: '៉', name: 'មូសិកទន្ត', romanized: 'Musekadoan',
      description: 'Chuyển phụ âm hàng ô sang hàng o',
      example: 'ម៉ា', exampleMeaning: 'mẹ',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '៊', name: 'ត្រីសព្ទ', romanized: 'Treysap',
      description: 'Chuyển phụ âm hàng o sang hàng ô',
      example: 'ស៊ី', exampleMeaning: 'ăn',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '្', name: 'ជើង', romanized: 'Cheung (Coeng)',
      description: 'Phụ âm dưới - ghép phụ âm kép',
      example: 'ស្រា', exampleMeaning: 'rượu',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: 'ៗ', name: 'លេខទោ', romanized: 'Lekto',
      description: 'Dấu lặp từ - lặp lại từ trước',
      example: 'ធំៗ', exampleMeaning: 'lớn lớn',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '។', name: 'ខ័ណ្ឌ', romanized: 'Khan',
      description: 'Dấu chấm câu - kết thúc câu',
      example: 'ខ្ញុំទៅ។', exampleMeaning: 'Tôi đi.',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '៎', name: 'កាកបាត', romanized: 'Kakabat',
      description: 'Dấu nhấn mạnh cảm xúc',
      example: 'អត់៎', exampleMeaning: 'không đâu!',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '៌', name: 'របាត', romanized: 'Robat',
      description: 'Dấu "r" viết trên - thay thế រ',
      example: 'សម្ម៌', exampleMeaning: 'dharma',
      starRating: 0, isLearned: false,
    ),
    KhmerDiacritical(
      character: '័', name: 'សំយោគសញ្ញា', romanized: 'Samyok Sannya',
      description: 'Dấu thay đổi nguyên âm mặc định',
      example: 'ខ័ន', exampleMeaning: 'chặn',
      starRating: 0, isLearned: false,
    ),
  ];
}
