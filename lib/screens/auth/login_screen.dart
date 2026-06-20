import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import '../admin/admin_main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập - Game UI & Magic Glassmorphism style - RESPONSIVE
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _mockEmailCtrl = TextEditingController();
  bool _remember = false;
  bool _obscure = true;
  bool _isLoading = false;
  String? _userError;
  String? _passError;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  bool _userFocused = false;
  bool _passFocused = false;

  // Star points for background decoration
  final List<Offset> _starPositions = [
    const Offset(0.15, 0.12),
    const Offset(0.85, 0.08),
    const Offset(0.08, 0.45),
    const Offset(0.90, 0.60),
    const Offset(0.20, 0.85),
    const Offset(0.80, 0.90),
  ];

  @override
  void initState() {
    super.initState();
    // Chuyển động trôi nổi của mascot con voi
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Chuyển động mạch đập nhẹ của vòng hào quang sáng phía sau mascot
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

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
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
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
      body: Stack(
        children: [
          // 1. Magical Background Gradient
          Container(
            width: 1.sw,
            height: 1.sh,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E5BB5),
                  Color(0xFF143D8A),
                  Color(0xFF091A40),
                ],
              ),
            ),
          ),

          // 2. Animated Glowing Orbs & Ambient Glow
          Positioned(
            top: -100.h,
            left: -50.w,
            child: _buildGlowingOrb(250.w, const Color(0xFF42A5F5).withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: -50.h,
            right: -100.w,
            child: _buildGlowingOrb(300.w, const Color(0xFF29B6F6).withValues(alpha: 0.25)),
          ),
          Positioned(
            top: 0.35.sh,
            right: -80.w,
            child: _buildGlowingOrb(200.w, const Color(0xFF9089E0).withValues(alpha: 0.2)),
          ),

          // 3. Twinkling Magic Stars Background
          ..._starPositions.map((pos) => Positioned(
                left: pos.dx * 1.sw,
                top: pos.dy * 1.sh,
                child: _buildTwinklingStar(),
              )),

          // 4. Main Login Card & Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  child: Column(
                    children: [
                      SizedBox(height: 28.h),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Frosted Glassmorphism Card
                          Container(
                            margin: EdgeInsets.only(top: 80.h),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(42.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF02091D).withValues(alpha: 0.5),
                                  blurRadius: 40.r,
                                  offset: Offset(0, 20.h),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(42.r),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(22.w, 100.h, 22.w, 40.h),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.16),
                                        Colors.white.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(42.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Brand Title
                                      Text(
                                        'Khmer Kids',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 36.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: const Color(0xFF0A2B70).withValues(alpha: 0.8),
                                              offset: const Offset(0, 4),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Học chữ Khmer vui nhộn ☀️',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFE0EAFC),
                                        ),
                                      ),

                                      SizedBox(height: 32.h),

                                      // Input Fields
                                      _glassInput(
                                        controller: _userCtrl,
                                        hint: 'Tên đăng nhập hoặc SĐT',
                                        icon: Icons.person_outline_rounded,
                                        focusNode: _userFocusNode,
                                        isFocused: _userFocused,
                                        errorText: _userError,
                                      ),
                                      if (_userError != null)
                                        _buildErrorMessage(_userError!),
                                      SizedBox(height: 16.h),

                                      _glassInput(
                                        controller: _passCtrl,
                                        hint: 'Mật khẩu',
                                        icon: Icons.lock_outline_rounded,
                                        focusNode: _passFocusNode,
                                        isFocused: _passFocused,
                                        errorText: _passError,
                                        isPassword: true,
                                      ),
                                      if (_passError != null)
                                        _buildErrorMessage(_passError!),
                                      SizedBox(height: 12.h),

                                      // Remember & Forgot Password row
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: GestureDetector(
                                                onTap: () => setState(() => _remember = !_remember),
                                                behavior: HitTestBehavior.opaque,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 6.h),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 22.w,
                                                        height: 22.w,
                                                        child: Checkbox(
                                                          value: _remember,
                                                          onChanged: (v) => setState(() => _remember = v ?? false),
                                                          activeColor: const Color(0xFFFFA000),
                                                          checkColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.8.w),
                                                          materialTapTargetSize: MaterialTapTargetSize.padded,
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      Flexible(
                                                        child: Text(
                                                          'Ghi nhớ',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 14.sp,
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.white.withValues(alpha: 0.95),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.push(context,
                                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                                                child: Text(
                                                  'Quên mật khẩu?',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFFFFD54F),
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: 20.h),

                                      // Satisfying 3D Game-Style Action Button
                                      _GameUI3DButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 24.w,
                                                height: 24.w,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  color: Color(0xFF5D4037),
                                                ),
                                              )
                                            : Text(
                                                'ĐĂNG NHẬP',
                                                style: GoogleFonts.fredoka(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(0xFF5D4037),
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                      ),

                                      SizedBox(height: 28.h),

                                      // Divider Line
                                      Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1.5.h)),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                                            child: Text(
                                              'hoặc đăng nhập bằng',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1.5.h)),
                                        ],
                                      ),

                                      SizedBox(height: 20.h),

                                      // Social Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _socialGlassBtn(
                                              'Google',
                                              isGoogle: true,
                                              onTap: _handleGoogleLogin,
                                            ),
                                          ),
                                          SizedBox(width: 14.w),
                                          Expanded(
                                            child: _socialGlassBtn(
                                              'Facebook',
                                              icon: Icons.facebook,
                                              color: const Color(0xFF1877F2),
                                              onTap: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đăng nhập bằng Facebook hiện tại chưa khả dụng.')),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 32.h),

                                      // Register suggestion
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Chưa có tài khoản? ',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.push(context,
                                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4.h),
                                              child: Text(
                                                'Đăng ký ngay',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFFFFD54F),
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Mascot container (Con voi trôi nổi)
                          Positioned(
                            top: -12.h,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing Pulse Ring
                                ScaleTransition(
                                  scale: _pulseAnim,
                                  child: Container(
                                    width: 156.w,
                                    height: 156.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.35),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Mascot Avatar Wrapper
                                AnimatedBuilder(
                                  animation: _floatAnim,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatAnim.value.h),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 144.w,
                                    height: 144.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFE3F2FD),
                                      border: Border.all(color: Colors.white, width: 4.w),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF02091D).withValues(alpha: 0.4),
                                          blurRadius: 24.r,
                                          offset: Offset(0, 10.h),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/elephant_mascot.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 36.h),
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

  Widget _buildGlowingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildTwinklingStar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 1000 + math.Random().nextInt(1200)),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      onEnd: () {},
      child: Icon(
        Icons.star_rounded,
        color: const Color(0xFFFFF59D).withValues(alpha: 0.8),
        size: (12 + math.Random().nextInt(10)).sp,
      ),
    );
  }

  Widget _glassInput({
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
    if (hasError) {
      borderStrokeColor = const Color(0xFFFF5252);
    } else if (isFocused) {
      borderStrokeColor = const Color(0xFFFFC107);
    } else {
      borderStrokeColor = Colors.white.withValues(alpha: 0.16);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: borderStrokeColor,
          width: 2.w,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                  blurRadius: 12.r,
                  spreadRadius: 1.r,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword ? _obscure : false,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Icon(
              icon,
              color: isFocused ? const Color(0xFFFFC107) : Colors.white.withValues(alpha: 0.6),
              size: 22.sp,
            ),
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isFocused ? const Color(0xFFFFC107) : Colors.white.withValues(alpha: 0.5),
                      size: 22.sp,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, top: 6.h),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14.sp, color: const Color(0xFFFF8A80)),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialGlassBtn(String label, {bool isGoogle = false, IconData? icon, Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              Text(
                'G',
                style: GoogleFonts.roboto(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)],
                    ).createShader(const Rect.fromLTWH(0, 0, 20, 20)),
                ),
              )
            else
              Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final emailVal = _mockEmailCtrl.text.trim();
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final nameVal = emailVal.isNotEmpty ? emailVal.split('@')[0] : null;
              final result = await AuthService().googleMockLogin(email: emailVal.isNotEmpty ? emailVal : null, name: nameVal);
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (result['success'] == true) {
                final profile = AuthService().userProfile;
                final isAdmin = profile?['role'] == 'admin';
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isAdmin ? const AdminMainScreen() : const MainScreen()));
              } else {
                _showErrorDialog(result['message']);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerMid, shape: const StadiumBorder()),
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đồng ý'))],
      ),
    );
  }
}

/// A beautiful Game-UI styled 3D Golden button with solid physical depth feedback
class _GameUI3DButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _GameUI3DButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_GameUI3DButton> createState() => _GameUI3DButtonState();
}

class _GameUI3DButtonState extends State<_GameUI3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final double depth = 5.h;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: SizedBox(
        height: 60.h,
        width: double.infinity,
        child: Stack(
          children: [
            // Cạnh 3D phía dưới (Shadow depth)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                color: isEnabled
                    ? const Color(0xFFD84315) // Cam đỏ đậm
                    : Colors.grey.shade700,
              ),
            ),
            // Mặt nút nhấn di chuyển vật lý
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              top: _isPressed ? depth : 0,
              left: 0,
              right: 0,
              bottom: _isPressed ? 0 : depth,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.r),
                  gradient: isEnabled
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFFF176), // Vàng tươi ở đỉnh
                            Color(0xFFFFA000), // Vàng cam đậm ở đáy
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  border: Border.all(
                    color: isEnabled ? const Color(0xFFFFF59D) : Colors.grey.shade300,
                    width: 1.5.w,
                  ),
                ),
                child: Center(
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

