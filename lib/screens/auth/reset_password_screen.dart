import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'login_screen.dart';

/// Màn hình Đặt lại mật khẩu - Green glassmorphism design
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _fadeCtrl.forward(); });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        Container(
          width: size.width, height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFB2DFDB), Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFFB2DFDB)],
              stops: [0.0, 0.3, 0.7, 1.0])),
        ),
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => CustomPaint(size: size, painter: _WavePainter(progress: _waveCtrl.value)),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              const SizedBox(height: 10),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32), size: 22)),
                  ),
                  const Spacer(),
                  Text('Mật khẩu mới', style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF1B5E20))),
                  const Spacer(),
                  const SizedBox(width: 44),
                ]),
              ),
              SizedBox(height: size.height * 0.06),
              // Shield icon
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.25), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 12, offset: const Offset(0, -2))]),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF43A047), size: 50),
              ),
              const SizedBox(height: 24),
              // Glass Card
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.08), blurRadius: 32, offset: const Offset(0, 12)),
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      Text('Tạo mật khẩu mới', style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20))),
                      const SizedBox(height: 6),
                      Text('Mật khẩu mới phải khác với\nmật khẩu đã sử dụng trước đó.', textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E), height: 1.5)),
                      const SizedBox(height: 24),
                      // Password field
                      _buildPassField(
                        controller: _passwordController,
                        hint: 'Mật khẩu mới',
                        obscure: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                      const SizedBox(height: 14),
                      // Confirm field
                      _buildPassField(
                        controller: _confirmPasswordController,
                        hint: 'Xác nhận mật khẩu mới',
                        obscure: _obscureConfirmPassword,
                        onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      const SizedBox(height: 14),
                      // Requirements
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Yêu cầu mật khẩu:', style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
                          const SizedBox(height: 6),
                          _req('Ít nhất 6 ký tự'),
                          _req('Có chữ hoa và chữ thường'),
                          _req('Có ít nhất 1 số'),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      // Reset button
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF43A047).withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Đặt lại mật khẩu', style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildPassField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBDBDBD)),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF66BB6A), size: 22),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFFBDBDBD), size: 22)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFF66BB6A).withValues(alpha: 0.2), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF43A047), width: 2)),
      ),
    );
  }

  Widget _req(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF66BB6A), size: 16),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF757575))),
      ]),
    );
  }

  void _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (password.isEmpty || confirm.isEmpty) { _showError('Vui lòng nhập đầy đủ mật khẩu'); return; }
    if (password.length < 6) { _showError('Mật khẩu phải có ít nhất 6 ký tự'); return; }
    if (password != confirm) { _showError('Mật khẩu không khớp'); return; }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSuccessDialog();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFEF5350),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _showSuccessDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 44)),
          const SizedBox(height: 20),
          Text('Thành công!', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          Text('Mật khẩu đã được đặt lại.\nHãy đăng nhập với mật khẩu mới!', textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF757575))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Đăng nhập ngay', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
        ])),
    ));
  }
}

// ══════════════════ WAVE PAINTER ══════════════════

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = progress * 2 * math.pi;

    _drawRibbon(canvas, points: [
      Offset(w * 0.6, -h * 0.02 + math.sin(t) * 8),
      Offset(w * 1.05, h * 0.12 + math.cos(t + 0.5) * 6),
      Offset(w * 0.7, h * 0.25 + math.sin(t + 1.0) * 10),
      Offset(w * 1.1, h * 0.38 + math.cos(t + 1.5) * 5),
    ], width: 55,
      color1: const Color(0xFF81C784).withValues(alpha: 0.35),
      color2: Colors.white.withValues(alpha: 0.20));

    _drawRibbon(canvas, points: [
      Offset(-w * 0.08, h * 0.78 + math.cos(t + 1.0) * 8),
      Offset(w * 0.25, h * 0.85 + math.sin(t + 1.5) * 10),
      Offset(w * 0.5, h * 0.75 + math.cos(t + 2.0) * 6),
      Offset(w * 0.8, h * 0.82 + math.sin(t + 2.5) * 8),
    ], width: 50,
      color1: const Color(0xFF66BB6A).withValues(alpha: 0.30),
      color2: Colors.white.withValues(alpha: 0.22));

    _drawGlowCircle(canvas, Offset(w * 0.12, h * 0.08), 50, const Color(0xFF81C784).withValues(alpha: 0.12));
    _drawGlowCircle(canvas, Offset(w * 0.88, h * 0.88), 45, const Color(0xFF66BB6A).withValues(alpha: 0.10));
  }

  void _drawRibbon(Canvas canvas, {required List<Offset> points, required double width, required Color color1, required Color color2}) {
    if (points.length < 4) return;
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy - width / 2);
    path.cubicTo(points[1].dx, points[1].dy - width / 2, points[2].dx, points[2].dy - width / 2, points[3].dx, points[3].dy - width / 2);
    path.lineTo(points[3].dx, points[3].dy + width / 2);
    path.cubicTo(points[2].dx, points[2].dy + width / 2, points[1].dx, points[1].dy + width / 2, points[0].dx, points[0].dy + width / 2);
    path.close();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color1, color2, color1])
        .createShader(path.getBounds()));
    final center = Path();
    center.moveTo(points[0].dx, points[0].dy);
    center.cubicTo(points[1].dx, points[1].dy, points[2].dx, points[2].dy, points[3].dx, points[3].dy);
    canvas.drawPath(center, Paint()..color = Colors.white.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawGlowCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.0)])
        .createShader(Rect.fromCircle(center: center, radius: radius)));
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}
