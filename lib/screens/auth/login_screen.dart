import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import '../main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập - Deep glassmorphism design - RESPONSIVE
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
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7), 
            end: Alignment(0.7, 0.7),
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        ),
        child: Stack(children: [
          // ── Radial glow overlays ──
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, 0.0), radius: 1.0,
              colors: [Colors.white.withValues(alpha: 0.25), Colors.transparent]),
          ))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.7, -0.4), radius: 1.0,
              colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent]),
          ))),

          // ── Large decorative circle (top-left) ──
          Positioned(
            top: -230.h, left: -125.w,
            child: Container(
              width: 660.w, height: 660.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 40.w),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.10), blurRadius: 40.r)]),
            ),
          ),

          // ── Large decorative circle (bottom-right) ──
          Positioned(
            bottom: -230.h, right: -145.w,
            child: Container(
              width: 620.w, height: 620.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 50.w),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.12), blurRadius: 40.r)]),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(children: [
                    SizedBox(height: 8.h),

                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Glass Card
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: 68.h),
                          padding: EdgeInsets.fromLTRB(28.w, 90.h, 28.w, 36.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(40.r),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF0D47A1).withValues(alpha: 0.10),
                              blurRadius: 40.r, offset: Offset(0, 12.h))]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                              child: Column(children: [
                                Text('Khmer Kids', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.sp, fontWeight: FontWeight.w800,
                                  color: Colors.white, letterSpacing: -0.5)),
                                SizedBox(height: 4.h),
                                Text('Học chữ Khmer vui nhộn ☀️', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),

                                SizedBox(height: 28.h),

                                Text('Đăng nhập', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 27.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                SizedBox(height: 4.h),
                                Text('Chào mừng bạn trở lại! 👋', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),

                                SizedBox(height: 24.h),

                                _glassInput(controller: _userCtrl,
                                  hint: 'Tên đăng nhập hoặc SĐT',
                                  icon: Icons.person_outline_rounded),
                                SizedBox(height: 14.h),

                                _glassInput(controller: _passCtrl,
                                  hint: 'Mật khẩu',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true),
                                SizedBox(height: 8.h),

                                // Remember + Forgot
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _remember = !_remember),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            SizedBox(width: 18.w, height: 18.w, child: Checkbox(
                                              value: _remember,
                                              onChanged: (v) => setState(() => _remember = v ?? false),
                                              activeColor: AppColors.primaryContainer,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                                              side: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5.w),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact)),
                                            SizedBox(width: 6.w),
                                            Flexible(child: Text('Ghi nhớ', style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
                                              overflow: TextOverflow.ellipsis)),
                                          ]),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.push(context,
                                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                        child: Text('Quên mật khẩu?', style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white.withValues(alpha: 0.5)))),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 16.h),

                                // Login button (gradient pill)
                                GestureDetector(
                                  onTap: _handleLogin,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50.r),
                                      boxShadow: [BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.30),
                                        blurRadius: 20.r, offset: Offset(0, 8.h))]),
                                    child: Center(child: Text('Đăng nhập', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1976D2)))),
                                  ),
                                ),

                                SizedBox(height: 24.h),

                                Row(children: [
                                  Expanded(child: _socialGlassBtn('Google', isGoogle: true)),
                                  SizedBox(width: 14.w),
                                  Expanded(child: _socialGlassBtn('Facebook', icon: Icons.facebook, color: Colors.white)),
                                ]),

                                SizedBox(height: 28.h),

                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('Chưa có tài khoản? ', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                    child: Text('Đăng ký ngay', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white.withValues(alpha: 0.5)))),
                                ]),
                              ]),
                            ),
                          ),
                        ),

                        // ── Overlapping Avatar ──
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 136.w, height: 136.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20.r)]),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: ClipOval(
                                    child: Image.asset('assets/images/elephant_mascot.png', fit: BoxFit.cover)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 36.h),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18.r)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscure : false,
        style: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 16.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22.sp),
          suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.6), size: 22.sp))
            : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        ),
      ),
    );
  }

  Widget _socialGlassBtn(String label, {bool isGoogle = false, IconData? icon, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50.r)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isGoogle)
          Text('G', style: GoogleFonts.roboto(fontSize: 20.sp, fontWeight: FontWeight.w700,
            foreground: Paint()..shader = const LinearGradient(
              colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)])
              .createShader(const Rect.fromLTWH(0, 0, 20, 20))))
        else
          Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 8.w),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }

  void _handleLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }
}
