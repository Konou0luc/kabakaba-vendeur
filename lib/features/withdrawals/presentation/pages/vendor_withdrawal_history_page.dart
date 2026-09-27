import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../data/withdrawals_repository.dart';
import '../../domain/withdrawal_models.dart';

class VendorWithdrawalHistoryPage extends ConsumerWidget {
  const VendorWithdrawalHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Historique des retraits',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Historique des retraits indisponible.',
                  style: AppTextStyles.emptySub,
                  textAlign: TextAlign.center,
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucun retrait',
                    subtitle:
                        'Tes demandes Flooz et Mixx apparaîtront ici, avec le délai pour signaler un problème.',
                    icon: Icons.payments_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(withdrawalHistoryProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _WithdrawalTile(
                      withdrawal: page.items[index],
                      onAppeal: () =>
                          _openAppeal(context, ref, page.items[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppeal(
    BuildContext context,
    WidgetRef ref,
    WithdrawalModel withdrawal,
  ) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppealSheet(withdrawal: withdrawal),
    );
    if (sent == true) {
      ref.invalidate(withdrawalHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réclamation envoyée.')),
        );
      }
    }
  }
}

class _WithdrawalTile extends StatelessWidget {
  final WithdrawalModel withdrawal;
  final VoidCallback onAppeal;

  const _WithdrawalTile({
    required this.withdrawal,
    required this.onAppeal,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (withdrawal.status) {
      WithdrawalStatus.completed => AppColors.green,
      WithdrawalStatus.failed || WithdrawalStatus.cancelled => AppColors.red,
      WithdrawalStatus.processing => AppColors.accent,
      WithdrawalStatus.pending || WithdrawalStatus.unknown =>
        AppColors.textSecondaryLight,
    };
    final reason = withdrawal.failureReason ?? withdrawal.cancellationReason;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  withdrawal.operator?.label ?? 'Mobile money',
                  style: AppTextStyles.navRowTitle,
                ),
              ),
              Text(
                CurrencyFormatter.formatTickets(withdrawal.amount),
                style: AppTextStyles.navRowTitle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  withdrawal.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDayMonthTime(withdrawal.createdAt),
                style: AppTextStyles.fieldLabelLight,
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reason, style: AppTextStyles.navRowSub),
          ],
          if (withdrawal.canAppeal) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAppeal,
                child: const Text('Signaler un problème'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppealSheet extends ConsumerStatefulWidget {
  final WithdrawalModel withdrawal;

  const _AppealSheet({required this.withdrawal});

  @override
  ConsumerState<_AppealSheet> createState() => _AppealSheetState();
}

class _AppealSheetState extends ConsumerState<_AppealSheet> {
  WithdrawalAppealType _type = WithdrawalAppealType.notReceived;
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.length < 8) {
      setState(
        () => _error = 'Décris le problème en quelques mots (8 caractères min.).',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(withdrawalsRepositoryProvider).appeal(
        withdrawalId: widget.withdrawal.id,
        type: _type,
        reason: reason,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Envoi impossible.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signaler un problème', style: AppTextStyles.promptTitle),
            const SizedBox(height: 8),
            Text(
              'Fenêtre ouverte jusqu’au ${formatDayMonthTime(widget.withdrawal.confirmationDeadlineAt!)}.',
              style: AppTextStyles.promptSub,
            ),
            const SizedBox(height: 16),
            ...WithdrawalAppealType.values.map((type) {
              final selected = _type == type;
              return InkWell(
                onTap: () => setState(() => _type = type),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(type.label)),
                    ],
                  ),
                ),
              );
            }),
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Précisions',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.emptySub.copyWith(color: AppColors.red),
              ),
            ],
            const SizedBox(height: 18),
            KabaButton(
              text: 'Envoyer',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
