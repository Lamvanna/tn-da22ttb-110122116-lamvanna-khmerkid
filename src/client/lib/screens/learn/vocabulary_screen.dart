import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vocabulary.dart';
import '../../widgets/app_header.dart';
import '../../services/score_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../services/lesson_service.dart';

/// Màn hình học từ vựng Khmer theo chủ đề — Premium UI/UX & Live Data from MongoDB
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  int _selectedCat = 0;
  String? _playingWord;
  Set<String> _learnedWords = {};
  StorageService? _storage;
  ScoreService? _scoreService;

  List<VocabCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initProgress().then((_) {
      _loadOnlineData();
    });
  }

  Future<void> _initProgress() async {
    _storage = await StorageService.getInstance();
    _scoreService = await ScoreService.getInstance();
    if (mounted) {
      setState(() {
        _learnedWords = _storage!.getLearnedVocab();
      });
    }
  }

  Future<void> _loadOnlineData() async {
    try {
      final lessonService = await LessonService.getInstance();
      final onlineLessons = await lessonService.fetchLessonsByType('vocabulary');
      
      if (onlineLessons.isNotEmpty) {
        // Gom nhóm các từ vựng theo trường category
        final Map<String, List<KhmerWord>> grouped = {};
        for (final l in onlineLessons) {
          // Lọc ra các từ vựng active
          if (l['isActive'] == false) continue;

          final khmer = l['khmerText']?.toString() ?? '';
          final romanized = l['romanized']?.toString() ?? '';
          final meaning = l['meaning']?.toString() ?? '';
          final pronunciation = l['pronunciation']?.toString() ?? '';
          final categoryName = l['category']?.toString() ?? 'Từ vựng';
          
          final emoji = _getDefaultEmoji(categoryName, khmer);
          
          final word = KhmerWord(
            khmer: khmer,
            romanized: romanized,
            meaning: meaning,
            pronunciation: pronunciation,
            emoji: emoji,
            category: categoryName,
          );
          
          grouped.putIfAbsent(categoryName, () => []).add(word);
        }
        
        final List<VocabCategory> parsedCats = [];
        const Map<String, Color> themeColors = {
          'Động vật': Color(0xFF4CAF50),
          'Trái cây': Color(0xFFFF9800),
          'Gia đình': Color(0xFFE91E63),
          'Cây cối': Color(0xFF2E7D32),
          'Đồ uống': Color(0xFF0288D1),
          'Thức ăn': Color(0xFFF57C00),
          'Xã hội': Color(0xFF673AB7),
          'Con người': Color(0xFF009688),
          'Học tập': Color(0xFF3F51B5),
        };
        
        const Map<String, String> themeEmojis = {
          'Động vật': '🐘',
          'Trái cây': '🍎',
          'Gia đình': '👪',
          'Cây cối': '🌲',
          'Đồ uống': '🥤',
          'Thức ăn': '🍚',
          'Xã hội': '🏢',
          'Con người': '👥',
          'Học tập': '📚',
        };
        
        grouped.forEach((catName, wordsList) {
          final color = themeColors[catName] ?? const Color(0xFF607D8B);
          final emoji = themeEmojis[catName] ?? '📝';
          parsedCats.add(VocabCategory(
            name: catName,
            emoji: emoji,
            color: color,
            words: wordsList,
          ));
        });
        
        // Sắp xếp các danh mục cho đẹp mắt
        parsedCats.sort((a, b) {
          final order = ['Động vật', 'Trái cây', 'Gia đình', 'Học tập'];
          final indexA = order.indexOf(a.name);
          final indexB = order.indexOf(b.name);
          if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
          if (indexA != -1) return -1;
          if (indexB != -1) return 1;
          return a.name.compareTo(b.name);
        });

        if (mounted) {
          setState(() {
            _categories = parsedCats;
            _isLoading = false;
          });
        }
      } else {
        // Fallback sang dữ liệu mẫu tĩnh nếu MongoDB trống
        if (mounted) {
          setState(() {
            _categories = KhmerVocabularyData.categories;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading online vocabulary: $e');
      if (mounted) {
        setState(() {
          _categories = KhmerVocabularyData.categories;
          _isLoading = false;
        });
      }
    }
  }

  String _getDefaultEmoji(String category, String khmer) {
    const Map<String, String> wordEmojis = {
      'ឆ្កែ': '🐕',
      'ឆ្មា': '🐱',
      'ដំរី': '🐘',
      'សេះ': '🐴',
      'គោ': '🐄',
      'មាន់': '🐓',
      'ត្រី': '🐟',
      'បក្សី': '🐦',
      'ចេក': '🍌',
      'ដូង': '🥥',
      'ស្វាយ': '🥭',
      'ប៉ា': '👨',
      'ម៉ែ': '👩',
      'តា': '👴',
      'យាយ': '👵',
      'បង': '🧑',
      'ប្អូន': '👶',
      'ផ្ка': '🌸',
      'ផ្ទះ': '🏠',
      'ទឹក': '💧',
      'បាយ': '🍚',
      'សាលារៀន': '🏫',
      'គ្រូបង្រៀន': '👩‍🏫',
      'សៀវភៅ': '📚',
      'ប៊ិច': '🖊️',
    };
    if (wordEmojis.containsKey(khmer)) {
      return wordEmojis[khmer]!;
    }
    
    if (category.contains('Động vật')) return '🐾';
    if (category.contains('Trái cây')) return '🍎';
    if (category.contains('Gia đình')) return '👪';
    if (category.contains('Học tập') || category.contains('trường')) return '✏️';
    return '📝';
  }

  Future<void> _speak(String text) async {
    if (_playingWord != null) return;
    setState(() => _playingWord = text);
    
    // TtsService tự động phát âm chuẩn tiếng Khmer
    await TtsService.instance.speakKhmerLetter(character: text);
    
    if (mounted) {
      setState(() => _playingWord = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                    ),
                  )
                : _categories.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có dữ liệu từ vựng nào.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(height: 16.h),
                          _buildCategoryTabs(_categories),
                          SizedBox(height: 16.h),
                          _buildCategoryInfo(_categories[_selectedCat]),
                          SizedBox(height: 10.h),
                          Expanded(child: _buildWordList(_categories[_selectedCat])),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // Header thống nhất của app
  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: context.translate('learn.vocabulary_title'),
      subtitle: 'Khám phá thế giới từ vựng Khmer sinh động',
      onBack: () => Navigator.pop(context),
      bottomPadding: 16.h, // Giảm chiều cao giúp header thon gọn hơn
    );
  }

  // Danh sách chủ đề cuộn mượt mà với Shadow Matching đặc trưng
  Widget _buildCategoryTabs(List<VocabCategory> cats) {
    return SizedBox(
      height: 48.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final c = cats[index];
          final selected = _selectedCat == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: 10.w, bottom: 4.h, top: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: selected ? c.color : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: selected ? c.color : const Color(0xFFE2E8F0),
                  width: 1.2.w,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.color.withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.emoji,
                    style: TextStyle(
                      fontSize: 16.sp,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ]
                    )
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    c.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Dashboard chủ đề hiện tại được nâng cấp giao diện trẻ trung, sinh động
  Widget _buildCategoryInfo(VocabCategory cat) {
    final learned = cat.words.where((w) => _learnedWords.contains(w.khmer)).length;
    final percent = cat.words.isEmpty ? 0.0 : learned / cat.words.length;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cat.color.withValues(alpha: 0.12),
              cat.color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: cat.color.withValues(alpha: 0.25), width: 1.2.w),
          boxShadow: [
            BoxShadow(
              color: cat.color.withValues(alpha: 0.03),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            )
          ]
        ),
        child: Row(
          children: [
            // Huy hiệu chủ đề hình tròn lớn bắt mắt
            Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.15),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  )
                ]
              ),
              child: Center(
                child: Text(cat.emoji, style: TextStyle(fontSize: 32.sp)),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: cat.color.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.translate('learn.words_learned_count', args: {'done': learned, 'total': cat.words.length}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Thanh tiến độ ngang mượt mà phong cách giáo dục cao cấp
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8.h,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 14.w),
            // Hiển thị phần trăm hoàn thành bằng số
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: cat.color.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${(percent * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: cat.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList(VocabCategory cat) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      itemCount: cat.words.length,
      itemBuilder: (context, index) =>
          _buildWordCard(cat.words[index], cat.color, index),
    );
  }

  // Thẻ từ vựng được tái thiết kế lung linh hơn, phân cấp thông tin rõ ràng
  Widget _buildWordCard(KhmerWord word, Color color, int index) {
    final isPlaying = _playingWord == word.khmer;
    final isLearned = _learnedWords.contains(word.khmer);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isPlaying ? color : const Color(0xFFE2E8F0),
          width: isPlaying ? 1.8.w : 1.2.w,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () => _speak(word.khmer),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Khung Emoji được lồng gradient mềm mại
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: color.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      word.emoji,
                      style: TextStyle(
                        fontSize: 28.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1.5),
                          )
                        ]
                      )
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                // Phần nội dung thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.khmer,
                            style: GoogleFonts.battambang(
                              fontSize: 23.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E293B),
                              height: 1.1,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Icon loa phát sáng khi đang phát âm
                          if (isPlaying)
                            Icon(
                              Icons.volume_up_rounded,
                              color: color,
                              size: 20.sp,
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      // Dịch nghĩa nổi bật
                      Text(
                        word.meaning,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Tag phiên âm dạng pastel xinh xắn
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              word.romanized,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (word.pronunciation.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            Text(
                              'Đọc: ${word.pronunciation}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút "Học" / "Tick xanh" được nâng cấp tương tác
                GestureDetector(
                  onTap: () async {
                    if (_storage == null || _scoreService == null) return;
                    if (isLearned) return;

                    // Đánh dấu đã thuộc
                    await _scoreService!.learnVocab(word.khmer);

                    // Cập nhật bộ nhớ cục bộ
                    final updated = _storage!.getLearnedVocab();
                    if (mounted) {
                      setState(() {
                        _learnedWords = updated;
                      });
                    }

                    // Hiển thị dynamic snackbar phong cách cao cấp
                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Text('🎉', style: TextStyle(fontSize: 20.sp)),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Đã thuộc từ "${word.khmer}"! (+5 XP, +1 ⭐)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: isLearned
                          ? const Color(0xFFD1FAE5)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: isLearned
                          ? Border.all(color: const Color(0xFF10B981), width: 1.8.w)
                          : Border.all(color: const Color(0xFFCBD5E1), width: 1.5.w),
                      boxShadow: isLearned
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: isLearned
                          ? Icon(
                              Icons.check_rounded,
                              color: const Color(0xFF059669),
                              size: 20.sp,
                            )
                          : Icon(
                              Icons.add_rounded,
                              color: const Color(0xFF64748B),
                              size: 20.sp,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
