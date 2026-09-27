import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LightStatusBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;

  const LightStatusBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final time = ValueNotifier<DateTime>(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (_) {
      time.value = DateTime.now();
    });

    return ValueListenableBuilder<DateTime>(
      valueListenable: time,
      builder: (context, now, _) {
        final hour = now.hour.toString().padLeft(2, '0');
        final minute = now.minute.toString().padLeft(2, '0');
        return Container(
          color: AppColors.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$hour:$minute', style: AppTextStyles.statusbarLight),
              Row(
                children: [
                  Text('📶', style: AppTextStyles.statusbarLight),
                  const SizedBox(width: 5),
                  Text('📡', style: AppTextStyles.statusbarLight),
                  const SizedBox(width: 5),
                  Text('🔋', style: AppTextStyles.statusbarLight),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class LightTopNav extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget>? actions;

  const LightTopNav({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          if (showBack) const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.topnavTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showBack) const SizedBox(width: 44),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
