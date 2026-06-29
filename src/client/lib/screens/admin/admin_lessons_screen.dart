import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Bài học — Admin (Premium Redesigned UI)
class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  List<dynamic> _lessons = [];
  bool _loading = true;
  String? _filterType;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  static const _typeLabels = {
    null: 'Tất cả',
    'consonant': 'Phụ âm',
    'vowel': 'Nguyên âm',
    'spelling': 'Ghép vần',
    'closed_syllable': 'Vần đóng',
    'coeng': 'Chữ ghép',
    'vocabulary': 'Từ vựng',
    'sentence': 'Câu',
    'number': 'Số',
  };

  static const _typeColors = {
    'consonant': AppColors.violet,
    'vowel': Color(0xFF0084FF),
    'spelling': Color(0xFF7F39FB),
    'closed_syllable': Color(0xFF0084FF),
    'coeng': Color(0xFF06B6D4),
    'vocabulary': AppColors.tertiary,
    'sentence': AppColors.coral,
    'number': AppColors.secondary,
  };

  static const _typeIcons = {
    'consonant': Icons.sort_by_alpha_rounded,
    'vowel': Icons.font_download_rounded,
    'spelling': Icons.spellcheck_rounded,
    'closed_syllable': Icons.space_bar_rounded,
    'coeng': Icons.layers_rounded,
    'vocabulary': Icons.menu_book_rounded,
    'sentence': Icons.text_fields_rounded,
    'number': Icons.calculate_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadLessons() async {
    setState(() {
      _loading = true;
      _page = 1;
    });
    final result = await AdminService().fetchLessons(
      page: 1,
      limit: 20,
      type: _filterType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _lessons = result['data'] ?? [];
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    _page++;
    final result = await AdminService().fetchLessons(
      page: _page,
      limit: 20,
      type: _filterType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _lessons.addAll(result['data'] ?? []);
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Row
        _buildSearchAndFilterRow(),

        // Match count and loading indicators
        _buildLessonCountBanner(),

        // Lesson Cards List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _lessons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 64.sp, color: AppColors.textHint),
                          SizedBox(height: 12.h),
                          Text(
                            'Chưa có bài học nào',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      color: const Color(0xFF0084FF),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _lessons.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _lessons.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.h),
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)),
                              ),
                            );
                          }
                          return _buildLessonCard(_lessons[index]);
                        },
                      ),
                    ),
        ),

        // FAB Bottom bar
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppColors.cardShadowList,
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _loadLessons(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm bài học...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF0084FF), size: 20.sp),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16.sp, color: AppColors.textHint),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadLessons();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.8),
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          
          // Dropdown Combobox Filter
          _buildFilterSelector(),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      width: 125.w,
      height: 46.h,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _filterType,
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ),
          selectedItemBuilder: (context) {
            return _typeLabels.entries.map((entry) {
              final type = entry.key;
              final label = entry.value;
              final color = type != null ? (_typeColors[type] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);
              final icon = type != null ? (_typeIcons[type] ?? Icons.menu_book_rounded) : Icons.grid_view_rounded;

              return Row(
                children: [
                  SizedBox(width: 10.w),
                  Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: _typeLabels.entries.map((entry) {
            final type = entry.key;
            final label = entry.value;
            final color = type != null ? (_typeColors[type] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);
            final icon = type != null ? (_typeIcons[type] ?? Icons.menu_book_rounded) : Icons.grid_view_rounded;

            return DropdownMenuItem<String?>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _filterType = v;
            });
            _loadLessons();
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
        ),
      ),
    );
  }

  Widget _buildLessonCountBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0084FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Tổng số: ${_lessons.length} bài học',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0084FF),
              ),
            ),
          ),
          const Spacer(),
          if (_loadingMore)
            Text(
              'Đang tải thêm...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final title = lesson['title'] ?? '';
    final type = lesson['type'] ?? '';
    final khmerText = lesson['khmerText'] ?? '';
    final difficulty = lesson['difficulty'] ?? 'beginner';
    final order = lesson['order'] ?? 0;
    final isActive = lesson['isActive'] ?? true;
    final id = lesson['_id']?.toString() ?? lesson['id']?.toString() ?? '';
    final color = _typeColors[type] ?? const Color(0xFF0084FF);
    final typeLabel = _typeLabels[type] ?? type;
    final category = lesson['category']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: isActive
              ? AppColors.outlineVariant.withValues(alpha: 0.4)
              : AppColors.errorRed.withValues(alpha: 0.25),
          width: isActive ? 1.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Side colored accent bar
              Container(
                width: 6.w,
                color: isActive ? color : AppColors.errorRed,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      // Khmer Character Tile (Gradient background)
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.18),
                              color.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            khmerText.isNotEmpty
                                ? (khmerText.length > 3 ? khmerText.substring(0, 3) : khmerText)
                                : '?',
                            style: GoogleFonts.battambang(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Core Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isActive ? AppColors.textPrimary : AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                _tag(typeLabel, color, icon: _typeIcons[type]),
                                if (category.isNotEmpty)
                                  _tag(category, Colors.teal, icon: Icons.category_rounded),
                                _tag(
                                  difficulty == 'beginner'
                                      ? 'Dễ'
                                      : (difficulty == 'intermediate' ? 'Trung bình' : 'Khó'),
                                  difficulty == 'beginner'
                                      ? AppColors.tertiary
                                      : (difficulty == 'intermediate' ? AppColors.secondary : AppColors.coral),
                                  icon: Icons.speed_rounded,
                                ),
                                _tag('#$order', AppColors.textHint, icon: Icons.format_list_numbered_rounded),
                                if (!isActive)
                                  _tag('Ẩn', AppColors.errorRed, icon: Icons.visibility_off_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions Button
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 4,
                        color: AppColors.cardWhite,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18.sp, color: color),
                                SizedBox(width: 10.w),
                                Text(
                                  'Sửa bài học',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18.sp, color: AppColors.errorRed),
                                SizedBox(width: 10.w),
                                Text(
                                  'Xóa bài học',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showLessonForm(lesson);
                          if (v == 'delete') _confirmDelete(id, title);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 155.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0084FF).withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLessonForm(null),
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm bài học mới',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLessonForm(Map<String, dynamic>? lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LessonFormPage(
          lesson: lesson,
          onSaved: _loadLessons,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40.sp),
        title: Text('Xóa bài học?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$title"?\nHành động không thể hoàn tác.',
          textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Xóa', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await AdminService().deleteLesson(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa bài học' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadLessons();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}

class _LessonFormPage extends StatefulWidget {
  final Map<String, dynamic>? lesson;
  final VoidCallback onSaved;

  const _LessonFormPage({
    required this.lesson,
    required this.onSaved,
  });

  @override
  State<_LessonFormPage> createState() => _LessonFormPageState();
}

class _LessonFormPageState extends State<_LessonFormPage> {
  late final bool _isEdit;
  bool _saving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _khmerCtrl;
  late final TextEditingController _romanizedCtrl;
  late final TextEditingController _meaningCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _exampleKhmerCtrl;
  late final TextEditingController _exampleRomanizedCtrl;
  late final TextEditingController _exampleMeaningCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _audioUrlCtrl;
  bool _uploadingImg = false;
  bool _uploadingAudio = false;
  late String _selectedType;
  late String _selectedDifficulty;
  late String _selectedSpellingCategory;
  late bool _isActive;

  final List<String> spellingCategories = [
    'Ghép vần phụ âm - nguyên âm',
    'Ghép vần có dấu',
  ];

  static const _typeLabels = {
    'consonant': 'Phụ âm',
    'vowel': 'Nguyên âm',
    'spelling': 'Ghép vần',
    'closed_syllable': 'Vần đóng',
    'coeng': 'Chữ ghép',
    'vocabulary': 'Từ vựng',
    'sentence': 'Câu',
    'number': 'Số',
  };

  static const _typeColors = {
    'consonant': AppColors.violet,
    'vowel': Color(0xFF0084FF),
    'spelling': Color(0xFF7F39FB),
    'closed_syllable': Color(0xFF0084FF),
    'coeng': Color(0xFF06B6D4),
    'vocabulary': AppColors.tertiary,
    'sentence': AppColors.coral,
    'number': AppColors.secondary,
  };

  static const _typeIcons = {
    'consonant': Icons.sort_by_alpha_rounded,
    'vowel': Icons.font_download_rounded,
    'spelling': Icons.spellcheck_rounded,
    'closed_syllable': Icons.space_bar_rounded,
    'coeng': Icons.layers_rounded,
    'vocabulary': Icons.menu_book_rounded,
    'sentence': Icons.text_fields_rounded,
    'number': Icons.calculate_rounded,
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.lesson != null;
    final lesson = widget.lesson;

    _titleCtrl = TextEditingController(text: lesson?['title'] ?? '');
    _khmerCtrl = TextEditingController(text: lesson?['khmerText'] ?? '');
    _romanizedCtrl = TextEditingController(text: lesson?['romanized'] ?? '');
    _meaningCtrl = TextEditingController(text: lesson?['meaning'] ?? '');
    _orderCtrl = TextEditingController(text: '${lesson?['order'] ?? 0}');
    _categoryCtrl = TextEditingController(text: lesson?['category'] ?? '');
    _selectedType = lesson?['type'] ?? 'consonant';
    _selectedDifficulty = lesson?['difficulty'] ?? 'beginner';
    _isActive = lesson?['isActive'] ?? true;

    final List initExamples = lesson?['examples'] ?? [];
    Map<String, dynamic> firstEx = {};
    if (initExamples.isNotEmpty && initExamples[0] is Map) {
      firstEx = Map<String, dynamic>.from(initExamples[0]);
    }
    _exampleKhmerCtrl = TextEditingController(text: firstEx['khmer']?.toString() ?? '');
    _exampleRomanizedCtrl = TextEditingController(text: firstEx['romanized']?.toString() ?? '');
    _exampleMeaningCtrl = TextEditingController(text: firstEx['meaning']?.toString() ?? '');
    _imageUrlCtrl = TextEditingController(text: lesson?['imageUrl']?.toString() ?? lesson?['image']?.toString() ?? '');
    _audioUrlCtrl = TextEditingController(text: lesson?['audioUrl']?.toString() ?? lesson?['audio']?.toString() ?? '');

    _selectedSpellingCategory = spellingCategories.contains(_categoryCtrl.text)
        ? _categoryCtrl.text
        : spellingCategories[0];
    if (_selectedType == 'spelling' && !spellingCategories.contains(_categoryCtrl.text)) {
      _categoryCtrl.text = _selectedSpellingCategory;
    }

    _titleCtrl.addListener(() => setState(() {}));
    _khmerCtrl.addListener(() => setState(() {}));
    _romanizedCtrl.addListener(() => setState(() {}));
    _meaningCtrl.addListener(() => setState(() {}));
    _orderCtrl.addListener(() => setState(() {}));
    _categoryCtrl.addListener(() => setState(() {}));
    _exampleKhmerCtrl.addListener(() => setState(() {}));
    _exampleRomanizedCtrl.addListener(() => setState(() {}));
    _exampleMeaningCtrl.addListener(() => setState(() {}));
    _imageUrlCtrl.addListener(() => setState(() {}));
    _audioUrlCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _khmerCtrl.dispose();
    _romanizedCtrl.dispose();
    _meaningCtrl.dispose();
    _orderCtrl.dispose();
    _categoryCtrl.dispose();
    _exampleKhmerCtrl.dispose();
    _exampleRomanizedCtrl.dispose();
    _exampleMeaningCtrl.dispose();
    _imageUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
    super.dispose();
  }

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 155.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _prettyField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
    TextStyle? textStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: textStyle ??
              GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500),
            prefixIcon:
                Icon(icon, color: color.withValues(alpha: 0.7), size: 20.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: color.withValues(alpha: 0.7), size: 20.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.8),
            ),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22.sp),
          borderRadius: BorderRadius.circular(14.r),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewLessonCard(Color color) {
    final title = _titleCtrl.text.trim();
    final typeLabel = _typeLabels[_selectedType] ?? _selectedType;
    final khmerText = _khmerCtrl.text.trim();
    final difficulty = _selectedDifficulty;
    final order = _orderCtrl.text.trim();
    final category = _categoryCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: _isActive
              ? color.withValues(alpha: 0.35)
              : AppColors.errorRed.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Side colored accent bar
              Container(
                width: 6.w,
                color: _isActive ? color : AppColors.errorRed,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      // Khmer Character Tile
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.18),
                              color.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            khmerText.isNotEmpty ? khmerText : '?',
                            style: GoogleFonts.battambang(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Core Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'Chưa nhập tiêu đề',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: title.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                _tag(typeLabel, color, icon: _typeIcons[_selectedType]),
                                if (category.isNotEmpty)
                                  _tag(category, Colors.teal, icon: Icons.category_rounded),
                                _tag(
                                  difficulty == 'beginner'
                                      ? 'Dễ'
                                      : (difficulty == 'intermediate' ? 'Trung bình' : 'Khó'),
                                  difficulty == 'beginner'
                                      ? AppColors.tertiary
                                      : (difficulty == 'intermediate'
                                          ? AppColors.secondary
                                          : AppColors.coral),
                                  icon: Icons.speed_rounded,
                                ),
                                _tag('#${order.isNotEmpty ? order : '0'}',
                                    AppColors.textHint, icon: Icons.format_list_numbered_rounded),
                                if (!_isActive)
                                  _tag('Ẩn', AppColors.errorRed, icon: Icons.visibility_off_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final titleText = _titleCtrl.text.trim();
    final khmerText = _khmerCtrl.text.trim();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (titleText.isEmpty || khmerText.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề và chữ Khmer là bắt buộc'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'title': titleText,
      'khmerText': khmerText,
      'romanized': _romanizedCtrl.text.trim(),
      'meaning': _meaningCtrl.text.trim(),
      'type': _selectedType,
      'difficulty': _selectedDifficulty,
      'order': int.tryParse(_orderCtrl.text) ?? 0,
      'category': _categoryCtrl.text.trim(),
      'isActive': _isActive,
      'imageUrl': _imageUrlCtrl.text.trim(),
      'audioUrl': _audioUrlCtrl.text.trim(),
      'examples': [
        {
          'khmer': _exampleKhmerCtrl.text.trim(),
          'romanized': _exampleRomanizedCtrl.text.trim(),
          'meaning': _exampleMeaningCtrl.text.trim(),
        }
      ],
    };

    final result = _isEdit
        ? await AdminService().updateLesson(
            widget.lesson!['_id']?.toString() ??
                widget.lesson!['id']?.toString() ??
                '',
            data)
        : await AdminService().createLesson(data);

    if (!mounted) return;
    setState(() => _saving = false);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? (_isEdit ? 'Đã cập nhật bài học' : 'Đã tạo bài học mới')
            : (result['message'] ?? 'Lỗi')),
        backgroundColor:
            result['success'] == true ? AppColors.tertiary : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (result['success'] == true) {
      widget.onSaved();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formColor = const Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 24.sp),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: formColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.school_rounded, color: formColor, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                _isEdit ? 'Sửa bài học' : 'Thêm bài học mới',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _saving
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                            color: formColor, strokeWidth: 2.w),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Lưu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: formColor,
                      ),
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h +
                  MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIVE PREVIEW HEADER
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 16.sp, color: formColor),
                        SizedBox(width: 6.w),
                        Text(
                          'XEM TRƯỚC BÀI HỌC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: formColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LIVE PREVIEW CARD
                  _buildPreviewLessonCard(_typeColors[_selectedType] ?? const Color(0xFF0084FF)),
                  SizedBox(height: 20.h),

                  // SECTION 1: CONTENT INFO
                  _sectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Nội dung bài học',
                    color: formColor,
                    children: [
                      _prettyField(
                        label: 'Tiêu đề',
                        ctrl: _titleCtrl,
                        hint: 'Nhập tiêu đề bài học',
                        icon: Icons.title_rounded,
                        color: formColor,
                      ),
                      SizedBox(height: 14.h),
                      _prettyField(
                        label: 'Chữ Khmer (Hiển thị)',
                        ctrl: _khmerCtrl,
                        hint: 'Nhập chữ Khmer (Ví dụ: ក)',
                        icon: Icons.translate_rounded,
                        color: formColor,
                        textStyle: GoogleFonts.battambang(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: _prettyField(
                              label: 'Phiên âm',
                              ctrl: _romanizedCtrl,
                              hint: 'Ví dụ: ka',
                              icon: Icons.abc_rounded,
                              color: formColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _prettyField(
                              label: 'Nghĩa từ',
                              ctrl: _meaningCtrl,
                              hint: 'Nhập nghĩa',
                              icon: Icons.info_outline_rounded,
                              color: formColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // SECTION 1.5: EXAMPLE VOCABULARY
                  if (_selectedType == 'consonant' || _selectedType == 'vowel') ...[
                    SizedBox(height: 16.h),
                    _sectionCard(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Từ vựng ví dụ minh họa',
                      color: formColor,
                      children: [
                        _prettyField(
                          label: 'Từ Khmer ví dụ (Ví dụ: កុក)',
                          ctrl: _exampleKhmerCtrl,
                          hint: 'Nhập từ Khmer ví dụ',
                          icon: Icons.translate_rounded,
                          color: formColor,
                          textStyle: GoogleFonts.battambang(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: _prettyField(
                                label: 'Phiên âm ví dụ (Ví dụ: kok)',
                                ctrl: _exampleRomanizedCtrl,
                                hint: 'Phiên âm',
                                icon: Icons.abc_rounded,
                                color: formColor,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _prettyField(
                                label: 'Nghĩa tiếng Việt (Ví dụ: con cò)',
                                ctrl: _exampleMeaningCtrl,
                                hint: 'Nghĩa từ ví dụ',
                                icon: Icons.info_outline_rounded,
                                color: formColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // SECTION 1.6: MEDIA
                  SizedBox(height: 16.h),
                  _sectionCard(
                    icon: Icons.image_outlined,
                    title: 'Hình ảnh & Âm thanh bài học',
                    color: formColor,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _uploadingImg ? null : () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 800,
                                maxHeight: 800,
                                imageQuality: 85,
                              );
                              if (image == null) return;
                              setState(() => _uploadingImg = true);
                              try {
                                final url = await AdminService().uploadImage(image.path);
                                if (url != null) {
                                  _imageUrlCtrl.text = url;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải ảnh lên thành công!'), backgroundColor: AppColors.tertiary),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải ảnh thất bại!'), backgroundColor: AppColors.errorRed),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorRed),
                                );
                              } finally {
                                setState(() => _uploadingImg = false);
                              }
                            },
                            child: Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                              ),
                              child: _uploadingImg
                                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)))
                                  : _imageUrlCtrl.text.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14.r),
                                          child: Image.network(_imageUrlCtrl.text, fit: BoxFit.cover),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_rounded, size: 24.sp, color: formColor),
                                            SizedBox(height: 4.h),
                                            Text('Chọn ảnh', style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: formColor)),
                                          ],
                                        ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _prettyField(
                              label: 'URL hình ảnh minh họa',
                              ctrl: _imageUrlCtrl,
                              hint: 'Dán link ảnh hoặc chọn ảnh',
                              icon: Icons.link_rounded,
                              color: formColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _uploadingAudio ? null : () async {
                              final result = await FilePicker.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                              );
                              if (result == null || result.files.single.path == null) return;
                              setState(() => _uploadingAudio = true);
                              try {
                                final url = await AdminService().uploadAudio(result.files.single.path!);
                                if (url != null) {
                                  _audioUrlCtrl.text = url;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải âm thanh lên thành công!'), backgroundColor: AppColors.tertiary),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tải âm thanh thất bại!'), backgroundColor: AppColors.errorRed),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorRed),
                                );
                              } finally {
                                setState(() => _uploadingAudio = false);
                              }
                            },
                            child: Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                              ),
                              child: _uploadingAudio
                                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)))
                                  : _audioUrlCtrl.text.isNotEmpty
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.audiotrack_rounded, size: 28.sp, color: AppColors.tertiary),
                                            SizedBox(height: 4.h),
                                            Text('Đã có âm', style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: AppColors.tertiary)),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.audiotrack_rounded, size: 24.sp, color: formColor),
                                            SizedBox(height: 4.h),
                                            Text('Chọn âm', style: GoogleFonts.plusJakartaSans(fontSize: 9.sp, fontWeight: FontWeight.w700, color: formColor)),
                                          ],
                                        ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _prettyField(
                              label: 'URL âm thanh phát âm',
                              ctrl: _audioUrlCtrl,
                              hint: 'Dán link âm thanh hoặc chọn tệp',
                              icon: Icons.link_rounded,
                              color: formColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // SECTION 2: CONFIGURATION
                  _sectionCard(
                    icon: Icons.tune_rounded,
                    title: 'Phân loại & Cấu hình',
                    color: formColor,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownField(
                              label: 'Loại bài học',
                              value: _selectedType,
                              icon: Icons.menu_book_rounded,
                              color: formColor,
                              items: [
                                'consonant',
                                'vowel',
                                'spelling',
                                'closed_syllable',
                                'coeng',
                                'vocabulary',
                                'sentence',
                                'number'
                              ]
                                  .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(_typeLabels[t] ?? t)))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedType = v!;
                                if (_selectedType == 'spelling') {
                                  if (!spellingCategories
                                      .contains(_categoryCtrl.text)) {
                                    _categoryCtrl.text =
                                        _selectedSpellingCategory;
                                  }
                                }
                              }),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _dropdownField(
                              label: 'Độ khó',
                              value: _selectedDifficulty,
                              icon: Icons.speed_rounded,
                              color: formColor,
                              items: ['beginner', 'intermediate', 'advanced']
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text({
                                              'beginner': 'Dễ',
                                              'intermediate': 'Trung bình',
                                              'advanced': 'Khó'
                                            }[d] ??
                                            d),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedDifficulty = v!;
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _selectedType == 'spelling'
                                ? _dropdownField(
                                    label: 'Danh mục ghép vần',
                                    value: _selectedSpellingCategory,
                                    icon: Icons.category_rounded,
                                    color: formColor,
                                    items: spellingCategories
                                        .map((c) => DropdownMenuItem(
                                            value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      _selectedSpellingCategory = v!;
                                      _categoryCtrl.text = v;
                                    }),
                                  )
                                : _prettyField(
                                    label: 'Danh mục / Nhóm',
                                    ctrl: _categoryCtrl,
                                    hint: 'Ví dụ: Phụ âm ក',
                                    icon: Icons.category_rounded,
                                    color: formColor,
                                  ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 1,
                            child: _prettyField(
                              label: 'Thứ tự',
                              ctrl: _orderCtrl,
                              hint: '0',
                              icon: Icons.format_list_numbered_rounded,
                              color: formColor,
                              keyboard: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Divider(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      SizedBox(height: 10.h),
                      
                      // Active/Inactive Switch Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? AppColors.tertiary.withValues(alpha: 0.1)
                                  : AppColors.errorRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isActive
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 16.sp,
                              color: _isActive ? AppColors.tertiary : AppColors.errorRed,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái hiển thị',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _isActive
                                      ? 'Học sinh có thể thấy bài này'
                                      : 'Đang ẩn bài này khỏi học sinh',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: Colors.white,
                            activeTrackColor: formColor,
                            inactiveThumbColor: AppColors.textHint,
                            inactiveTrackColor: AppColors.outlineVariant,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
