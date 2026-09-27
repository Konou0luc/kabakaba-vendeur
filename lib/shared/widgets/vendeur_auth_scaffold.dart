import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VendeurAuthScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final IconData heroIcon;
  final String heroTitle;
  final String heroSubtitle;
  final Widget body;
  final VoidCallback? onBack;
  final bool showBackButton;

  const VendeurAuthScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.heroIcon,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.body,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.indigoDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 46),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.indigoDark],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -60,
                    right: -50,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -70,
                    left: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (showBackButton)
                            GestureDetector(
                              onTap:
                                  onBack ?? () => Navigator.of(context).pop(),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.white.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.white,
                                  size: 14,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 32, height: 32),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: AppColors.white.withValues(alpha: 0.12),
                            ),
                            child: Text(
                              'Étape $currentStep/$totalSteps',
                              style: AppTextStyles.progressPill,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(
                          heroIcon,
                          color: AppColors.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(heroTitle, style: AppTextStyles.heroTitle),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 230,
                        child: Text(
                          heroSubtitle,
                          style: AppTextStyles.heroSubtitle,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppColors.white.withValues(alpha: 0.16),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * progressPercent,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: AppColors.accent,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
