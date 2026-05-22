/// Model dữ liệu cho bài ghép vần đóng Khmer
/// Ghép phụ âm đầu + phụ âm cuối + dấu ់ (Bantoc)
class KhmerClosedSyllable {
  final String initialConsonant; // Phụ âm đầu
  final String finalConsonant;   // Phụ âm cuối (kèm dấu ់)
  final String combined;         // Kết quả ghép
  final String romanized;        // Phiên âm Latin
  final String meaning;          // Nghĩa tiếng Việt
  int starRating;
  bool isLearned;

  KhmerClosedSyllable({
    required this.initialConsonant,
    required this.finalConsonant,
    required this.combined,
    required this.romanized,
    this.meaning = '',
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 80 bài ghép vần đóng — 10 phụ âm đầu × 8 phụ âm cuối
/// 10 phụ âm đầu phổ biến: ក ខ គ ច ដ ត ន ប ម រ
/// 8 phụ âm cuối phổ biến (+ dấu ់): ក់ ង់ ច់ ន់ ញ់ ម់ រ់ ល់
class KhmerClosedSyllableData {
  KhmerClosedSyllableData._();

  static final List<KhmerClosedSyllable> lessons = [
    for (var c in [
      // 10 phụ âm đầu phổ biến
      'ក', 'ខ', 'គ', 'ច', 'ដ',
      'ត', 'ន', 'ប', 'ម', 'រ',
    ]) ...[
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ក់', combined: '${c}ក់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ង់', combined: '${c}ង់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ច់', combined: '${c}ច់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ន់', combined: '${c}ន់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ញ់', combined: '${c}ញ់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ម់', combined: '${c}ម់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'រ់', combined: '${c}រ់', romanized: '...'),
      KhmerClosedSyllable(initialConsonant: c, finalConsonant: 'ល់', combined: '${c}ល់', romanized: '...'),
    ]
  ];
}
