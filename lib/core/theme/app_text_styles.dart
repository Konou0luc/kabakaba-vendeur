import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle _base = GoogleFonts.plusJakartaSans();

  static TextTheme getTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.text : AppColors.textPrimaryLight;

    return TextTheme(
      displayLarge: _base.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.02,
      ),
      displayMedium: _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.01,
      ),
      displaySmall: _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      bodyLarge: _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodySmall: _base.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      labelLarge: _base.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      labelMedium: _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: 0.04,
      ),
      titleMedium: _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      titleSmall: _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
    );
  }

  // ===== Auth (dark) maquette styles =====
  static TextStyle get heroTitle => _base.copyWith(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.02,
    color: AppColors.white,
  );

  static TextStyle get heroSubtitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.white.withValues(alpha: 0.62),
  );

  static TextStyle get fieldLabel => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.04,
    color: AppColors.muted,
  );

  static TextStyle get inputText => _base.copyWith(
    fontSize: 15.3,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static TextStyle get inputPlaceholder => _base.copyWith(
    fontSize: 15.3,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedSoft,
  );

  static TextStyle get buttonPrimary => _base.copyWith(
    fontSize: 15.8,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get progressPill => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.02,
    color: AppColors.white.withValues(alpha: 0.85),
  );

  static TextStyle get hintText => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w500,
    height: 1.55,
    color: AppColors.white.withValues(alpha: 0.75),
  );

  static TextStyle get pinCaption => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedSoft,
  );

  static TextStyle get otpDigit => _base.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static TextStyle get timerText => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.normal,
    color: AppColors.muted,
  );

  static TextStyle get resendText => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get welcomeGreet => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static TextStyle get welcomeName => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    color: AppColors.white,
  );

  static TextStyle get welcomeSub => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedSoft,
  );

  static TextStyle get forgotLink => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  static TextStyle get successTitle => _base.copyWith(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    color: AppColors.white,
  );

  static TextStyle get successSubtitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: AppColors.white.withValues(alpha: 0.62),
  );

  // ===== Light / dashboard maquette styles =====
  static TextStyle get pageTitle => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static TextStyle get pageSub => _base.copyWith(
    fontSize: 12.5,
    color: AppColors.textSecondaryLight,
    height: 1.6,
  );

  static TextStyle get flowTitle => _base.copyWith(
    fontSize: 16.3,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.01,
  );

  static TextStyle get flowSub => _base.copyWith(
    fontSize: 14.8,
    color: AppColors.textSecondaryLight,
    height: 1.6,
  );

  static TextStyle get topnavTitle => _base.copyWith(
    fontSize: 16.3,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get statusbarLight => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get vheaderName => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get vheaderCampus => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get tabLabel => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get tabActive => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle get tabBadge => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get sectionLabel => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.05,
  );

  static TextStyle get orderNum => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get orderMeta => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get orderItemsSub => _base.copyWith(
    fontSize: 13.3,
    color: AppColors.textPrimaryLight,
    height: 1.55,
  );

  static TextStyle get statusBadge =>
      _base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800);

  static TextStyle get countdownTime => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    letterSpacing: -0.02,
  );

  static TextStyle get countdownLabel => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get countdownSub => _base.copyWith(
    fontSize: 11.5,
    color: AppColors.textPrimaryLight,
    height: 1.4,
  );

  static TextStyle get btnFill => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get btnOutline => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get btnRefuse => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.red,
  );

  static TextStyle get btnAccept => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get readyBannerTitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w800,
    color: AppColors.green,
  );

  static TextStyle get readyBannerSub => _base.copyWith(
    fontSize: 13,
    color: AppColors.textPrimaryLight,
    height: 1.55,
  );

  static TextStyle get tlLabel => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get emptyTitle => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get emptySub => _base.copyWith(
    fontSize: 13.3,
    color: AppColors.textSecondaryLight,
    height: 1.55,
  );

  static TextStyle get walletAmount => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.02,
    color: AppColors.white,
  );

  static TextStyle get walletAmountSmall => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w600,
    color: AppColors.white.withValues(alpha: 0.45),
  );

  static TextStyle get walletLabel => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.white.withValues(alpha: 0.5),
    letterSpacing: 0.05,
  );

  static TextStyle get txTitle => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get txMeta =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondaryLight);

  static TextStyle get txAmount =>
      _base.copyWith(fontSize: 14.3, fontWeight: FontWeight.w800);

  static TextStyle get fieldCardLabel => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.04,
  );

  static TextStyle get amountDisplay => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get amountSub =>
      _base.copyWith(fontSize: 13, color: AppColors.textSecondaryLight);

  static TextStyle get presetChip => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get recapRow =>
      _base.copyWith(fontSize: 13.8, color: AppColors.textSecondaryLight);

  static TextStyle get recapRowBold => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get pinDotLightCaption => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get keyLight => _base.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get successLightTitle => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get successLightSubtitle => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get successRecapRow =>
      _base.copyWith(fontSize: 13.3, color: AppColors.textSecondaryLight);

  static TextStyle get perfTitle => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get perfSub =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondaryLight);

  static TextStyle get perfPct => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get metricLabel => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.03,
  );

  static TextStyle get metricValue => _base.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get metricDelta =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w700);

  static TextStyle get chartTitle => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get chartSub =>
      _base.copyWith(fontSize: 12.5, color: AppColors.textSecondaryLight);

  static TextStyle get barHour => _base.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get rankName => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get rankCount => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get rankCountSmall => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get periodTab => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get insightText =>
      _base.copyWith(fontSize: 13, color: AppColors.primary, height: 1.55);

  static TextStyle get profileName => _base.copyWith(
    fontSize: 15.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get profileMeta =>
      _base.copyWith(fontSize: 13, color: AppColors.textSecondaryLight);

  static TextStyle get profileCampusBadge => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    backgroundColor: AppColors.indigoLight,
  );

  static TextStyle get sectionTitle => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
    letterSpacing: 0.04,
  );

  static TextStyle get fieldLabelLight => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.03,
  );

  static TextStyle get fieldStatic => _base.copyWith(
    fontSize: 14.8,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get toggleTitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get toggleSub =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondaryLight);

  static TextStyle get navRowTitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get navRowSub =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondaryLight);

  static TextStyle get navItemLabel =>
      _base.copyWith(fontSize: 9, fontWeight: FontWeight.w700);

  static TextStyle get sheetTitle => _base.copyWith(
    fontSize: 15.8,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get sheetSub => _base.copyWith(
    fontSize: 13.3,
    color: AppColors.textSecondaryLight,
    height: 1.5,
  );

  static TextStyle get motifChip => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get sheetWarn =>
      _base.copyWith(fontSize: 12.5, color: AppColors.accent, height: 1.5);

  static TextStyle get promptTitle => _base.copyWith(
    fontSize: 17.3,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.01,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get promptSub => _base.copyWith(
    fontSize: 13.8,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get debtTitle => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w800,
    color: AppColors.red,
  );

  static TextStyle get debtSub => _base.copyWith(
    fontSize: 13,
    color: AppColors.textPrimaryLight,
    height: 1.55,
  );

  static TextStyle get methodRowName => _base.copyWith(
    fontSize: 14.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get methodRowSub =>
      _base.copyWith(fontSize: 12.5, color: AppColors.textSecondaryLight);

  static TextStyle get hintBoxLight => _base.copyWith(
    fontSize: 13.3,
    fontWeight: FontWeight.w500,
    height: 1.55,
    color: AppColors.textPrimaryLight,
  );
}
