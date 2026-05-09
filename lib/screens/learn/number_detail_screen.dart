import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../models/khmer_number.dart';
import '../../widgets/number_grid_item.dart';
import 'spelling_map_screen.dart';

/// Màn hình chi tiết số Khmer
/// Tích hợp TTS phát âm, tập viết, lưới chọn số, mẹo học
class NumberDetailScreen extends StatefulWidget {
  final int initialIndex;

  const NumberDetailScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends State<NumberDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  final List<KhmerNumber> _numbers = KhmerNumberData.numbers;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
    _initTts();
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    final langList =
        (languages as List).map((l) => l.toString().toLowerCase()).toList();
    final hasKhmer =
        langList.any((l) => l.contains('km') || l.contains('khmer'));

    if (hasKhmer) {
      await _tts.setLanguage('km');
    } else {
      final hasVi = langList.any((l) => l.contains('vi'));
      await _tts.setLanguage(hasVi ? 'vi-VN' : 'en-US');
    }

    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isPlaying = false);
    });

    if (mounted) setState(() => _ttsReady = true);
  }

  Future<void> _speak() async {
    if (!_ttsReady || _isPlaying) return;
    setState(() => _isPlaying = true);

    // Nói: số Khmer + phiên âm
    final text = '${_current.character}. ${_current.khmerWord}';
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    _animController.dispose();
    super.dispose();
  }

  void _selectNumber(int index) {
    _animController.reset();
    setState(() {
      _currentIndex = index;
    });
    _animController.forward();
  }

  KhmerNumber get _current => _numbers[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNumberGrid(),
                  const SizedBox(height: 20),
                  _buildNumberDetailCard(),
                  const SizedBox(height: 16),
                  _buildListenButton(),
                  const SizedBox(height: 16),
                  _buildTipsCard(),
                  const SizedBox(height: 16),
                  _buildWriteButton(),
                  const SizedBox(height: 16),
                  _buildNavigationButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textWhite,
                iconSize: 28,
              ),
              Expanded(
                child: Text(
                  'Số ${_current.value}',
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              // Speaker icon
              GestureDetector(
                onTap: _speak,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    color: AppColors.textWhite,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _numbers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;
          return GestureDetector(
            onTap: () => _selectNumber(index),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryPurple.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primaryPurple, width: 2)
                    : null,
              ),
              child: NumberGridItem(number: _numbers[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberDetailCard() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  _current.value,
                  style: AppTextStyles.statNumber.copyWith(
                    fontSize: 36,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _current.character,
                    style: GoogleFonts.battambang(
                      fontSize: 48,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  Text(
                    '${_current.khmerWord} - ${_current.romanized}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút nghe phát âm (TTS)
  Widget _buildListenButton() {
    return GestureDetector(
      onTap: _speak,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPlaying ? Icons.volume_up_rounded : Icons.headphones_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              _isPlaying ? 'Đang phát...' : 'Nghe phát âm số ${_current.value}',
              style: AppTextStyles.buttonText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(AppStrings.numberTips, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('• ${AppStrings.numberTip1}'),
          _buildTipItem('• ${AppStrings.numberTip2}'),
          _buildTipItem('• ${AppStrings.numberTip3}'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }

  Widget _buildWriteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SpellingMapScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.edit_rounded, size: 22),
        label: Text(
          '${AppStrings.practiceWriting} ${_current.value}',
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentIndex > 0
                ? () => _selectNumber(_currentIndex - 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              disabledBackgroundColor:
                  AppColors.textHint.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            label: Text(AppStrings.previous, style: AppTextStyles.buttonText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _currentIndex < _numbers.length - 1
                ? () => _selectNumber(_currentIndex + 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              disabledBackgroundColor:
                  AppColors.textHint.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.next, style: AppTextStyles.buttonText),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 24, color: AppColors.textWhite),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
