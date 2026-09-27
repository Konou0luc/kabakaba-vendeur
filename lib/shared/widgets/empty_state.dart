import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isGray;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.isGray = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isGray ? AppColors.textSecondaryLight : AppColors.primary;
    final iconBg = isGray ? AppColors.grayLight : AppColors.indigoLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: icon != null
                  ? Icon(icon!, size: 24, color: iconColor)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.emptyTitle,
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTextStyles.emptySub,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
