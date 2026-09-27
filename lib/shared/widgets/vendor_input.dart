import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VendorInput extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final Widget? prefixWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final TextAlign textAlign;

  const VendorInput({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.prefixWidget,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppColors.field : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.line : AppColors.borderLight;
    final labelColor = isDark ? AppColors.muted : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.text : AppColors.textPrimaryLight;
    final placeholderColor = isDark
        ? AppColors.mutedSoft
        : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: isDark
                ? AppTextStyles.fieldLabel
                : AppTextStyles.fieldLabelLight,
          ),
          const SizedBox(height: 7),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            color: containerColor,
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: IconTheme(
                    data: IconThemeData(color: labelColor, size: 18),
                    child: prefixIcon!,
                  ),
                ),
              ],
              if (prefixWidget != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: prefixWidget,
                ),
              ],
              if (prefixText != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Text(
                    prefixText!,
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  validator: validator,
                  onChanged: onChanged,
                  maxLength: maxLength,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  textCapitalization: textCapitalization,
                  readOnly: readOnly,
                  textAlign: textAlign,
                  style: AppTextStyles.inputText.copyWith(color: textColor),
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTextStyles.inputPlaceholder.copyWith(
                      color: placeholderColor,
                    ),
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(
                      right: 14,
                      top: 12,
                      bottom: 12,
                    ),
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconTheme(
                    data: IconThemeData(color: labelColor),
                    child: suffixIcon!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
