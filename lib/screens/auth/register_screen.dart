import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import 'login_screen.dart';

/// Màn hình Đăng ký - Deep glassmorphism design - RESPONSIVE
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
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        ),
        child: Stack(children: [
          // ── Blurred background shapes ──
          Positioned(top: -50.h, left: -50.w,
            child: Container(width: 300.w, height: 300.w,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2)))),
          Positioned(bottom: -100.h, right: -50.w,
            child: Container(width: 400.w, height: 400.w,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15)))),
          Positioned(top: 270.h, right: -50.w,
            child: Container(width: 250.w, height: 250.w,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18)))),
          Positioned(bottom: 90.h, left: -100.w,
            child: Container(width: 350.w, height: 350.w,
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(children: [
                    SizedBox(height: 16.h),

                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Glass Card
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: 80.h),
                          padding: EdgeInsets.fromLTRB(28.w, 100.h, 28.w, 36.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(40.r),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF0D47A1).withValues(alpha: 0.10),
                              blurRadius: 40.r, offset: Offset(0, 12.h))]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Form(
                                key: _formKey,
                                child: Column(children: [
                                  Text('Đăng ký tài khoản', style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28.sp, fontWeight: FontWeight.w800, color: Colors.white)),

                                  SizedBox(height: 24.h),

                                  _glassInput(controller: _nameCtrl, hint: 'Họ và tên',
                                    icon: Icons.person_outline_rounded),
                                  SizedBox(height: 14.h),

                                  _glassInput(controller: _phoneCtrl, hint: 'Số điện thoại',
                                    icon: Icons.phone_android_rounded,
                                    keyboard: TextInputType.phone),
                                  SizedBox(height: 14.h),

                                  _glassInput(controller: _passCtrl, hint: 'Mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true, obscure: _obPass,
                                    onToggle: () => setState(() => _obPass = !_obPass)),
                                  SizedBox(height: 14.h),

                                  _glassInput(controller: _confirmCtrl, hint: 'Xác nhận mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true, obscure: _obConfirm,
                                    onToggle: () => setState(() => _obConfirm = !_obConfirm)),

                                  SizedBox(height: 20.h),

                                  // Register button — yellow CTA
                                  GestureDetector(
                                    onTap: _handleRegister,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50.r),
                                        boxShadow: [BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.30),
                                          blurRadius: 20.r, offset: Offset(0, 8.h))]),
                                      child: Center(child: Text('Đăng ký', style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1976D2)))),
                                    ),
                                  ),

                                  SizedBox(height: 24.h),

                                  Row(children: [
                                    Expanded(child: _socialGlassBtn('Google', isGoogle: true)),
                                    SizedBox(width: 14.w),
                                    Expanded(child: _socialGlassBtn('Facebook', icon: Icons.facebook, color: Colors.white)),
                                  ]),

                                  SizedBox(height: 24.h),

                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text('Đã có tài khoản? ', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                                    GestureDetector(
                                      onTap: () => Navigator.pushReplacement(context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                                      child: Text('Đăng nhập', style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white,
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
                            width: 150.w, height: 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 20.r)]),
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
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18.r)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboard,
        style: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15.sp, fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22.sp),
          suffixIcon: isPassword
            ? IconButton(onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.6), size: 22.sp))
            : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _socialGlassBtn(String label, {bool isGoogle = false, IconData? icon, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
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
          fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }

  void _handleRegister() {
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(padding: EdgeInsets.all(28.w), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72.w, height: 72.w,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: AppColors.tertiary, size: 44.sp)),
          SizedBox(height: 20.h),
          Text('Đăng ký thành công!', style: GoogleFonts.plusJakartaSans(
            fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
          SizedBox(height: 8.h),
          Text('Tài khoản đã được tạo.\nHãy đăng nhập để bắt đầu học!', textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          SizedBox(height: 24.h),
          SizedBox(width: double.infinity, height: 50.h, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              shape: const StadiumBorder()),
            child: Text('Đăng nhập ngay', style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)))),
        ])),
    ));
  }
}
