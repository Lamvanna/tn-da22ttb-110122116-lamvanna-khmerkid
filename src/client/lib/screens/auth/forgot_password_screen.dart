import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'reset_password_screen.dart';

// Màn hình Quên mật khẩu - Premium UI/UX KhmerKid
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  final FocusNode _emailFocusNode = FocusNode();
  bool _emailFocused = false;
  String? _emailError;

  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() => _emailFocused = _emailFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Stack(
        children: [


          // 2. Lớp sóng chính phía trước (Front Wave)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220.h,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySurface,
                      AppColors.primarySurface.withOpacity(0.5),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),



          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  // Header với nút quay lại và tiêu đề
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8.r,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Quên mật khẩu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A2540),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 44.w), // Cân bằng với nút Back
                      ],
                    ),
                  ),
                  SizedBox(height: 35.h),

                  // Logo ứng dụng khớp nền 173F9B
                  _buildBrandLogo(),
                  SizedBox(height: 24.h),

                  // Card thông tin & Form
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 32.r,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Đừng lo lắng! 🔐',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A2540),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Nhập email hoặc số điện thoại đã đăng ký để nhận mã xác minh.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Input Email/Phone
                        _modernInputField(
                          controller: _emailCtrl,
                          hint: 'Email hoặc số điện thoại',
                          icon: Icons.email_outlined,
                          focusNode: _emailFocusNode,
                          isFocused: _emailFocused,
                          errorText: _emailError,
                        ),
                        if (_emailError != null) _buildErrorMessage(_emailError!),
                        SizedBox(height: 24.h),

                        // Nút Gửi mã
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isButtonPressed = true),
                          onTapUp: (_) => setState(() => _isButtonPressed = false),
                          onTapCancel: () => setState(() => _isButtonPressed = false),
                          onTap: _isLoading ? null : _handleSendCode,
                          child: AnimatedScale(
                            scale: _isButtonPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: double.infinity,
                              height: 54.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          AppColors.primaryLight.withOpacity(0.6),
                                          AppColors.primary.withOpacity(0.6)
                                        ]
                                      : [AppColors.primaryLight, AppColors.primary],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.24),
                                    blurRadius: 16.r,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Gửi mã xác minh',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Quay lại đăng nhập link
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Quay lại đăng nhập',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      width: 110.w,
      height: 110.w,
      decoration: BoxDecoration(
        color: const Color(0xFF173F9B),
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: Colors.white,
          width: 3.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173F9B).withOpacity(0.2),
            blurRadius: 20.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(10.w),
      child: Image.asset(
        'image/Logo App.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _modernInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    String? errorText,
  }) {
    final hasError = errorText != null;
    Color borderStrokeColor;
    Color iconColor;
    Color bgColor;

    if (hasError) {
      borderStrokeColor = const Color(0xFFEF5350);
      iconColor = const Color(0xFFEF5350);
      bgColor = const Color(0xFFFFECEB);
    } else if (isFocused) {
      borderStrokeColor = AppColors.primary;
      iconColor = AppColors.primary;
      bgColor = Colors.white;
    } else {
      borderStrokeColor = const Color(0xFFE5E7EB);
      iconColor = const Color(0xFF9CA3AF);
      bgColor = const Color(0xFFF9FAFB);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderStrokeColor,
          width: isFocused ? 1.6.w : 1.2.w,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 10.r,
                  spreadRadius: 1.r,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: 22.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h, left: 4.w),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF5350),
            size: 16,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF5350),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email hoặc số điện thoại');
      return;
    }
    setState(() {
      _emailError = null;
      _isLoading = true;
    });

    final result = await AuthService().forgotPassword(email);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ══════════════════ VERIFY CODE SCREEN ══════════════════

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 60;
  bool _canResend = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (int i = 0; i < 4; i++) {
      _focusNodes[i].addListener(() => setState(() {}));
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) _canResend = true;
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _codeControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Stack(
        children: [


          // 2. Lớp sóng chính phía trước (Front Wave)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220.h,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySurface,
                      AppColors.primarySurface.withOpacity(0.5),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),



          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  // Header với nút quay lại và tiêu đề
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8.r,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Xác minh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A2540),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 44.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 35.h),

                  // Logo ứng dụng khớp nền 173F9B
                  _buildBrandLogo(),
                  SizedBox(height: 24.h),

                  // Card thông tin & OTP boxes
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 32.r,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Nhập mã xác minh ✉️',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A2540),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Chúng tôi đã gửi mã 4 số đến\n${widget.email}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 28.h),

                        // Ô OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final isFocused = _focusNodes[i].hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 58.w,
                              height: 62.w,
                              margin: EdgeInsets.only(right: i < 3 ? 14.w : 0),
                              decoration: BoxDecoration(
                                color: isFocused ? Colors.white : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isFocused ? AppColors.primary : const Color(0xFFE5E7EB),
                                  width: isFocused ? 1.8.w : 1.2.w,
                                ),
                                boxShadow: isFocused
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.06),
                                          blurRadius: 10.r,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _codeControllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0A2540),
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  if (v.length == 1 && i < 3) {
                                    _focusNodes[i + 1].requestFocus();
                                  } else if (v.isEmpty && i > 0) {
                                    _focusNodes[i - 1].requestFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 24.h),

                        // Resend
                        _canResend
                            ? GestureDetector(
                                onTap: () {
                                  _startResendTimer();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã gửi lại mã xác minh!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Gửi lại mã',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                ),
                              )
                            : RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                  children: [
                                    const TextSpan(text: 'Gửi lại mã sau '),
                                    TextSpan(
                                      text: '${_resendSeconds}s',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        SizedBox(height: 28.h),

                        // Nút Xác minh
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isButtonPressed = true),
                          onTapUp: (_) => setState(() => _isButtonPressed = false),
                          onTapCancel: () => setState(() => _isButtonPressed = false),
                          onTap: _isLoading ? null : _handleVerify,
                          child: AnimatedScale(
                            scale: _isButtonPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: double.infinity,
                              height: 54.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          AppColors.primaryLight.withOpacity(0.6),
                                          AppColors.primary.withOpacity(0.6)
                                        ]
                                      : [AppColors.primaryLight, AppColors.primary],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.24),
                                    blurRadius: 16.r,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Xác minh',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      width: 110.w,
      height: 110.w,
      decoration: BoxDecoration(
        color: const Color(0xFF173F9B),
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: Colors.white,
          width: 3.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173F9B).withOpacity(0.2),
            blurRadius: 20.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(10.w),
      child: Image.asset(
        'image/Logo App.png',
        fit: BoxFit.contain,
      ),
    );
  }

  void _handleVerify() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập đủ 4 số',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    
    final result = await AuthService().verifyOTP(widget.email, code);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email, otp: code),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ══════════════════ WAVE CLIPPERS (Shared) ══════════════════

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);

    final firstControl = Offset(size.width * 0.3, size.height * 0.95);
    final firstEnd = Offset(size.width * 0.6, size.height * 0.7);
    path.quadraticBezierTo(firstControl.dx, firstControl.dy, firstEnd.dx, firstEnd.dy);

    final secondControl = Offset(size.width * 0.85, size.height * 0.5);
    final secondEnd = Offset(size.width, size.height * 0.85);
    path.quadraticBezierTo(secondControl.dx, secondControl.dy, secondEnd.dx, secondEnd.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BackWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);

    final firstControl = Offset(size.width * 0.25, size.height * 0.65);
    final firstEnd = Offset(size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(firstControl.dx, firstControl.dy, firstEnd.dx, firstEnd.dy);

    final secondControl = Offset(size.width * 0.75, size.height * 1.05);
    final secondEnd = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(secondControl.dx, secondControl.dy, secondEnd.dx, secondEnd.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
