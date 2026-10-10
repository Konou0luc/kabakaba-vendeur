import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.textPrimaryLight,
                  ),
                )
              else
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.topnavTitle.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
