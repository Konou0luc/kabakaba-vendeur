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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.borderLight.withValues(alpha: 0.55),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0D1A6B),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap?.call(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.indigoLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: selected
                              ? AppColors.white
                              : AppColors.textSecondaryLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTextStyles.navItemLabel.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
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
