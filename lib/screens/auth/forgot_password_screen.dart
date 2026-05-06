import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'reset_password_screen.dart';

/// Màn hình Quên mật khẩu - Green glassmorphism design
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _waveCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))..repeat();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        // Background gradient
        Container(
          width: size.width, height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFB2DFDB), Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFFB2DFDB)],
              stops: [0.0, 0.3, 0.7, 1.0]),
          ),
        ),
        // Waves
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => CustomPaint(size: size, painter: _WavePainter(progress: _waveCtrl.value)),
        ),
        // Content
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
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32), size: 22),
                    ),
                  ),
                  const Spacer(),
                  Text('Quên mật khẩu', style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF1B5E20))),
                  const Spacer(),
                  const SizedBox(width: 44),
                ]),
              ),
              SizedBox(height: size.height * 0.06),
              // Icon
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.25), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 12, offset: const Offset(0, -2))]),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF43A047), size: 50),
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
                      Text('Đừng lo lắng!', style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20))),
                      const SizedBox(height: 6),
                      Text('Nhập email hoặc số điện thoại\nđã đăng ký để nhận mã xác minh.', textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E), height: 1.5)),
                      const SizedBox(height: 24),
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D)),
                        decoration: InputDecoration(
                          hintText: 'Email hoặc số điện thoại',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBDBDBD)),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF66BB6A), size: 22),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: const Color(0xFF66BB6A).withValues(alpha: 0.2), width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF43A047), width: 2)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Send button
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF43A047).withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            disabledBackgroundColor: const Color(0xFF43A047).withValues(alpha: 0.6)),
                          child: _isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Gửi mã xác minh', style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Back to login
              FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 6),
                    Text('Quay lại đăng nhập', style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
                  ]),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }

  void _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vui lòng nhập email hoặc số điện thoại', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)));
  }
}

// ══════════════════ VERIFY CODE SCREEN ══════════════════

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});
  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 60;
  bool _canResend = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _fadeCtrl.forward(); });
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { _resendSeconds--; if (_resendSeconds <= 0) _canResend = true; });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _codeControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
                  Text('Xác minh', style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF1B5E20))),
                  const Spacer(),
                  const SizedBox(width: 44),
                ]),
              ),
              SizedBox(height: size.height * 0.06),
              // Mail icon
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.25), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 12, offset: const Offset(0, -2))]),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF43A047), size: 50),
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
                      Text('Nhập mã xác minh', style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20))),
                      const SizedBox(height: 6),
                      Text('Chúng tôi đã gửi mã 4 số đến\n${widget.email}', textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9E9E9E), height: 1.5)),
                      const SizedBox(height: 28),
                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) => Container(
                          width: 58, height: 62,
                          margin: EdgeInsets.only(right: i < 3 ? 14 : 0),
                          child: TextField(
                            controller: _codeControllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20)),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.7),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: const Color(0xFF66BB6A).withValues(alpha: 0.3), width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF43A047), width: 2))),
                            onChanged: (v) {
                              if (v.length == 1 && i < 3) _focusNodes[i + 1].requestFocus();
                              else if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                            },
                          ),
                        )),
                      ),
                      const SizedBox(height: 20),
                      // Resend
                      _canResend
                        ? GestureDetector(
                            onTap: () {
                              _startResendTimer();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Đã gửi lại mã xác minh!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                            },
                            child: Text('Gửi lại mã', style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32),
                              decoration: TextDecoration.underline, decorationColor: const Color(0xFF2E7D32))))
                        : RichText(text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9E9E9E)),
                            children: [
                              const TextSpan(text: 'Gửi lại mã sau '),
                              TextSpan(text: '${_resendSeconds}s',
                                style: const TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.w700)),
                            ])),
                      const SizedBox(height: 24),
                      // Verify button
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF43A047).withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Xác minh', style: GoogleFonts.plusJakartaSans(
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

  void _handleVerify() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vui lòng nhập đủ 4 số', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
  }
}

// ══════════════════ WAVE PAINTER (shared) ══════════════════

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
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
      Offset(-w * 0.05, h * 0.05 + math.sin(t + 2.0) * 6),
      Offset(w * 0.35, h * 0.02 + math.cos(t + 2.5) * 8),
      Offset(w * 0.55, h * 0.1 + math.sin(t + 3.0) * 5),
      Offset(w * 0.85, h * 0.04 + math.cos(t + 3.5) * 7),
    ], width: 40,
      color1: Colors.white.withValues(alpha: 0.30),
      color2: const Color(0xFFA5D6A7).withValues(alpha: 0.18));

    _drawRibbon(canvas, points: [
      Offset(-w * 0.08, h * 0.78 + math.cos(t + 1.0) * 8),
      Offset(w * 0.25, h * 0.85 + math.sin(t + 1.5) * 10),
      Offset(w * 0.5, h * 0.75 + math.cos(t + 2.0) * 6),
      Offset(w * 0.8, h * 0.82 + math.sin(t + 2.5) * 8),
    ], width: 50,
      color1: const Color(0xFF66BB6A).withValues(alpha: 0.30),
      color2: Colors.white.withValues(alpha: 0.22));

    _drawGlowCircle(canvas, Offset(w * 0.12, h * 0.08), 50, const Color(0xFF81C784).withValues(alpha: 0.12));
    _drawGlowCircle(canvas, Offset(w * 0.88, h * 0.15), 35, Colors.white.withValues(alpha: 0.15));
    _drawGlowCircle(canvas, Offset(w * 0.85, h * 0.88), 45, const Color(0xFF66BB6A).withValues(alpha: 0.10));
  }

  void _drawRibbon(Canvas canvas, {required List<Offset> points, required double width, required Color color1, required Color color2}) {
    if (points.length < 4) return;
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy - width / 2);
    path.cubicTo(points[1].dx, points[1].dy - width / 2, points[2].dx, points[2].dy - width / 2, points[3].dx, points[3].dy - width / 2);
    path.lineTo(points[3].dx, points[3].dy + width / 2);
    path.cubicTo(points[2].dx, points[2].dy + width / 2, points[1].dx, points[1].dy + width / 2, points[0].dx, points[0].dy + width / 2);
    path.close();
    final rect = path.getBounds();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color1, color2, color1]).createShader(rect));
    final center = Path();
    center.moveTo(points[0].dx, points[0].dy);
    center.cubicTo(points[1].dx, points[1].dy, points[2].dx, points[2].dy, points[3].dx, points[3].dy);
    canvas.drawPath(center, Paint()..color = Colors.white.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawGlowCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.0)]).createShader(
        Rect.fromCircle(center: center, radius: radius)));
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}
