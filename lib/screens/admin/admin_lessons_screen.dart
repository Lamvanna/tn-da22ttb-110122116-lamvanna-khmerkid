import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Bài học — Admin
class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});
  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  List<dynamic> _lessons = [];
  bool _loading = true;
  String? _filterType;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollCtrl = ScrollController();

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
    'vowel': AppColors.primary,
    'spelling': Color(0xFF7F39FB),
    'closed_syllable': Color(0xFF0084FF),
    'coeng': AppColors.primaryDark,
    'vocabulary': AppColors.tertiary,
    'sentence': AppColors.coral,
    'number': AppColors.secondary,
  };

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        if (!_loadingMore && _hasMore) _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() { _loading = true; _page = 1; });
    final result = await AdminService().fetchLessons(page: 1, limit: 20, type: _filterType);
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
    final result = await AdminService().fetchLessons(page: _page, limit: 20, type: _filterType);
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
        // ── Filter Chips ──
        SizedBox(
          height: 52.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            children: _typeLabels.entries.map((e) {
              final selected = _filterType == e.key;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilterChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filterType = e.key);
                    _loadLessons();
                  },
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surfaceContainerLowest,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Lesson List ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _lessons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 64.sp, color: AppColors.textHint),
                      SizedBox(height: 12.h),
                      Text('Chưa có bài học nào',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLessons,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                    itemCount: _lessons.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _lessons.length) {
                        return Center(child: Padding(
                          padding: EdgeInsets.all(16.h),
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }
                      return _buildLessonCard(_lessons[index]);
                    },
                  ),
                ),
        ),

        // ── FAB ──
        _buildAddButton(),
      ],
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
    final color = _typeColors[type] ?? AppColors.primary;
    final typeLabel = _typeLabels[type] ?? type;
    final category = lesson['category']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppColors.cardShadowList,
        border: !isActive ? Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Row(
        children: [
          // Type badge
          Container(
            width: 48.w, height: 48.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                khmerText.isNotEmpty ? khmerText.substring(0, khmerText.length > 2 ? 2 : khmerText.length) : '?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp, fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    _tag(typeLabel, color),
                    if (category.isNotEmpty)
                      _tag(category, Colors.teal),
                    _tag(difficulty, AppColors.textSecondary),
                    _tag('#$order', AppColors.textHint),
                    if (!isActive)
                      _tag('Ẩn', AppColors.errorRed),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22.sp),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(Icons.edit_rounded, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w), const Text('Sửa'),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 20.sp, color: AppColors.errorRed),
                SizedBox(width: 8.w), Text('Xóa', style: TextStyle(color: AppColors.errorRed)),
              ])),
            ],
            onSelected: (v) {
              if (v == 'edit') _showLessonForm(lesson);
              if (v == 'delete') _confirmDelete(id, title);
            },
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(text,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildAddButton() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _showLessonForm(null),
            icon: Icon(Icons.add_rounded, size: 22.sp),
            label: Text('Thêm bài học mới',
              style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
          ),
        ),
      ),
    );
  }

  void _showLessonForm(Map<String, dynamic>? lesson) {
    final isEdit = lesson != null;
    final titleCtrl = TextEditingController(text: lesson?['title'] ?? '');
    final khmerCtrl = TextEditingController(text: lesson?['khmerText'] ?? '');
    final romanizedCtrl = TextEditingController(text: lesson?['romanized'] ?? '');
    final meaningCtrl = TextEditingController(text: lesson?['meaning'] ?? '');
    final orderCtrl = TextEditingController(text: '${lesson?['order'] ?? 0}');
    final categoryCtrl = TextEditingController(text: lesson?['category'] ?? '');
    String selectedType = lesson?['type'] ?? 'consonant';
    String selectedDifficulty = lesson?['difficulty'] ?? 'beginner';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final formColor = _typeColors[selectedType] ?? AppColors.primary;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 44.w, height: 5.h,
                  margin: EdgeInsets.only(top: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: formColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_rounded,
                          color: formColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        isEdit ? 'Sửa bài học' : 'Thêm bài học mới',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, size: 24.sp, color: AppColors.textSecondary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
                          padding: EdgeInsets.all(6.w),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h + MediaQuery.of(ctx).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── REAL-TIME PREVIEW CARD ──
                        Container(
                          margin: EdgeInsets.only(bottom: 20.h),
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: AppColors.cardShadowList,
                            border: Border.all(
                              color: formColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 14.sp, color: formColor),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'XEM TRƯỚC TRỰC TIẾP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: formColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  _tag(
                                    selectedDifficulty == 'beginner'
                                        ? 'Dễ'
                                        : (selectedDifficulty == 'intermediate' ? 'Trung bình' : 'Khó'),
                                    selectedDifficulty == 'beginner'
                                        ? AppColors.tertiary
                                        : (selectedDifficulty == 'intermediate' ? AppColors.secondary : AppColors.coral),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              const Divider(height: 1, color: AppColors.outlineVariant),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Container(
                                    width: 52.w, height: 52.w,
                                    decoration: BoxDecoration(
                                      color: formColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        khmerCtrl.text.isNotEmpty ? khmerCtrl.text : '?',
                                        style: GoogleFonts.battambang(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w800,
                                          color: formColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Chưa nhập tiêu đề',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (romanizedCtrl.text.isNotEmpty || meaningCtrl.text.isNotEmpty) ...[
                                          SizedBox(height: 3.h),
                                          Text(
                                            '${romanizedCtrl.text.isNotEmpty ? "[${romanizedCtrl.text}] " : ""}${meaningCtrl.text.isNotEmpty ? "• ${meaningCtrl.text}" : ""}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        SizedBox(height: 6.h),
                                        Wrap(
                                          spacing: 6.w,
                                          runSpacing: 4.h,
                                          children: [
                                            _tag(_typeLabels[selectedType] ?? selectedType, formColor),
                                            if (categoryCtrl.text.isNotEmpty)
                                              _tag(categoryCtrl.text, Colors.teal),
                                            _tag('#${orderCtrl.text.isNotEmpty ? orderCtrl.text : '0'}', AppColors.textHint),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── SECTION 1: CONTENT INFO ──
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: AppColors.cardShadowList,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 18.sp, color: formColor),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Nội dung bài học',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              _formField(
                                label: 'Tiêu đề',
                                ctrl: titleCtrl,
                                hint: 'Nhập tiêu đề bài học',
                                icon: Icons.title_rounded,
                                color: formColor,
                                onChanged: (_) => setSheetState(() {}),
                              ),
                              SizedBox(height: 14.h),
                              _formField(
                                label: 'Chữ Khmer (Hiển thị)',
                                ctrl: khmerCtrl,
                                hint: 'Nhập chữ Khmer (Ví dụ: ក)',
                                icon: Icons.translate_rounded,
                                color: formColor,
                                textStyle: GoogleFonts.battambang(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                onChanged: (_) => setSheetState(() {}),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _formField(
                                      label: 'Phiên âm',
                                      ctrl: romanizedCtrl,
                                      hint: 'Ví dụ: ka',
                                      icon: Icons.abc_rounded,
                                      color: formColor,
                                      onChanged: (_) => setSheetState(() {}),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _formField(
                                      label: 'Nghĩa từ',
                                      ctrl: meaningCtrl,
                                      hint: 'Nhập nghĩa',
                                      icon: Icons.info_outline_rounded,
                                      color: formColor,
                                      onChanged: (_) => setSheetState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // ── SECTION 2: CONFIGURATION ──
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: AppColors.cardShadowList,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 18.sp, color: formColor),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Phân loại & Cấu hình',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _dropdownField(
                                      label: 'Loại bài học',
                                      value: selectedType,
                                      icon: Icons.menu_book_rounded,
                                      color: formColor,
                                      items: ['consonant', 'vowel', 'spelling', 'closed_syllable', 'coeng', 'vocabulary', 'sentence', 'number']
                                          .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t] ?? t)))
                                          .toList(),
                                      onChanged: (v) => setSheetState(() {
                                        selectedType = v!;
                                      }),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _dropdownField(
                                      label: 'Độ khó',
                                      value: selectedDifficulty,
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
                                      onChanged: (v) => setSheetState(() {
                                        selectedDifficulty = v!;
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
                                    child: _formField(
                                      label: 'Danh mục / Nhóm',
                                      ctrl: categoryCtrl,
                                      hint: 'Ví dụ: Phụ âm ក',
                                      icon: Icons.category_rounded,
                                      color: formColor,
                                      onChanged: (_) => setSheetState(() {}),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    flex: 1,
                                    child: _formField(
                                      label: 'Thứ tự',
                                      ctrl: orderCtrl,
                                      hint: '0',
                                      icon: Icons.format_list_numbered_rounded,
                                      color: formColor,
                                      keyboard: TextInputType.number,
                                      onChanged: (_) => setSheetState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // ── ACTIONS ROW ──
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  side: const BorderSide(color: AppColors.outlineVariant),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                                child: Text(
                                  'Hủy',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final data = {
                                    'title': titleCtrl.text.trim(),
                                    'khmerText': khmerCtrl.text.trim(),
                                    'romanized': romanizedCtrl.text.trim(),
                                    'meaning': meaningCtrl.text.trim(),
                                    'type': selectedType,
                                    'difficulty': selectedDifficulty,
                                    'order': int.tryParse(orderCtrl.text) ?? 0,
                                    'category': categoryCtrl.text.trim(),
                                  };

                                  if (data['title']!.toString().isEmpty || data['khmerText']!.toString().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tiêu đề và chữ Khmer là bắt buộc'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                  final result = isEdit
                                      ? await AdminService().updateLesson(
                                          lesson['_id']?.toString() ?? lesson['id']?.toString() ?? '', data)
                                      : await AdminService().createLesson(data);
                                  if (!mounted) return;
                                  _showSnack(
                                    result['success'] == true
                                        ? (isEdit ? 'Đã cập nhật bài học' : 'Đã tạo bài học mới')
                                        : (result['message'] ?? 'Lỗi'),
                                    result['success'] == true ? AppColors.tertiary : AppColors.errorRed,
                                  );
                                  if (result['success'] == true) _loadLessons();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: formColor,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                  elevation: 2,
                                  shadowColor: formColor.withValues(alpha: 0.3),
                                ),
                                icon: Icon(
                                  isEdit ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                                  size: 18.sp,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isEdit ? 'Lưu thay đổi' : 'Tạo bài học',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
        },
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
    TextStyle? textStyle,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: textStyle ?? GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: color, width: 1.5),
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
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22.sp),
              style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              borderRadius: BorderRadius.circular(14.r),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
