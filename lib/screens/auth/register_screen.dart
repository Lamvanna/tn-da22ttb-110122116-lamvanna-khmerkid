import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import 'login_screen.dart';

/// Màn hình Đăng ký - Deep glassmorphism design
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obPass = true, _obConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width, height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
            colors: [AppColors.primary, AppColors.primaryLight]),
        ),
        child: Stack(children: [
          // ── Blurred background shapes ──
          Positioned(top: -50, left: -50,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2)))),
          Positioned(bottom: -100, right: -50,
            child: Container(width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15)))),
          Positioned(top: size.height * 0.3, right: -50,
            child: Container(width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18)))),
          Positioned(bottom: size.height * 0.1, left: -100,
            child: Container(width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10)))),

          // ── Blur overlay ──
          Positioned.fill(child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const SizedBox())),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(children: [
                    SizedBox(height: size.height * 0.02),

                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Glass Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 80),
                          padding: const EdgeInsets.fromLTRB(28, 100, 28, 36),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.10),
                              blurRadius: 40, offset: const Offset(0, 12))]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Form(
                                key: _formKey,
                                child: Column(children: [
                                  Text('Đăng ký tài khoản', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),

                                  const SizedBox(height: 24),

                                  _glassInput(controller: _nameCtrl, hint: 'Họ và tên',
                                    icon: Icons.person_outline_rounded),
                                  const SizedBox(height: 14),

                                  _glassInput(controller: _phoneCtrl, hint: 'Số điện thoại',
                                    icon: Icons.phone_android_rounded,
                                    keyboard: TextInputType.phone),
                                  const SizedBox(height: 14),

                                  _glassInput(controller: _passCtrl, hint: 'Mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true, obscure: _obPass,
                                    onToggle: () => setState(() => _obPass = !_obPass)),
                                  const SizedBox(height: 14),

                                  _glassInput(controller: _confirmCtrl, hint: 'Xác nhận mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true, obscure: _obConfirm,
                                    onToggle: () => setState(() => _obConfirm = !_obConfirm)),

                                  const SizedBox(height: 20),

                                  // Register button — yellow CTA
                                  GestureDetector(
                                    onTap: _handleRegister,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.secondaryLight, AppColors.secondary]),
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [BoxShadow(
                                          color: AppColors.secondary.withValues(alpha: 0.30),
                                          blurRadius: 20, offset: const Offset(0, 8))]),
                                      child: Center(child: Text('Đăng ký', style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onBackground))),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Row(children: [
                                    Expanded(child: _socialGlassBtn('Google', isGoogle: true)),
                                    const SizedBox(width: 14),
                                    Expanded(child: _socialGlassBtn('Facebook', icon: Icons.facebook, color: Colors.white)),
                                  ]),

                                  const SizedBox(height: 24),

                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text('Đã có tài khoản? ', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                                    GestureDetector(
                                      onTap: () => Navigator.pushReplacement(context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                                      child: Text('Đăng nhập', style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white.withValues(alpha: 0.5)))),
                                  ]),
                                ]),
                              ),
                            ),
                          ),
                        ),

                        // ── Overlapping Avatar ──
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 20)]),
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

  Widget _glassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboard,
        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22),
          suffixIcon: isPassword
            ? IconButton(onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.6), size: 22))
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _socialGlassBtn(String label, {bool isGoogle = false, IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isGoogle)
          Text('G', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700,
            foreground: Paint()..shader = const LinearGradient(
              colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)])
              .createShader(const Rect.fromLTWH(0, 0, 20, 20))))
        else
          Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }

  void _handleRegister() {
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(padding: const EdgeInsets.all(28), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: AppColors.tertiary, size: 44)),
          const SizedBox(height: 20),
          Text('Đăng ký thành công!', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
          const SizedBox(height: 8),
          Text('Tài khoản đã được tạo.\nHãy đăng nhập để bắt đầu học!', textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder()),
            child: Text('Đăng nhập ngay', style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
        ])),
    ));
  }
}
