import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_text_styles.dart';

/// Màn hình Đánh vần / Viết chữ - Spelling Practice Screen
/// Hiển thị chữ mẫu và vùng viết (dùng ngón tay vẽ)
class SpellingScreen extends StatefulWidget {
  final String character;
  final String romanized;

  const SpellingScreen({
    super.key,
    this.character = 'ក',
    this.romanized = 'Ca',
  });

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Thẻ chữ mẫu ──
                  _buildTemplateCard(),

                  const SizedBox(height: 20),

                  // ── Vùng viết ──
                  _buildWritingArea(),

                  const SizedBox(height: 16),

                  // ── Nút hành động ──
                  _buildActionButtons(),
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
        gradient: AppColors.purpleGradient,
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
                  AppStrings.spellingTitle,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ hiển thị ký tự mẫu cần viết
  Widget _buildTemplateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
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
          // Ký tự lớn
          Text(
            widget.character,
            style: GoogleFonts.kantumruyPro(
              fontSize: 80,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.romanized,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.traceTemplate,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Vùng viết - Canvas vẽ bằng ngón tay
  Widget _buildWritingArea() {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.writingArea,
                  style: AppTextStyles.sectionTitle,
                ),
                IconButton(
                  onPressed: _clearDrawing,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.writingAreaDesc,
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          // Drawing canvas
          Container(
            margin: const EdgeInsets.all(16),
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Grid lines (dotted guide)
                  CustomPaint(
                    size: const Size(double.infinity, 250),
                    painter: _GridPainter(),
                  ),
                  // Ghost template character
                  Center(
                    child: Text(
                      widget.character,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 120,
                        color: AppColors.primaryPurple.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Drawing area
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _strokes.add(List.from(_currentStroke));
                        _currentStroke = [];
                      });
                    },
                    child: CustomPaint(
                      size: const Size(double.infinity, 250),
                      painter: _DrawingPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearDrawing,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textHint.withValues(alpha: 0.3),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 22),
            label: Text('Xóa', style: AppTextStyles.buttonText.copyWith(
              color: AppColors.textPrimary,
            )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkWriting,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 22),
            label: Text('Kiểm tra', style: AppTextStyles.buttonText),
          ),
        ),
      ],
    );
  }

  /// Kiểm tra nét viết dựa trên: số stroke, tổng điểm, và vùng phủ
  void _checkWriting() {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hãy viết chữ trước khi kiểm tra!',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    // Tính số điểm đã vẽ
    int totalPoints = 0;
    for (final stroke in _strokes) {
      totalPoints += stroke.length;
    }

    // Đánh giá:
    // - Ít nhất 1 stroke → đã viết
    // - Ít nhất 30 điểm → viết đủ nét
    // - Ít nhất 2 strokes → viết có nhiều nét
    int stars = 0;
    String message;
    bool passed;

    if (totalPoints >= 50 && _strokes.length >= 2) {
      stars = 3;
      message = 'Xuất sắc! Nét viết rất đẹp! 🌟';
      passed = true;
    } else if (totalPoints >= 30) {
      stars = 2;
      message = 'Khá tốt! Cố gắng thêm nhé! 👍';
      passed = true;
    } else if (totalPoints >= 10) {
      stars = 1;
      message = 'Cần luyện tập thêm! 💪';
      passed = true;
    } else {
      stars = 0;
      message = 'Viết chưa đủ, thử lại nhé!';
      passed = false;
    }

    _showResultDialog(stars, message, passed);
  }

  void _showResultDialog(int stars, String message, bool passed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(passed ? '✅' : '✏️',
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(passed ? 'Đạt!' : 'Thử lại',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: passed
                        ? AppColors.accentGreen
                        : AppColors.accentOrange,
                  )),
              const SizedBox(height: 8),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFD54F),
                    size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium),
              if (passed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${stars * 10} XP ⭐',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.accentOrange,
                      )),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearDrawing();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.primaryPurple),
                      ),
                      child: Text('Viết lại',
                          style: AppTextStyles.buttonTextSmall.copyWith(
                            color: AppColors.primaryPurple,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Hoàn thành',
                          style: AppTextStyles.buttonTextSmall),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter vẽ lưới dotted
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double y = 0; y < size.height; y += size.height / 4) {
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    // Vertical center line
    _drawDashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    // Simple dashed approach
    final totalDistance = (end - start).distance;
    if (totalDistance == 0) return;
    final count = (totalDistance / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < count; i++) {
      final startFraction = i * (dashWidth + dashSpace) / (end - start).distance;
      final endFraction = (i * (dashWidth + dashSpace) + dashWidth) / (end - start).distance;
      if (endFraction > 1.0) break;
      canvas.drawLine(
        Offset.lerp(start, end, startFraction)!,
        Offset.lerp(start, end, endFraction)!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter vẽ nét người dùng
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryPurple
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    // Draw current stroke
    _drawStroke(canvas, currentStroke, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
