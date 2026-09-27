import 'package:flutter/foundation.dart';

/// Page de résultats renvoyée par l'API.
///
/// Toutes les routes de liste répondent `{ data: [...], meta: { page, limit,
/// total, totalPages } }`. Transporter `meta` jusqu'à l'UI est ce qui permet
/// un vrai défilement infini : sans lui, on ne peut que deviner s'il reste des
/// pages, et c'est ainsi qu'on se retrouve avec un `limit: 50` figé.
@immutable
class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  const Paginated.empty()
    : items = const [],
      page = 1,
      limit = 0,
      total = 0,
      totalPages = 0;

  bool get hasMore => page < totalPages;
  int get nextPage => page + 1;
  bool get isEmpty => items.isEmpty;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) parse,
  ) {
    final rawItems = json['data'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => parse(Map<String, dynamic>.from(item)))
              .toList()
        : <T>[];

    final meta = json['meta'];
    if (meta is! Map) {
      // Route sans enveloppe de pagination : on considère la réponse comme
      // une page unique complète plutôt que d'inventer des totaux.
      return Paginated(
        items: items,
        page: 1,
        limit: items.length,
        total: items.length,
        totalPages: 1,
      );
    }

    final total = _asInt(meta['total']) ?? items.length;
    final limit = _asInt(meta['limit']) ?? items.length;
    return Paginated(
      items: items,
      page: _asInt(meta['page']) ?? 1,
      limit: limit,
      total: total,
      totalPages:
          _asInt(meta['totalPages']) ??
          (limit > 0 ? (total / limit).ceil() : 1),
    );
  }

  /// Concatène la page suivante en conservant l'ordre et en écartant les
  /// doublons, qu'une insertion côté serveur entre deux pages peut produire.
  Paginated<T> appendPage(
    Paginated<T> next, {
    required Object Function(T item) identify,
  }) {
    final seen = items.map(identify).toSet();
    return Paginated(
      items: [
        ...items,
        ...next.items.where((item) => seen.add(identify(item))),
      ],
      page: next.page,
      limit: next.limit,
      total: next.total,
      totalPages: next.totalPages,
    );
  }

  Paginated<T> replaceItems(List<T> updated) {
    return Paginated(
      items: updated,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static int? _asInt(Object? value) => switch (value) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}
