import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isLight;

  const StatusBadge({super.key, required this.status, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    final config = _StatusConfig.fromStatus(status, isLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.statusBadge.copyWith(
          color: config.textColor,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _StatusConfig {
  final Color bgColor;
  final Color textColor;

  const _StatusConfig(this.bgColor, this.textColor);

  factory _StatusConfig.fromStatus(OrderStatus status, bool isLight) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusConfig(
          isLight ? AppColors.orangeLight : AppColors.orangeLight,
          AppColors.accent,
        );
      case OrderStatus.accepted:
      case OrderStatus.inPreparation:
        return _StatusConfig(
          isLight ? AppColors.indigoLight : AppColors.indigoLight,
          AppColors.primary,
        );
      case OrderStatus.ready:
        return _StatusConfig(
          isLight ? AppColors.greenLight : AppColors.greenLight,
          AppColors.green,
        );
      case OrderStatus.received:
      case OrderStatus.autoReceived:
        return _StatusConfig(
          isLight ? AppColors.greenLight : AppColors.greenLight,
          AppColors.green,
        );
      case OrderStatus.refused:
        return _StatusConfig(
          isLight ? AppColors.redLight : AppColors.redLight,
          AppColors.red,
        );
      case OrderStatus.cancelledVendor:
        return _StatusConfig(
          isLight ? AppColors.grayLight : AppColors.grayLight,
          AppColors.textSecondaryLight,
        );
      case OrderStatus.refunded:
        return _StatusConfig(
          isLight ? AppColors.orangeLight : AppColors.orangeLight,
          AppColors.accent,
        );
    }
  }
}
