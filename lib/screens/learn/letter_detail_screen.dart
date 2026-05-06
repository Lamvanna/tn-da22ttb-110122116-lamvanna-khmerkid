import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/khmer_letter.dart';

/// Màn hình chi tiết học chữ cái Khmer
/// Tích hợp TTS (nghe), STT (nói), stroke validation (viết)
class LetterDetailScreen extends StatefulWidget {
  final int initialIndex;

  const LetterDetailScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _idx;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<KhmerLetter> _letters = KhmerLetterData.consonants;

  // Track hoàn thành (0=nghe, 1=nói, 2=viết)
  final Map<int, Set<int>> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  KhmerLetter get _letter => _letters[_idx];

  bool _isLocked(int idx) {
    if (idx < 0 || idx >= _letters.length) return true;
    if (_letters[idx].isLearned) return false;
    final firstUnlearned = _letters.indexWhere((l) => !l.isLearned);
    return idx != firstUnlearned;
  }

  void _goTo(int i) {
    if (i < 0 || i >= _letters.length || _isLocked(i)) return;
    _animCtrl.reset();
    setState(() => _idx = i);
    _animCtrl.forward();
  }

  void _markStepComplete(int step) {
    _completedSteps[_idx] ??= {};
    if (_completedSteps[_idx]!.contains(step)) return;
    setState(() => _completedSteps[_idx]!.add(step));

    if (_completedSteps[_idx]!.length == 3) {
      _onLetterCompleted();
    }
  }

