import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_tabs.dart';
import '../../../../shared/widgets/vendor_header.dart';
import '../../../orders/data/orders_repository.dart';
import '../../data/vendor_profile_repository.dart';

class VendorStatsPage extends ConsumerStatefulWidget {
  const VendorStatsPage({super.key});
  @override
  ConsumerState<VendorStatsPage> createState() => _VendorStatsPageState();
}

class _VendorStatsPageState extends ConsumerState<VendorStatsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorStatsOrdersProvider);
    final vendor = ref.watch(currentVendorProvider);
    return Column(
      children: [
        VendorHeader(vendor: vendor.value),
        SectionTabs(
          tabs: const [
            TabItem(label: "Vue d'ensemble"),
            TabItem(label: 'Performance'),
            TabItem(label: 'Top articles'),
            TabItem(label: 'Affluence'),
          ],
          selectedIndex: _tab,
          onTabSelected: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Statistiques indisponibles')),
            data: (orders) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [..._buildBody(orders, _tab)],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBody(List<OrderModel> orders, int tab) {
    switch (tab) {
      case 0:
        return _overviewBody(orders);
      case 1:
        return _performanceBody(orders);
      case 2:
        return _topItemsBody(orders);
      case 3:
        return _affluenceBody(orders);
      default:
        return [];
    }
  }

  List<Widget> _overviewBody(List<OrderModel> orders) {
    final done = orders.where((o) => o.status.isCompleted).toList();
    final revenue = done.fold<double>(0, (s, o) => s + o.escrowAmount);
    final avg = done.isEmpty ? 0 : (revenue / done.length).round();
    final completionRate = orders.isEmpty
        ? 0
        : ((done.length / orders.length) * 100).round();
    final metrics = [
      _Metric(
        label: "Chiffre d'affaires",
        value: CurrencyFormatter.formatTickets(revenue),
        icon: Icons.payments_rounded,
      ),
      _Metric(
        label: 'Commandes',
        value: orders.length.toString(),
        icon: Icons.receipt_long_rounded,
      ),
      _Metric(
        label: 'Panier moyen',
        value: CurrencyFormatter.formatTickets(avg),
        icon: Icons.shopping_bag_rounded,
      ),
      _Metric(
        label: 'Taux de complétion',
        value: '$completionRate%',
        icon: Icons.percent_rounded,
      ),
    ];
    return [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.28,
        children: metrics.map((m) => _MetricCard(metric: m)).toList(),
      ),
      const SizedBox(height: 14),
    ];
  }

  List<Widget> _performanceBody(List<OrderModel> orders) {
    final accepted = orders
        .where(
          (o) =>
              o.status == OrderStatus.accepted ||
              o.status == OrderStatus.inPreparation ||
              o.status.isReady ||
              o.status.isCompleted,
        )
        .length;
    final refused = orders.where((o) => o.status == OrderStatus.refused).length;
    final cancelled = orders
        .where((o) => o.status == OrderStatus.cancelledVendor)
        .length;
    final total = orders.isEmpty ? 1 : orders.length;
    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1B2A6B),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _PerfRow(
              title: "Taux d'acceptation",
              sub: '$accepted commandes acceptées sur ${orders.length} reçues',
              percentage: ((accepted / total) * 100).round(),
            ),
            const Divider(height: 1, color: AppColors.borderLight, indent: 14),
            _PerfRow(
              title: 'Taux de refus',
              sub: '$refused commandes refusées',
              percentage: ((refused / total) * 100).round(),
              warn: true,
            ),
            const Divider(height: 1, color: AppColors.borderLight, indent: 14),
            _PerfRow(
              title: 'Annulation après acceptation',
              sub: '$cancelled commande annulée en cours de préparation',
              percentage: ((cancelled / total) * 100).round(),
              warn: true,
            ),
            const Divider(height: 1, color: AppColors.borderLight, indent: 14),
          ],
        ),
      ),
    ];
  }

  List<Widget> _topItemsBody(List<OrderModel> orders) {
    final counts = <String, int>{};
    for (final o in orders) {
      for (final it in o.items) {
        counts.update(
          it.name,
          (v) => v + it.quantity,
          ifAbsent: () => it.quantity,
        );
      }
    }
    if (counts.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: EmptyState(
            title: 'Pas encore de ventes',
            subtitle: 'Les articles les plus commandés apparaîtront ici.',
            icon: Icons.bar_chart_rounded,
            framed: true,
          ),
        ),
      ];
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxV = top.first.value;
    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1B2A6B),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: List.generate(top.length, (i) {
            final entry = top[i];
            return _RankRow(
              rank: i + 1,
              name: entry.key,
              count: entry.value,
              ratio: entry.value / maxV,
            );
          }),
        ),
      ),
    ];
  }

  List<Widget> _affluenceBody(List<OrderModel> orders) {
    final byHour = <int, int>{};
    for (final o in orders) {
      byHour.update(o.createdAt.hour, (v) => v + 1, ifAbsent: () => 1);
    }
    final hours = List.generate(11, (i) => i + 8);
    final maxV = byHour.values.fold<int>(0, (a, b) => a > b ? a : b);
    final values = hours.map((h) => byHour[h] ?? 0).toList();
    final labels = hours.map((h) => '${h}h').toList();
    final peakIndex = values.indexOf(maxV);
    return [
      _BarChartCard(
        title: 'Commandes par heure',
        subtitle: 'Commandes chargées, de 8h à 18h',
        peakIndex: maxV == 0 ? -1 : peakIndex,
        values: values,
        labels: labels,
      ),
    ];
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  _Metric({required this.label, required this.value, required this.icon});
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.indigoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(metric.label, style: AppTextStyles.metricLabel),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: AppTextStyles.metricValue.copyWith(fontSize: 17),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int peakIndex;
  final List<int> values;
  final List<String> labels;
  const _BarChartCard({
    required this.title,
    required this.subtitle,
    required this.peakIndex,
    required this.values,
    required this.labels,
  });
  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.chartTitle),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.chartSub),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final v = values[i];
                final ratio = maxV == 0 ? 0.0 : v / maxV;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: 100 * ratio,
                        decoration: BoxDecoration(
                          color: peakIndex >= 0 && i == peakIndex
                              ? AppColors.accent
                              : AppColors.indigoLight,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(labels[i], style: AppTextStyles.barHour),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  final String title;
  final String sub;
  final int percentage;
  final bool warn;
  const _PerfRow({
    required this.title,
    required this.sub,
    required this.percentage,
    this.warn = false,
  });
  @override
  Widget build(BuildContext context) {
    final pct = '$percentage%';
    final color = warn ? AppColors.accent : AppColors.green;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 4,
                    backgroundColor: AppColors.grayLight,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(pct, style: AppTextStyles.perfPct),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.perfTitle),
                Text(sub, style: AppTextStyles.perfSub, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int count;
  final double ratio;
  const _RankRow({
    required this.rank,
    required this.name,
    required this.count,
    required this.ratio,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.accent : AppColors.grayLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.rankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: AppTextStyles.rankCount),
              Text('ventes', style: AppTextStyles.rankCountSmall),
            ],
          ),
        ],
      ),
    );
  }
}
