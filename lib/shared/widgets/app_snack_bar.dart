import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppSnackKind { error, success, info }

/// Snackbar unique de l'app : message court, jamais de dump technique.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackKind kind = AppSnackKind.error,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: switch (kind) {
          AppSnackKind.error => AppColors.red,
          AppSnackKind.success => AppColors.green,
          AppSnackKind.info => AppColors.primary,
        },
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
}
