import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import 'vendor_withdraw_success_page.dart';

class VendorWithdrawConfirmPage extends ConsumerStatefulWidget {
  final VendorModel vendor;
  final int amount;
  final String operator;
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

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            ApiEndpoints.withdrawals,
            data: {
              'amount': widget.amount,
              'operator': widget.operator.contains('Mixx') ? 'MIXX' : 'FLOOZ',
            },
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
      setState(() => _loading = false);
      return;
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VendorWithdrawSuccessPage(
            amount: widget.amount,
            operator: widget.operator,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.vendor.balanceFcfa - widget.amount).clamp(
      0,
      double.maxFinite,
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Confirmer le retrait',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
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
                          label: 'Montant',
                          value: CurrencyFormatter.formatTickets(widget.amount),
                        ),
                        const Divider(height: 1, color: AppColors.borderLight),
                        _RecapRow(
                          label: 'Vers',
                          value:
                              '${widget.operator} — •••• ${(widget.vendor.phone ?? "").length > 4 ? (widget.vendor.phone ?? "").substring((widget.vendor.phone ?? "").length - 4) : "——"}',
                        ),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const _RecapRow(
                          label: 'Frais opérateur',
                          value: 'À ta charge',
                        ),
                        const Divider(height: 1, color: AppColors.borderLight),
                        _RecapRow(
                          label: 'Solde restant après retrait',
                          value: CurrencyFormatter.formatTickets(remaining),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirm,
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
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
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
