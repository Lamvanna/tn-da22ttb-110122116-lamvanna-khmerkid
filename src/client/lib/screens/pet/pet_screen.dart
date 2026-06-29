import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/app_header.dart';

/// Màn hình Thú vui - Pet Screen
/// Thú cưng ảo có thể tương tác: cho ăn, chơi, ngủ
class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen>
    with SingleTickerProviderStateMixin {
  double _health = 0.75;
  double _hunger = 0.60;
  double _energy = 0.80;
  double _happiness = 0.50;
  int _level = 5;
  int _stars = 1500;
  String _petMood = '😊';
  String _petAction = '';
  bool _animating = false;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _feedPet() {
    if (_stars < 10) {
      _showMessage('Không đủ sao! Cần 10⭐');
      return;
    }
    _bounceCtrl.forward(from: 0);
    setState(() {
      _stars -= 10;
      _hunger = (_hunger + 0.2).clamp(0.0, 1.0);
      _health = (_health + 0.05).clamp(0.0, 1.0);
      _petMood = '😋';
      _petAction = 'Đang ăn...';
      _animating = true;
    });
    _resetAction();
  }

  void _playWithPet() {
    if (_energy < 0.1) {
      _showMessage('Thú cưng quá mệt! Hãy cho ngủ trước.');
      return;
    }
    _bounceCtrl.forward(from: 0);
    setState(() {
      _happiness = (_happiness + 0.25).clamp(0.0, 1.0);
      _energy = (_energy - 0.1).clamp(0.0, 1.0);
      _hunger = (_hunger - 0.05).clamp(0.0, 1.0);
      _petMood = '🥳';
      _petAction = 'Đang chơi...';
      _animating = true;
    });
    _resetAction();
  }

  void _sleepPet() {
    _bounceCtrl.forward(from: 0);
    setState(() {
      _energy = (_energy + 0.3).clamp(0.0, 1.0);
      _health = (_health + 0.1).clamp(0.0, 1.0);
      _petMood = '😴';
      _petAction = 'Zzz...';
      _animating = true;
    });
    _resetAction();
  }

  void _resetAction() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _petMood = _happiness > 0.7 ? '😊' : _happiness > 0.4 ? '😐' : '😢';
        _petAction = '';
        _animating = false;
        // Level up check
        if (_health > 0.9 && _happiness > 0.9 && _hunger > 0.7) {
          _level++;
          _showMessage('🎉 Lên cấp $_level!');
        }
      });
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF7E57C2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildPetTab(),
                  const SizedBox(height: 16),
                  _buildPetStats(),
                  const SizedBox(height: 16),
                  _buildLevelInfo(),
                  const SizedBox(height: 16),
                  _buildPetArea(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
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
    return AppHeader(
      title: '🐱 Thú cưng',
      onBack: () => Navigator.pop(context),
      gradientColors: const [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text('$_stars', style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildPetTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(AppStrings.petTitle,
            style: AppTextStyles.cardTitleWhite.copyWith(fontSize: 20)),
      ),
    );
  }

  Widget _buildPetStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
          children: [
            _buildStatBar(
                icon: Icons.favorite_rounded,
                color: AppColors.statHealth,
                value: _health,
                label: '${(_health * 100).toInt()}%'),
            const SizedBox(height: 12),
            _buildStatBar(
                icon: Icons.restaurant_rounded,
                color: AppColors.statHunger,
                value: _hunger,
                label: '${(_hunger * 100).toInt()}%'),
            const SizedBox(height: 12),
            _buildStatBar(
                icon: Icons.bolt_rounded,
                color: AppColors.statEnergy,
                value: _energy,
                label: '${(_energy * 100).toInt()}%'),
            const SizedBox(height: 12),
            _buildStatBar(
                icon: Icons.emoji_emotions_rounded,
                color: AppColors.statHappiness,
                value: _happiness,
                label: '${(_happiness * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar({
    required IconData icon,
    required Color color,
    required double value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 14,
                backgroundColor: AppColors.progressBackground,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildLevelInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('${AppStrings.level} ', style: AppTextStyles.bodyMedium),
                Text('$_level',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: AppColors.primaryPurple)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('Tâm trạng: ',
                    style: AppTextStyles.bodyMedium),
                Text(_petMood, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.backgroundMint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền cỏ
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ),
          // Mèo với hiệu ứng bounce
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _bounceAnim,
                child: Text('🐱',
                    style: TextStyle(
                        fontSize: _animating ? 80 : 72)),
              ),
              const SizedBox(height: 4),
              if (_petAction.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_petAction,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF616161))),
                )
              else
                Text('Mèo con',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  /// 3 nút tương tác: Cho ăn, Chơi, Ngủ
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.restaurant_rounded,
              label: 'Cho ăn',
              sub: '10⭐',
              color: const Color(0xFFFF9800),
              onTap: _feedPet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.sports_esports_rounded,
              label: 'Chơi',
              sub: 'Miễn phí',
              color: const Color(0xFFE91E63),
              onTap: _playWithPet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.bedtime_rounded,
              label: 'Ngủ',
              sub: 'Miễn phí',
              color: const Color(0xFF5C6BC0),
              onTap: _sleepPet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(sub,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
