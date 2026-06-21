import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import '../admin/admin_main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập - Phiên bản Premium Polish UI/UX
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _mockEmailCtrl = TextEditingController();
  bool _remember = false;
  bool _obscure = true;
  bool _isLoading = false;
  String? _userError;
  String? _passError;

  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  bool _userFocused = false;
  bool _passFocused = false;

  // Trạng thái tương tác vật lý của các nút nhấn (Micro-interactions)
  bool _isLoginPressed = false;
  bool _isGooglePressed = false;
  bool _isFacebookPressed = false;

  @override
  void initState() {
    super.initState();
    _userFocusNode.addListener(() {
      setState(() {
        _userFocused = _userFocusNode.hasFocus;
      });
    });
    _passFocusNode.addListener(() {
      setState(() {
        _passFocused = _passFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _mockEmailCtrl.dispose();
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



          // 4. Biểu mẫu đăng nhập chính cuộn mượt mà
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 35.h),

                      // Biểu tượng Logo thương hiệu có viền nổi bật màu xanh đậm 173F9B
                      _buildBrandLogo(),
                      SizedBox(height: 12.h),

                      // Tiêu đề & Phụ đề chào mừng
                      Text(
                        'Khmer Kid',
                        style: GoogleFonts.plusJakartaSans(

                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A2540),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Đăng nhập để tiếp tục sử dụng ứng dụng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),

                      // Ô nhập tài khoản/email
                      _modernInputField(
                        controller: _userCtrl,
                        hint: 'Tên đăng nhập hoặc email',
                        icon: Icons.person_outline_rounded,
                        focusNode: _userFocusNode,
                        isFocused: _userFocused,
                        errorText: _userError,
                      ),
                      if (_userError != null) _buildErrorMessage(_userError!),
                      SizedBox(height: 16.h),

                      // Ô nhập mật khẩu
                      _modernInputField(
                        controller: _passCtrl,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        focusNode: _passFocusNode,
                        isFocused: _passFocused,
                        errorText: _passError,
                        isPassword: true,
                      ),
                      if (_passError != null) _buildErrorMessage(_passError!),
                      SizedBox(height: 14.h),

                      // Hàng Ghi nhớ đăng nhập & Quên mật khẩu
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _remember = !_remember),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: Checkbox(
                                      value: _remember,
                                      onChanged: (v) => setState(() => _remember = v ?? false),
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.r),
                                      ),
                                      side: BorderSide(
                                        color: const Color(0xFFD1D5DB),
                                        width: 1.5.w,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Ghi nhớ đăng nhập',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: Text(
                                'Quên mật khẩu?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26.h),

                      // Nút Đăng nhập chính với hiệu ứng chạm nén nhẹ (micro-interaction)
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isLoginPressed = true),
                        onTapUp: (_) {
                          setState(() => _isLoginPressed = false);
                          if (!_isLoading) _handleLogin();
                        },
                        onTapCancel: () => setState(() => _isLoginPressed = false),
                        child: AnimatedScale(
                          scale: _isLoginPressed ? 0.97 : 1.0,
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
                                      'Đăng nhập',
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

                      // Đăng nhập bằng Google
                      _socialButton(
                        onTap: _handleGoogleLogin,
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
                        label: 'Đăng nhập với Google',
                        isPressed: _isGooglePressed,
                        onPressedChange: (val) => setState(() => _isGooglePressed = val),
                      ),
                      SizedBox(height: 14.h),

                      // Đăng nhập bằng Facebook
                      _socialButton(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đăng nhập bằng Facebook hiện tại chưa khả dụng.'),
                            ),
                          );
                        },
                        logoWidget: Icon(
                          Icons.facebook,
                          color: const Color(0xFF1877F2),
                          size: 24.sp,
                        ),
                        label: 'Đăng nhập với Facebook',
                        isPressed: _isFacebookPressed,
                        onPressedChange: (val) => setState(() => _isFacebookPressed = val),
                      ),
                      SizedBox(height: 32.h),

                      // Gợi ý đăng ký tài khoản
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: Text(
                              'Đăng ký ngay',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tiện ích hiển thị Logo ứng dụng chính thức với khung xanh 173F9B cao cấp
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

  // Tiện ích vẽ các Ô nhập liệu tương tác cao cấp (Tactile/Interactive Input)
  Widget _modernInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    String? errorText,
    bool isPassword = false,
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
        obscureText: isPassword ? _obscure : false,
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
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

  // Widget dựng nút đăng nhập Mạng xã hội phẳng có hiệu ứng nhấn nén
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

  // ═══════════════════════════════════════════════════════════════════
  // LOGIC XỬ LÝ (Giữ nguyên 100% logic kết nối & bypass ban đầu)
  // ═══════════════════════════════════════════════════════════════════
  void _handleLogin() async {
    String? userErr;
    String? passErr;
    final emailInput = _userCtrl.text.trim();
    final passwordInput = _passCtrl.text;
    if (emailInput.isEmpty) {
      userErr = 'Vui lòng nhập email đăng nhập';
    } else if (!emailInput.contains('@')) {
      userErr = 'Địa chỉ email không hợp lệ (cần ký tự @)';
    }
    if (passwordInput.isEmpty) {
      passErr = 'Vui lòng nhập mật khẩu';
    } else if (passwordInput.length < 6) {
      passErr = 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    setState(() {
      _userError = userErr;
      _passError = passErr;
    });
    if (userErr != null || passErr != null) return;
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().login(email: emailInput, password: passwordInput);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        final profile = AuthService().userProfile;
        final isAdmin = profile?['role'] == 'admin';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => isAdmin ? const AdminMainScreen() : const MainScreen()),
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Đăng nhập thất bại.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi kết nối mạng: $e');
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().googleLogin();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        final profile = AuthService().userProfile;
        final isAdmin = profile?['role'] == 'admin';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => isAdmin ? const AdminMainScreen() : const MainScreen()),
        );
      } else if (result['isDeveloperError'] == true) {
        _showMockBypassDialog();
      } else {
        _showErrorDialog(result['message'] ?? 'Đăng nhập bằng Google thất bại.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi kết nối tới hệ thống Google: $e');
    }
  }

  void _showMockBypassDialog() {
    _mockEmailCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(children: [
          Icon(Icons.g_mobiledata_rounded, color: Colors.blueAccent, size: 36.sp),
          SizedBox(width: 4.w),
          const Text('Bypass Google Auth'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thiết bị gặp lỗi cấu hình hoặc lỗi kết nối mạng với hệ thống Google.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              const Text('Bạn có muốn sử dụng Đăng nhập giả lập (Mock Login) để truy cập ứng dụng không?'),
              SizedBox(height: 16.h),
              TextField(
                controller: _mockEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Email kiểm thử (Không bắt buộc)',
                  hintText: 'Nhập email (ví dụ: hero@gmail.com)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final emailVal = _mockEmailCtrl.text.trim();
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final nameVal = emailVal.isNotEmpty ? emailVal.split('@')[0] : null;
              final result = await AuthService().googleMockLogin(
                email: emailVal.isNotEmpty ? emailVal : null,
                name: nameVal,
              );
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (result['success'] == true) {
                final profile = AuthService().userProfile;
                final isAdmin = profile?['role'] == 'admin';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => isAdmin ? const AdminMainScreen() : const MainScreen()),
                );
              } else {
                _showErrorDialog(result['message']);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerMid,
              shape: const StadiumBorder(),
            ),
            child: const Text('Đồng ý (Test nhanh)', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
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
          ),
        ],
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
