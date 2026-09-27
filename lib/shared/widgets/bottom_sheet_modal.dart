import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/kaba_button.dart';

class BottomSheetModal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> chips;
  final String? selectedChip;
  final ValueChanged<String?> onChipSelected;
  final String? textAreaHint;
  final TextEditingController? textController;
  final String confirmText;
  final String cancelText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isConfirmEnabled;
  final bool showWarn;
  final String? warnText;
  final bool isConfirmDanger;
  final bool isConfirmOrange;

  const BottomSheetModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.chips,
    this.selectedChip,
    required this.onChipSelected,
    this.textAreaHint,
    this.textController,
    required this.confirmText,
    required this.cancelText,
    required this.onCancel,
    required this.onConfirm,
    this.isConfirmEnabled = true,
    this.showWarn = false,
    this.warnText,
    this.isConfirmDanger = true,
    this.isConfirmOrange = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = textAreaHint != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTextStyles.sheetTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTextStyles.sheetSub),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) {
                final selected = selectedChip == chip;
                return GestureDetector(
                  onTap: () => onChipSelected(chip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderLight,
                        width: 1.5,
                      ),
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                    ),
                    child: Text(
                      chip,
                      style: AppTextStyles.motifChip.copyWith(
                        color: selected
                            ? AppColors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (hasText && textController != null) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surfaceLight,
                ),
                child: TextFormField(
                  controller: textController,
                  maxLines: 3,
                  maxLength: 200,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: textAreaHint,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                ),
              ),
            ],
            if (showWarn) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        warnText ?? '',
                        style: AppTextStyles.sheetWarn,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: KabaButton(
                    text: cancelText,
                    variant: KabaButtonVariant.outline,
                    onPressed: onCancel,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KabaButton(
                    text: confirmText,
                    onPressed: isConfirmEnabled ? onConfirm : null,
                    backgroundColor: isConfirmOrange
                        ? AppColors.accent
                        : (isConfirmDanger ? AppColors.red : AppColors.accent),
                    foregroundColor: AppColors.white,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showKabaBottomSheet<T>(
  BuildContext context, {
  required Widget sheet,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: sheet,
      ),
    ),
  );
}
