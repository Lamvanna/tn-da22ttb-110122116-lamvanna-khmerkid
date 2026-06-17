import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/admin_service.dart';

/// Màn hình Quản lý Câu hỏi Trò chơi — Admin (Premium UI)
class AdminGamesScreen extends StatefulWidget {
  const AdminGamesScreen({super.key});

  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  String _selectedGameKey = 'letter_catch';
  final _searchCtrl = TextEditingController();

  static const _gameLabels = {
    'letter_catch': 'Bắt chữ Khmer',
    'word_search': 'Giải cứu thú rừng',
    'sentence_builder': 'Đảo quốc Ngữ pháp',
    'math_garden': 'Khu vườn Toán học',
  };

  static const _gameEmojis = {
    'letter_catch': '🔵',
    'word_search': '🌳',
    'sentence_builder': '🗺️',
    'math_garden': '🍎',
  };

  static const _gameColors = {
    'letter_catch': Color(0xFF6366F1), // Chàm sáng (Indigo)
    'word_search': Color(0xFF10B981), // Xanh Emerald sáng
    'sentence_builder': Color(0xFF3B82F6), // Xanh dương sáng
    'math_garden': Color(0xFFF97316), // Cam tươi sáng
  };

  static const _gameIcons = {
    'letter_catch': Icons.abc_rounded,
    'word_search': Icons.grid_on_rounded,
    'sentence_builder': Icons.sort_rounded,
    'math_garden': Icons.calculate_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    final result = await AdminService().fetchGameQuestions(
      page: 1,
      limit: 150,
      gameKey: _selectedGameKey,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _questions = result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF0084FF);
    return Column(
      children: [
        // ── Search & Filter Row ──
        _buildSearchAndFilterRow(),

        // ── Questions List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
              : _questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64.sp, color: AppColors.textHint),
                          SizedBox(height: 12.h),
                          Text(
                            'Không tìm thấy câu hỏi nào',
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
                      onRefresh: _loadQuestions,
                      color: activeColor,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) => _buildQuestionCard(_questions[index]),
                      ),
                    ),
        ),

        // ── Add Button ──
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    final activeColor = const Color(0xFF0084FF);
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
                  prefixIcon: Icon(Icons.search_rounded, color: activeColor, size: 20.sp),
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
                    borderSide: BorderSide(color: activeColor, width: 1.8),
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
        child: DropdownButton<String>(
          value: _selectedGameKey,
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
            return _gameLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final color = _gameColors[key] ?? const Color(0xFF0084FF);
              final icon = _gameIcons[key] ?? Icons.sports_esports_rounded;

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
          items: _gameLabels.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final color = _gameColors[key] ?? const Color(0xFF0084FF);
            final icon = _gameIcons[key] ?? Icons.sports_esports_rounded;
            final emoji = _gameEmojis[key] ?? '';

            return DropdownMenuItem<String>(
              value: key,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$emoji $label',
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
            if (v != null) {
              setState(() {
                _selectedGameKey = v;
              });
              _loadQuestions();
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: AppColors.cardWhite,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final title = q['title'] ?? '';
    final prompt = q['prompt'] ?? '';
    final answer = q['answer'] ?? '';
    final List<dynamic> choices = q['choices'] ?? [];
    final isActive = q['isActive'] ?? true;
    final id = q['_id']?.toString() ?? q['id']?.toString() ?? '';
    final color = const Color(0xFF0084FF);

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
                      // Answer Icon Circle
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            answer.isNotEmpty ? (answer.length > 2 ? answer.substring(0, 2) : answer) : '?',
                            style: GoogleFonts.battambang(
                                fontSize: 16.sp, fontWeight: FontWeight.w800, color: color),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '$prompt ➔ $answer',
                              style: GoogleFonts.battambang(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isActive ? AppColors.textPrimary : AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (choices.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: choices.map((c) => _miniTag(c.toString(), color)).toList(),
                              ),
                            ],
                            if (!isActive) ...[
                              SizedBox(height: 6.h),
                              _miniTag('Ẩn', AppColors.errorRed),
                            ],
                          ],
                        ),
                      ),

                      // Actions
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
                                Icon(Icons.delete_outline_rounded, size: 18.sp, color: AppColors.errorRed),
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
                        onSelected: (v) {
                          if (v == 'edit') _showQuestionForm(q);
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

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.battambang(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
                onTap: () => _showQuestionForm(null),
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Thêm câu hỏi mới',
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

  void _showQuestionForm(Map<String, dynamic>? q) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GameQuestionFormPage(
          gameKey: _selectedGameKey,
          question: q,
          gameColor: const Color(0xFF0084FF),
          gameLabel: _gameLabels[_selectedGameKey] ?? '',
          gameEmoji: _gameEmojis[_selectedGameKey] ?? '',
          gameIcon: _gameIcons[_selectedGameKey] ?? Icons.gamepad_rounded,
          onSaved: () {
            _loadQuestions();
          },
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
        title: Text('Xóa câu hỏi?', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Xóa "$title"?\nHành động này không thể hoàn tác.', textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp)),
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
    final result = await AdminService().deleteGameQuestion(id);
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Đã xóa câu hỏi' : (result['message'] ?? 'Lỗi'),
      result['success'] == true ? AppColors.tertiary : AppColors.errorRed);
    if (result['success'] == true) _loadQuestions();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  FULL-SCREEN FORM PAGE — beautiful, grouped, with live preview
// ════════════════════════════════════════════════════════════════

class _GameQuestionFormPage extends StatefulWidget {
  final String gameKey;
  final Map<String, dynamic>? question;
  final Color gameColor;
  final String gameLabel;
  final String gameEmoji;
  final IconData gameIcon;
  final VoidCallback onSaved;

  const _GameQuestionFormPage({
    required this.gameKey,
    required this.question,
    required this.gameColor,
    required this.gameLabel,
    required this.gameEmoji,
    required this.gameIcon,
    required this.onSaved,
  });

  @override
  State<_GameQuestionFormPage> createState() => _GameQuestionFormPageState();
}

class _GameQuestionFormPageState extends State<_GameQuestionFormPage> {
  late final bool _isEdit;
  bool _saving = false;
  bool _isActive = true;

  // Common controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _promptCtrl;
  late final TextEditingController _answerCtrl;
  final TextEditingController _newChoiceCtrl = TextEditingController();
  List<String> _choices = [];

  // letter_catch
  late final TextEditingController _consonantCtrl;
  late final TextEditingController _vowelCtrl;

  // word_search
  late final TextEditingController _romanizedCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _objectiveCtrl;
  List<List<TextEditingController>> _gridCtrls = [];
  final Set<String> _pathCells = {};  // "row,col" format
  int _gridRows = 6;
  int _gridCols = 5;

  // sentence_builder
  late final TextEditingController _islandNameCtrl;
  late final TextEditingController _sbEmojiCtrl;
  late final TextEditingController _wordTypesCtrl;
  late final TextEditingController _meaningsCtrl;

  // math_garden
  late final TextEditingController _gardenNameCtrl;
  late final TextEditingController _khmerProblemCtrl;
  late final TextEditingController _mgRomanizedCtrl;
  late final TextEditingController _arabicMeaningCtrl;
  late final TextEditingController _visualEmojisCtrl;
  late final TextEditingController _bgGradientCtrl;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.question != null;
    final q = widget.question;

    Map<String, dynamic> ad = {};
    if (q?['additionalData'] is Map) {
      ad = Map<String, dynamic>.from(q!['additionalData']);
    }

    _isActive = q?['isActive'] ?? true;

    _titleCtrl = TextEditingController(text: q?['title'] ?? '');
    _promptCtrl = TextEditingController(text: q?['prompt'] ?? '');
    _answerCtrl = TextEditingController(text: q?['answer'] ?? '');
    final List initChoices = q?['choices'] ?? [];
    _choices = initChoices.map((e) => e.toString()).toList();

    _consonantCtrl = TextEditingController(text: ad['consonant']?.toString() ?? '');
    _vowelCtrl = TextEditingController(text: ad['vowel']?.toString() ?? '');

    _romanizedCtrl = TextEditingController(text: ad['romanized']?.toString() ?? '');
    _emojiCtrl = TextEditingController(text: ad['emoji']?.toString() ?? '');
    _objectiveCtrl = TextEditingController(text: ad['objective']?.toString() ?? '');

    // Parse grid into 2D controllers
    if (ad['grid'] is List) {
      final List gridList = ad['grid'];
      _gridRows = gridList.length;
      if (_gridRows > 0 && gridList[0] is List) {
        _gridCols = (gridList[0] as List).length;
      }
      _gridCtrls = gridList.map<List<TextEditingController>>((row) {
        if (row is List) {
          return row.map<TextEditingController>((cell) {
            final ctrl = TextEditingController(text: cell.toString());
            ctrl.addListener(() => setState(() {}));
            return ctrl;
          }).toList();
        }
        return <TextEditingController>[];
      }).toList();
    }
    // Ensure grid has correct dimensions
    if (_gridCtrls.isEmpty) {
      _gridCtrls = List.generate(_gridRows, (_) => List.generate(_gridCols, (_) {
        final ctrl = TextEditingController();
        ctrl.addListener(() => setState(() {}));
        return ctrl;
      }));
    }

    // Parse path
    if (ad['path'] is List) {
      for (var p in ad['path']) {
        if (p is List && p.length >= 2) {
          _pathCells.add('${p[0]},${p[1]}');
        }
      }
    }

    _islandNameCtrl = TextEditingController(text: ad['islandName']?.toString() ?? '');
    _sbEmojiCtrl = TextEditingController(text: ad['emoji']?.toString() ?? '');
    final List initWT = ad['wordTypes'] is List ? ad['wordTypes'] : [];
    _wordTypesCtrl = TextEditingController(text: initWT.join(', '));
    String meanStr = '';
    if (ad['wordMeanings'] is Map) {
      meanStr = (ad['wordMeanings'] as Map).entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
    _meaningsCtrl = TextEditingController(text: meanStr);

    _gardenNameCtrl = TextEditingController(text: ad['gardenName']?.toString() ?? '');
    _khmerProblemCtrl = TextEditingController(text: ad['khmerProblem']?.toString() ?? '');
    _mgRomanizedCtrl = TextEditingController(text: ad['romanized']?.toString() ?? '');
    _arabicMeaningCtrl = TextEditingController(text: ad['arabicMeaning']?.toString() ?? '');
    final List initVE = ad['visualEmojis'] is List ? ad['visualEmojis'] : [];
    _visualEmojisCtrl = TextEditingController(text: initVE.join(', '));
    final List initBG = ad['bgGradient'] is List ? ad['bgGradient'] : [];
    _bgGradientCtrl = TextEditingController(text: initBG.join(', '));

    // Add listeners to rebuild live preview on text change
    _titleCtrl.addListener(() => setState(() {}));
    _promptCtrl.addListener(() => setState(() {}));
    _answerCtrl.addListener(() => setState(() {}));
    _consonantCtrl.addListener(() => setState(() {}));
    _vowelCtrl.addListener(() => setState(() {}));
    _romanizedCtrl.addListener(() => setState(() {}));
    _emojiCtrl.addListener(() => setState(() {}));
    _objectiveCtrl.addListener(() => setState(() {}));
    _islandNameCtrl.addListener(() => setState(() {}));
    _sbEmojiCtrl.addListener(() => setState(() {}));
    _wordTypesCtrl.addListener(() => setState(() {}));
    _meaningsCtrl.addListener(() => setState(() {}));
    _gardenNameCtrl.addListener(() => setState(() {}));
    _khmerProblemCtrl.addListener(() => setState(() {}));
    _mgRomanizedCtrl.addListener(() => setState(() {}));
    _arabicMeaningCtrl.addListener(() => setState(() {}));
    _visualEmojisCtrl.addListener(() => setState(() {}));
    _bgGradientCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _promptCtrl.dispose();
    _answerCtrl.dispose();
    _newChoiceCtrl.dispose();
    _consonantCtrl.dispose();
    _vowelCtrl.dispose();
    _romanizedCtrl.dispose();
    _emojiCtrl.dispose();
    _objectiveCtrl.dispose();
    _islandNameCtrl.dispose();
    _sbEmojiCtrl.dispose();
    _wordTypesCtrl.dispose();
    _meaningsCtrl.dispose();
    _gardenNameCtrl.dispose();
    _khmerProblemCtrl.dispose();
    _mgRomanizedCtrl.dispose();
    _arabicMeaningCtrl.dispose();
    _visualEmojisCtrl.dispose();
    _bgGradientCtrl.dispose();
    for (var row in _gridCtrls) {
      for (var ctrl in row) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.battambang(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.gameColor;
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.sports_esports_rounded, color: color, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                _isEdit ? 'Sửa câu hỏi' : 'Thêm câu hỏi mới',
                style: GoogleFonts.plusJakartaSans(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                          color: color,
                          strokeWidth: 2.w,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _onSave,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Lưu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Game badge ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.gameEmoji, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Text(widget.gameLabel,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── LIVE PREVIEW CARD ──
            Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 14.sp, color: color),
                      SizedBox(width: 4.w),
                      Text(
                        'XEM TRƯỚC TRỰC TIẾP CÂU HỎI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _isActive ? AppColors.tertiary.withValues(alpha: 0.1) : AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _isActive ? 'Kích hoạt' : 'Ẩn',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: _isActive ? AppColors.tertiary : AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _answerCtrl.text.isNotEmpty
                                ? (_answerCtrl.text.length > 2 ? _answerCtrl.text.substring(0, 2) : _answerCtrl.text)
                                : '?',
                            style: GoogleFonts.battambang(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
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
                              _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Chưa có tiêu đề',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${_promptCtrl.text.isNotEmpty ? _promptCtrl.text : "Chưa nhập gợi ý"} ➔ ${_answerCtrl.text.isNotEmpty ? _answerCtrl.text : "?"}',
                              style: GoogleFonts.battambang(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_choices.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Wrap(
                                spacing: 4.w,
                                runSpacing: 4.h,
                                children: _choices.map<Widget>((c) => _miniTag(c, color)).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SECTION 1: Thông tin cơ bản ──
            _sectionCard(
              icon: Icons.info_outline_rounded,
              title: 'Thông tin cơ bản',
              color: color,
              children: [
                _prettyField(
                  label: 'Tiêu đề',
                  ctrl: _titleCtrl,
                  hint: 'Ví dụ: Bắt chữ - mẹ',
                  icon: Icons.title_rounded,
                  color: color,
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _prettyField(
                        label: 'Câu hỏi / Gợi ý (prompt)',
                        ctrl: _promptCtrl,
                        hint: 'Ví dụ: mẹ',
                        icon: Icons.help_outline_rounded,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _prettyField(
                        label: 'Đáp án đúng',
                        ctrl: _answerCtrl,
                        hint: 'Ví dụ: មា',
                        icon: Icons.check_circle_outline_rounded,
                        color: color,
                        textStyle: GoogleFonts.battambang(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _choicesChipInput(color),
              ],
            ),
            SizedBox(height: 16.h),

            // ── SECTION 2: Cấu hình riêng game ──
            if (widget.gameKey == 'letter_catch') _letterCatchSection(color),
            if (widget.gameKey == 'word_search') _wordSearchSection(color),
            if (widget.gameKey == 'sentence_builder') _sentenceBuilderSection(color),
            if (widget.gameKey == 'math_garden') _mathGardenSection(color),
            SizedBox(height: 16.h),

            // ── SECTION 3: Trạng thái ──
            _sectionCard(
              icon: Icons.toggle_on_rounded,
              title: 'Trạng thái hiển thị',
              color: color,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isActive ? 'Đang kích hoạt' : 'Đã tắt',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp, fontWeight: FontWeight.w700,
                              color: _isActive ? AppColors.tertiary : AppColors.errorRed)),
                          SizedBox(height: 2.h),
                          Text('Câu hỏi ${_isActive ? "sẽ xuất hiện" : "sẽ không xuất hiện"} trong trò chơi',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      activeTrackColor: color.withValues(alpha: 0.5),
                      activeThumbColor: color,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  SECTION BUILDERS (per game type)
  // ═══════════════════════════════════════

  Widget _letterCatchSection(Color color) {
    return _sectionCard(
      icon: Icons.abc_rounded,
      title: 'Cấu hình — Bắt chữ Khmer',
      color: color,
      children: [
        Row(
          children: [
            Expanded(
              child: _prettyField(
                label: 'Phụ âm đúng',
                ctrl: _consonantCtrl,
                hint: 'Ví dụ: ម',
                icon: Icons.text_fields_rounded,
                color: color,
                textStyle: GoogleFonts.battambang(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _prettyField(
                label: 'Nguyên âm đúng',
                ctrl: _vowelCtrl,
                hint: 'Ví dụ: ា',
                icon: Icons.text_fields_rounded,
                color: color,
                textStyle: GoogleFonts.battambang(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16.sp, color: color),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Bé sẽ bắt chữ phụ âm + nguyên âm rơi xuống để ghép thành từ đúng.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wordSearchSection(Color color) {
    return _sectionCard(
      icon: Icons.grid_on_rounded,
      title: 'Cấu hình — Giải cứu thú rừng',
      color: color,
      children: [
        Row(
          children: [
            Expanded(child: _prettyField(label: 'Phiên âm', ctrl: _romanizedCtrl, hint: 'dâm-rei', icon: Icons.record_voice_over_rounded, color: color)),
            SizedBox(width: 12.w),
            Expanded(child: _prettyField(label: 'Emoji thú', ctrl: _emojiCtrl, hint: '🐘', icon: Icons.emoji_emotions_rounded, color: color)),
          ],
        ),
        SizedBox(height: 14.h),
        _prettyField(label: 'Mục tiêu', ctrl: _objectiveCtrl, hint: 'Tìm phụ âm ដ, nguyên âm ំ...', icon: Icons.flag_rounded, color: color),
        SizedBox(height: 16.h),

        // ── Visual Grid Editor ──
        Row(
          children: [
            Icon(Icons.grid_4x4_rounded, size: 16.sp, color: color.withValues(alpha: 0.7)),
            SizedBox(width: 6.w),
            Text('Ma trận chữ cái', style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            Text('$_gridRows × $_gridCols', style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        SizedBox(height: 8.h),

        // Grid size controls
        Row(
          children: [
            _gridSizeBtn('Hàng', _gridRows, 
              onMinus: () { if (_gridRows > 2) setState(() { _gridRows--; _gridCtrls.removeLast(); _pathCells.removeWhere((k) => k.startsWith('$_gridRows,')); }); },
              onPlus: () => setState(() { _gridRows++; _gridCtrls.add(List.generate(_gridCols, (_) {
                final ctrl = TextEditingController();
                ctrl.addListener(() => setState(() {}));
                return ctrl;
              })); }),
              color: color,
            ),
            SizedBox(width: 12.w),
            _gridSizeBtn('Cột', _gridCols,
              onMinus: () { if (_gridCols > 2) setState(() { _gridCols--; for (var row in _gridCtrls) { if (row.length > _gridCols) row.removeLast(); } _pathCells.removeWhere((k) => int.tryParse(k.split(',').last) == _gridCols); }); },
              onPlus: () => setState(() { _gridCols++; for (var row in _gridCtrls) {
                final ctrl = TextEditingController();
                ctrl.addListener(() => setState(() {}));
                row.add(ctrl);
              } }),
              color: color,
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Visual Grid
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              // Column headers
              Row(
                children: [
                  SizedBox(width: 24.w), // spacer for row labels
                  ...List.generate(_gridCols, (c) => Expanded(
                    child: Center(
                      child: Text('$c', style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.textHint)),
                    ),
                  )),
                ],
              ),
              SizedBox(height: 4.h),
              // Grid rows
              ...List.generate(_gridRows, (r) {
                // Ensure row exists
                while (_gridCtrls.length <= r) {
                  _gridCtrls.add(List.generate(_gridCols, (_) {
                    final ctrl = TextEditingController();
                    ctrl.addListener(() => setState(() {}));
                    return ctrl;
                  }));
                }
                while (_gridCtrls[r].length < _gridCols) {
                  final ctrl = TextEditingController();
                  ctrl.addListener(() => setState(() {}));
                  _gridCtrls[r].add(ctrl);
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      // Row label
                      SizedBox(
                        width: 24.w,
                        child: Center(
                          child: Text('$r', style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.textHint)),
                        ),
                      ),
                      // Cells
                      ...List.generate(_gridCols, (c) {
                        final key = '$r,$c';
                        final isPath = _pathCells.contains(key);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              if (isPath) { _pathCells.remove(key); } else { _pathCells.add(key); }
                            }),
                            child: Container(
                              height: 42.w,
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              decoration: BoxDecoration(
                                color: isPath ? color.withValues(alpha: 0.15) : Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: isPath ? color : AppColors.outlineVariant,
                                  width: isPath ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _gridCtrls[r][c],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.battambang(
                                    fontSize: 16.sp,
                                    fontWeight: isPath ? FontWeight.w800 : FontWeight.w500,
                                    color: isPath ? color : AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // Path indicator
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: widget.gameColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16.sp, color: widget.gameColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhập chữ Khmer vào ô → Bấm vào ô để đánh dấu đáp án (viền màu)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w600, color: widget.gameColor)),
                    if (_pathCells.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: _pathCells.map((k) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text('[$k]', style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gridSizeBtn(String label, int value, {required VoidCallback onMinus, required VoidCallback onPlus, required Color color}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            InkWell(onTap: onMinus, child: Container(
              width: 26.w, height: 26.w,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: AppColors.outlineVariant)),
              child: Icon(Icons.remove_rounded, size: 16.sp, color: AppColors.textSecondary),
            )),
            SizedBox(width: 8.w),
            Text('$value', style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w800, color: color)),
            SizedBox(width: 8.w),
            InkWell(onTap: onPlus, child: Container(
              width: 26.w, height: 26.w,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r), border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Icon(Icons.add_rounded, size: 16.sp, color: color),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sentenceBuilderSection(Color color) {
    return _sectionCard(
      icon: Icons.sort_rounded,
      title: 'Cấu hình — Đảo quốc Ngữ pháp',
      color: color,
      children: [
        Row(
          children: [
            Expanded(child: _prettyField(label: 'Tên hòn đảo', ctrl: _islandNameCtrl, hint: 'Đảo Ngọc Trai', icon: Icons.landscape_rounded, color: color)),
            SizedBox(width: 12.w),
            Expanded(child: _prettyField(label: 'Emoji đảo', ctrl: _sbEmojiCtrl, hint: '🏝️', icon: Icons.emoji_emotions_rounded, color: color)),
          ],
        ),
        SizedBox(height: 14.h),
        _prettyField(label: 'Loại từ (subject, verb, object, modifier)', ctrl: _wordTypesCtrl, hint: 'subject, verb, object', icon: Icons.category_rounded, color: color),
        SizedBox(height: 14.h),
        _prettyField(
          label: 'Nghĩa các từ (mỗi dòng: từ_Khmer: nghĩa_Việt)',
          ctrl: _meaningsCtrl,
          hint: 'ខ្ញុំ: Tôi\nទៅ: đi\nសាលារៀន: trường học',
          icon: Icons.translate_rounded,
          color: color,
          maxLines: 5,
          textStyle: GoogleFonts.battambang(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color.withValues(alpha: 0.15))),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16.sp, color: color),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Phần "Lựa chọn" ở trên chính là các từ Khmer đúng theo đúng thứ tự câu.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mathGardenSection(Color color) {
    return _sectionCard(
      icon: Icons.calculate_rounded,
      title: 'Cấu hình — Khu vườn Toán học',
      color: color,
      children: [
        Row(
          children: [
            Expanded(child: _prettyField(label: 'Tên khu vườn', ctrl: _gardenNameCtrl, hint: 'Vườn Táo Đỏ', icon: Icons.park_rounded, color: color)),
            SizedBox(width: 12.w),
            Expanded(child: _prettyField(label: 'Phiên âm', ctrl: _mgRomanizedCtrl, hint: 'prăm', icon: Icons.record_voice_over_rounded, color: color)),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _prettyField(
                label: 'Phép toán Khmer',
                ctrl: _khmerProblemCtrl,
                hint: '🍎🍎🍎🍎🍎',
                icon: Icons.functions_rounded,
                color: color,
                textStyle: GoogleFonts.battambang(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: _prettyField(label: 'Đáp án số Latin', ctrl: _arabicMeaningCtrl, hint: '5', icon: Icons.pin_rounded, color: color)),
          ],
        ),
        SizedBox(height: 14.h),
        _prettyField(label: 'Emoji minh họa (phân tách bằng dấu phẩy)', ctrl: _visualEmojisCtrl, hint: '🍎, 🍎, 🍎, 🍎, 🍎', icon: Icons.emoji_food_beverage_rounded, color: color),
        SizedBox(height: 14.h),
        _prettyField(label: 'Màu nền gradient (2 mã hex)', ctrl: _bgGradientCtrl, hint: '#F57C00, #FFB74D', icon: Icons.palette_rounded, color: color),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color.withValues(alpha: 0.15))),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16.sp, color: color),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('"Đáp án đúng" ở trên là chữ số Khmer (ví dụ: ៥). Đáp án số Latin chỉ là phụ trợ hiển thị.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════
  //  REUSABLE WIDGETS
  // ═══════════════════════════════

  /// Grouped card section with icon header
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          ...AppColors.cardShadowList,
        ],
        border: Border.all(color: color.withValues(alpha: 0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.07),
                  color.withValues(alpha: 0.01),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.5.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w, height: 32.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 16.sp),
                ),
                SizedBox(width: 10.w),
                Text(title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive chip input for choices
  Widget _choicesChipInput(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 16.sp, color: color.withValues(alpha: 0.7)),
            SizedBox(width: 6.w),
            Text('Các lựa chọn trả lời', style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${_choices.length} mục', style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textHint)),
          ],
        ),
        SizedBox(height: 8.h),
        // Chip list
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_choices.isNotEmpty)
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _choices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ch = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(10.w, 6.h, 4.w, 6.h),
                            child: Text(ch, style: GoogleFonts.battambang(
                              fontSize: 15.sp, fontWeight: FontWeight.w700, color: color)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _choices.removeAt(idx)),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Icon(Icons.close_rounded, size: 16.sp, color: color.withValues(alpha: 0.6)),
                            ),
                          ),
                          SizedBox(width: 2.w),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (_choices.isNotEmpty) SizedBox(height: 10.h),
              // Add new choice
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: TextField(
                        controller: _newChoiceCtrl,
                        style: GoogleFonts.battambang(fontSize: 15.sp, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Nhập chữ rồi bấm +',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: color, width: 1.5),
                          ),
                        ),
                        onSubmitted: (val) {
                          final v = val.trim();
                          if (v.isNotEmpty) {
                            setState(() => _choices.add(v));
                            _newChoiceCtrl.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: FilledButton(
                      onPressed: () {
                        final v = _newChoiceCtrl.text.trim();
                        if (v.isNotEmpty) {
                          setState(() => _choices.add(v));
                          _newChoiceCtrl.clear();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pretty form field with left icon indicator
  Widget _prettyField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
    int maxLines = 1,
    TextStyle? textStyle,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color.withValues(alpha: 0.7)),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
          maxLines: maxLines,
          onChanged: onChanged,
          style: textStyle ?? GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════
  //  SAVE LOGIC
  // ═══════════════════════════════

  Future<void> _onSave() async {
    if (_titleCtrl.text.trim().isEmpty || _promptCtrl.text.trim().isEmpty || _answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập Tiêu đề, Câu hỏi và Đáp án',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.errorRed, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);

    final choicesList = List<String>.from(_choices);
    final Map<String, dynamic> ad = {};

    if (widget.gameKey == 'letter_catch') {
      ad['consonant'] = _consonantCtrl.text.trim();
      ad['vowel'] = _vowelCtrl.text.trim();
    } else if (widget.gameKey == 'word_search') {
      ad['romanized'] = _romanizedCtrl.text.trim();
      ad['emoji'] = _emojiCtrl.text.trim();
      ad['objective'] = _objectiveCtrl.text.trim();
      // Build grid from visual editors
      final List<List<String>> gridParsed = [];
      for (int r = 0; r < _gridRows && r < _gridCtrls.length; r++) {
        final row = <String>[];
        for (int c = 0; c < _gridCols && c < _gridCtrls[r].length; c++) {
          row.add(_gridCtrls[r][c].text.trim().isNotEmpty ? _gridCtrls[r][c].text.trim() : '·');
        }
        gridParsed.add(row);
      }
      ad['grid'] = gridParsed;
      // Build path from selected cells
      final List<List<int>> pathParsed = [];
      for (var key in _pathCells) {
        final parts = key.split(',');
        if (parts.length >= 2) {
          final r = int.tryParse(parts[0]);
          final c = int.tryParse(parts[1]);
          if (r != null && c != null) pathParsed.add([r, c]);
        }
      }
      ad['path'] = pathParsed;
    } else if (widget.gameKey == 'sentence_builder') {
      ad['islandName'] = _islandNameCtrl.text.trim();
      ad['emoji'] = _sbEmojiCtrl.text.trim();
      ad['wordTypes'] = _wordTypesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final Map<String, String> mp = {};
      for (var line in _meaningsCtrl.text.split('\n')) {
        final idx = line.indexOf(':');
        if (idx != -1) {
          final k = line.substring(0, idx).trim();
          final v = line.substring(idx + 1).trim();
          if (k.isNotEmpty && v.isNotEmpty) mp[k] = v;
        }
      }
      ad['wordMeanings'] = mp;
    } else if (widget.gameKey == 'math_garden') {
      ad['gardenName'] = _gardenNameCtrl.text.trim();
      ad['khmerProblem'] = _khmerProblemCtrl.text.trim();
      ad['romanized'] = _mgRomanizedCtrl.text.trim();
      ad['arabicMeaning'] = _arabicMeaningCtrl.text.trim();
      ad['visualEmojis'] = _visualEmojisCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      ad['bgGradient'] = _bgGradientCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    final data = {
      'gameKey': widget.gameKey,
      'title': _titleCtrl.text.trim(),
      'prompt': _promptCtrl.text.trim(),
      'answer': _answerCtrl.text.trim(),
      'choices': choicesList,
      'additionalData': ad,
      'isActive': _isActive,
    };

    final q = widget.question;
    final result = _isEdit
      ? await AdminService().updateGameQuestion(q?['_id']?.toString() ?? q?['id']?.toString() ?? '', data)
      : await AdminService().createGameQuestion(data);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? '✅ Đã cập nhật câu hỏi!' : '✅ Đã tạo câu hỏi mới!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.tertiary,
          behavior: SnackBarBehavior.floating));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Có lỗi xảy ra',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating));
    }
  }
}
