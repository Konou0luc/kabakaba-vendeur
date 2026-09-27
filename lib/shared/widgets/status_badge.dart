import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';

/// Pastille de statut d'une commande.
class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _palette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.statusBadge.copyWith(
          color: foreground,
          fontSize: 12.5,
        ),
      ),
    );
  }

  static (Color background, Color foreground) _palette(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => (AppColors.orangeLight, AppColors.accent),
      OrderStatus.accepted ||
      OrderStatus.inPreparation => (AppColors.indigoLight, AppColors.primary),
      OrderStatus.ready ||
      OrderStatus.received ||
      OrderStatus.autoReceived => (AppColors.greenLight, AppColors.green),
      OrderStatus.refused => (AppColors.redLight, AppColors.red),
      OrderStatus.cancelledVendor ||
      OrderStatus.cancelledStudent ||
      OrderStatus.unknown => (
        AppColors.grayLight,
        AppColors.textSecondaryLight,
      ),
      OrderStatus.refunded => (AppColors.orangeLight, AppColors.accent),
    };
  }
}