  void _onLetterCompleted() {
    _letters[_idx].isLearned = true;
    _letters[_idx].starRating = 3;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final hasNext = _idx < _letters.length - 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Chúc mừng!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary)),
              const SizedBox(height: 8),
              Text('Bạn đã hoàn thành chữ "${_letter.character}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (i) => Icon(Icons.star_rounded,
                        size: 28, color: AppColors.secondary)),
              ),
              const SizedBox(height: 6),
              Text('+30 XP ⭐',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary)),
              const SizedBox(height: 20),
              if (hasNext) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goTo(_idx + 1);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Text('Học chữ tiếp theo →',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: AppColors.violet)),
                  child: Text('Quay về bản đồ',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStepComplete(int step) =>
      _completedSteps[_idx]?.contains(step) ?? false;
  int get _completedCount => _completedSteps[_idx]?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.consonantBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  children: [
                    _buildLetterCard(),
                    const SizedBox(height: 12),
                    _buildIllustrationCard(),
                    const SizedBox(height: 12),
                    _buildListenSpeakRow(),
                    const SizedBox(height: 10),
                    _buildWriteButton(),
                    const SizedBox(height: 12),
                    _buildProgressIndicator(),
                    const SizedBox(height: 12),
                    _buildNavButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.consonantAccent, AppColors.consonantAccentDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Positioned(
            left: -30, bottom: -10,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: back + title + stars
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white, iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      Expanded(
                        child: Text(
                          'Chữ cái ${_idx + 1}/${_letters.length}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            i < _letter.starRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 20,
                            color: i < _letter.starRating ? AppColors.secondaryLight : Colors.white24,
                          ),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _headerStep(Icons.headphones_rounded, 'Nghe', 0),
                      _headerDivider(),
                      _headerStep(Icons.mic_rounded, 'Nói', 1),
                      _headerDivider(),
                      _headerStep(Icons.edit_rounded, 'Viết', 2),
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

  Widget _headerStep(IconData icon, String label, int stepIdx) {
    final done = _isStepComplete(stepIdx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: done ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15,
            color: done ? Colors.white : Colors.white60),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: done ? Colors.white : Colors.white60)),
          if (done) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded, size: 14, color: AppColors.tertiaryLight),
          ],
        ],
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 16, height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }

  // ═══════════════════ CARD CHỮ LỚN ═══════════════════
  Widget _buildLetterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.consonantAccent.withValues(alpha: 0.10),
            blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(_letter.character,
            style: GoogleFonts.kantumruyPro(
              fontSize: 110, fontWeight: FontWeight.w400,
              color: AppColors.consonantAccent, height: 1.1)),
          const SizedBox(height: 10),
          Container(
            width: 80, height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.consonantAccent, AppColors.consonantAccentLight]),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.violetSurface,
              borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.consonantAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(_letter.character,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 20, fontWeight: FontWeight.w500,
                      color: AppColors.consonantAccent)),
                ),
                const SizedBox(width: 12),
                Text('Phát âm: "${_letter.romanized}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ CARD MINH HỌA ═══════════════════
  Widget _buildIllustrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_letter.character,
                    style: GoogleFonts.kantumruyPro(
                    fontSize: 36, fontWeight: FontWeight.w700,
                    color: AppColors.consonantAccent)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _letter.meaning.isNotEmpty ? _letter.meaning : _letter.pronunciation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.violetSurface, AppColors.violetSurface]),
              borderRadius: BorderRadius.circular(18)),
            child: Center(
              child: Text(_getEmoji(), style: const TextStyle(fontSize: 44))),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ NGHE + NÓI ═══════════════════
  Widget _buildListenSpeakRow() {
    return Row(
      children: [
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
      ],
    );
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
        ],
      ),
      child: Column(
        children: [
          Stack(alignment: Alignment.topRight, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            if (done) Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              child: Icon(Icons.check_rounded, size: 12, color: color),
            ),
          ]),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  // ═══════════════════ VIẾT ═══════════════════
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
          ],
        ),
        child: Column(
          children: [
            Stack(alignment: Alignment.topRight, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
              ),
              if (done) Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                child: Icon(Icons.check_rounded, size: 12, color: AppColors.violet),
              ),
            ]),
            const SizedBox(height: 8),
            Text('Viết', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Tập viết chữ', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ PROGRESS ═══════════════════
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
        ],
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Hoàn thành! 🎉' : '$_completedCount/3 bước hoàn thành',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: allDone ? AppColors.tertiaryDark : AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedCount / 3, minHeight: 5,
                    backgroundColor: allDone ? AppColors.tertiaryLight : AppColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation(allDone ? AppColors.tertiary : AppColors.consonantAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ NAVIGATION ═══════════════════
  Widget _buildNavButtons() {
    final canPrev = _idx > 0 && !_isLocked(_idx - 1);
    final canNext = _idx < _letters.length - 1 && !_isLocked(_idx + 1);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: canPrev ? () => _goTo(_idx - 1) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: canPrev ? Colors.white : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: canPrev ? Border.all(color: AppColors.surfaceContainerHighest) : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left_rounded,
                    color: canPrev ? AppColors.consonantAccent : AppColors.textHint, size: 20),
                  Text('Trước', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
                    color: canPrev ? AppColors.consonantAccent : AppColors.textHint)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: canNext ? () => _goTo(_idx + 1) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: canNext ? AppColors.consonantAccent : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: canNext ? [BoxShadow(
                  color: AppColors.consonantAccent.withValues(alpha: 0.25),
                  blurRadius: 6, offset: const Offset(0, 2))] : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(canNext ? 'Tiếp theo' : 'Khóa', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
                    color: canNext ? Colors.white : AppColors.textHint)),
                  Icon(canNext ? Icons.chevron_right_rounded : Icons.lock_rounded,
                    color: canNext ? Colors.white : AppColors.textHint, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ SHEETS ═══════════════════
  void _showListenSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _ListenSheet(letter: _letter, onComplete: () => _markStepComplete(0)),
    );
  }

  void _showSpeakSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _SpeakSheet(letter: _letter, onComplete: () => _markStepComplete(1)),
    );
  }

  void _showWriteSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _WriteSheet(letter: _letter, onComplete: () => _markStepComplete(2)),
    );
  }

  String _getEmoji() {
    switch (_letter.meaning) {
      case 'con cò': return '🦩';
      case 'con khỉ': return '🐒';
      case 'con gà': return '🐓';
      case 'con ngỗng': return '🦢';
      case 'con chó': return '🐕';
      default: return '📝';
    }
  }
}

