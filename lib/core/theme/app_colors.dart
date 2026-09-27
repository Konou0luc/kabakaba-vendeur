import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette (from maquette)
  static const Color primary = Color(0xFF1B2A6B);
  static const Color indigoDark = Color(0xFF0D1438);
  static const Color cardDark = Color(0xFF111A45);
  static const Color accent = Color(0xFFF07840);

  // Lines & Fields (verre dépoli)
  static const Color line = Color(0x1FFFFFFF);
  static const Color field = Color(0x0DFFFFFF);
  static const Color fieldFocus = Color(0x17FFFFFF);

  // Text variants (dark mode)
  static const Color text = Color(0xFFFFFFFF);
  static const Color muted = Color(0x7FFFFFFF);
  static const Color mutedSoft = Color(0x60FFFFFF);

  // Light Mode
  static const Color backgroundLight = Color(0xFFF4F6FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0D1438);
  static const Color textSecondaryLight = Color(0xFF5C6584);
  static const Color textMutedLight = Color(0xFF96A0BC);
  static const Color surfaceSecondaryLight = Color(0xFFEEF1FA);

  // Dashboard / light theme tokens (from maquette vendor section)
  static const Color bg = Color(0xFFF7F8FC);
  static const Color indigoLight = Color(0xFFEEF1FA);
  static const Color orangeLight = Color(0xFFFEF0E9);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFF0FDF4);
  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFEF2F2);
  static const Color grayLight = Color(0xFFF1F3F8);
  static const Color borderLight = Color(0xFFE4E9F4);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Dynamic helpers
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? bg : indigoDark;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? textPrimaryLight
      : text;

  static Color surfaceSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? surfaceSecondaryLight
      : cardDark;
}
