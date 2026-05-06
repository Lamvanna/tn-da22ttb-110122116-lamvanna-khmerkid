import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_vowel.dart';
import 'vowel_sheets.dart';

/// Chi tiết 1 nguyên âm — 3 bước: Nghe, Nói, Viết (giống phụ âm)
class VowelDetailScreen extends StatefulWidget {
  final int initialIndex;
  const VowelDetailScreen({super.key, this.initialIndex = 0});
  @override
  State<VowelDetailScreen> createState() => _VowelDetailScreenState();
}

class _VowelDetailScreenState extends State<VowelDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerVowel> _vowels = KhmerVowelData.vowels;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _isPlaying = false;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    await _tts.setLanguage(hasKhmer ? 'km' : langList.any((l) => l.contains('vi')) ? 'vi-VN' : 'en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _isPlaying = false); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _isPlaying = false); });
    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady || _isPlaying) return;
    setState(() => _isPlaying = true);
    await _tts.speak(text);
    _markStepComplete(0);
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));
    if (_completedSteps[_idx]!.length == 3) _onCompleted();
  }

  void _onCompleted() {
    _vowels[_idx].isLearned = true;
    _vowels[_idx].starRating = 3;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _vowels.length - 1;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Chúc mừng!', style: GoogleFonts.plusJakartaSans(
              fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Bạn đã hoàn thành nguyên âm "${_v.character}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) =>
                Icon(Icons.star_rounded, size: 28, color: AppColors.secondary))),
            const SizedBox(height: 6),
            Text('+15 XP ⭐', style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 20),
            if (hasNext) ...[
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _goTo(_idx + 1); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Học nguyên âm tiếp →', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
              const SizedBox(height: 8),
            ],
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppColors.violet)),
              child: Text('Quay về danh sách', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.violet)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() { _tts.stop(); _animCtrl.dispose(); super.dispose(); }

  KhmerVowel get _v => _vowels[_idx];
  bool _isStepComplete(int step) => _completedSteps[_idx]?.contains(step) ?? false;
  int get _completedCount => _completedSteps[_idx]?.length ?? 0;

  bool _canGo(int i) => i >= 0 && i < _vowels.length;
  void _goTo(int i) {
    if (!_canGo(i)) return;
    _animCtrl.reset();
    setState(() => _idx = i);
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(children: [
                _buildMainCard(),
                const SizedBox(height: 12),
                _buildExampleCard(),
                const SizedBox(height: 12),
                _buildListenSpeakRow(),
                const SizedBox(height: 10),
                _buildWriteButton(),
                const SizedBox(height: 12),
                _buildProgressIndicator(),
                const SizedBox(height: 12),
                _buildNavButtons(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════ HEADER (giống phụ âm) ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -20, top: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(left: -30, bottom: -10,
          child: Container(width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Top row: back + title + stars
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white, iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
                Expanded(child: Text('Nguyên âm ${_idx + 1}/${_vowels.length}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                Row(mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      i < _v.starRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 20,
                      color: i < _v.starRating ? AppColors.secondaryLight : Colors.white24)))),
              ]),
              const SizedBox(height: 8),
              // Step indicators (giống phụ âm)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _headerStep(Icons.headphones_rounded, 'Nghe', 0),
                _headerDivider(),
                _headerStep(Icons.mic_rounded, 'Nói', 1),
                _headerDivider(),
                _headerStep(Icons.edit_rounded, 'Viết', 2),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _headerStep(IconData icon, String label, int stepIdx) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: done ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? Colors.white.withValues(alpha: 0.3) : Colors.transparent, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: done ? Colors.white : Colors.white60),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: done ? Colors.white : Colors.white60)),
        if (done) ...[
          const SizedBox(width: 4),
          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.tertiaryLight),
        ],
      ]),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 16, height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24);
  }

  // ═══════════════════ MAIN CARD ═══════════════════
  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.10),
          blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(children: [
        Text(_v.character, style: GoogleFonts.kantumruyPro(
          fontSize: 100, fontWeight: FontWeight.w400,
          color: AppColors.primary, height: 1.1)),
        const SizedBox(height: 10),
        Container(
          width: 80, height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(_v.character, style: GoogleFonts.kantumruyPro(
                fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Text('Phát âm: "${_v.romanized}"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 12),
        // Dạng phụ thuộc
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Dạng phụ thuộc: ', style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Text(_v.dependent, style: GoogleFonts.kantumruyPro(
              fontSize: 24, color: AppColors.tertiary)),
          ),
        ]),
      ]),
    );
  }

  // ═══════════════════ EXAMPLE ═══════════════════
  Widget _buildExampleCard() {
    if (_v.example.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📝 Ví dụ', style: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _speak(_v.dependent),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(_v.dependent, style: GoogleFonts.kantumruyPro(
                  fontSize: 32, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Phụ thuộc', style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 20)),
          Expanded(child: GestureDetector(
            onTap: () => _speak(_v.example),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(_v.example, style: GoogleFonts.kantumruyPro(
                  fontSize: 32, color: AppColors.tertiary)),
                const SizedBox(height: 4),
                Text(_v.exampleMeaning, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 6),
        Center(child: Text('👆 Chạm để nghe', style: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textHint))),
      ]),
    );
  }

  // ═══════════════════ NGHE + NÓI (giống phụ âm) ═══════════════════
  Widget _buildListenSpeakRow() {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: _showListenSheet,
        child: _actionButton(
          icon: Icons.headphones_rounded, label: 'Nghe',
          sub: 'Phát âm mẫu', color: AppColors.tertiary, stepIdx: 0),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: _showSpeakSheet,
        child: _actionButton(
          icon: Icons.mic_rounded, label: 'Nói',
          sub: 'Luyện phát âm', color: AppColors.secondary, stepIdx: 1),
      )),
    ]);
  }

  Widget _actionButton({
    required IconData icon, required String label,
    required String sub, required Color color, required int stepIdx,
  }) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.12)!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 5)),
        ]),
      child: Column(children: [
        Stack(alignment: Alignment.topRight, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 24)),
          if (done) Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
            child: Icon(Icons.check_rounded, size: 12, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.75))),
      ]),
    );
  }

  // ═══════════════════ VIẾT (giống phụ âm) ═══════════════════
  Widget _buildWriteButton() {
    final done = _isStepComplete(2);
    return GestureDetector(
      onTap: _showWriteSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.violet, AppColors.violetDark]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.violet.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 5)),
          ]),
        child: Column(children: [
          Stack(alignment: Alignment.topRight, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24)),
            if (done) Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              child: Icon(Icons.check_rounded, size: 12, color: AppColors.violet)),
          ]),
          const SizedBox(height: 8),
          Text('Viết', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Tập viết chữ', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75))),
        ]),
      ),
    );
  }

  // ═══════════════════ PROGRESS (giống phụ âm) ═══════════════════
  Widget _buildProgressIndicator() {
    final allDone = _completedCount == 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: allDone ? AppColors.tertiarySurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone ? AppColors.tertiary.withValues(alpha: 0.3) : AppColors.surfaceContainerLow),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ]),
      child: Row(children: [
        ...List.generate(3, (i) {
          final isDone = _isStepComplete(i);
          return Container(
            width: 24, height: 24,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.tertiary : AppColors.surfaceContainerLow),
            child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Center(child: Text('${i + 1}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textHint))),
          );
        }),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              allDone ? 'Hoàn thành! 🎉' : '$_completedCount/3 bước hoàn thành',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700,
                color: allDone ? AppColors.tertiaryDark : AppColors.textSecondary)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _completedCount / 3, minHeight: 5,
                backgroundColor: allDone ? AppColors.tertiaryLight : AppColors.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation(allDone ? AppColors.tertiary : AppColors.primary),
              ),
            ),
          ],
        )),
      ]),
    );
  }

  // ═══════════════════ NAVIGATION (giống phụ âm) ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _canGo(_idx - 1);
    final canNext = _canGo(_idx + 1);
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: canPrev ? () => _goTo(_idx - 1) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: canPrev ? Colors.white : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: canPrev ? Border.all(color: AppColors.surfaceContainerHighest) : null),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chevron_left_rounded,
              color: canPrev ? AppColors.primary : AppColors.textHint, size: 20),
            Text('Trước', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
              color: canPrev ? AppColors.primary : AppColors.textHint)),
          ]),
        ),
      )),
      const SizedBox(width: 10),
      Expanded(child: GestureDetector(
        onTap: canNext ? () => _goTo(_idx + 1) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: canNext ? AppColors.primary : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            boxShadow: canNext ? [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 6, offset: const Offset(0, 2))] : null),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Tiếp theo', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
              color: canNext ? Colors.white : AppColors.textHint)),
            if (canNext) const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ]),
        ),
      )),
    ]);
  }

  // ═══════════════════ SHEETS ═══════════════════
  void _showListenSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => VowelListenSheet(vowel: _v, onComplete: () => _markStepComplete(0)),
    );
  }

  void _showSpeakSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => VowelSpeakSheet(vowel: _v, onComplete: () => _markStepComplete(1)),
    );
  }

  void _showWriteSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => VowelWriteSheet(vowel: _v, onComplete: () => _markStepComplete(2)),
    );
  }
}
