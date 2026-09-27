import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'bottom_nav_bar.dart';

class LightPageScaffold extends StatelessWidget {
  final Widget body;
  final int navIndex;
  final void Function(int)? onNavTap;
  final bool showBottomNav;
  final bool showTopNav;
  final String? topNavTitle;
  final Widget? leading;
  final Color? backgroundColor;

  const LightPageScaffold({
    super.key,
    required this.body,
    this.navIndex = 0,
    this.onNavTap,
    this.showBottomNav = true,
    this.showTopNav = false,
    this.topNavTitle,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.bg,
      body: Column(
        children: [
          if (showTopNav)
            Container(
              height: 50,
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Text(topNavTitle ?? '', style: AppTextStyles.topnavTitle),
                ],
              ),
            ),
          Expanded(child: body),
          if (showBottomNav)
            BottomNavBar(currentIndex: navIndex, onTap: onNavTap ?? (index) {}),
        ],
      ),
    );
  }
}
