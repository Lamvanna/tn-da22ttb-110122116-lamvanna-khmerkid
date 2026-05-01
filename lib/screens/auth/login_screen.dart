import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập - Deep glassmorphism design (from HTML reference)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _remember = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width, height: size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF71DB9B),
        ),
        child: Stack(children: [
          // ── Radial glow overlays ──
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, 0.0),
              radius: 1.0,
              colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent]),
          ))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.7, -0.4),
              radius: 1.0,
              colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent]),
          ))),

          // ── Large decorative circle (top-left) ──
          Positioned(
            top: -size.height * 0.25,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 1.6,
              height: size.width * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 40),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 40)]),
            ),
          ),

          // ── Large decorative circle (bottom-right) ──
          Positioned(
            bottom: -size.height * 0.25,
            right: -size.width * 0.35,
            child: Container(
              width: size.width * 1.5,
              height: size.width * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 50),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 40)]),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(children: [
                    SizedBox(height: size.height * 0.01),

                    // ── Glass Card with overlapping avatar ──
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Glass Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 68),
                          padding: const EdgeInsets.fromLTRB(28, 90, 28, 36),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                            boxShadow: [BoxShadow(color: const Color(0xFF004D40).withValues(alpha: 0.15), blurRadius: 50, offset: const Offset(0, 20))]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                              child: Column(children: [
                                // App Name
                                Text('Khmer Kids', style: GoogleFonts.fredoka(
                                  fontSize: 34, fontWeight: FontWeight.w700, color: const Color(0xFF004D40),
                                  letterSpacing: -0.5)),
                                const SizedBox(height: 4),
                                Text('Học chữ Khmer vui nhộn ☀️', style: GoogleFonts.nunito(
                                  fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),

                                const SizedBox(height: 28),

                                // Welcome
                                Text('Đăng nhập', style: GoogleFonts.nunito(
                                  fontSize: 27, fontWeight: FontWeight.w700, color: Colors.black)),
                                const SizedBox(height: 4),
                                Text('Chào mừng bạn trở lại! 👋', style: GoogleFonts.nunito(
                                  fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),

                                const SizedBox(height: 24),

                                // Username field
                                _glassInput(
                                  controller: _userCtrl,
                                  hint: 'Tên đăng nhập hoặc SĐT',
                                  icon: Icons.person_outline_rounded),

                                const SizedBox(height: 14),

                                // Password field
                                _glassInput(
                                  controller: _passCtrl,
                                  hint: 'Mật khẩu',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true),

                                const SizedBox(height: 8),

                                // Remember + Forgot
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _remember = !_remember),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          SizedBox(width: 18, height: 18, child: Checkbox(
                                            value: _remember,
                                            onChanged: (v) => setState(() => _remember = v ?? false),
                                            activeColor: const Color(0xFF059669),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact)),
                                          const SizedBox(width: 8),
                                          Text('Ghi nhớ đăng nhập', style: GoogleFonts.nunito(
                                            fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
                                        ]),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.push(context,
                                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                        child: Text('Quên mật khẩu?', style: GoogleFonts.nunito(
                                          fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF1A1A1A).withValues(alpha: 0.5)))),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Login button (gradient pill)
                                GestureDetector(
                                  onTap: _handleLogin,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        colors: [Color(0xFF34D399), Color(0xFF059669)]),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 4))]),
                                    child: Center(child: Text('Đăng nhập', style: GoogleFonts.nunito(
                                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Social buttons (glass pill)
                                Row(children: [
                                  Expanded(child: _socialGlassBtn('Google', isGoogle: true)),
                                  const SizedBox(width: 14),
                                  Expanded(child: _socialGlassBtn('Facebook', icon: Icons.facebook, color: const Color(0xFF1877F2))),
                                ]),

                                const SizedBox(height: 28),

                                // Register link
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('Chưa có tài khoản? ', style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                    child: Text('Đăng ký ngay', style: GoogleFonts.nunito(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.black.withValues(alpha: 0.5)))),
                                ]),
                              ]),
                            ),
                          ),
                        ),

                        // ── Overlapping Avatar ──
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 136, height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 6),
                              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 20)]),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipOval(
                                    child: Image.asset('assets/images/elephant_mascot.png', fit: BoxFit.cover)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.04),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Glass input field ──
  Widget _glassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscure : false,
        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280)),
          prefixIcon: Icon(icon, color: const Color(0xFF809990), size: 22),
          suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF809990), size: 22))
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  // ── Social glass pill button ──
  Widget _socialGlassBtn(String label, {bool isGoogle = false, IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isGoogle)
          Text('G', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700,
            foreground: Paint()..shader = const LinearGradient(
              colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)])
              .createShader(const Rect.fromLTWH(0, 0, 20, 20))))
        else
          Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
      ]),
    );
  }

  void _handleLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }
}
