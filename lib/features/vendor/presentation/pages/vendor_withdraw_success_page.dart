import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../auth/data/vendor_auth_provider.dart';
import '../../data/vendor_wallet_provider.dart';

class VendorWithdrawSuccessPage extends ConsumerStatefulWidget {
  final int amount;
  final String operator;

  const VendorWithdrawSuccessPage({
    super.key,
    required this.amount,
    required this.operator,
  });

  @override
  ConsumerState<VendorWithdrawSuccessPage> createState() =>
      _VendorWithdrawSuccessPageState();
}

class _VendorWithdrawSuccessPageState
    extends ConsumerState<VendorWithdrawSuccessPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(currentVendorProvider);
      ref.invalidate(vendorTransactionsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.4),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Retrait en cours',
                style: AppTextStyles.successLightTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 240,
                child: Text(
                  'Ta demande de retrait a été enregistrée auprès de ${widget.operator}.',
                  style: AppTextStyles.successLightSubtitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _Row(
                      label: 'Montant',
                      value: CurrencyFormatter.formatTickets(widget.amount),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              KabaButton(
                text: 'Retour au portefeuille',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.successRecapRow.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.recapRowBold),
        ],
      ),
    );
  }
}
