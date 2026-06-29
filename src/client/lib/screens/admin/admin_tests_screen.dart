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
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
    return Column(
      children: [
        // ── Search & Filter Section ──
        _buildSearchAndFilterRow(),

        // ── Questions List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _questions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadQuestions,
                      color: const Color(0xFF0084FF),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _questions.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _questions.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF))),
                            );
                          }
                          return _buildQuestionCard(_questions[index]);
                        },
                      ),
                    ),
        ),

        // ── Add Button ──
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    final themeColor = _selectedRange != null ? (_rangeColors[_selectedRange] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);
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
                onSubmitted: (_) => _loadQuestions(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm câu hỏi...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: themeColor, size: 20.sp),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16.sp, color: AppColors.textHint),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadQuestions();
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
                    borderSide: BorderSide(color: themeColor, width: 1.8),
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
      width: 175.w,
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
          value: _selectedRange,
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
            return _rangeLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final color = key != null ? (_rangeColors[key] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);

              return Row(
                children: [
                  SizedBox(width: 10.w),
                  Icon(
                    Icons.assignment_rounded,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
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
          items: _rangeLabels.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final color = key != null ? (_rangeColors[key] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);

            return DropdownMenuItem<String?>(
              value: key,
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
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
              _selectedRange = v;
            });
            _loadQuestions();
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
        ),
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
    final rangeColor = _rangeColors[range] ?? const Color(0xFF0084FF);
    final options = List<String>.from(question['options'] ?? []);
    final answer = question['answer']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar on the left
              Container(
                width: 6.w,
                color: rangeColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Range Badge & Actions Menu
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
                                    Icon(Icons.edit_rounded, size: 18.sp, color: rangeColor),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Sửa câu hỏi',
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
                                    Icon(Icons.delete_rounded, size: 18.sp, color: AppColors.errorRed),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Xóa câu hỏi',
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
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showFormBottomSheet(question);
                              } else if (value == 'delete') {
                                _confirmDelete(question);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // Question text with Audio Player
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              question['question']?.toString() ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF0084FF), size: 22),
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
                                Flexible(
                                  child: Text(
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
              final messenger = ScaffoldMessenger.of(context);
              final res = await AdminService().deleteTestQuestion(id);
              if (res['success'] == true) {
                _loadQuestions();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Xóa câu hỏi thành công!'), backgroundColor: AppColors.successGreen),
                );
              } else {
                messenger.showSnackBar(
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

  Widget _buildAddButton() {
    final themeColor = _selectedRange != null ? (_rangeColors[_selectedRange] ?? const Color(0xFF0084FF)) : const Color(0xFF0084FF);
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
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _showFormBottomSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Thêm câu hỏi kiểm tra',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFormBottomSheet([dynamic question]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TestQuestionFormPage(
          question: question,
          onSaved: _loadQuestions,
        ),
      ),
    );
  }
}

class _TestQuestionFormPage extends StatefulWidget {
  final Map<String, dynamic>? question;
  final VoidCallback onSaved;

  const _TestQuestionFormPage({
    required this.question,
    required this.onSaved,
  });

  @override
  State<_TestQuestionFormPage> createState() => _TestQuestionFormPageState();
}

class _TestQuestionFormPageState extends State<_TestQuestionFormPage> {
  late final bool _isEdit;
  bool _saving = false;

  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _optCtrls;

  late String _selectedRangeVal;
  String _selectedAnsVal = '';

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

