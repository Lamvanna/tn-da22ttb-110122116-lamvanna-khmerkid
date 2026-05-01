import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Widget hiển thị số thống kê (sử dụng trên Home screen)
/// Ví dụ: "45/61" - Chữ đã học, "78" - Sao tích lũy, "74%" - Hoàn thành
class StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const StatBadge({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = AppColors.primaryPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.statNumber.copyWith(
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.statLabel,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
