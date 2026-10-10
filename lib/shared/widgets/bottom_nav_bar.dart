import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int)? onTap;

  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItemModel(icon: Icons.receipt_long_rounded, label: 'Commandes'),
      _NavItemModel(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portefeuille',
      ),
      _NavItemModel(icon: Icons.bar_chart_rounded, label: 'Stats'),
      _NavItemModel(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141B2A6B),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap?.call(index),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: selected
                              ? AppColors.white
                              : AppColors.textMutedLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: AppTextStyles.navItemLabel.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMutedLight,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemModel {
  final IconData icon;
  final String label;
  const _NavItemModel({required this.icon, required this.label});
}
