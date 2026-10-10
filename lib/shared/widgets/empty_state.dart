import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isGray;
  final Widget? action;
  final bool framed;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.isGray = false,
    this.action,
    this.framed = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isGray ? AppColors.textSecondaryLight : AppColors.primary;
    final iconBg = isGray ? AppColors.grayLight : AppColors.indigoLight;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: icon != null
                      ? Icon(icon, size: 26, color: iconColor)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.emptyTitle.copyWith(
                fontSize: 16,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                style: AppTextStyles.emptySub,
                textAlign: TextAlign.center,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );

    if (!framed) return content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1B2A6B),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}
