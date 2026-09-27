import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SectionTabs extends StatelessWidget {
  final List<TabItem> tabs;
  final int selectedIndex;
  final void Function(int)? onTabSelected;
  final bool isLight;

  const SectionTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabSelected,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected?.call(index),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: selected
                                  ? AppTextStyles.tabActive
                                  : AppTextStyles.tabLabel,
                            ),
                          ),
                          if (tab.badgeCount != null)
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.grayLight,
                              ),
                              child: Text(
                                tab.badgeCount.toString(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (selected)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TabItem {
  final String label;
  final int? badgeCount;
  const TabItem({required this.label, this.badgeCount});
}

class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTextStyles.sectionLabel),
    );
  }
}
