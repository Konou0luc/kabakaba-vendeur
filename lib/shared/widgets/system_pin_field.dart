import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'pin_dots.dart';

/// Saisie PIN via le clavier système (pavé numérique), pas un clavier dessiné.
class SystemPinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final Color emptyBorderColor;

  const SystemPinField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onChanged,
    this.enabled = true,
    this.emptyBorderColor = AppColors.line,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: PinDots(
              pin: controller.text,
              length: length,
              emptyBorderColor: emptyBorderColor,
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autofocus: true,
            obscureText: true,
            showCursor: false,
            enableInteractiveSelection: false,
            keyboardType: const TextInputType.numberWithOptions(),
            textInputAction: TextInputAction.done,
            maxLength: length,
            style: const TextStyle(color: Colors.transparent, fontSize: 16),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
