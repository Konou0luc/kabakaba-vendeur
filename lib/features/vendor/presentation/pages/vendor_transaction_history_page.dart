import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../data/vendor_wallet_provider.dart';

class VendorTransactionHistoryPage extends ConsumerWidget {
  const VendorTransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorTransactionsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Historique des transactions',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Historique indisponible',
                    style: AppTextStyles.emptySub),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    title: 'Aucune transaction',
                    subtitle: 'L\'historique apparaîtra ici.',
                    icon: Icons.history_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(vendorTransactionsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _TxTile(transaction: list[i]),
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

class _TxTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TxTile({required this.transaction});
  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final iconColor = isCredit ? AppColors.green : AppColors.accent;
    final iconBg = isCredit ? AppColors.greenLight : AppColors.orangeLight;
    final amountColor =
        isCredit ? AppColors.green : AppColors.textPrimaryLight;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F1B2A6B),
              blurRadius: 14,
              offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(transaction.icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
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
                Text(transaction.reference,
                    style: AppTextStyles.txMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
