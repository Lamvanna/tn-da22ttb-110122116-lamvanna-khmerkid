import 'package:flutter/material.dart';

/// Model dữ liệu cho từ vựng Khmer
class KhmerWord {
  final String khmer;
  final String romanized;
  final String pronunciation;
  final String meaning;
  final String emoji;
  final String category;
  bool isLearned;

  KhmerWord({
    required this.khmer,
    required this.romanized,
    this.pronunciation = '',
    required this.meaning,
    required this.emoji,
    required this.category,
    this.isLearned = false,
  });
}

/// Danh mục từ vựng
class VocabCategory {
  final String name;
  final String emoji;
  final Color color;
  final List<KhmerWord> words;

  const VocabCategory({
    required this.name,
    required this.emoji,
    required this.color,
    required this.words,
  });
}

/// Dữ liệu từ vựng Khmer theo chủ đề
class KhmerVocabularyData {
  KhmerVocabularyData._();

  static final List<VocabCategory> categories = [
    VocabCategory(
      name: 'Động vật',
      emoji: '🐘',
      color: const Color(0xFF4CAF50),
      words: [
        KhmerWord(khmer: 'ឆ្កែ', romanized: 'chkae', pronunciation: 'chkae', meaning: 'Con chó', emoji: '🐕', category: 'Động vật'),
        KhmerWord(khmer: 'ឆ្មា', romanized: 'chma', pronunciation: 'chma', meaning: 'Con mèo', emoji: '🐱', category: 'Động vật'),
        KhmerWord(khmer: 'ដំរី', romanized: 'damrei', pronunciation: 'đamrây', meaning: 'Con voi', emoji: '🐘', category: 'Động vật'),
        KhmerWord(khmer: 'សេះ', romanized: 'seh', pronunciation: 'seh', meaning: 'Con ngựa', emoji: '🐴', category: 'Động vật'),
        KhmerWord(khmer: 'គោ', romanized: 'ko', pronunciation: 'kô', meaning: 'Con bò', emoji: '🐄', category: 'Động vật'),
        KhmerWord(khmer: 'មាន់', romanized: 'moan', pronunciation: 'moan', meaning: 'Con gà', emoji: '🐓', category: 'Động vật'),
        KhmerWord(khmer: 'ត្រី', romanized: 'trey', pronunciation: 'trây', meaning: 'Con cá', emoji: '🐟', category: 'Động vật'),
        KhmerWord(khmer: 'បក្សី', romanized: 'paksei', pronunciation: 'pak-sây', meaning: 'Con chim', emoji: '🐦', category: 'Động vật'),
      ],
    ),
    VocabCategory(
      name: 'Trái cây',
      emoji: '🍎',
      color: const Color(0xFFE91E63),
      words: [
        KhmerWord(khmer: 'ស្វាយ', romanized: 'svay', pronunciation: 'svai', meaning: 'Xoài', emoji: '🥭', category: 'Trái cây'),
        KhmerWord(khmer: 'ចេក', romanized: 'chek', pronunciation: 'chek', meaning: 'Chuối', emoji: '🍌', category: 'Trái cây'),
        KhmerWord(khmer: 'ក្រូច', romanized: 'krouch', pronunciation: 'krouch', meaning: 'Cam', emoji: '🍊', category: 'Trái cây'),
        KhmerWord(khmer: 'ទុរេន', romanized: 'turen', pronunciation: 'turen', meaning: 'Sầu riêng', emoji: '🥝', category: 'Trái cây'),
        KhmerWord(khmer: 'ត្រសក់', romanized: 'trasak', pronunciation: 'trasak', meaning: 'Dưa leo', emoji: '🥒', category: 'Trái cây'),
        KhmerWord(khmer: 'ដូង', romanized: 'doung', pronunciation: 'đoung', meaning: 'Dừa', emoji: '🥥', category: 'Trái cây'),
      ],
    ),
    VocabCategory(
      name: 'Gia đình',
      emoji: '👨‍👩‍👧‍👦',
      color: const Color(0xFF5B9CF5),
      words: [
        KhmerWord(khmer: 'ម៉ែ', romanized: 'mae', pronunciation: 'mae', meaning: 'Mẹ', emoji: '👩', category: 'Gia đình'),
        KhmerWord(khmer: 'ប៉ា', romanized: 'pa', pronunciation: 'pa', meaning: 'Bố', emoji: '👨', category: 'Gia đình'),
        KhmerWord(khmer: 'បង', romanized: 'bong', pronunciation: 'bong', meaning: 'Anh/chị', emoji: '👦', category: 'Gia đình'),
        KhmerWord(khmer: 'ប្អូន', romanized: 'paoun', pronunciation: 'paoun', meaning: 'Em', emoji: '👧', category: 'Gia đình'),
        KhmerWord(khmer: 'តា', romanized: 'ta', pronunciation: 'ta', meaning: 'Ông', emoji: '👴', category: 'Gia đình'),
        KhmerWord(khmer: 'យាយ', romanized: 'yeay', pronunciation: 'yêy', meaning: 'Bà', emoji: '👵', category: 'Gia đình'),
      ],
    ),
    VocabCategory(
      name: 'Màu sắc',
      emoji: '🎨',
      color: const Color(0xFFFF9800),
      words: [
        KhmerWord(khmer: 'ក្រហម', romanized: 'kraham', pronunciation: 'kraham', meaning: 'Đỏ', emoji: '🔴', category: 'Màu sắc'),
        KhmerWord(khmer: 'ខៀវ', romanized: 'khiev', pronunciation: 'khiêv', meaning: 'Xanh dương', emoji: '🔵', category: 'Màu sắc'),
        KhmerWord(khmer: 'បៃតង', romanized: 'baitang', pronunciation: 'bai-tang', meaning: 'Xanh lá', emoji: '🟢', category: 'Màu sắc'),
        KhmerWord(khmer: 'លឿង', romanized: 'lueang', pronunciation: 'lưang', meaning: 'Vàng', emoji: '🟡', category: 'Màu sắc'),
        KhmerWord(khmer: 'ស', romanized: 'sor', pronunciation: 'so', meaning: 'Trắng', emoji: '⚪', category: 'Màu sắc'),
        KhmerWord(khmer: 'ខ្មៅ', romanized: 'khmao', pronunciation: 'khmao', meaning: 'Đen', emoji: '⚫', category: 'Màu sắc'),
      ],
    ),
    VocabCategory(
      name: 'Cơ thể',
      emoji: '🧑',
      color: const Color(0xFF7E57C2),
      words: [
        KhmerWord(khmer: 'ក្បាល', romanized: 'kbal', pronunciation: 'kbal', meaning: 'Đầu', emoji: '🧠', category: 'Cơ thể'),
        KhmerWord(khmer: 'ដៃ', romanized: 'dai', pronunciation: 'đai', meaning: 'Tay', emoji: '✋', category: 'Cơ thể'),
        KhmerWord(khmer: 'ជើង', romanized: 'cheung', pronunciation: 'chưng', meaning: 'Chân', emoji: '🦶', category: 'Cơ thể'),
        KhmerWord(khmer: 'ភ្នែក', romanized: 'phnek', pronunciation: 'phnek', meaning: 'Mắt', emoji: '👁️', category: 'Cơ thể'),
        KhmerWord(khmer: 'ច្រមុះ', romanized: 'chramoh', pronunciation: 'chramoh', meaning: 'Mũi', emoji: '👃', category: 'Cơ thể'),
        KhmerWord(khmer: 'មាត់', romanized: 'moat', pronunciation: 'moat', meaning: 'Miệng', emoji: '👄', category: 'Cơ thể'),
      ],
    ),
    VocabCategory(
      name: 'Trường học',
      emoji: '🏫',
      color: const Color(0xFF00897B),
      words: [
        KhmerWord(khmer: 'សាលា', romanized: 'sala', pronunciation: 'sala', meaning: 'Trường', emoji: '🏫', category: 'Trường học'),
        KhmerWord(khmer: 'គ្រូ', romanized: 'kru', pronunciation: 'kru', meaning: 'Giáo viên', emoji: '👨‍🏫', category: 'Trường học'),
        KhmerWord(khmer: 'សៀវភៅ', romanized: 'sievphov', pronunciation: 'siêvphov', meaning: 'Sách', emoji: '📕', category: 'Trường học'),
        KhmerWord(khmer: 'ខ្មៅដៃ', romanized: 'khmao dai', pronunciation: 'khmao đai', meaning: 'Bút chì', emoji: '✏️', category: 'Trường học'),
        KhmerWord(khmer: 'ដាស', romanized: 'das', pronunciation: 'đas', meaning: 'Cục tẩy', emoji: '🧹', category: 'Trường học'),
        KhmerWord(khmer: 'ក្ដារខៀន', romanized: 'kdar khien', pronunciation: 'kđa khiên', meaning: 'Bảng', emoji: '📋', category: 'Trường học'),
      ],
    ),
  ];

  static List<KhmerWord> get allWords =>
      categories.expand((c) => c.words).toList();
}
