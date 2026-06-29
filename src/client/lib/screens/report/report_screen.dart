import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/score_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_header.dart';
import '../../repositories/progress_repository.dart';

/// Màn hình Báo cáo — Thống kê tiến độ học tập 100% Dynamic từ MongoDB
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ScoreService? _score;
  StorageService? _storage;
  bool _loading = true;

  // Tiến độ học tập chi tiết (được đồng bộ và tải từ Isar + fallback)
  int _consonantDone = 0;
  int _vowelDone = 0;
  int _spellingDone = 0;        // Phụ âm + Nguyên âm
  int _closedSyllableDone = 0; // Phụ âm + Phụ âm + dấu ់
  int _coengDone = 0;           // Phụ âm có chân ្
  int _diacriticalDone = 0;     // Dấu Khmer
  int _readingDone = 0;         // Tập đọc
  int _numberDone = 0;          // Số Khmer
  int _vocabDone = 0;           // Từ vựng

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _score = await ScoreService.getInstance();
    _storage = await StorageService.getInstance();

    // Tải profile mới nhất từ MongoDB
    try {
      await AuthService().fetchProfile();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    // Tải tiến trình chi tiết từ ProgressRepository (offline-first Isar DB)
    try {
      final repo = ProgressRepository.instance;
      _consonantDone = await repo.getCompletedCount('consonant');
      _vowelDone = await repo.getCompletedCount('vowel');
      _spellingDone = await repo.getCompletedCount('spelling');
      _closedSyllableDone = await repo.getCompletedCount('closed_syllable');
      _coengDone = await repo.getCompletedCount('coeng');
      _diacriticalDone = await repo.getCompletedCount('diacritical');
      _readingDone = await repo.getCompletedCount('reading');
      _numberDone = await repo.getCompletedCount('number');
      _vocabDone = _score?.vocabLearned ?? 0;

      // Fallback nếu SharedPreferences lưu lớn hơn (cho tương thích ngược)
      final lettersL = _score?.lettersLearned ?? 0;
      if (lettersL > _consonantDone) _consonantDone = lettersL;

      final vowelsL = _score?.vowelsLearned ?? 0;
      if (vowelsL > _vowelDone) _vowelDone = vowelsL;

      final spellingL = _score?.spellingLearned ?? 0;
      if (spellingL > _spellingDone) _spellingDone = spellingL;

      final diacriticalsL = _score?.diacriticalsLearned ?? 0;
      if (diacriticalsL > _diacriticalDone) _diacriticalDone = diacriticalsL;

      final readingL = _score?.readingLearned ?? 0;
      if (readingL > _readingDone) _readingDone = readingL;

      final numbersL = _score?.numbersLearned ?? 0;
      if (numbersL > _numberDone) _numberDone = numbersL;
    } catch (e) {
      debugPrint('Error loading progress stats from Isar: $e');
      // Tránh crash, dùng fallback từ score_service / shared_preferences
      _consonantDone = _score?.lettersLearned ?? 0;
      _vowelDone = _score?.vowelsLearned ?? 0;
      _spellingDone = _score?.spellingLearned ?? 0;
      _diacriticalDone = _score?.diacriticalsLearned ?? 0;
      _readingDone = _score?.readingLearned ?? 0;
      _numberDone = _score?.numbersLearned ?? 0;
      _vocabDone = _score?.vocabLearned ?? 0;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(context),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent()),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: 'Báo cáo học tập',
      subtitle: 'Dành cho phụ huynh & giáo viên',
      bottomPadding: 24.h,
      onBack: () => Navigator.pop(context),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildOverviewCard(),
        const SizedBox(height: 14),
        _buildProgressCard(),
        const SizedBox(height: 14),
        _buildSkillLevelsCard(),
        const SizedBox(height: 14),
        _buildTestHistoryCard(),
        const SizedBox(height: 14),
        _buildStreakCard(),
        const SizedBox(height: 14),
        _buildRecommendations(),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // OVERVIEW CARD — Dữ liệu từ MongoDB
  // ══════════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════════
  // OVERVIEW CARD — Dữ liệu từ MongoDB
  // ══════════════════════════════════════════════════════════════
  Widget _buildOverviewCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.02),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 14.h),
          // Row of 4 quick stats cards
          Row(
            children: [
              _quickStatCard('image/sao.png', '${_score?.totalStars ?? 0}', 'Tổng sao', const Color(0xFFB8891A), [const Color(0xFFFFF9EE), const Color(0xFFFFF3DB)]),
              SizedBox(width: 8.w),
              _quickStatCard('image/Cấp ${(_score?.level ?? 1).clamp(1, 5)}.png', '${_score?.level ?? 1}', 'Cấp độ', const Color(0xFF3468A8), [const Color(0xFFF0F4FB), const Color(0xFFE2EBFA)]),
              SizedBox(width: 8.w),
              _quickStatCard('image/Lửa chuổi.png', '${_score?.streak ?? 0}', 'Streak', const Color(0xFFD05A4F), [const Color(0xFFFFF2F0), const Color(0xFFFFE4E1)]),
              SizedBox(width: 8.w),
              _quickStatCard('image/Huy hiệu.png', '${_score?.totalMedals ?? 0}', 'Huy chương', const Color(0xFF7367D6), [const Color(0xFFF4F2FF), const Color(0xFFEBE8FF)]),
            ],
          ),
          SizedBox(height: 18.h),
          // Level progress header
          Row(
            children: [
              Text(
                'Tiến trình cấp ${_score?.level ?? 1}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${((_score?.levelProgress ?? 0) * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Custom Gradient Level Progress Bar
          Container(
            height: 10.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * (_score?.levelProgress ?? 0.0);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: width,
                    height: 10.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4580C4), Color(0xFF6A9DD6)],
                      ),
                      borderRadius: BorderRadius.circular(5.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 18.h),
          // Row of 3 stats
          Row(
            children: [
              _statCard('image/Học.png', '${_score?.totalLessonsCompleted ?? 0}', 'Bài học', const Color(0xFF3DA06A), [const Color(0xFFF2FAF5), const Color(0xFFE5F5EC)]),
              SizedBox(width: 8.w),
              _statCard('image/Trò chơi.png', '${_score?.totalGamesPlayed ?? 0}', 'Game', const Color(0xFF4A9BB5), [const Color(0xFFF0F8FA), const Color(0xFFE3F1F6)]),
              SizedBox(width: 8.w),
              _statCard('image/XP.png', '${_score?.totalXp ?? 0}', 'XP', const Color(0xFFB8891A), [const Color(0xFFFFF9EE), const Color(0xFFFFF3DB)]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard(String imagePath, String value, String label, Color color, List<Color> cardGradient) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardGradient,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.1), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.02),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 28.w, height: 28.w, fit: BoxFit.contain),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String imagePath, String value, String label, Color color, List<Color> cardGradient) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardGradient,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.1), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.02),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 32.w, height: 32.w, fit: BoxFit.contain),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PROGRESS CARD — Dữ liệu Dynamic từ MongoDB
  // ══════════════════════════════════════════════════════════════
  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.02),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 Tiến độ học tập',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 18.h),
          _customProgressRow(
            'Phụ âm',
            'image/Phụ âm.png',
            _consonantDone,
            33,
            AppColors.primary,
            [AppColors.primary, AppColors.primaryLight],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Nguyên âm',
            'image/Nguyên âm.png',
            _vowelDone,
            24,
            AppColors.coral,
            [AppColors.coral, AppColors.coralLight],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Số Khmer',
            'image/Học số.png',
            _numberDone,
            10,
            AppColors.tertiary,
            [AppColors.tertiary, AppColors.tertiaryLight],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Phụ âm + Nguyên âm',
            'image/Học phụ âm và nguyên âm.png',
            _spellingDone,
            330,
            AppColors.violet,
            [AppColors.violet, AppColors.violetLight],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Phụ âm + Phụ âm',
            'image/Phụ âm va phụ âm.png',
            _closedSyllableDone,
            80,
            const Color(0xFF3468A8),
            [const Color(0xFF3468A8), const Color(0xFF4580C4)],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Phụ âm có chân ្',
            'image/phụ âm có chân.png',
            _coengDone,
            75,
            AppColors.secondary,
            [AppColors.secondary, AppColors.secondaryLight],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Dấu Khmer',
            'image/Học dấu.png',
            _diacriticalDone,
            12,
            const Color(0xFF9089E0),
            [const Color(0xFF9089E0), const Color(0xFFFF80AB)],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Tập đọc',
            'image/Tập đọc.png',
            _readingDone,
            5,
            const Color(0xFF00ACC1),
            [const Color(0xFF00ACC1), const Color(0xFF80DEEA)],
          ),
          SizedBox(height: 16.h),
          _customProgressRow(
            'Từ vựng',
            'image/Sách.png',
            _vocabDone,
            38,
            const Color(0xFF2D8054),
            [const Color(0xFF2D8054), const Color(0xFF6BBF8E)],
          ),
        ],
      ),
    );
  }

  Widget _customProgressRow(
    String label,
    String iconAsset,
    int current,
    int total,
    Color color,
    List<Color> gradientColors,
  ) {
    final pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.all(5.w),
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => Icon(Icons.menu_book_rounded, color: color, size: 20.sp),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$current/$total (${(pct * 100).toInt()}%)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * pct;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: width,
                        height: 10.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SKILL LEVELS CARD — Dynamic từ MongoDB learningProgress
  // ══════════════════════════════════════════════════════════════
  Widget _buildSkillLevelsCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.02),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Kỹ năng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 18.h),
          _customSkillRow('Nghe', _score?.listeningLevel ?? 0, const Color(0xFF3DA06A), Icons.hearing_rounded, [const Color(0xFF3DA06A), const Color(0xFF6BBF8E)]),
          SizedBox(height: 14.h),
          _customSkillRow('Nói', _score?.speakingLevel ?? 0, const Color(0xFF4580C4), Icons.record_voice_over_rounded, [const Color(0xFF4580C4), const Color(0xFF6A9DD6)]),
          SizedBox(height: 14.h),
          _customSkillRow('Đọc', _score?.readingLevel ?? 0, const Color(0xFF7367D6), Icons.menu_book_rounded, [const Color(0xFF7367D6), const Color(0xFF9089E0)]),
          SizedBox(height: 14.h),
          _customSkillRow('Viết', _score?.writingLevel ?? 0, const Color(0xFFB8891A), Icons.edit_rounded, [const Color(0xFFB8891A), const Color(0xFFD4A430)]),
        ],
      ),
    );
  }

  Widget _customSkillRow(String label, int level, Color color, IconData icon, List<Color> gradientColors) {
    final pct = (level / 100.0).clamp(0.0, 1.0);
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$level/100',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * pct;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: width,
                        height: 10.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TEST HISTORY CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildTestHistoryCard() {
    final history = _storage?.getTestHistory() ?? [];
    final avg = _score?.avgTestScore ?? 0;
    final totalTests = _score?.totalTests ?? 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.02),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Kết quả kiểm tra',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _miniStat('Tổng bài', '$totalTests', const Color(0xFF4580C4)),
              SizedBox(width: 10.w),
              _miniStat('Điểm TB', '${avg.toInt()}%', avg >= 70 ? const Color(0xFF3DA06A) : const Color(0xFFD05A4F)),
            ],
          ),
          if (history.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              'Lịch sử gần đây:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            ...history.reversed.take(5).map((t) {
              final pct = ((t['correct'] as int) / (t['total'] as int) * 100).toInt();
              final diff = ['Dễ', 'TB', 'Khó'][t['difficulty'] as int];
              final date = DateTime.tryParse(t['date'] as String);
              final dateStr = date != null ? '${date.day}/${date.month}' : '';
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      pct >= 70 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 18.sp,
                      color: pct >= 70 ? const Color(0xFF3DA06A) : const Color(0xFFD05A4F),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$dateStr — $diff — ${t['correct']}/${t['total']} ($pct%)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 16.sp,
                          color: i < (t['stars'] as int) ? const Color(0xFFFFD54F) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'Chưa có bài kiểm tra nào.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.w),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _score?.streak ?? 0;
    final totalStudyTime = _score?.totalStudyTime ?? 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.02),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⏱️ Thời gian học',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _miniStat('Streak', '$streak ngày', const Color(0xFFD05A4F)),
              SizedBox(width: 8.w),
              _miniStat('Tổng thời gian', '$totalStudyTime phút', const Color(0xFF4580C4)),
              SizedBox(width: 8.w),
              _miniStat('Bài học', '${_score?.totalLessonsCompleted ?? 0}', const Color(0xFF3DA06A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final letterProg = _score?.lettersLearned ?? 0;
    final avgScore = _score?.avgTestScore ?? 0;

    final tips = <String>[];
    if (letterProg < 10) tips.add('💡 Nên học thêm phụ âm cơ bản mỗi ngày');
    if (avgScore < 70 && avgScore > 0) tips.add('📝 Cần ôn tập lại — điểm TB dưới 70%');
    if ((_score?.streak ?? 0) < 3) tips.add('🔥 Khuyến khích học liên tục mỗi ngày');
    if ((_score?.vocabLearned ?? 0) < 5) tips.add('📚 Nên bắt đầu học từ vựng theo chủ đề');
    if ((_score?.listeningLevel ?? 0) < 30) tips.add('🎧 Nên luyện nghe nhiều hơn');
    if ((_score?.speakingLevel ?? 0) < 30) tips.add('🗣️ Nên luyện nói nhiều hơn');
    if (tips.isEmpty) tips.add('🎉 Bé đang học rất tốt! Tiếp tục phát huy!');

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFFFF59D), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57F17).withValues(alpha: 0.03),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Khuyến nghị',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF57F17),
            ),
          ),
          SizedBox(height: 12.h),
          ...tips.map((t) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  t,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