  static const _rangeLabels = {
    '1-5': 'Mốc 1-5',
    '6-10': 'Mốc 6-10',
    '13-17': 'Mốc 13-17',
    '19-23': 'Mốc 19-23',
    '25-29': 'Mốc 25-29',
    '31-34': 'Mốc 31-34',
    '36-39': 'Mốc 36-39',
    '1-40': 'Tổng hợp 1-40',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.question != null;
    final q = widget.question;

    _qCtrl = TextEditingController(text: q?['question'] ?? '');
    
    final opts = List<String>.from(q?['options'] ?? []);
    _optCtrls = List.generate(4, (i) {
      return TextEditingController(text: i < opts.length ? opts[i] : '');
    });

    _selectedRangeVal = q?['testRange'] ?? '1-5';
    _selectedAnsVal = q?['answer'] ?? '';

    _qCtrl.addListener(() => setState(() {}));
    for (var ctrl in _optCtrls) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    for (var ctrl in _optCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
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
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
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
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.8)),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: textStyle ?? GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
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
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
    String? hint,
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
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: hint != null ? Text(hint, style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, color: AppColors.textHint)) : null,
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

  Future<void> _save() async {
    final questionText = _qCtrl.text.trim();
    if (questionText.isEmpty) {
      _showSnack('Vui lòng nhập nội dung câu hỏi', AppColors.errorRed);
      return;
    }

    final options = _optCtrls.map((c) => c.text.trim()).toList();
    if (options.any((o) => o.isEmpty)) {
      _showSnack('Vui lòng điền đủ 4 phương án lựa chọn', AppColors.errorRed);
      return;
    }

    if (_selectedAnsVal.isEmpty) {
      _showSnack('Vui lòng chọn đáp án đúng', AppColors.errorRed);
      return;
    }

    if (!options.contains(_selectedAnsVal)) {
      _showSnack('Đáp án đúng không khớp với phương án nào, vui lòng chọn lại', AppColors.errorRed);
      return;
    }

    setState(() => _saving = true);

    final data = {
      'question': questionText,
      'options': options,
      'answer': _selectedAnsVal,
      'testRange': _selectedRangeVal,
    };

    final result = _isEdit
        ? await AdminService().updateTestQuestion(widget.question!['_id'] ?? widget.question!['id'], data)
        : await AdminService().createTestQuestion(data);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      _showSnack(_isEdit ? 'Đã cập nhật câu hỏi' : 'Đã tạo câu hỏi mới', AppColors.successGreen);
      widget.onSaved();
      Navigator.pop(context);
    } else {
      _showSnack(result['message'] ?? 'Lỗi xảy ra', AppColors.errorRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF0084FF);
    final previewColor = _rangeColors[_selectedRangeVal] ?? const Color(0xFF0084FF);

    final validOptions = _optCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24.sp),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w, height: 32.w,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.help_outline_rounded, color: themeColor, size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              _isEdit ? 'Sửa câu hỏi' : 'Thêm câu hỏi mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
                        child: CircularProgressIndicator(color: themeColor, strokeWidth: 2.w),
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
                        color: themeColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // ── Live Preview Card ──
            Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(color: previewColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 14.sp, color: themeColor),
                      SizedBox(width: 4.w),
                      Text(
                        'Xem trước thời gian thực',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: previewColor, width: 4.w)),
                    ),
                    padding: EdgeInsets.only(left: 12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: previewColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Mốc: $_selectedRangeVal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: previewColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF0084FF), size: 20),
                              onPressed: () {
                                final ans = _selectedAnsVal;
                                if (ans.isEmpty) return;
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
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _qCtrl.text.isEmpty ? 'Câu hỏi kiểm tra?' : _qCtrl.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: List.generate(4, (i) {
                            final text = _optCtrls[i].text.trim();
                            final isAnswer = text.isNotEmpty && text == _selectedAnsVal;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: isAnswer ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.background,
                                borderRadius: BorderRadius.circular(8.r),
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
                                    size: 13.sp,
                                    color: isAnswer ? AppColors.successGreen : AppColors.textHint,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    text.isEmpty ? 'Phương án ${String.fromCharCode(65 + i)}' : text,
                                    style: text.length <= 2
                                        ? GoogleFonts.battambang(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isAnswer ? AppColors.successGreen : AppColors.textPrimary,
                                          )
                                        : GoogleFonts.plusJakartaSans(
                                            fontSize: 12.sp,
                                            fontWeight: isAnswer ? FontWeight.w700 : FontWeight.w500,
                                            color: isAnswer ? AppColors.successGreen : AppColors.textPrimary,
                                          ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Question Info Section ──
            _sectionCard(
              icon: Icons.help_outline_rounded,
              title: 'Nội dung câu hỏi',
              color: const Color(0xFF0084FF),
              children: [
                _prettyField(
                  label: 'Nội dung câu hỏi',
                  ctrl: _qCtrl,
                  hint: 'Ví dụ: Nghe và chọn chữ cái đúng:',
                  icon: Icons.title_rounded,
                  color: const Color(0xFF0084FF),
                ),
                SizedBox(height: 16.h),
                _dropdownField(
                  label: 'Mốc phạm vi kiểm tra',
                  value: _selectedRangeVal,
                  items: _rangeLabels.keys.map((k) {
                    return DropdownMenuItem(
                      value: k,
                      child: Text(_rangeLabels[k]!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRangeVal = val);
                  },
                  icon: Icons.timeline_rounded,
                  color: const Color(0xFF0084FF),
                ),
              ],
            ),

            // ── Options Section ──
            _sectionCard(
              icon: Icons.list_rounded,
              title: 'Các phương án lựa chọn',
              color: AppColors.secondary,
              children: [
                ...List.generate(4, (i) {
                  final examples = ['ក', 'ខ', 'គ', 'ឃ'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14.r,
                          backgroundColor: const Color(0xFF0084FF).withValues(alpha: 0.1),
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0084FF)),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _prettyField(
                            label: 'Phương án ${String.fromCharCode(65 + i)}',
                            ctrl: _optCtrls[i],
                            hint: 'Ví dụ: ${examples[i]}',
                            icon: Icons.edit_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

            // ── Answer Section ──
            _sectionCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'Đáp án chính xác',
              color: AppColors.tertiary,
              children: [
                _dropdownField(
                  label: 'Đáp án đúng',
                  value: validOptions.contains(_selectedAnsVal) && _selectedAnsVal.isNotEmpty ? _selectedAnsVal : null,
                  hint: 'Chọn một trong các phương án đã nhập',
                  items: validOptions.map((val) {
                    return DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: val.length <= 2 ? GoogleFonts.battambang(fontSize: 16.sp, fontWeight: FontWeight.bold) : GoogleFonts.plusJakartaSans(fontSize: 14.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAnsVal = val);
                  },
                  icon: Icons.done_all_rounded,
                  color: AppColors.tertiary,
                ),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
