import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../wallet/data/transactions_repository.dart';
import '../../data/vendor_profile_repository.dart';

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
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionHistoryControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.green,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Retrait en cours',
                style: AppTextStyles.successLightTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Ta demande de retrait a été enregistrée auprès de ${widget.operator}.',
                  style: AppTextStyles.successLightSubtitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _Row(
                      label: 'Montant',
                      value: CurrencyFormatter.formatTickets(widget.amount),
                    ),
                    const Divider(height: 18, color: AppColors.borderLight),
                    _Row(label: 'Opérateur', value: widget.operator),
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
    return Row(
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
    );
  }
}
