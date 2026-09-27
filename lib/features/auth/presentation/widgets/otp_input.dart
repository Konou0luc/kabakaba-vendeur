import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Six cases de saisie du code SMS.
///
/// Un champ par chiffre, mais un seul état : le code complet remonte par
/// [onChanged], et [onCompleted] déclenche la vérification dès la sixième
/// touche pour éviter un appui supplémentaire.
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final bool enabled;

  /// Incrémenté par le parent pour vider les cases après un code refusé ou un
  /// renvoi de SMS.
  final int resetToken;

  const OtpInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.enabled = true,
    this.resetToken = 0,
  });

  static const digitCount = 6;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      OtpInput.digitCount,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(OtpInput.digitCount, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _clear();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {});
    widget.onChanged('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _handleInput(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Saisie automatique du SMS ou collage : le code arrive d'un coup dans la
    // case qui a le focus, il faut l'étaler sur les suivantes.
    if (digits.length > 1) {
      for (var i = index; i < OtpInput.digitCount; i++) {
        final offset = i - index;
        _controllers[i].text = offset < digits.length ? digits[offset] : '';
      }
      final filled = (index + digits.length).clamp(0, OtpInput.digitCount);
      if (filled >= OtpInput.digitCount) {
        _focusNodes.last.unfocus();
      } else {
        _focusNodes[filled].requestFocus();
      }
    } else {
      _controllers[index].value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      if (digits.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      } else if (digits.isNotEmpty && index < OtpInput.digitCount - 1) {
        _focusNodes[index + 1].requestFocus();
      } else if (digits.isNotEmpty) {
        _focusNodes[index].unfocus();
      }
    }

    setState(() {});
    final code = _code;
    widget.onChanged(code);
    if (code.length == OtpInput.digitCount) widget.onCompleted(code);
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < OtpInput.digitCount; i++)
            Padding(
              padding: EdgeInsets.only(right: i < OtpInput.digitCount - 1 ? 5 : 0),
              child: SizedBox(
                width: 36,
                height: 48,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.otpDigit,
                  keyboardType: TextInputType.number,
                  textInputAction: i < OtpInput.digitCount - 1
                      ? TextInputAction.next
                      : TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: i == 0
                      ? const [AutofillHints.oneTimeCode]
                      : null,
                  enableSuggestions: false,
                  enabled: widget.enabled,
                  autofocus: i == 0,
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _controllers[i].text.isEmpty
                        ? AppColors.field
                        : AppColors.accent.withValues(alpha: 0.12),
                    border: _border(AppColors.line),
                    enabledBorder: _border(AppColors.line),
                    focusedBorder: _border(AppColors.accent, width: 2),
                    disabledBorder: _border(AppColors.line),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => _handleInput(i, value),
                ),
              ),
            ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
