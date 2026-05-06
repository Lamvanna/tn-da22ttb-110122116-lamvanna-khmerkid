import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';

/// Greeting card — mascot + speech bubble Khmer (sáng, sang trọng)
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.ambientShadow,
        border: Border.all(color: const Color(0xFFEEF1F8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mascot icon
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      AppColors.tertiary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.08),
                    ]),
                  borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.pets_rounded, color: AppColors.tertiary, size: 34),
              ),
              const SizedBox(width: 14),
              // Speech bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(children: [
                  Text('សួស្តី!',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                  Text('(Xin chào!)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9))),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Hôm nay bé muốn học gì nhỉ? 🌟',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.onBackground)),
        ],
      ),
    );
  }
}
