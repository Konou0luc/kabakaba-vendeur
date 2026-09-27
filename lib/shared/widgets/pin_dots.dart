import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Indicateur de progression de la saisie du code PIN.
///
/// La position en cours est mise en avant (halo + contour épaissi) pour que le
/// vendeur suive sa frappe sans voir les chiffres.
class PinDots extends StatelessWidget {
  final String pin;
  final int length;

  /// Contour des positions non encore saisies. Le fond sombre de l'écran
  /// d'activation et le fond clair du reste de l'app n'ont pas le même.
  final Color emptyBorderColor;

  const PinDots({
    super.key,
    required this.pin,
    this.length = 4,
    this.emptyBorderColor = AppColors.borderLight,
  });

  static const _idleSize = 15.0;
  static const _focusedSize = 17.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final filled = index < pin.length;
        final isNext = index == pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: filled || isNext ? _focusedSize : _idleSize,
          height: filled || isNext ? _focusedSize : _idleSize,
          margin: EdgeInsets.only(right: index < length - 1 ? 18 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: filled || isNext ? AppColors.accent : emptyBorderColor,
              width: isNext ? 2 : 1.5,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
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
