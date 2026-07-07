import 'package:flutter/material.dart';

/// Model dữ liệu cho mỗi dòng trong bài tập đọc
class KhmerReadLine {
  final String khmer;      // Chữ Khmer
  final String romanized;  // Phiên âm Latin
  final String meaning;    // Nghĩa tiếng Việt

  const KhmerReadLine({
    required this.khmer,
    required this.romanized,
    required this.meaning,
  });
}

/// Model dữ liệu cho bài tập đọc Khmer
class KhmerReading {
  final String title;      // Tên bài học
  final String subtitle;   // Phụ đề mô tả ngắn
  final String emoji;      // Biểu tượng cảm xúc đại diện
  final Color color;       // Màu sắc chủ đạo của bài học
  final List<KhmerReadLine> lines; // Danh sách các câu/dòng đọc
  int starRating;          // Đánh giá sao (0 - 3)
  bool isLearned;          // Đã hoàn thành học hay chưa

  KhmerReading({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.lines,
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// Dữ liệu tĩnh của các bài tập đọc Khmer
class KhmerReadingData {
  KhmerReadingData._();

  static final List<KhmerReading> lessons = [
    KhmerReading(
      title: 'Bài 1: Phụ âm cơ bản',
      subtitle: 'Đọc phụ âm ក - ខ',
      emoji: '📖',
      color: const Color(0xFF4CAF50),
      lines: [
        const KhmerReadLine(khmer: 'ក   ខ', romanized: 'Ka   Kha', meaning: 'Phụ âm Ka và Kha'),
        const KhmerReadLine(khmer: 'ា  េ  ែ', romanized: 'aa  ey  ae', meaning: 'Các nguyên âm phụ'),
        const KhmerReadLine(khmer: 'កា   ការ   កកេរ', romanized: 'Kaa   Kar   Kaker', meaning: 'Từ ghép với phụ âm ក'),
        const KhmerReadLine(khmer: 'ខ   ខែ', romanized: 'Kha   Khae', meaning: 'Từ ghép với phụ âm ខ'),
      ],
    ),
    KhmerReading(
      title: 'Bài 2: Từ đơn giản',
      subtitle: 'Đọc từ 1-2 âm tiết',
      emoji: '📗',
      color: const Color(0xFF2196F3),
      lines: [
        const KhmerReadLine(khmer: 'កា', romanized: 'Kaa', meaning: 'Con quạ'),
        const KhmerReadLine(khmer: 'គោ', romanized: 'Ko', meaning: 'Con bò'),
        const KhmerReadLine(khmer: 'ឆ្មា', romanized: 'Chma', meaning: 'Con mèo'),
        const KhmerReadLine(khmer: 'ឆ្កែ', romanized: 'Chkae', meaning: 'Con chó'),
        const KhmerReadLine(khmer: 'ត្រី', romanized: 'Trey', meaning: 'Con cá'),
      ],
    ),
    KhmerReading(
      title: 'Bài 3: Câu ngắn',
      subtitle: 'Đọc câu đơn giản',
      emoji: '📘',
      color: const Color(0xFFE91E63),
      lines: [
        const KhmerReadLine(khmer: 'ម៉ែ ស្រឡាញ់ ខ្ញុំ', romanized: 'Mae srolanh knhom', meaning: 'Mẹ yêu con'),
        const KhmerReadLine(khmer: 'ខ្ញុំ ទៅ សាលា', romanized: 'Knhom tov sala', meaning: 'Con đi học'),
        const KhmerReadLine(khmer: 'ប៉ា ធ្វើ ការ', romanized: 'Pa thveu ka', meaning: 'Bố đi làm'),
      ],
    ),
    KhmerReading(
      title: 'Bài 4: Số đếm',
      subtitle: 'Đọc số từ 1-10',
      emoji: '📙',
      color: const Color(0xFFFF9800),
      lines: [
        const KhmerReadLine(khmer: '១ ២ ៣ ៤ ៥', romanized: 'Muoy Pi Bey Buon Pram', meaning: '1 2 3 4 5'),
        const KhmerReadLine(khmer: '៦ ៧ ៨ ៩ ១០', romanized: 'Prammuoy Prampil Prambey Prambuon Dop', meaning: '6 7 8 9 10'),
      ],
    ),
    KhmerReading(
      title: 'Bài 5: Đoạn văn',
      subtitle: 'Đọc đoạn văn ngắn',
      emoji: '📕',
      color: const Color(0xFF7E57C2),
      lines: [
        const KhmerReadLine(khmer: 'ខ្ញុំ ឈ្មោះ សុខា។', romanized: 'Knhom chhmuoh Sokha.', meaning: 'Tôi tên là Sokha.'),
        const KhmerReadLine(khmer: 'ខ្ញុំ រៀន នៅ សាលា។', romanized: 'Knhom rien nov sala.', meaning: 'Tôi học ở trường.'),
        const KhmerReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ គ្រូ។', romanized: 'Knhom srolanh kru.', meaning: 'Tôi yêu cô giáo.'),
        const KhmerReadLine(khmer: 'ខ្ញុំ ស្រឡាញ់ ម៉ែ ប៉ា។', romanized: 'Knhom srolanh mae pa.', meaning: 'Tôi yêu mẹ bố.'),
      ],
    ),
  ];
}
