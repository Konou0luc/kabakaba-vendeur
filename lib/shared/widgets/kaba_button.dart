import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';

enum KabaButtonVariant { fill, outline, ghost }

class KabaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final KabaButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const KabaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = KabaButtonVariant.fill,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveHeight =
        height ?? (variant == KabaButtonVariant.fill ? 56.0 : 50.0);

    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(text)),
              ),
            ],
          );

    return SizedBox(
      width: width ?? (fullWidth ? double.infinity : null),
      height: effectiveHeight,
      child: _buildButton(context, child, isDark, effectiveHeight),
    );
  }

  Widget _buildButton(
    BuildContext context,
    Widget child,
    bool isDark,
    double height,
  ) {
    switch (variant) {
      case KabaButtonVariant.fill:
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.accent,
            borderRadius: BorderRadius.circular(height * 0.28),
            boxShadow: backgroundColor == null ? AppShadows.accentGlow : null,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.accent,
              foregroundColor: foregroundColor ?? AppColors.white,
              textStyle: AppTextStyles.buttonPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(height * 0.28),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: height * 0.16,
              ),
            ),
            child: child,
          ),
        );
      case KabaButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.textPrimaryLight,
            side: BorderSide(
              color: isDark ? AppColors.line : AppColors.borderLight,
              width: 1.5,
            ),
            backgroundColor: backgroundColor ?? AppColors.surfaceLight,
            textStyle: Theme.of(context).textTheme.bodyMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height * 0.28),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: height * 0.14,
            ),
          ),
          child: child,
        );
      case KabaButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.textPrimaryLight,
            textStyle: Theme.of(context).textTheme.bodyMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height * 0.28),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: height * 0.14,
            ),
          ),
          child: child,
        );
    }
  }
}
