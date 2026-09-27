import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HintBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isLight;

  const HintBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIsLight = isLight || !isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: effectiveIsLight
            ? AppColors.orangeLight
            : AppColors.accent.withValues(alpha: 0.10),
        border: Border.all(
          color: effectiveIsLight
              ? AppColors.accent.withValues(alpha: 0.28)
              : AppColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: effectiveIsLight
                  ? AppTextStyles.hintBoxLight
                  : AppTextStyles.hintText,
            ),
          ),
        ],
      ),
    );
  }
}
