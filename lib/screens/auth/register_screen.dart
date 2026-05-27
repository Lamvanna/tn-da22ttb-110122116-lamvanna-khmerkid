import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

/// Màn hình Đăng ký — Deep Glassmorphism (Premium 2026)
/// Đồng bộ visual language với LoginScreen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ─── Form ──
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obPass    = true;
  bool _obConfirm = true;
  bool _isLoading = false;

  String? _nameError, _emailError, _passError, _confirmError;

  // ─── Entrance animation ──
  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width:  1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7),
            end:   Alignment(0.7, 0.7),
            colors: [AppColors.headerDark, AppColors.headerAccent],
          ),
        ),
        child: Stack(
          children: [
            // ─── Decorative background (đồng bộ login) ──
            _buildBackdrop(),

            // ─── Main content ──
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 8.h),
                            _buildCardWithMascot(),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Background: 2 ring circles + 2 radial glow ──────────────────
  Widget _buildBackdrop() {
    return Stack(
      children: [
        // Radial glows
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, 0.0),
                radius: 1.0,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.4),
                radius: 1.0,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Top-left ring
        Positioned(
          top: -230.h, left: -125.w,
          child: Container(
            width: 660.w, height: 660.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 40.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.10),
                  blurRadius: 40.r,
                ),
              ],
            ),
          ),
        ),
        // Bottom-right ring
        Positioned(
          bottom: -230.h, right: -145.w,
          child: Container(
            width: 620.w, height: 620.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 50.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 40.r,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Glass card + overlapping mascot ─────────────────────────────
  Widget _buildCardWithMascot() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Glass card
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 68.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(40.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.12),
                blurRadius: 40.r,
                offset: Offset(0, 14.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Padding(
                padding: EdgeInsets.fromLTRB(28.w, 90.h, 28.w, 32.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Heading ──
                      Text(
                        'Tạo tài khoản',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Bắt đầu hành trình học Khmer 🎉',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // ── Inputs ──
                      _glassInput(
                        controller: _nameCtrl,
                        hint: 'Họ và tên',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _animatedError(_nameError),

                      SizedBox(height: 12.h),
                      _glassInput(
                        controller: _emailCtrl,
                        hint: 'Địa chỉ Email',
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                      ),
                      _animatedError(_emailError),

                      SizedBox(height: 12.h),
                      _glassInput(
                        controller: _passCtrl,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: _obPass,
                        onToggle: () => setState(() => _obPass = !_obPass),
                      ),
                      _animatedError(_passError),

                      SizedBox(height: 12.h),
                      _glassInput(
                        controller: _confirmCtrl,
                        hint: 'Xác nhận mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: _obConfirm,
                        onToggle: () =>
                            setState(() => _obConfirm = !_obConfirm),
                      ),
                      _animatedError(_confirmError),

                      SizedBox(height: 24.h),

                      // ── CTA ──
                      _primaryCta(),

                      SizedBox(height: 24.h),

                      // ── Social ──
                      Row(
                        children: [
                          Expanded(
                              child: _socialGlassBtn('Google', isGoogle: true)),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _socialGlassBtn(
                              'Facebook',
                              icon: Icons.facebook,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // ── Bottom link ──
                      _signInLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Mascot avatar (overlap)
        Positioned(
          top: 0,
          child: Container(
            width: 136.w, height: 136.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.30),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.30),
                  blurRadius: 20.r,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/elephant_mascot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMPONENTS
  // ════════════════════════════════════════════════════════════════
  Widget _glassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboard,
        textCapitalization: textCapitalization,
        cursorColor: Colors.white,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.3,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.75),
            size: 22.sp,
          ),
          prefixIconConstraints:
              BoxConstraints(minWidth: 48.w, minHeight: 48.w),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggle,
                  splashRadius: 22.r,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 22.sp,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        ),
      ),
    );
  }

  Widget _animatedError(String? msg) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: msg == null
            ? const SizedBox(key: ValueKey('empty'), width: double.infinity)
            : Padding(
                key: ValueKey(msg),
                padding: EdgeInsets.only(left: 6.w, top: 6.h, right: 6.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14.sp,
                      color: const Color(0xFFFFB4AB),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        msg,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFFB4AB),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _primaryCta() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleRegister,
        borderRadius: BorderRadius.circular(50.r),
        splashColor: AppColors.headerMid.withValues(alpha: 0.08),
        highlightColor: AppColors.headerMid.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50.r),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.30),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
                    width: 22.w, height: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.headerMid,
                    ),
                  )
                : Text(
                    'Đăng ký',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headerMid,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _socialGlassBtn(
    String label, {
    bool isGoogle = false,
    IconData? icon,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // TODO: hook social auth
        borderRadius: BorderRadius.circular(50.r),
        splashColor: Colors.white.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(50.r),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isGoogle)
                  Text(
                    'G',
                    style: GoogleFonts.roboto(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            Color(0xFFEA4335),
                            Color(0xFFFBBC05),
                            Color(0xFF34A853),
                            Color(0xFF4285F4),
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 20, 20)),
                    ),
                  )
                else
                  Icon(icon, color: color, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  LOGIC
  // ════════════════════════════════════════════════════════════════
  void _handleRegister() async {
    String? nameErr, emailErr, passErr, confirmErr;

    final nameInput = _nameCtrl.text.trim();
    final emailInput = _emailCtrl.text.trim();
    final passwordInput = _passCtrl.text;
    final confirmInput = _confirmCtrl.text;

    if (nameInput.isEmpty) {
      nameErr = 'Vui lòng nhập họ và tên';
    }
    if (emailInput.isEmpty) {
      emailErr = 'Vui lòng nhập email đăng ký';
    } else if (!emailInput.contains('@')) {
      emailErr = 'Địa chỉ email không hợp lệ (cần ký tự @)';
    }
    
    if (passwordInput.isEmpty) {
      passErr = 'Vui lòng nhập mật khẩu';
    } else if (passwordInput.length < 6) {
      passErr = 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    
    if (confirmInput != passwordInput) {
      confirmErr = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _nameError    = nameErr;
      _emailError   = emailErr;
      _passError    = passErr;
      _confirmError = confirmErr;
    });

    if (nameErr != null ||
        emailErr != null ||
        passErr != null ||
        confirmErr != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().register(
        name: nameInput,
        email: emailInput,
        password: passwordInput,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccess();
      } else {
        _showErrorDialog(result['message'] ?? 'Đăng ký tài khoản thất bại.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi kết nối mạng: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24.sp),
          SizedBox(width: 8.w),
          const Text('Thông báo lỗi'),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đồng ý'),
          )
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 32.h, 28.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76.w, height: 76.w,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.tertiary,
                  size: 46.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Đăng ký thành công!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tài khoản đã được tạo.\nHãy đăng nhập để bắt đầu học!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerMid,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    'Đăng nhập ngay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
