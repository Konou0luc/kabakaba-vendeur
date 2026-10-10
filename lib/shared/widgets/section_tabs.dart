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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.indigoLight,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(4),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final tab = tabs[index];
            final selected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onTabSelected?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Text(
                      tab.label,
                      style: (selected
                              ? AppTextStyles.tabActive
                              : AppTextStyles.tabLabel)
                          .copyWith(
                            color: selected
                                ? AppColors.white
                                : AppColors.textSecondaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tab.badgeCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? AppColors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
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
