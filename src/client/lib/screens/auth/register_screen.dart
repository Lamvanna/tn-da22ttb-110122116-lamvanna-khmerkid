import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

/// Màn hình Đăng ký - Đồng bộ phong cách Premium Polish UI/UX với LoginScreen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obPass = true;
  bool _obConfirm = true;
  bool _isLoading = false;

  String? _nameError, _emailError, _passError, _confirmError;

  // Quản lý Focus để tạo hiệu ứng viền động cho các ô nhập liệu
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmFocused = false;

  // Quản lý trạng thái micro-interaction của các nút bấm
  bool _isRegisterPressed = false;
  bool _isGooglePressed = false;
  bool _isFacebookPressed = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      setState(() => _nameFocused = _nameFocusNode.hasFocus);
    });
    _emailFocusNode.addListener(() {
      setState(() => _emailFocused = _emailFocusNode.hasFocus);
    });
    _passFocusNode.addListener(() {
      setState(() => _passFocused = _passFocusNode.hasFocus);
    });
    _confirmFocusNode.addListener(() {
      setState(() => _confirmFocused = _confirmFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _confirmFocusNode.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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



          // 4. Biểu mẫu đăng ký cuộn mượt mà
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 35.h),

                        // Logo ứng dụng khớp nền 173F9B
                        _buildBrandLogo(),
                        SizedBox(height: 12.h),

                        // Tiêu đề & Phụ đề chào mừng
                        Text(
                          'Tạo tài khoản',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A2540),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Bắt đầu hành trình học tiếng Khmer vui nhộn 🎉',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 28.h),

                        // Ô Họ và tên
                        _modernInputField(
                          controller: _nameCtrl,
                          hint: 'Họ và tên',
                          icon: Icons.person_outline_rounded,
                          focusNode: _nameFocusNode,
                          isFocused: _nameFocused,
                          errorText: _nameError,
                          textCapitalization: TextCapitalization.words,
                        ),
                        if (_nameError != null) _buildErrorMessage(_nameError!),
                        SizedBox(height: 12.h),

                        // Ô Địa chỉ Email
                        _modernInputField(
                          controller: _emailCtrl,
                          hint: 'Địa chỉ Email',
                          icon: Icons.email_outlined,
                          focusNode: _emailFocusNode,
                          isFocused: _emailFocused,
                          errorText: _emailError,
                          keyboard: TextInputType.emailAddress,
                        ),
                        if (_emailError != null) _buildErrorMessage(_emailError!),
                        SizedBox(height: 12.h),

                        // Ô Mật khẩu
                        _modernInputField(
                          controller: _passCtrl,
                          hint: 'Mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          focusNode: _passFocusNode,
                          isFocused: _passFocused,
                          errorText: _passError,
                          isPassword: true,
                          obscure: _obPass,
                          onToggle: () => setState(() => _obPass = !_obPass),
                        ),
                        if (_passError != null) _buildErrorMessage(_passError!),
                        SizedBox(height: 12.h),

                        // Ô Xác nhận Mật khẩu
                        _modernInputField(
                          controller: _confirmCtrl,
                          hint: 'Xác nhận mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          focusNode: _confirmFocusNode,
                          isFocused: _confirmFocused,
                          errorText: _confirmError,
                          isPassword: true,
                          obscure: _obConfirm,
                          onToggle: () => setState(() => _obConfirm = !_obConfirm),
                        ),
                        if (_confirmError != null) _buildErrorMessage(_confirmError!),
                        SizedBox(height: 26.h),

                        // Nút Đăng ký với hiệu ứng nhấn nén
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isRegisterPressed = true),
                          onTapUp: (_) {
                            setState(() => _isRegisterPressed = false);
                            if (!_isLoading) _handleRegister();
                          },
                          onTapCancel: () => setState(() => _isRegisterPressed = false),
                          child: AnimatedScale(
                            scale: _isRegisterPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              height: 54.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryLight,
                                    AppColors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.24),
                                    blurRadius: 12.r,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24.w,
                                        height: 24.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Đăng ký',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 26.h),

                        // Đường phân cách "HOẶC"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: const Color(0xFFE5E7EB),
                                thickness: 1.2.h,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'HOẶC',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9CA3AF),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: const Color(0xFFE5E7EB),
                                thickness: 1.2.h,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 22.h),

                        // Google Register Button
                        _socialButton(
                          onTap: () {}, // Google registration hook if any
                          logoWidget: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFEA4335),
                                Color(0xFFFBBC05),
                                Color(0xFF34A853),
                                Color(0xFF4285F4),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'G',
                              style: GoogleFonts.roboto(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          label: 'Đăng ký với Google',
                          isPressed: _isGooglePressed,
                          onPressedChange: (val) => setState(() => _isGooglePressed = val),
                        ),
                        SizedBox(height: 14.h),

                        // Facebook Register Button
                        _socialButton(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đăng ký bằng Facebook hiện tại chưa khả dụng.'),
                              ),
                            );
                          },
                          logoWidget: Icon(
                            Icons.facebook,
                            color: const Color(0xFF1877F2),
                            size: 24.sp,
                          ),
                          label: 'Đăng ký với Facebook',
                          isPressed: _isFacebookPressed,
                          onPressedChange: (val) => setState(() => _isFacebookPressed = val),
                        ),
                        SizedBox(height: 32.h),

                        // Quay lại Đăng nhập
                        _signInLink(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Tiện ích Logo squircle 173F9B đồng bộ với Login
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

  // Tiện ích vẽ các Ô nhập liệu tương tác cao cấp
  Widget _modernInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    String? errorText,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        keyboardType: keyboard,
        textCapitalization: textCapitalization,
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

  // Thông báo lỗi nhỏ dưới ô nhập liệu
  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, top: 6.h),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14.sp, color: const Color(0xFFEF5350)),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget dựng nút Đăng nhập Mạng xã hội phẳng có hiệu ứng nhấn nén
  Widget _socialButton({
    required VoidCallback onTap,
    required Widget logoWidget,
    required String label,
    required bool isPressed,
    required Function(bool) onPressedChange,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressedChange(true),
      onTapUp: (_) {
        onPressedChange(false);
        onTap();
      },
      onTapCancel: () => onPressedChange(false),
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8.r,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logoWidget,
              SizedBox(width: 12.w),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
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
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Đăng nhập',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // LOGIC ĐĂNG KÝ
  // ═════════════════════════════════════════════════════════════════
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
      _nameError = nameErr;
      _emailError = emailErr;
      _passError = passErr;
      _confirmError = confirmErr;
    });

    if (nameErr != null || emailErr != null || passErr != null || confirmErr != null) {
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
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.12),
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
                    backgroundColor: AppColors.primary,
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

/// Clipper vẽ dải sóng xanh trang nhã phía đầu trang
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

/// Clipper vẽ dải sóng nền phụ tạo chiều sâu
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
