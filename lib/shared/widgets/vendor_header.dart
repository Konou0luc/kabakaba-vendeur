import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/vendor_model.dart';

class VendorHeader extends StatelessWidget {
  final VendorModel? vendor;
  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final bool showAvailabilityBadge;
  final VoidCallback? onAvailabilityTap;
  final bool isLight;

  const VendorHeader({
    super.key,
    this.vendor,
    this.showNotification = false,
    this.onNotificationTap,
    this.showAvailabilityBadge = true,
    this.onAvailabilityTap,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = vendor?.canteenName ?? 'Chez Maman Afi';
    final campus = vendor?.campusName.isNotEmpty == true
        ? vendor!.campusName
        : 'Campus UCAO';
    final isOpen = vendor?.isOpen ?? false;
    final initials = vendor?.initials ?? 'MA';

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 15.3,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.vheaderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      campus,
                      style: AppTextStyles.vheaderCampus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showNotification) ...[
                const SizedBox(width: 8),
                _IconButton(
                  icon: Icons.notifications_rounded,
                  hasBadge: true,
                  onTap: onNotificationTap,
                ),
              ],
              if (showAvailabilityBadge) ...[
                TextButton(
                  onPressed: onAvailabilityTap ?? onNotificationTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                  ),
                  child: _AvailabilityBadge(isOpen: isOpen),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, this.hasBadge = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Stack(
          alignment: const Alignment(0.9, -0.9),
          children: [
            Icon(icon, size: 17, color: AppColors.textSecondaryLight),
            if (hasBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isOpen;

  const _AvailabilityBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOpen ? AppColors.green : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          isOpen ? 'Cantine ouverte' : 'Cantine fermée',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isOpen ? AppColors.green : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
