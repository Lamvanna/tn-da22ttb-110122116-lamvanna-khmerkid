/// Model dữ liệu cho bài tập viết chữ Khmer
class KhmerWriting {
  final String? id;           // ID từ MongoDB
  final String character;     // Ký tự cần viết
  final String romanized;     // Phiên âm Latin
  final String type;          // 'consonant', 'vowel', 'combined'
  final String hint;          // Hướng dẫn viết
  final String topicKey;      // Key đề tài/chủ đề riêng của bài viết
  final String? audioUrl;     // URL âm thanh thực tế tải lên
  int starRating;
  bool isLearned;

  KhmerWriting({
    this.id,
    required this.character,
    required this.romanized,
    required this.topicKey,
    this.type = 'consonant',
    this.hint = '',
    this.audioUrl,
    this.starRating = 0,
    this.isLearned = false,
  });
}

/// 20 bài tập viết cơ bản
class KhmerWritingData {
  KhmerWritingData._();

  static final List<KhmerWriting> lessons = [
    // ══ Nhóm 1: Động vật ══
    KhmerWriting(character: 'ឆ្មា', romanized: 'chma', type: 'combined', topicKey: 'topic_1',
      hint: 'Con mèo dễ thương'),
    KhmerWriting(character: 'ឆ្កែ', romanized: 'chkae', type: 'combined', topicKey: 'topic_2',
      hint: 'Con chó trung thành'),
    KhmerWriting(character: 'គោ', romanized: 'ko', type: 'combined', topicKey: 'topic_3',
      hint: 'Con bò kéo xe'),
    KhmerWriting(character: 'សេះ', romanized: 'seh', type: 'combined', topicKey: 'topic_4',
      hint: 'Con ngựa chạy nhanh'),
    KhmerWriting(character: 'មាន់', romanized: 'moan', type: 'combined', topicKey: 'topic_5',
      hint: 'Con gà gáy sáng'),
    KhmerWriting(character: 'ត្រី', romanized: 'trey', type: 'combined', topicKey: 'topic_6',
      hint: 'Con cá bơi dưới nước'),
    KhmerWriting(character: 'ដំរី', romanized: 'damrei', type: 'combined', topicKey: 'topic_7',
      hint: 'Con voi to lớn'),

    // ══ Nhóm 2: Gia đình ══
    KhmerWriting(character: 'ប៉ា', romanized: 'pa', type: 'combined', topicKey: 'topic_8',
      hint: 'Bố yêu thương bé'),
    KhmerWriting(character: 'ម៉ែ', romanized: 'mae', type: 'combined', topicKey: 'topic_9',
      hint: 'Mẹ hiền chăm sóc bé'),
    KhmerWriting(character: 'តា', romanized: 'ta', type: 'combined', topicKey: 'topic_10',
      hint: 'Ông kể chuyện hay'),
    KhmerWriting(character: 'យាយ', romanized: 'yeay', type: 'combined', topicKey: 'topic_11',
      hint: 'Bà ru bé ngủ'),
    KhmerWriting(character: 'បង', romanized: 'bong', type: 'combined', topicKey: 'topic_12',
      hint: 'Anh chị nhường nhịn bé'),
    KhmerWriting(character: 'ប្អូន', romanized: 'paoun', type: 'combined', topicKey: 'topic_13',
      hint: 'Em bé đáng yêu'),

    // ══ Nhóm 3: Trái cây & Đồ vật ══
    KhmerWriting(character: 'ចេក', romanized: 'chek', type: 'combined', topicKey: 'topic_14',
      hint: 'Chuối chín vàng ngọt'),
    KhmerWriting(character: 'ដូង', romanized: 'doung', type: 'combined', topicKey: 'topic_15',
      hint: 'Nước dừa thơm mát'),
    KhmerWriting(character: 'ស្វាយ', romanized: 'svay', type: 'combined', topicKey: 'topic_16',
      hint: 'Xoài chín ngọt lịm'),
    KhmerWriting(character: 'សាលា', romanized: 'sala', type: 'combined', topicKey: 'topic_17',
      hint: 'Trường học mến yêu'),
    KhmerWriting(character: 'គ្រូ', romanized: 'kru', type: 'combined', topicKey: 'topic_18',
      hint: 'Cô giáo dạy học'),
    KhmerWriting(character: 'សៀវភៅ', romanized: 'sievphov', type: 'combined', topicKey: 'topic_19',
      hint: 'Sách mở ra tri thức'),
    KhmerWriting(character: 'ដៃ', romanized: 'dai', type: 'combined', topicKey: 'topic_20',
      hint: 'Bàn tay bé nhỏ'),
  ];
}
