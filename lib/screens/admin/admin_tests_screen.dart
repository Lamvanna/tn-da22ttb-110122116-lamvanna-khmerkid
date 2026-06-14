import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_letter.dart';
import '../../services/admin_service.dart';
import '../../services/tts_service.dart';

/// Màn hình Quản lý Câu hỏi Kiểm tra — Admin (Premium UI)
class AdminTestsScreen extends StatefulWidget {
  const AdminTestsScreen({super.key});

  @override
  State<AdminTestsScreen> createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends State<AdminTestsScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  String? _selectedRange;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollCtrl = ScrollController();

  static const _rangeLabels = {
    null: 'Tất cả',
    '1-5': 'Mốc 1-5',
    '6-10': 'Mốc 6-10',
    '13-17': 'Mốc 13-17',
    '19-23': 'Mốc 19-23',
    '25-29': 'Mốc 25-29',
    '31-34': 'Mốc 31-34',
    '36-39': 'Mốc 36-39',
    '1-40': 'Tổng hợp 1-40',
  };

  static const _rangeColors = {
    '1-5': Color(0xFFEC407A),
    '6-10': Color(0xFF2979FF),
    '13-17': Color(0xFFFF1744),
    '19-23': Color(0xFF43A047),
    '25-29': Color(0xFF00ACC1),
    '31-34': Color(0xFFF57C00),
    '36-39': Color(0xFFFFD600),
    '1-40': Color(0xFF7F39FB),
  };

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        if (!_loadingMore && _hasMore) _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _page = 1;
    });
    final result = await AdminService().fetchTestQuestions(
      page: 1,
      limit: 20,
      testRange: _selectedRange,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (!mounted) return;
    setState(() {
      _questions = result['data'] ?? [];
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page++;
    final result = await AdminService().fetchTestQuestions(
      page: _page,
      limit: 20,
      testRange: _selectedRange,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (!mounted) return;
    setState(() {
      _questions.addAll(result['data'] ?? []);
      _hasMore = result['pagination']?['hasNextPage'] ?? false;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Search & Filter Section ──
          _buildSearchAndFilters(),

          // ── Questions List ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _questions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                          itemCount: _questions.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _questions.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              );
                            }
                            return _buildQuestionCard(_questions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormBottomSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Thêm Câu Hỏi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        children: [
          // Search Field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
                _loadQuestions();
              },
              decoration: InputDecoration(
                hintText: 'Tìm câu hỏi...',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textHint, fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _loadQuestions();
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Filter Chips
          SizedBox(
            height: 48.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: _rangeLabels.entries.map((e) {
                final selected = _selectedRange == e.key;
                final color = selected ? (_rangeColors[e.key] ?? AppColors.primary) : AppColors.outlineVariant;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedRange = e.key);
                      _loadQuestions();
                    },
                    selectedColor: color.withValues(alpha: 0.12),
                    checkmarkColor: color,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    side: BorderSide(
                      color: selected ? color : AppColors.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64.sp, color: AppColors.textHint),
          SizedBox(height: 12.h),
          Text(
            'Không tìm thấy câu hỏi nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Hãy nhấn nút bên dưới để thêm mới',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    final range = question['testRange']?.toString() ?? '1-40';
    final rangeColor = _rangeColors[range] ?? AppColors.primary;
    final options = List<String>.from(question['options'] ?? []);
    final answer = question['answer']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: rangeColor, width: 5.w)),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Range Badge & ID/Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: rangeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Mốc: $range',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: rangeColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showFormBottomSheet(question),
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(question),
                        icon: const Icon(Icons.delete_rounded, color: AppColors.errorRed),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Question text with Audio Player
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question['question']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                    onPressed: () {
                      final ans = question['answer']?.toString() ?? '';
                      String char = '';
                      String romanized = '';
                      if (ans.length == 1) {
                        char = ans;
                        final match = KhmerLetterData.consonants.firstWhere(
                          (l) => l.character == ans,
                          orElse: () => KhmerLetterData.consonants.first,
                        );
                        romanized = match.romanized;
                      } else {
                        final match = KhmerLetterData.consonants.firstWhere(
                          (l) => l.romanized.toLowerCase() == ans.toLowerCase(),
                          orElse: () => KhmerLetterData.consonants.first,
                        );
                        char = match.character;
                        romanized = match.romanized;
                      }
                      TtsService.instance.speakKhmerLetter(
                        character: char,
                        romanized: romanized,
                      );
                    },
                    tooltip: 'Nghe thử',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Options display
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: options.map((opt) {
                  final isAnswer = opt == answer;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isAnswer ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.background,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isAnswer ? AppColors.successGreen : AppColors.outlineVariant,
                        width: isAnswer ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAnswer ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 14.sp,
                          color: isAnswer ? AppColors.successGreen : AppColors.textHint,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          opt,
                          style: opt.length <= 2
                              ? GoogleFonts.battambang(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isAnswer ? AppColors.successGreen : AppColors.textPrimary,
                                )
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: isAnswer ? FontWeight.w700 : FontWeight.w500,
                                  color: isAnswer ? AppColors.successGreen : AppColors.textPrimary,
                                ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(dynamic question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa câu hỏi này không?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = question['_id'] ?? '';
              final res = await AdminService().deleteTestQuestion(id);
              if (res['success'] == true) {
                _loadQuestions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa câu hỏi thành công!'), backgroundColor: AppColors.successGreen),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xóa thất bại: ${res['message']}'), backgroundColor: AppColors.errorRed),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFormBottomSheet([dynamic question]) {
    final isEdit = question != null;
    final formKey = GlobalKey<FormState>();

    final qCtrl = TextEditingController(text: isEdit ? question['question'] : '');
    final List<TextEditingController> optCtrls = List.generate(4, (i) {
      if (isEdit) {
        final opts = List<String>.from(question['options'] ?? []);
        return TextEditingController(text: i < opts.length ? opts[i] : '');
      }
      return TextEditingController();
    });

    String selectedRangeVal = isEdit ? (question['testRange'] ?? '1-5') : '1-5';
    String selectedAnsVal = isEdit ? (question['answer'] ?? '') : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.h,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Chỉnh Sửa Câu Hỏi' : 'Thêm Câu Hỏi Mới',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.outlineVariant, height: 20.h),

                      // Input Question
                      Text(
                        'Nội dung câu hỏi',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: qCtrl,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nhập nội dung câu hỏi' : null,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Nghe và chọn chữ cái đúng:',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Dropdown: Test Range
                      Text(
                        'Mốc phạm vi bài kiểm tra',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 6.h),
                      DropdownButtonFormField<String>(
                        value: selectedRangeVal,
                        items: _rangeLabels.keys.where((k) => k != null).map((k) {
                          return DropdownMenuItem(
                            value: k!,
                            child: Text(
                              _rangeLabels[k]!,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedRangeVal = val);
                          }
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Inputs Options
                      Text(
                        'Các phương án lựa chọn',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 8.h),
                      ...List.generate(4, (i) {
                        final examples = ['ក', 'ខ', 'គ', 'ឃ'];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14.r,
                                backgroundColor: AppColors.primarySurface,
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: TextFormField(
                                  controller: optCtrls[i],
                                  onChanged: (val) {
                                    // Cập nhật đáp án đúng có thể chọn nếu trùng
                                    setSheetState(() {});
                                  },
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Nhập phương án ${String.fromCharCode(65 + i)}' : null,
                                  decoration: InputDecoration(
                                    hintText: 'Phương án ${String.fromCharCode(65 + i)} (Ví dụ: ${examples[i]})',
                                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 8.h),

                      // Select Answer Dropdown
                      Text(
                        'Đáp án đúng',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 6.h),
                      DropdownButtonFormField<String>(
                        value: selectedAnsVal.isEmpty ? null : selectedAnsVal,
                        hint: Text('Chọn đáp án đúng', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint)),
                        items: optCtrls
                            .where((c) => c.text.trim().isNotEmpty)
                            .map((c) => c.text.trim())
                            .toSet() // Tránh trùng lặp
                            .map((val) {
                          return DropdownMenuItem(
                            value: val,
                            child: Text(
                              val,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedAnsVal = val);
                          }
                        },
                        validator: (val) => val == null || val.isEmpty ? 'Hãy chọn đáp án đúng' : null,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final data = {
                                'question': qCtrl.text.trim(),
                                'options': optCtrls.map((c) => c.text.trim()).toList(),
                                'answer': selectedAnsVal,
                                'testRange': selectedRangeVal,
                              };

                              Navigator.pop(sheetContext); // Close sheet
                              setState(() => _loading = true);

                              Map<String, dynamic> res;
                              if (isEdit) {
                                res = await AdminService().updateTestQuestion(question['_id'], data);
                              } else {
                                res = await AdminService().createTestQuestion(data);
                              }

                              if (res['success'] == true) {
                                _loadQuestions();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Cập nhật câu hỏi thành công!' : 'Tạo câu hỏi thành công!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              } else {
                                setState(() => _loading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${res['message']}'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEdit ? 'Lưu Thay Đổi' : 'Tạo Câu Hỏi',
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
