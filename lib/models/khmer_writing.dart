/// Model dữ liệu cho bài tập viết chữ Khmer
class KhmerWriting {
  final String character;     // Ký tự cần viết
  final String romanized;     // Phiên âm Latin
  final String type;          // 'consonant', 'vowel', 'combined'
  final String hint;          // Hướng dẫn viết
  int starRating;
  bool isLearned;

  KhmerWriting({
    required this.character,
    required this.romanized,
    this.type = 'consonant',
    this.hint = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 20 bài tập viết cơ bản
class KhmerWritingData {
  KhmerWritingData._();

  static final List<KhmerWriting> lessons = [
    // ══ Nhóm 1: Phụ âm cơ bản ══
    KhmerWriting(character: 'ក', romanized: 'ko', type: 'consonant',
      hint: 'Bắt đầu từ đầu bên trái, vẽ vòng tròn rồi kéo nét thẳng xuống'),
    KhmerWriting(character: 'ខ', romanized: 'kho', type: 'consonant',
      hint: 'Giống chữ ក nhưng thêm một nét cong bên phải'),
    KhmerWriting(character: 'គ', romanized: 'ko', type: 'consonant',
      hint: 'Vẽ vòng tròn rồi kéo hai nét thẳng xuống'),
    KhmerWriting(character: 'ង', romanized: 'ngo', type: 'consonant',
      hint: 'Vẽ vòng tròn nhỏ rồi kéo nét cong sang phải'),
    KhmerWriting(character: 'ច', romanized: 'co', type: 'consonant',
      hint: 'Bắt đầu bằng nét cong, rồi kéo xuống dưới'),

    // ══ Nhóm 2: Phụ âm nâng cao ══
    KhmerWriting(character: 'ដ', romanized: 'do', type: 'consonant',
      hint: 'Vẽ nét thẳng đứng rồi thêm vòng cong bên phải'),
    KhmerWriting(character: 'ត', romanized: 'to', type: 'consonant',
      hint: 'Vẽ hai vòng tròn nối liền nhau'),
    KhmerWriting(character: 'ន', romanized: 'no', type: 'consonant',
      hint: 'Vẽ nét cong mềm mại giống chữ U ngược'),
    KhmerWriting(character: 'ប', romanized: 'bo', type: 'consonant',
      hint: 'Bắt đầu từ trên, vẽ vòng tròn rồi kéo thẳng xuống'),
    KhmerWriting(character: 'ម', romanized: 'mo', type: 'consonant',
      hint: 'Vẽ hai vòng cong nối tiếp nhau'),

    // ══ Nhóm 3: Nguyên âm ══
    KhmerWriting(character: 'ា', romanized: 'aa', type: 'vowel',
      hint: 'Nét thẳng đứng đơn giản bên phải phụ âm'),
    KhmerWriting(character: 'ិ', romanized: 'i', type: 'vowel',
      hint: 'Dấu nhỏ đặt phía trên phụ âm'),
    KhmerWriting(character: 'ី', romanized: 'ii', type: 'vowel',
      hint: 'Hai dấu nhỏ đặt phía trên phụ âm'),
    KhmerWriting(character: 'ុ', romanized: 'u', type: 'vowel',
      hint: 'Dấu nhỏ đặt phía dưới phụ âm'),
    KhmerWriting(character: 'ូ', romanized: 'uu', type: 'vowel',
      hint: 'Dấu dưới kết hợp với nét bên phải'),

    // ══ Nhóm 4: Chữ ghép ══
    KhmerWriting(character: 'កា', romanized: 'kaa', type: 'combined',
      hint: 'Viết phụ âm ក trước, rồi thêm nguyên âm ា'),
    KhmerWriting(character: 'កី', romanized: 'kei', type: 'combined',
      hint: 'Viết phụ âm ក trước, rồi thêm dấu ី phía trên'),
    KhmerWriting(character: 'មា', romanized: 'maa', type: 'combined',
      hint: 'Viết phụ âm ម trước, rồi thêm nguyên âm ា'),
    KhmerWriting(character: 'ដី', romanized: 'dei', type: 'combined',
      hint: 'Viết phụ âm ដ trước, rồi thêm dấu ី phía trên'),
    KhmerWriting(character: 'កូ', romanized: 'kou', type: 'combined',
      hint: 'Viết phụ âm ក trước, rồi thêm nguyên âm ូ'),
  ];
}
