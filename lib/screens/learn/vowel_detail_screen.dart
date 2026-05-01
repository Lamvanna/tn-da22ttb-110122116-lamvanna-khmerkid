import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/khmer_vowel.dart';

/// Màn hình chi tiết nguyên âm Khmer
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

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
  }

  @override
  void dispose() { _tts.stop(); _animCtrl.dispose(); super.dispose(); }

  KhmerVowel get _vowel => _vowels[_idx];

  bool _isLocked(int idx) {
    if (idx < 0 || idx >= _vowels.length) return true;
    if (_vowels[idx].isLearned) return false;
    final first = _vowels.indexWhere((v) => !v.isLearned);
    return idx != first;
  }

  void _goTo(int i) {
    if (i < 0 || i >= _vowels.length || _isLocked(i)) return;
    _animCtrl.reset();
    setState(() => _idx = i);
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: ScaleTransition(scale: _scaleAnim, child: Column(children: [
            _buildVowelGrid(),
            const SizedBox(height: 16),
            _buildVowelCard(),
            const SizedBox(height: 14),
            _buildExampleCard(),
            const SizedBox(height: 14),
            _buildListenButton(),
            const SizedBox(height: 14),
            _buildTipsCard(),
            const SizedBox(height: 14),
            _buildNavButtons(),
          ])),
        )),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFAD1457)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 18),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), color: Colors.white, iconSize: 26),
          Expanded(child: Text('Nguyên âm ${_idx + 1}/${_vowels.length}', textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Icon(
            i < _vowel.starRating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 20, color: i < _vowel.starRating ? const Color(0xFFFFD54F) : Colors.white.withValues(alpha: 0.4)))),
        ]),
      )),
    );
  }

  Widget _buildVowelGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: _vowels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.85),
        itemBuilder: (context, index) {
          final v = _vowels[index]; final isSelected = index == _idx; final locked = _isLocked(index);
          return GestureDetector(
            onTap: locked ? null : () => _goTo(index),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE91E63).withValues(alpha: 0.1) : locked ? const Color(0xFFF5F5F5) : null,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: const Color(0xFFE91E63), width: 2) : null),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (locked) Icon(Icons.lock_rounded, size: 16, color: Colors.grey.shade400)
                else Text(v.character, style: GoogleFonts.kantumruyPro(fontSize: 14, color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF3E2C6E))),
                if (v.isLearned) Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
                  Icon(Icons.star_rounded, size: 7, color: i < v.starRating ? const Color(0xFFFFD54F) : const Color(0xFFE0E0E0)))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVowelCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Text(_vowel.character, style: GoogleFonts.kantumruyPro(fontSize: 90, color: const Color(0xFF880E4F), height: 1.1)),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 1, color: const Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(10)),
          child: Text('Phát âm: "${_vowel.romanized}" (${_vowel.pronunciation})',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFE91E63))),
        ),
      ]),
    );
  }

  Widget _buildExampleCard() {
    if (_vowel.example.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📝', style: TextStyle(fontSize: 18)), const SizedBox(width: 8),
          Text('Ví dụ kết hợp', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF37474F))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          GestureDetector(
            onTap: () => _speak(_vowel.dependent),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(_vowel.dependent, style: GoogleFonts.kantumruyPro(fontSize: 36, color: const Color(0xFF7B1FA2))),
                Text('Phụ thuộc', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: Color(0xFFBDBDBD), size: 20),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => _speak(_vowel.example),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(_vowel.example, style: GoogleFonts.kantumruyPro(fontSize: 32, color: const Color(0xFF2E7D32))),
                Text(_vowel.exampleMeaning, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF757575))),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 8),
        Center(child: Text('👆 Chạm vào chữ để nghe', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFFBDBDBD)))),
      ]),
    );
  }

  Widget _buildListenButton() {
    return GestureDetector(
      onTap: () => _speak(_vowel.character),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_isPlaying ? Icons.volume_up_rounded : Icons.headphones_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(_isPlaying ? 'Đang phát...' : 'Nghe phát âm 🔊',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('💡', style: TextStyle(fontSize: 18)), const SizedBox(width: 8),
          Text('Mẹo học nguyên âm', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF37474F)))]),
        const SizedBox(height: 10),
        Text('• Nguyên âm kết hợp với phụ âm tạo thành âm tiết', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF616161))),
        Text('• Nghe phát âm nhiều lần để nhớ tốt hơn', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF616161))),
        Text('• So sánh nguyên âm ngắn và dài', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF616161))),
      ]),
    );
  }

  Widget _buildNavButtons() {
    final canPrev = _idx > 0 && !_isLocked(_idx - 1);
    final canNext = _idx < _vowels.length - 1 && !_isLocked(_idx + 1);
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: canPrev ? () => _goTo(_idx - 1) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: canPrev ? const Color(0xFFE91E63) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chevron_left_rounded, color: canPrev ? Colors.white : const Color(0xFF9E9E9E), size: 22),
            Text('Trước', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: canPrev ? Colors.white : const Color(0xFF9E9E9E))),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: canNext ? () => _goTo(_idx + 1) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: canNext ? const Color(0xFFE91E63) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(canNext ? 'Tiếp theo' : '🔒 Khóa', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: canNext ? Colors.white : const Color(0xFF9E9E9E))),
            Icon(Icons.chevron_right_rounded, color: canNext ? Colors.white : const Color(0xFF9E9E9E), size: 22),
          ]),
        ),
      )),
    ]);
  }
}
