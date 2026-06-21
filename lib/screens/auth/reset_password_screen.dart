import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'login_screen.dart';

/// Màn hình Đặt lại mật khẩu - Premium UI/UX KhmerKid
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  bool _passFocused = false;
  bool _confirmFocused = false;
  String? _passError;
  String? _confirmError;

  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _passFocusNode.addListener(() {
      setState(() => _passFocused = _passFocusNode.hasFocus);
    });
    _confirmFocusNode.addListener(() {
      setState(() => _confirmFocused = _confirmFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passFocusNode.dispose();
    _confirmFocusNode.dispose();
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
                          'Mật khẩu mới',
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
                          'Tạo mật khẩu mới 🔑',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A2540),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Mật khẩu mới phải khác với mật khẩu đã sử dụng trước đó.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Ô Mật khẩu mới
                        _modernInputField(
                          controller: _passwordController,
                          hint: 'Mật khẩu mới',
                          icon: Icons.lock_outline_rounded,
                          focusNode: _passFocusNode,
                          isFocused: _passFocused,
                          errorText: _passError,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        if (_passError != null) _buildErrorMessage(_passError!),
                        SizedBox(height: 14.h),

                        // Ô Xác nhận mật khẩu mới
                        _modernInputField(
                          controller: _confirmPasswordController,
                          hint: 'Xác nhận mật khẩu mới',
                          icon: Icons.lock_outline_rounded,
                          focusNode: _confirmFocusNode,
                          isFocused: _confirmFocused,
                          errorText: _confirmError,
                          isPassword: true,
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        if (_confirmError != null) _buildErrorMessage(_confirmError!),
                        SizedBox(height: 16.h),

                        // Yêu cầu mật khẩu
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.primarySurface,
                              width: 1.w,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yêu cầu mật khẩu:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _req('Ít nhất 6 ký tự'),
                              _req('Có chữ hoa và chữ thường'),
                              _req('Có ít nhất 1 số'),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Nút đặt lại mật khẩu
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isButtonPressed = true),
                          onTapUp: (_) => setState(() => _isButtonPressed = false),
                          onTapCancel: () => setState(() => _isButtonPressed = false),
                          onTap: _isLoading ? null : _handleReset,
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
                                      'Đặt lại mật khẩu',
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

  Widget _modernInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    String? errorText,
    bool isPassword = false,
    required bool obscure,
    required VoidCallback onToggle,
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
        obscureText: isPassword ? obscure : false,
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
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: iconColor,
                    size: 22.sp,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _req(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
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

  void _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _passError = null;
      _confirmError = null;
    });

    bool hasErr = false;
    if (password.isEmpty) {
      setState(() => _passError = 'Vui lòng nhập mật khẩu');
      hasErr = true;
    }
    if (confirm.isEmpty) {
      setState(() => _confirmError = 'Vui lòng xác nhận mật khẩu');
      hasErr = true;
    }
    if (hasErr) return;

    if (password.length < 6) {
      setState(() => _passError = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (password != confirm) {
      setState(() => _confirmError = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Thành công!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A2540),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Mật khẩu đã được đặt lại.\nHãy đăng nhập với mật khẩu mới!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Đăng nhập ngay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
