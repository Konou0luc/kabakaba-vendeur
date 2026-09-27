import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/vendor_model.dart';

class VendorHeader extends StatelessWidget {
  final VendorModel? vendor;
  final bool showNotification;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;
  final bool showAvailabilityBadge;
  final VoidCallback? onAvailabilityTap;

  const VendorHeader({
    super.key,
    this.vendor,
    this.showNotification = false,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
    this.showAvailabilityBadge = true,
    this.onAvailabilityTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = vendor?.canteenName ?? 'Chargement…';
    final campus = vendor?.campusName ?? '';
    final isOpen = vendor?.isOpen ?? false;
    final initials = vendor?.initials ?? '··';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.vheaderName.copyWith(
                    fontSize: 17,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (campus.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    campus.toUpperCase(),
                    style: AppTextStyles.vheaderCampus.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (showNotification) ...[
            _CircleAction(
              icon: Icons.notifications_none_rounded,
              hasBadge: hasUnreadNotifications,
              onTap: onNotificationTap,
            ),
            const SizedBox(width: 8),
          ],
          if (showAvailabilityBadge)
            _StatusChip(
              isOpen: isOpen,
              onTap: onAvailabilityTap,
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _CircleAction({
    required this.icon,
    this.hasBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimaryLight),
            if (hasBadge)
              const Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  final VoidCallback? onTap;

  const _StatusChip({required this.isOpen, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOpen ? AppColors.greenLight : AppColors.indigoLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOpen ? AppColors.green : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOpen ? 'Ouverte' : 'Fermée',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isOpen ? AppColors.green : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
