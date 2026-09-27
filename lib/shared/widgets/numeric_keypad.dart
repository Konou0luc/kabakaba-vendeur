import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Palette du pavé, selon le fond de l'écran qui l'accueille.
enum NumericKeypadTone {
  /// Écrans d'activation, sur le fond sombre.
  dark(
    keyBackground: Color(0x0DFFFFFF),
    keyBorder: Color(0x1FFFFFFF),
    digit: Colors.white,
    action: Color(0xFF94A3B8),
  ),

  /// Reste de l'application, sur fond clair.
  light(
    keyBackground: Color(0xFFF1F3F8),
    keyBorder: AppColors.borderLight,
    digit: Color(0xFF0D1438),
    action: Color(0xFF96A0BC),
  );

  final Color keyBackground;
  final Color keyBorder;
  final Color digit;
  final Color action;

  const NumericKeypadTone({
    required this.keyBackground,
    required this.keyBorder,
    required this.digit,
    required this.action,
  });
}

/// Pavé numérique de saisie du code PIN.
///
/// Un pavé dédié plutôt qu'un clavier système : la saisie reste possible sans
/// masquer la moitié de l'écran, et les touches sont assez grandes pour être
/// utilisées d'une main pendant le service.
class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final NumericKeypadTone tone;

  /// Désactivé pendant un appel réseau, pour éviter une double validation.
  final bool enabled;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.tone = NumericKeypadTone.light,
    this.enabled = true,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Expanded(
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: key.isEmpty
                          ? const SizedBox.shrink()
                          : AspectRatio(
                              aspectRatio: 1,
                              child: _Key(
                                label: key,
                                tone: tone,
                                enabled: enabled,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  key == 'del' ? onDelete() : onDigit(key);
                                },
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final NumericKeypadTone tone;
  final bool enabled;
  final VoidCallback onTap;

  const _Key({
    required this.label,
    required this.tone,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDelete = label == 'del';

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: tone.keyBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.keyBorder),
            ),
            alignment: Alignment.center,
            child: isDelete
                ? Icon(Icons.backspace_rounded, size: 20, color: tone.action)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: tone.digit,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
