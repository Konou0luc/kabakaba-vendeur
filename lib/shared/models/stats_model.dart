import 'package:flutter/material.dart';

class StatsOverview {
  final num revenue;
  final int orders;
  final num averageCart;
  final num completionRate;
  final num revenueDelta;
  final num ordersDelta;
  final num cartDelta;
  final num completionDelta;

  StatsOverview({
    required this.revenue,
    required this.orders,
    required this.averageCart,
    required this.completionRate,
    this.revenueDelta = 0,
    this.ordersDelta = 0,
    this.cartDelta = 0,
    this.completionDelta = 0,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) => StatsOverview(
    revenue: (json['revenue'] as num? ?? 0),
    orders: (json['orders'] as num? ?? 0).toInt(),
    averageCart: (json['averageCart'] as num? ?? 0),
    completionRate: (json['completionRate'] as num? ?? 0),
    revenueDelta: (json['revenueDelta'] as num? ?? 0),
    ordersDelta: (json['ordersDelta'] as num? ?? 0),
    cartDelta: (json['cartDelta'] as num? ?? 0),
    completionDelta: (json['completionDelta'] as num? ?? 0),
  );
}

class RevenuePoint {
  final String label;
  final num value;
  final bool isPeak;

  RevenuePoint({required this.label, required this.value, this.isPeak = false});

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
    label: (json['label'] ?? '') as String,
    value: (json['value'] as num? ?? 0),
    isPeak: (json['isPeak'] as bool? ?? false),
  );
}

class PerformanceMetric {
  final String title;
  final String subtitle;
  final num percentage;
  final Color Function() colorBuilder;
  final IconData icon;

  PerformanceMetric({
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.colorBuilder,
    required this.icon,
  });
}

class TopItem {
  final int rank;
  final String name;
  final int salesCount;
  final num proportion;

  TopItem({
    required this.rank,
    required this.name,
    required this.salesCount,
    this.proportion = 1.0,
  });

  factory TopItem.fromJson(Map<String, dynamic> json) => TopItem(
    rank: (json['rank'] as num? ?? 0).toInt(),
    name: (json['name'] ?? '') as String,
    salesCount: (json['salesCount'] as num? ?? 0).toInt(),
    proportion: (json['proportion'] as num? ?? 1.0),
  );
}

class AffluencePoint {
  final String hour;
  final num orders;
  final bool isPeak;

  AffluencePoint({
    required this.hour,
    required this.orders,
    this.isPeak = false,
  });
}

class Insight {
  final String text;
  final IconData icon;

  Insight({required this.text, this.icon = Icons.lightbulb_rounded});
}
