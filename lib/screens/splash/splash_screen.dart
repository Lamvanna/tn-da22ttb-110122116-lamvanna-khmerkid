import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../auth/login_screen.dart';

/// Màn hình khởi động - Background image + animated overlays
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _shimmerCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();

    // Fade in
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    // Shimmer sweep
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    // Bounce for loading dots
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _bounceAnim = Tween<double>(begin: 0, end: 1).animate(_bounceCtrl);

    // Sparkle twinkle
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeCtrl.forward();
    });

    // Navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _navigateToLogin();
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, animation, __) => const LoginScreen(),
      transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 600)));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shimmerCtrl.dispose();
    _bounceCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(children: [
          // ── Background image ──
          SizedBox.expand(
            child: Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover)),

          // ── Shimmer sweep overlay ──
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) {
              final dx = _shimmerCtrl.value * size.width * 2 - size.width * 0.5;
              return Positioned(
                left: dx, top: 0,
                child: Container(
                  width: size.width * 0.4,
                  height: size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                      ]),
                  ),
                ),
              );
            },
          ),

          // ── Floating sparkles ──
          ..._buildSparkles(size),

          // ── Bottom loading area ──
          Positioned(
            bottom: size.height * 0.06,
            left: 0, right: 0,
            child: Column(children: [
              // Loading dots
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = ((_bounceAnim.value - delay) % 1.0).clamp(0.0, 1.0);
                    final y = -8 * math.sin(t * math.pi);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.translate(
                        offset: Offset(0, y),
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(
                              color: Colors.white.withValues(alpha: 0.6),
                              blurRadius: 6)])),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Text('Đang tải...', style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)])),
            ]),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildSparkles(Size size) {
    final sparkles = [
      [0.1, 0.15], [0.85, 0.12], [0.15, 0.4], [0.9, 0.35],
      [0.05, 0.6], [0.92, 0.55], [0.2, 0.75], [0.8, 0.7],
    ];
    return sparkles.map((pos) {
      return AnimatedBuilder(
        animation: _sparkleCtrl,
        builder: (_, __) {
          final phase = (pos[0] * 3 + pos[1] * 2) % 1.0;
          final t = ((_sparkleCtrl.value + phase) % 1.0);
          final opacity = (math.sin(t * math.pi) * 0.8).clamp(0.0, 0.8);
          final scale = 0.5 + math.sin(t * math.pi) * 0.5;
          return Positioned(
            left: size.width * pos[0],
            top: size.height * pos[1],
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: const Text('✨', style: TextStyle(fontSize: 20)))),
          );
        },
      );
    }).toList();
  }
}
