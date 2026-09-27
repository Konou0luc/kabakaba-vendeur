import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.04),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardDark => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.09),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.45),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get greenGlow => [
    BoxShadow(
      color: AppColors.green.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}
