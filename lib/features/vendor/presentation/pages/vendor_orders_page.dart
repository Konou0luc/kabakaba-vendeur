import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/bottom_sheet_modal.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_tabs.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated.dart';
import '../../../../shared/widgets/vendor_header.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/presentation/pages/vendor_notifications_page.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../orders/presentation/controllers/vendor_orders_controller.dart';
import '../../data/vendor_profile_repository.dart';

class VendorOrdersPage extends ConsumerStatefulWidget {
  const VendorOrdersPage({super.key});
  @override
  ConsumerState<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends ConsumerState<VendorOrdersPage> {
  int _tab = 0;

  OrderBucket get _bucket => OrderBucket.values[_tab];

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(currentVendorProvider);
    final current = ref.watch(vendorOrdersControllerProvider(_bucket));
    final counts = {
      for (final bucket in OrderBucket.values)
        bucket: ref
            .watch(vendorOrdersControllerProvider(bucket))
            .maybeWhen(data: (page) => page.total, orElse: () => 0),
    };

    return Column(
      children: [
        VendorHeader(
          vendor: vendor.maybeWhen(data: (v) => v, orElse: () => null),
          showNotification: true,
          hasUnreadNotifications:
              ref.watch(unreadNotificationsCountProvider) > 0,
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VendorNotificationsPage(),
              ),
            );
          },
          onAvailabilityTap: () => _showAvailabilityDialog(),
        ),
        SectionTabs(
          tabs: [
            TabItem(
              label: 'Nouvelles',
              badgeCount: counts[OrderBucket.incoming] ?? 0,
            ),
            TabItem(
              label: 'Préparation',
              badgeCount: counts[OrderBucket.preparing] ?? 0,
            ),
            TabItem(
              label: 'Prêtes',
              badgeCount: counts[OrderBucket.ready] ?? 0,
            ),
            const TabItem(label: 'Historique'),
          ],
          selectedIndex: _tab,
          onTabSelected: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(vendorOrdersControllerProvider(_bucket).notifier)
                .refresh(),
            child: current.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: EmptyState(
                      title: 'Impossible de charger les commandes',
                      subtitle: error is ApiException
                          ? error.message
                          : 'Tire vers le bas pour réessayer.',
                      icon: Icons.cloud_off_rounded,
                    ),
                  ),
                ],
              ),
              data: (page) => _buildList(page, isHistory: _tab == 3),
            ),
          ),
        ),
      ],
    );
  }

  void _showAvailabilityDialog() async {
    final repo = ref.read(vendorProfileRepositoryProvider);
    final vendor = ref.read(currentVendorProvider).value;
    if (vendor == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AvailabilityDialog(isOpen: vendor.isOpen),
    );
    if (result != null) {
      try {
        await repo.setOpen(result);
        ref.invalidate(currentVendorProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changement impossible. Réessaie.')),
          );
        }
      }
    }
  }

  Widget _buildList(Paginated<OrderModel> page, {bool isHistory = false}) {
    final items = page.items;
    if (items.isEmpty) {
      final subtitles = [
        'Les commandes des étudiants apparaîtront ici dès qu\'ils passeront commande.',
        'Aucune commande en cours de préparation.',
        'Aucune commande prête à remettre pour le moment.',
        'L\'historique de tes commandes apparaîtra ici.',
      ];
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1B2A6B),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: EmptyState(
              title: isHistory && _tab == 3
                  ? 'Pas encore d\'historique'
                  : 'Aucune commande pour l\'instant',
              subtitle: subtitles[_tab],
              icon: Icons.receipt_long_rounded,
            ),
          ),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 280 && page.hasMore) {
          ref.read(vendorOrdersControllerProvider(_bucket).notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (page.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return isHistory
              ? _HistoryCard(order: items[i])
              : _OrderCard(order: items[i]);
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});
  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  late int _remainingSeconds;
  Timer? _timer;

  VendorOrdersController get _orders {
    final bucket =
        OrderBucket.forStatus(widget.order.status) ?? OrderBucket.incoming;
    return ref.read(vendorOrdersControllerProvider(bucket).notifier);
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _computeRemaining();
    if (widget.order.status.isIncoming || widget.order.status.isReady) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remainingSeconds = _computeRemaining());
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
        }
      });
    }
  }

  int _computeRemaining() {
    if (widget.order.status.isIncoming) {
      final elapsed = DateTime.now().difference(widget.order.createdAt).inSeconds;
      return (300 - elapsed).clamp(0, 300);
    }
    if (widget.order.status.isReady) {
      final start = widget.order.readyAt ?? widget.order.createdAt;
      final elapsed = DateTime.now().difference(start).inSeconds;
      return (3600 - elapsed).clamp(0, 3600);
    }
    return 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showRefuseSheet() async {
    String? selected;
    final result = await showKabaBottomSheet<String>(
      context,
      sheet: BottomSheetModal(
        title: 'Pourquoi refuser cette commande ?',
        subtitle:
            'Le motif est transmis à l\'étudiant. Ses tickets sont immédiatement recrédités.',
        chips: const [
          'Rupture de stock',
          'Cantine surchargée',
          'Erreur sur l\'article',
          'Autre',
        ],
        selectedChip: selected,
        onChipSelected: (c) => selected = c,
        confirmText: 'Confirmer le refus',
        cancelText: 'Annuler',
        isConfirmDanger: true,
        isConfirmEnabled: true,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () => Navigator.of(context).pop(selected),
      ),
    );
    if (result != null && context.mounted) {
      try {
        await _orders.refuse(widget.order.id, result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refus impossible. Réessaie.')),
          );
        }
      }
    }
  }

  Future<void> _showCancelSheet() async {
    String? selected;
    final result = await showKabaBottomSheet<String>(
      context,
      sheet: BottomSheetModal(
        title: 'Pourquoi annuler cette commande ?',
        subtitle: 'Les tickets seront immédiatement recrédités à l\'étudiant.',
        chips: const ['Ingrédient manquant', 'Erreur de préparation', 'Autre'],
        selectedChip: selected,
        onChipSelected: (c) => selected = c,
        confirmText: 'Confirmer l\'annulation',
        cancelText: 'Retour',
        isConfirmDanger: true,
        isConfirmEnabled: true,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () => Navigator.of(context).pop(selected),
      ),
    );
    if (result != null && context.mounted) {
      try {
        await _orders.cancel(widget.order.id, result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annulation impossible. Réessaie.')),
          );
        }
      }
    }
  }

  Future<void> _showRefundSheet() async {
    String? selected;
    final result = await showKbaConfirmDialog(
      context,
      sheet: BottomSheetModal(
        title:
            'Rembourser ${CurrencyFormatter.formatTickets(widget.order.totalTickets)} ?',
        subtitle: 'Motif obligatoire avant soumission.',
        chips: const ['Article manquant', 'Non conforme', 'Autre'],
        selectedChip: selected,
        onChipSelected: (c) => selected = c,
        confirmText: 'Confirmer',
        cancelText: 'Annuler',
        isConfirmOrange: true,
        isConfirmEnabled: true,
        showWarn: true,
        warnText:
            'Si ton solde est insuffisant, kabakaba avance le remboursement. La somme devient une créance sur ton compte, récupérée automatiquement — le retrait est bloqué tant qu\'elle est active.',
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () => Navigator.of(context).pop(selected),
      ),
    );
    if (result != null && context.mounted) {
      try {
        await _orders.refund(widget.order.id, result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remboursement impossible. Réessaie.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showReadySheet() async {
    final result = await showKabaBottomSheet<String>(
      context,
      sheet: _ReadyMessageSheet(
        pickupCode: widget.order.displayCode,
      ),
    );
    if (result != null && context.mounted) {
      try {
        await _orders.markReady(widget.order.id, message: result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is ApiException
                    ? e.message
                    : 'Mise à jour impossible. Réessaie.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final packaging = order.packagingName ?? 'Sur place';
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
        border: Border(
          left: BorderSide(color: _leftColor(order.status), width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.receipt_long_rounded,
                color: AppColors.indigoLight,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.displayCode}',
                      style: AppTextStyles.orderNum,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(_orderMeta(order), style: AppTextStyles.orderMeta),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (order.status.isIncoming)
                Text(
                  CurrencyFormatter.formatTickets(order.totalTickets),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    fontSize: 15.3,
                  ),
                )
              else
                StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.orderItemsSub,
                children: [
                  for (var i = 0; i < order.items.length; i++) ...[
                    if (i > 0) const TextSpan(text: ' · '),
                    TextSpan(
                      text: '${order.items[i].quantity}×',
                      style: const TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' ${order.items[i].name}',
                      style: const TextStyle(color: AppColors.textPrimaryLight),
                    ),
                  ],
                  if (order.items.isNotEmpty) const TextSpan(text: ' · '),
                  TextSpan(
                    text: packaging,
                    style: const TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (order.status.isIncoming) ...[
            _CountdownBox(seconds: _remainingSeconds),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    label: 'Refuser',
                    icon: Icons.close_rounded,
                    color: AppColors.red,
                    borderColor: const Color(0xFFFECACA),
                    onPressed: _showRefuseSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilledAction(
                    label: 'Accepter',
                    icon: Icons.check_rounded,
                    color: AppColors.green,
                    onPressed: () async {
                      try {
                        await _orders.accept(order.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Acceptation impossible. Réessaie.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.accepted) ...[
            _Timeline(currentStep: 2),
            const SizedBox(height: 12),
            _FilledAction(
              label: 'Commencer la préparation',
              icon: Icons.soup_kitchen_rounded,
              color: AppColors.primary,
              onPressed: () async {
                try {
                  await _orders.startPreparing(order.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is ApiException
                              ? e.message
                              : 'Mise à jour impossible.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            _OutlineAction(
              label: 'Annuler la commande',
              icon: Icons.close_rounded,
              color: AppColors.red,
              borderColor: const Color(0xFFFECACA),
              onPressed: _showCancelSheet,
            ),
          ] else if (order.status == OrderStatus.inPreparation) ...[
            _Timeline(currentStep: 2),
            const SizedBox(height: 12),
            _FilledAction(
              label: 'Marquer comme prête',
              icon: Icons.check_rounded,
              color: AppColors.accent,
              onPressed: _showReadySheet,
            ),
            const SizedBox(height: 8),
            _OutlineAction(
              label: 'Annuler la commande',
              icon: Icons.close_rounded,
              color: AppColors.red,
              borderColor: const Color(0xFFFECACA),
              onPressed: _showCancelSheet,
            ),
          ] else if (order.status.isReady) ...[
            _PickupCodeBanner(code: order.displayCode),
            const SizedBox(height: 12),
            _ReadyBanner(seconds: _remainingSeconds),
            const SizedBox(height: 12),
            _OutlineAction(
              label: 'Rembourser cette commande',
              icon: Icons.u_turn_left_rounded,
              color: AppColors.red,
              borderColor: const Color(0xFFFECACA),
              onPressed: _showRefundSheet,
            ),
          ] else ...[
            Row(
              children: [
                StatusBadge(status: order.status),
                const Spacer(),
                Text(
                  CurrencyFormatter.formatTickets(order.totalTickets),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    fontSize: 15.3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _leftColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.accent;
      case OrderStatus.accepted:
      case OrderStatus.inPreparation:
        return AppColors.primary;
      case OrderStatus.ready:
      case OrderStatus.received:
      case OrderStatus.autoReceived:
        return AppColors.green;
      case OrderStatus.refunded:
        return AppColors.accent;
      case OrderStatus.refused:
        return AppColors.red;
      case OrderStatus.cancelledVendor:
      case OrderStatus.cancelledStudent:
      case OrderStatus.unknown:
        return AppColors.textSecondaryLight;
    }
  }

  String _orderMeta(OrderModel o) {
    if (o.status.isPreparing) {
      return '${o.studentName} · ${o.totalArticles} article${o.totalArticles > 1 ? 's' : ''}';
    }
    if (o.status.isReady && o.readyAt != null) {
      final remaining = 3600 - DateTime.now().difference(o.readyAt!).inSeconds;
      if (remaining > 0) {
        final minutes = (remaining / 60).ceil();
        return 'N° ${o.displayCode} · $minutes min restantes';
      }
      return 'N° ${o.displayCode} · délai de retrait dépassé';
    }
    return 'Reçue à ${_formatTime(o.createdAt)}';
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HistoryCard extends StatefulWidget {
  final OrderModel order;
  const _HistoryCard({required this.order});
  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.receipt_long_rounded,
                color: AppColors.indigoLight,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.displayCode}',
                      style: AppTextStyles.orderNum,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(_historyMeta(order), style: AppTextStyles.orderMeta),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _open ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  _DetailRow(
                    'Numéro',
                    order.displayCode,
                  ),
                  if (order.items.isNotEmpty)
                    _DetailRow(
                      'Article',
                      order.items
                          .map((e) => '${e.quantity}× ${e.name}')
                          .join(', '),
                    ),
                  _DetailRow(
                    'Conditionnement',
                    order.packagingName ?? 'Sur place',
                  ),
                  _DetailRow(
                    'Montant',
                    CurrencyFormatter.formatTickets(order.totalTickets),
                  ),
                  _DetailRow(
                    'Confirmation',
                    order.status == OrderStatus.autoReceived
                        ? 'Automatique après 1h'
                        : (order.status == OrderStatus.received
                              ? 'Manuelle par l\'étudiant'
                              : '—'),
                  ),
                  if (order.reason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: order.status == OrderStatus.refunded
                            ? AppColors.orangeLight
                            : AppColors.redLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        order.status == OrderStatus.refunded
                            ? 'Remboursement : ${order.reason}'
                            : 'Motif : ${order.reason}',
                        style: TextStyle(
                          fontSize: 13,
                          color: order.status == OrderStatus.refunded
                              ? AppColors.accent
                              : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _historyMeta(OrderModel o) {
    final now = DateTime.now();
    final diff = now.difference(o.createdAt);
    if (diff.inHours < 24) {
      return 'Aujourd\'hui, ${_formatTime(o.createdAt)}';
    }
    if (diff.inDays < 2) {
      return 'Hier, ${_formatTime(o.createdAt)}';
    }
    return _formatDate(o.createdAt);
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime t) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${t.day} ${months[t.month - 1]}';
  }
}

class _CountdownBox extends StatelessWidget {
  final int seconds;
  const _CountdownBox({required this.seconds});
  @override
  Widget build(BuildContext context) {
    final progress = (seconds / 300).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCountdown(seconds),
                  style: AppTextStyles.countdownTime,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réponds avant la fin du délai',
                  style: AppTextStyles.countdownLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  'Passé ce délai, la commande est annulée automatiquement.',
                  style: AppTextStyles.countdownSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int currentStep;
  const _Timeline({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final steps = ['Acceptée', 'Préparation', 'Prête'];
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i + 1 < currentStep;
        final current = i + 1 == currentStep;
        return Expanded(
          child: _TimelineStep(
            label: steps[i],
            state: done
                ? _StepState.done
                : (current ? _StepState.current : _StepState.idle),
            index: i + 1,
            isLast: i == steps.length - 1,
          ),
        );
      }),
    );
  }
}

enum _StepState { done, current, idle }

class _TimelineStep extends StatelessWidget {
  final String label;
  final _StepState state;
  final int index;
  final bool isLast;
  const _TimelineStep({
    required this.label,
    required this.state,
    required this.index,
    required this.isLast,
  });
  @override
  Widget build(BuildContext context) {
    final isDone = state == _StepState.done;
    final isCurrent = state == _StepState.current;
    return Column(
      children: [
        SizedBox(
          height: 21,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isLast)
                Positioned(
                  left: 21,
                  right: 0,
                  top: 10,
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.primary : AppColors.borderLight,
                  ),
                ),
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primary
                      : (isCurrent ? AppColors.accent : AppColors.borderLight),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
                      : Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.tlLabel),
      ],
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  final int seconds;
  const _ReadyBanner({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_rounded, color: AppColors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  seconds > 0
                      ? 'Retrait · ${CurrencyFormatter.formatCountdown(seconds)}'
                      : 'Délai de retrait dépassé',
                  style: AppTextStyles.readyBannerTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'L\'étudiant a été notifié. Le montant est crédité. Sans confirmation sous 1 h, la commande est clôturée automatiquement.',
            style: AppTextStyles.readyBannerSub,
          ),
        ],
      ),
    );
  }
}

class _PickupCodeBanner extends StatelessWidget {
  final String code;
  const _PickupCodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.indigoLight,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Text(
            'Numéro à communiquer',
            style: AppTextStyles.orderMeta,
          ),
          const SizedBox(height: 4),
          Text(
            code,
            style: AppTextStyles.orderNum.copyWith(
              fontSize: 28,
              letterSpacing: 4,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyMessageSheet extends StatefulWidget {
  final String pickupCode;
  const _ReadyMessageSheet({required this.pickupCode});

  @override
  State<_ReadyMessageSheet> createState() => _ReadyMessageSheetState();
}

class _ReadyMessageSheetState extends State<_ReadyMessageSheet> {
  static const _messages = [
    'Ta commande est prête. Tu peux passer la récupérer.',
    'C’est prêt au comptoir. Présente ton numéro de commande.',
    'Commande prête. Tu as 1 heure pour venir la chercher.',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return BottomSheetModal(
      title: 'Prévenir l’étudiant',
      subtitle:
          'Choisis le message envoyé avec le numéro ${widget.pickupCode}. Tes tickets sont crédités à cet instant.',
      chips: _messages,
      selectedChip: _selected,
      onChipSelected: (chip) => setState(() => _selected = chip),
      confirmText: 'Envoyer et marquer prête',
      cancelText: 'Retour',
      isConfirmDanger: false,
      isConfirmOrange: true,
      isConfirmEnabled: _selected != null,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () => Navigator.of(context).pop(_selected),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onPressed;
  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 16),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14.3,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _FilledAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _FilledAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: color.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  const _IconBox({
    required this.icon,
    required this.color,
    required this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 17),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 13.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityDialog extends StatefulWidget {
  final bool isOpen;
  const _AvailabilityDialog({required this.isOpen});
  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  late bool _isOpen = widget.isOpen;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
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
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Statut de la cantine',
              style: AppTextStyles.promptTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les étudiants voient immédiatement le nouveau statut.',
              style: AppTextStyles.promptSub,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Fermée',
                      selected: !_isOpen,
                      onTap: () => setState(() => _isOpen = false),
                    ),
                  ),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Ouverte',
                      selected: _isOpen,
                      onTap: () => setState(() => _isOpen = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _isOpen),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// Re-export the showKabaBottomSheet helper to keep call-sites tidy.
Future<T?> showKbaConfirmDialog<T>(
  BuildContext context, {
  required Widget sheet,
}) {
  return showKabaBottomSheet<T>(context, sheet: sheet);
}
