import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/vendor_header.dart';
import '../../../auth/data/vendor_auth_provider.dart';
import '../../data/vendor_wallet_provider.dart';
import 'vendor_withdraw_amount_page.dart';
import 'vendor_transaction_history_page.dart';

class VendorWalletPage extends ConsumerWidget {
  const VendorWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(currentVendorProvider);
    final txAsync = ref.watch(vendorTransactionsProvider);

    return Column(
      children: [
        VendorHeader(vendor: vendorAsync.value),
        vendorAsync.when(
          loading: () => _WalletSkeleton(),
          error: (_, __) => _ErrorView(
            message: 'Portefeuille indisponible',
            onRetry: () => ref.invalidate(currentVendorProvider),
          ),
          data: (vendor) => _LoadedWallet(
            vendor: vendor,
            txAsync: txAsync,
            onWithdraw: vendor.isActive
                ? () {
                    if (vendor.debtFcfa > 0) {
                      _showDebtBlockedDialog(context);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VendorWithdrawAmountPage(vendor: vendor),
                        ),
                      );
                    }
                  }
                : null,
            onHistory: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VendorTransactionHistoryPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDebtBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Retrait indisponible',
                style: AppTextStyles.promptTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu as une créance active. Régularise-la pour pouvoir retirer de nouveau.',
                style: AppTextStyles.promptSub,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedWallet extends StatelessWidget {
  final VendorModel vendor;
  final AsyncValue<List<TransactionModel>> txAsync;
  final VoidCallback? onWithdraw;
  final VoidCallback onHistory;
  const _LoadedWallet({
    required this.vendor,
    required this.txAsync,
    required this.onWithdraw,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _WalletCard(
            vendor: vendor,
            onWithdraw: onWithdraw,
            onHistory: onHistory,
          ),
          if (vendor.debtFcfa > 0) ...[
            const SizedBox(height: 12),
            _DebtBanner(debtFcfa: vendor.debtFcfa),
          ],
          const SizedBox(height: 18),
          const SectionLabel('Mouvements récents'),
          const SizedBox(height: 8),
          txAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Historique indisponible',
                style: AppTextStyles.emptySub,
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _EmptyTxCard();
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F1B2A6B),
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: list.take(8).map((t) {
                    return _TxRow(transaction: t);
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback? onWithdraw;
  final VoidCallback onHistory;
  const _WalletCard({
    required this.vendor,
    required this.onWithdraw,
    required this.onHistory,
  });
  @override
  Widget build(BuildContext context) {
    final blocked = vendor.debtFcfa > 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.indigoDark],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B2A6B),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SOLDE DISPONIBLE', style: AppTextStyles.walletLabel),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatTickets(vendor.balanceFcfa),
            style: AppTextStyles.walletAmount,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WalletBtn(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Retirer',
                  filled: true,
                  enabled: !blocked,
                  onTap: onWithdraw,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WalletBtn(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  filled: false,
                  onTap: onHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;
  const _WalletBtn({
    required this.icon,
    required this.label,
    required this.filled,
    this.enabled = true,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: filled
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: filled ? 14 : 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtBanner extends StatelessWidget {
  final num debtFcfa;
  const _DebtBanner({required this.debtFcfa});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créance active : ${CurrencyFormatter.formatTickets(debtFcfa)}',
                  style: AppTextStyles.debtTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  'kabakaba a avancé un remboursement. Cette somme sera prélevée automatiquement sur tes prochaines commandes. Le retrait reste bloqué jusqu\'au remboursement intégral.',
                  style: AppTextStyles.debtSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionModel transaction;
  const _TxRow({required this.transaction});
  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final iconColor = isCredit ? AppColors.green : AppColors.accent;
    final iconBg = isCredit ? AppColors.greenLight : AppColors.orangeLight;
    final amountColor = isCredit ? AppColors.green : AppColors.textPrimaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(transaction.icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.label,
                  style: AppTextStyles.txTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  transaction.reference,
                  style: AppTextStyles.txMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} ${CurrencyFormatter.formatTickets(transaction.amount)}',
            style: AppTextStyles.txAmount.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.sectionLabel),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.borderLight, height: 1)),
      ],
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Expanded(child: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: AppTextStyles.emptySub),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _EmptyTxCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: const EmptyState(
        title: 'Aucune opération pour l\'instant',
        subtitle: 'L\'historique de tes mouvements apparaîtra ici.',
        icon: Icons.receipt_long_rounded,
      ),
    );
  }
}
