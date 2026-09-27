import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../../withdrawals/data/withdrawals_repository.dart';
import '../../../withdrawals/domain/withdrawal_models.dart';
import '../../data/vendor_profile_repository.dart';
import 'vendor_withdraw_success_page.dart';

class VendorWithdrawConfirmPage extends ConsumerStatefulWidget {
  final VendorModel vendor;
  final int amount;
  final WithdrawalOperator operator;

  const VendorWithdrawConfirmPage({
    super.key,
    required this.vendor,
    required this.amount,
    required this.operator,
  });

  @override
  ConsumerState<VendorWithdrawConfirmPage> createState() =>
      _VendorWithdrawConfirmPageState();
}

class _VendorWithdrawConfirmPageState
    extends ConsumerState<VendorWithdrawConfirmPage> {
  bool _loading = false;

  WithdrawalDraft get _draft => WithdrawalDraft(
    amount: widget.amount,
    operator: widget.operator,
  );

  Future<void> _confirm(WithdrawalRecap recap) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(withdrawalsRepositoryProvider)
          .request(amount: widget.amount, operator: widget.operator);
      ref.invalidate(currentVendorProvider);
      ref.invalidate(withdrawalHistoryProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VendorWithdrawSuccessPage(
            amount: recap.payoutAmountToSend.round(),
            operator: widget.operator.label,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(withdrawalPreviewProvider(_draft));
    final phone = widget.vendor.phone ?? '';
    final lastDigits = phone.length > 4
        ? phone.substring(phone.length - 4)
        : '——';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Confirmer le retrait',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: preview.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error is ApiException
                        ? error.message
                        : 'Impossible de calculer les frais. Réessaie.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.emptySub,
                  ),
                ),
              ),
              data: (recap) {
                final remaining =
                    (widget.vendor.balanceFcfa - recap.debitedFromBalance)
                        .clamp(0, double.maxFinite);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x141B2A6B),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
                        child: Column(
                          children: [
                            _RecapRow(
                              label: 'Montant demandé',
                              value: CurrencyFormatter.formatTickets(
                                recap.amountRequested,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Vers',
                              value:
                                  '${widget.operator.label} — •••• $lastDigits',
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Palier',
                              value: recap.tier.label,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Frais à ta charge',
                              value: CurrencyFormatter.formatTickets(
                                recap.feesBorneByVendor,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Tu recevras',
                              value: CurrencyFormatter.formatTickets(
                                recap.payoutAmountToSend,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Débit du solde',
                              value: CurrencyFormatter.formatTickets(
                                recap.debitedFromBalance,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _RecapRow(
                              label: 'Solde restant',
                              value: CurrencyFormatter.formatTickets(remaining),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      if (recap.lines.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...recap.lines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(line, style: AppTextStyles.hintText),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _confirm(recap),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Confirmer le retrait',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _RecapRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.recapRow.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.recapRowBold.copyWith(
                    color: AppColors.accent,
                    fontSize: 16.3,
                  )
                : AppTextStyles.recapRowBold,
          ),
        ],
      ),
    );
  }
}
