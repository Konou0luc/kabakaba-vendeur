import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

class VendorNotificationsPage extends ConsumerWidget {
  const VendorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(vendorNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Notifications',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: notifications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible de charger les notifications.',
                  style: AppTextStyles.emptySub,
                  textAlign: TextAlign.center,
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucune notification',
                    subtitle:
                        'Les commandes, retraits et alertes de créance apparaîtront ici.',
                    icon: Icons.notifications_none_rounded,
                    framed: true,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(vendorNotificationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = page.items[index];
                      return _NotificationTile(
                        notification: item,
                        onTap: () => _markRead(context, ref, item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (notification.isRead) return;
    try {
      await ref.read(notificationsRepositoryProvider).markRead(notification.id);
      ref.invalidate(vendorNotificationsProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Marquage impossible.',
          ),
        ),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (notification.type) {
      NotificationKind.success => (
        Icons.check_circle_rounded,
        AppColors.green,
        AppColors.greenLight,
      ),
      NotificationKind.warning => (
        Icons.warning_rounded,
        AppColors.accent,
        AppColors.orangeLight,
      ),
      NotificationKind.error => (
        Icons.error_rounded,
        AppColors.red,
        AppColors.redLight,
      ),
      NotificationKind.info => (
        Icons.notifications_rounded,
        AppColors.primary,
        AppColors.indigoLight,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.indigoLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1B2A6B),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.navRowTitle,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message, style: AppTextStyles.navRowSub),
                  const SizedBox(height: 6),
                  Text(
                    formatDayMonthTime(notification.createdAt),
                    style: AppTextStyles.fieldLabelLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
