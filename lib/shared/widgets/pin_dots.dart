import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PinDots extends StatelessWidget {
  final String pin;
  final int length;
  final Color fillColor;
  final Color borderColor;
  final Color activeBorderColor;
  final double size;
  final double activeSize;

  const PinDots({
    super.key,
    required this.pin,
    this.length = 4,
    this.fillColor = AppColors.accent,
    this.borderColor = AppColors.line,
    this.activeBorderColor = AppColors.accent,
    this.size = 15,
    this.activeSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor = isDark ? borderColor : AppColors.borderLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final filled = index < pin.length;
        final isActive = index == pin.length;
        final dotSize = (filled || isActive) ? activeSize : size;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: dotSize,
          height: dotSize,
          margin: EdgeInsets.only(right: index < length - 1 ? 18.0 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? fillColor
                : (isActive ? Colors.transparent : Colors.transparent),
            border: Border.all(
              color: filled
                  ? fillColor
                  : (isActive ? activeBorderColor : effectiveBorderColor),
              width: isActive && !filled ? 2 : 1.5,
            ),
            boxShadow: isActive && !filled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class PinDotsLight extends StatelessWidget {
  final String pin;
  final int length;

  const PinDotsLight({super.key, required this.pin, this.length = 4});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final filled = index < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: filled ? 14 : 14,
          height: filled ? 14 : 14,
          margin: EdgeInsets.only(right: index < length - 1 ? 16.0 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.accent : AppColors.borderLight,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