// ═══════════════════════════════════════════════════════════════

class _ListenSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _ListenSheet({required this.letter, required this.onComplete});

  @override
  State<_ListenSheet> createState() => _ListenSheetState();
}

class _ListenSheetState extends State<_ListenSheet>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _speed = 1;
  int _playCount = 0;
  bool _ttsReady = false;
  bool _khmerSupported = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    _khmerSupported = langList.any((l) => l.contains('km') || l.contains('khmer'));

    if (_khmerSupported) {
      await _tts.setLanguage('km');
    } else {
      final viSupported = langList.any((l) => l.contains('vi'));
      if (viSupported) {
        await _tts.setLanguage('vi-VN');
      } else {
        await _tts.setLanguage('en-US');
      }
    }

    await _tts.setSpeechRate(_speedRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
        _waveCtrl.stop();
      }
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _waveCtrl.stop();
      }
    });

    if (mounted) setState(() => _ttsReady = true);
  }

  double get _speedRate {
    switch (_speed) {
      case 0: return 0.2;
      case 2: return 0.7;
      default: return 0.4;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _playCount++;
    });
    _waveCtrl.repeat(reverse: true);

    await _tts.setSpeechRate(_speedRate);

    final textToSpeak = _khmerSupported
        ? widget.letter.character
        : widget.letter.pronunciation.isNotEmpty
            ? widget.letter.pronunciation
            : widget.letter.romanized;

    final result = await _tts.speak(textToSpeak);

    if (result != 1 && mounted) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _waveCtrl.stop();
        }
      });
    }

    if (_playCount >= 1) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.tertiary, AppColors.tertiaryDark]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Icon(Icons.headphones_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text('Nghe phát âm', style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Lắng nghe và ghi nhớ cách đọc', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.white70)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(children: [
              // ── Character ──
              Text(widget.letter.character,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 80, fontWeight: FontWeight.w700, color: AppColors.consonantAccent, height: 1.1)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.violetSurface, borderRadius: BorderRadius.circular(20)),
                child: Text('Phát âm: "${widget.letter.romanized}"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.violet)),
              ),
              const SizedBox(height: 24),

              // ── Wave Bars + Play Button ──
              AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(8, (i) {
                      final h = _isPlaying ? 12.0 + 20 * ((i % 4 + 1) / 4) * (0.4 + 0.6 * _waveCtrl.value) : 8.0 + (i % 3) * 4.0;
                      return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25), borderRadius: BorderRadius.circular(2)));
                    }),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _ttsReady ? _play : null,
                      child: Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [AppColors.tertiaryLight, AppColors.tertiaryDark]),
                          boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ...List.generate(8, (i) {
                      final h = _isPlaying ? 12.0 + 20 * (((7 - i) % 4 + 1) / 4) * (0.4 + 0.6 * _waveCtrl.value) : 8.0 + ((7 - i) % 3) * 4.0;
                      return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: _isPlaying ? 0.8 : 0.25), borderRadius: BorderRadius.circular(2)));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isPlaying ? 'Đang phát âm...'
                  : _playCount > 0 ? 'Đã nghe $_playCount lần • Nhấn nghe lại'
                  : 'Nhấn nút để nghe phát âm',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              const SizedBox(height: 20),

              // ── Speed ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Tốc độ: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                const SizedBox(width: 6),
                _speedChip('🐢 Chậm', 0),
                const SizedBox(width: 8),
                _speedChip('🔊 Vừa', 1),
                const SizedBox(width: 8),
                _speedChip('🐇 Nhanh', 2),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _speedChip(String label, int val) {
    final active = _speed == val;
    return GestureDetector(
      onTap: () => setState(() => _speed = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: AppColors.surfaceContainerHighest)),
        child: Text(label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// SPEAK SHEET — Nhận diện giọng nói THẬT bằng Speech-to-Text
// Flow: Bấm mic → Nói → Hệ thống tự chấm điểm
// ═══════════════════════════════════════════════════════════════

class _SpeakSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _SpeakSheet({required this.letter, required this.onComplete});

  @override
  State<_SpeakSheet> createState() => _SpeakSheetState();
}

class _SpeakSheetState extends State<_SpeakSheet>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulseCtrl;

  bool _sttReady = false;
  bool _isListening = false;
  bool _isPlayingExample = false;
  String _recognized = '';
  String _statusMsg = '';
  bool _hasResult = false;
  bool _isCorrect = false;
  int _score = 0;
  String _selectedLocaleId = 'vi-VN';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _initTts();
    _initSTT();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer = langList.any((l) => l.contains('km') || l.contains('khmer'));
    if (hasKhmer) {
      await _tts.setLanguage('km');
    } else {
      final hasVi = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(hasVi ? 'vi-VN' : 'en-US');
    }
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingExample = false);
    });
  }

  Future<void> _playExample() async {
    if (_isPlayingExample) return;
    setState(() => _isPlayingExample = true);
    final text = widget.letter.pronunciation.isNotEmpty
        ? widget.letter.pronunciation
        : widget.letter.romanized;
    await _tts.speak(text);
  }

  Future<void> _initSTT() async {
    final micStatus = await Permission.microphone.request();
    debugPrint('[STT] Mic permission: $micStatus');
    if (!micStatus.isGranted) {
      if (mounted) {
        setState(() => _statusMsg = 'Cần cấp quyền microphone!');
      }
      return;
    }

    try {
      _sttReady = await _speech.initialize(
        onError: (err) {
          debugPrint('[STT] Error: ${err.errorMsg}');
          if (mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() {
              _isListening = false;
              if (_recognized.isEmpty) {
                _statusMsg = 'Không nghe được. Hãy nói to và rõ hơn!';
              } else {
                _evaluate();
              }
            });
          }
        },
        onStatus: (status) {
          debugPrint('[STT] Status: $status');
          if (status == 'done' && mounted && _isListening) {
            _pulseCtrl.stop();
            setState(() => _isListening = false);
            _evaluate();
          }
        },
      );
      debugPrint('[STT] Initialize: $_sttReady');

      // Pre-select locale
      if (_sttReady) {
        final locales = await _speech.locales();
        for (final l in locales) {
          if (l.localeId.toLowerCase().startsWith('vi')) {
            _selectedLocaleId = l.localeId;
            break;
          }
        }
        if (_selectedLocaleId == 'vi-VN') {
          for (final l in locales) {
            if (l.localeId.toLowerCase().startsWith('km')) {
              _selectedLocaleId = l.localeId;
              break;
            }
          }
        }
        debugPrint('[STT] Selected locale: $_selectedLocaleId');
      }
    } catch (e) {
      debugPrint('[STT] Init error: $e');
      _sttReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Stop TTS if playing
    await _tts.stop();
    setState(() {
      _recognized = '';
      _statusMsg = '';
      _hasResult = false;
      _isListening = true;
      _isPlayingExample = false;
    });
    _pulseCtrl.repeat(reverse: true);

    debugPrint('[STT] Using locale: $_selectedLocaleId');

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint('[STT] Result: "${result.recognizedWords}" final=${result.finalResult}');
          if (mounted) {
            setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) {
              _pulseCtrl.stop();
              setState(() => _isListening = false);
              _evaluate();
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 4),
        localeId: _selectedLocaleId,
      );
    } catch (e) {
      debugPrint('[STT] Listen error: $e');
      _pulseCtrl.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMsg = 'Lỗi nhận diện giọng nói. Thử lại!';
        });
      }
    }
  }

  void _evaluate() {
    if (_hasResult) return;
    final spoken = _recognized.toLowerCase().trim();
    if (spoken.isEmpty) {
      setState(() => _statusMsg = 'Không nhận diện được. Hãy nói to hơn!');
      return;
    }

    // Normalize: remove diacritics-like chars, spaces
    String normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');

    final spokenNorm = normalize(spoken);
    final targets = [
      widget.letter.romanized,
      widget.letter.pronunciation,
      widget.letter.character,
    ].where((t) => t.isNotEmpty).map(normalize).toList();

    // Check exact or contains match
    bool exact = targets.any((t) => spokenNorm.contains(t) || t.contains(spokenNorm));
    if (exact) {
      _score = 5;
      _isCorrect = true;
    } else {
      // Check first character match (common for short syllables)
      bool firstCharMatch = targets.any((t) =>
          t.isNotEmpty && spokenNorm.isNotEmpty && t[0] == spokenNorm[0]);

      double best = 0;
      for (final t in targets) {
        final s = _sim(spokenNorm, t);
        if (s > best) best = s;
      }

      // More lenient: if first char matches, boost score
      if (firstCharMatch) best = (best + 0.15).clamp(0.0, 1.0);

      if (best > 0.5) {
        _score = 4;
        _isCorrect = true;
      } else if (best > 0.3) {
        _score = 3;
        _isCorrect = true;
      } else if (best > 0.15) {
        _score = 2;
        _isCorrect = false;
      } else {
        _score = 1;
        _isCorrect = false;
      }
    }

    setState(() => _hasResult = true);
    if (_isCorrect) widget.onComplete();

    // Show result dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isCorrect ? '🎉' : '😅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800,
                color: _isCorrect ? AppColors.tertiary : AppColors.coral)),
            const SizedBox(height: 8),
            Text(_isCorrect ? 'Phát âm rất tốt!' : 'Hãy thử lại nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:
              List.generate(3, (i) => Icon(
                i < _score ~/ 2 ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 28, color: i < _score ~/ 2 ? AppColors.secondary : AppColors.surfaceContainerHighest))),
            if (_recognized.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Nghe được: "$_recognized"',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary)),
            ],
            if (_isCorrect) ...[
              const SizedBox(height: 6),
              Text('+10 XP ⭐', style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            ],
            const SizedBox(height: 20),
            if (_isCorrect) ...[
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Hoàn thành ✅', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
              const SizedBox(height: 8),
            ],
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() { _hasResult = false; _recognized = ''; _statusMsg = ''; _score = 0; });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppColors.violet)),
              child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.violet)),
            )),
          ]),
        ),
      ),
    );
  }

  double _sim(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final mx = a.length > b.length ? a.length : b.length;
    return 1.0 - (_lev(a, b) / mx);
  }

  int _lev(String s, String t) {
    final m = s.length, n = t.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) { d[i][0] = i; }
    for (int j = 0; j <= n; j++) { d[0][j] = j; }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final c = s[i - 1] == t[j - 1] ? 0 : 1;
        final v = [d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+c];
        d[i][j] = v.reduce((a, b) => a < b ? a : b);
      }
    }
    return d[m][n];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
         child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(2)))),

            // ── Title ──
            Center(child: Text('Tập nói phát âm', style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onBackground))),
            const SizedBox(height: 14),

            // ── Khi chưa có kết quả: hiện character + mic ──
            if (!_hasResult) ...[
              // Character in blue circle
              Center(child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF42A5F5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                child: Center(child: Text(widget.letter.character,
                  style: GoogleFonts.kantumruyPro(fontSize: 56, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1))),
              )),
              const SizedBox(height: 8),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0D5C5)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
                child: Text(widget.letter.romanized, style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
              )),
              const SizedBox(height: 14),

              // Stars placeholder
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ...List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.star_outline_rounded, size: 30, color: AppColors.surfaceContainerHighest))),
              ]),
              const SizedBox(height: 14),

              // Listen example pill
              Center(child: GestureDetector(
                onTap: !_isPlayingExample && !_isListening ? _playExample : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.consonantBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_isPlayingExample ? Icons.volume_up_rounded : Icons.headphones_rounded,
                      color: const Color(0xFF7E57C2), size: 18),
                    const SizedBox(width: 6),
                    Text(_isPlayingExample ? 'Đang phát...' : 'Nghe mẫu trước',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF7E57C2))),
                  ]),
                ),
              )),
              const SizedBox(height: 18),

              // Mic button with wave bars
              Center(child: GestureDetector(
                onTap: _sttReady && !_isListening ? _startListening : null,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) => SizedBox(
                    width: 200, height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...List.generate(4, (i) {
                          final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                          return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _isListening ? Color.lerp(AppColors.coral, AppColors.secondary, i / 3.0)! : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4)));
                        }).reversed.toList(),
                        const SizedBox(width: 6),
                        Container(
                          width: _isListening ? 80 + 8 * _pulseCtrl.value : 76,
                          height: _isListening ? 80 + 8 * _pulseCtrl.value : 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: _isListening
                                ? [const Color(0xFFEF5350), const Color(0xFFC62828)]
                                : !_sttReady
                                  ? [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]
                                  : [const Color(0xFF66BB6A), const Color(0xFF388E3C)]),
                            boxShadow: [if (_sttReady) BoxShadow(
                              color: (_isListening ? const Color(0xFFEF5350) : const Color(0xFF4CAF50)).withValues(alpha: 0.4),
                              blurRadius: 18, offset: const Offset(0, 6))]),
                          child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 6),
                        ...List.generate(4, (i) {
                          final h = _isListening ? 12.0 + (20 + i * 6) * (0.4 + 0.6 * _pulseCtrl.value) : 8.0 + i * 3.0;
                          return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _isListening ? Color.lerp(AppColors.coral, AppColors.primary, i / 3.0)! : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4)));
                        }),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              Center(child: Text(
                !_sttReady ? 'Đang khởi tạo...'
                  : _isListening ? (_recognized.isNotEmpty ? '"$_recognized"' : 'Đang nghe...')
                  : _statusMsg.isNotEmpty ? _statusMsg : 'Bé nhấn để nói',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700,
                  color: _isListening ? AppColors.coral : AppColors.textSecondary))),
              if (_statusMsg.contains('Không') && !_isListening) ...[
                const SizedBox(height: 10),
                Center(child: GestureDetector(
                  onTap: () => setState(() => _statusMsg = ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                    child: Text('Thử lại', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WRITE SHEET — Tập viết chữ Khmer
// ═══════════════════════════════════════════════════════════════

class _WriteSheet extends StatefulWidget {
  final KhmerLetter letter;
  final VoidCallback onComplete;
  const _WriteSheet({required this.letter, required this.onComplete});

  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String? _feedback;
  bool? _passed;

  void _check() {
    if (_strokes.length < 2) {
      setState(() { _passed = false; _feedback = 'Cần ít nhất 2 nét vẽ! (hiện có ${_strokes.length} nét)'; });
      return;
    }
    int pts = 0;
    for (final s in _strokes) { pts += s.length; }
    if (pts < 20) {
      setState(() { _passed = false; _feedback = 'Nét viết quá ngắn! Hãy viết rõ ràng hơn.'; });
      return;
    }
    double minX = double.infinity, maxX = 0, minY = double.infinity, maxY = 0;
    for (final s in _strokes) {
      for (final p in s) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    if ((maxX - minX) < 30 || (maxY - minY) < 30) {
      setState(() { _passed = false; _feedback = 'Chữ quá nhỏ! Hãy viết lớn hơn.'; });
      return;
    }
    setState(() { _passed = true; _feedback = null; });
    widget.onComplete();

    // Show success dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Viết tuyệt vời!',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Bé viết chữ "${widget.letter.character}" rất đẹp!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:
              List.generate(3, (i) => Icon(Icons.star_rounded, size: 28, color: AppColors.secondary))),
            const SizedBox(height: 6),
            Text('+10 XP ⭐', style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('Hoàn thành ✅', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppColors.violet)),
              child: Text('Viết lại', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.violet)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        // Title (ẩn khi có kết quả)
        if (_passed != true) ...[
          Text('✍️ Tập viết chữ ${widget.letter.character}', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
          const SizedBox(height: 2),
          Text('Quan sát mẫu rồi viết theo', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
        ],
        // ── Khi chưa viết đúng ──
        if (_passed != true) ...[
          // Model Character Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.secondarySurface, AppColors.secondaryLight]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary, width: 2.5),
              boxShadow: [
                BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                const BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2))]),
            child: Stack(children: [
              Positioned(left: 0, top: 0, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(8)),
                child: const Text('✏️', style: TextStyle(fontSize: 16)))),
              Positioned(right: 0, top: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.onBackground, borderRadius: BorderRadius.circular(10)),
                child: Text('Mẫu', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(widget.letter.character,
                  style: GoogleFonts.kantumruyPro(fontSize: 90, fontWeight: FontWeight.w700, color: AppColors.onBackground, height: 1.15)))),
            ]),
          ),
          const SizedBox(height: 6),
          // Feedback banner (chỉ hiện khi sai)
          if (_feedback != null && _passed == false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF9A9A))),
                child: Row(children: [
                  const Text('😅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_feedback!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFC62828)))),
                ]),
              ),
            ),
          // Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _passed == null ? const Color(0xFFD7CCC8) : _passed! ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(children: [
                  CustomPaint(size: Size.infinite, painter: _GridPainter()),
                  Center(child: Text(widget.letter.character,
                    style: GoogleFonts.kantumruyPro(fontSize: 180, fontWeight: FontWeight.w300,
                      color: const Color(0xFFE0D5C5).withValues(alpha: 0.45)))),
                  GestureDetector(
                    onPanStart: (d) => setState(() { _current = [d.localPosition]; _passed = null; _feedback = null; }),
                    onPanUpdate: (d) => setState(() => _current.add(d.localPosition)),
                    onPanEnd: (_) => setState(() { _strokes.add(List.from(_current)); _current = []; }),
                    child: CustomPaint(size: Size.infinite, painter: _StrokePainter(_strokes, _current)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0D5C5)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _toolBtn(icon: Icons.check_circle_outline_rounded, label: 'Kiểm tra',
                  color: _strokes.isNotEmpty ? AppColors.tertiary : AppColors.textHint,
                  onTap: _strokes.isNotEmpty ? _check : null),
                _toolBtn(icon: Icons.auto_fix_high_rounded, label: 'Cục tẩy',
                  color: _strokes.isNotEmpty ? AppColors.secondary : AppColors.textHint,
                  onTap: _strokes.isNotEmpty ? () => setState(() { _strokes.removeLast(); _passed = null; _feedback = null; }) : null),
                _toolBtn(icon: Icons.refresh_rounded, label: 'Làm lại',
                  color: AppColors.coral,
                  onTap: () => setState(() { _strokes.clear(); _current.clear(); _passed = null; _feedback = null; })),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _toolBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid squares
    final gridPaint = Paint()
      ..color = const Color(0xFFE0D5C5).withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    const cols = 8;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).ceil();
    // Vertical lines
    for (int i = 0; i <= cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Horizontal lines
    for (int j = 0; j <= rows; j++) {
      final y = j * cellW;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Center cross (thicker)
    final centerPaint = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), centerPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _StrokePainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final done = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s[0].dx, s[0].dy);
      for (int i = 1; i < s.length; i++) path.lineTo(s[i].dx, s[i].dy);
      canvas.drawPath(path, done);
    }
    if (current.length >= 2) {
      final active = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (int i = 1; i < current.length; i++) path.lineTo(current[i].dx, current[i].dy);
      canvas.drawPath(path, active);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

