import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated.dart';
import '../../../../shared/models/order_model.dart';
import '../../../vendor/data/vendor_profile_repository.dart';
import '../../data/orders_repository.dart';

/// Une file de commandes, paginée.
///
/// Les mutations sont optimistes : la carte quitte l'écran immédiatement puis
/// l'appel réseau confirme. L'implémentation précédente repassait l'état à
/// `AsyncValue.loading()` à chaque action, ce qui faisait disparaître toute la
/// liste derrière un indicateur plein écran, et une erreur réseau remplaçait
/// la liste par un écran d'erreur.
class VendorOrdersController
    extends FamilyAsyncNotifier<Paginated<OrderModel>, OrderBucket> {
  static const _pageSize = 20;

  OrdersRepository get _repository => ref.read(ordersRepositoryProvider);

  bool _isLoadingMore = false;

  @override
  Future<Paginated<OrderModel>> build(OrderBucket arg) {
    return _repository.fetchOrders(bucket: arg, limit: _pageSize);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _repository.fetchOrders(bucket: arg, limit: _pageSize),
    );
  }

  /// Page suivante, concaténée à la liste courante.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final next = await _repository.fetchOrders(
        bucket: arg,
        page: current.nextPage,
        limit: _pageSize,
      );
      // Une commande insérée côté serveur entre deux pages peut faire
      // réapparaître un élément déjà chargé : `appendPage` déduplique.
      state = AsyncValue.data(
        current.appendPage(next, identify: (order) => order.id),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> accept(String orderId) =>
      _transition(orderId, OrderStatus.accepted);

  /// Refus d'une nouvelle commande : les tickets de l'étudiant sont
  /// recrédités, le solde du vendeur n'est pas touché.
  Future<void> refuse(String orderId, String reason) =>
      _transition(orderId, OrderStatus.refused, reason: reason);

  Future<void> startPreparing(String orderId) =>
      _transition(orderId, OrderStatus.inPreparation);

  /// Passage en « prête » : c'est cette transition qui libère le séquestre
  /// vers le solde de la cantine, d'où l'invalidation du profil.
  Future<void> markReady(String orderId) =>
      _transition(orderId, OrderStatus.ready, refreshesBalance: true);

  Future<void> cancel(String orderId, String reason) => _transition(
    orderId,
    OrderStatus.cancelledVendor,
    reason: reason,
    refreshesBalance: true,
  );

  /// Remboursement après remise : débite le solde du vendeur.
  Future<void> refund(String orderId, String reason) async {
    final rollback = _removeOptimistically(orderId);
    try {
      await _repository.refund(orderId, reason: reason);
      _invalidateOtherBuckets();
      ref.invalidate(currentVendorProvider);
    } catch (_) {
      rollback();
      rethrow;
    }
  }

  Future<void> _transition(
    String orderId,
    OrderStatus target, {
    String? reason,
    bool refreshesBalance = false,
  }) async {
    final destination = OrderBucket.forStatus(target);
    // La commande reste visible si elle ne change pas de file (aucune
    // transition vendeur n'est dans ce cas aujourd'hui, mais la règle évite
    // qu'une carte disparaisse à tort si un statut est ajouté plus tard).
    final rollback = destination == arg
        ? _patchOptimistically(orderId, target)
        : _removeOptimistically(orderId);

    try {
      await _repository.updateStatus(orderId, target, reason: reason);
      if (destination != arg) _invalidateOtherBuckets();
      if (refreshesBalance) ref.invalidate(currentVendorProvider);
    } catch (_) {
      rollback();
      rethrow;
    }
  }

  /// Retire la commande de la file et renvoie de quoi annuler ce retrait.
  void Function() _removeOptimistically(String orderId) {
    final current = state.valueOrNull;
    if (current == null) return () {};

    final index = current.items.indexWhere((order) => order.id == orderId);
    if (index < 0) return () {};

    final removed = current.items[index];
    final remaining = [...current.items]..removeAt(index);
    state = AsyncValue.data(
      Paginated(
        items: remaining,
        page: current.page,
        limit: current.limit,
        // Le compteur d'onglet suit immédiatement, sans attendre le réseau.
        total: current.total > 0 ? current.total - 1 : 0,
        totalPages: current.totalPages,
      ),
    );

    return () {
      final rolledBack = [...state.valueOrNull?.items ?? const <OrderModel>[]]
        ..insert(index.clamp(0, state.valueOrNull?.items.length ?? 0), removed);
      state = AsyncValue.data(current.replaceItems(rolledBack));
    };
  }

  void Function() _patchOptimistically(String orderId, OrderStatus status) {
    final current = state.valueOrNull;
    if (current == null) return () {};

    final updated = current.items
        .map(
          (order) =>
              order.id == orderId ? order.copyWith(status: status) : order,
        )
        .toList();
    state = AsyncValue.data(current.replaceItems(updated));

    return () => state = AsyncValue.data(current);
  }

  /// Rafraîchit les autres files sans toucher à celle-ci, dont l'état vient
  /// d'être ajusté de façon optimiste.
  void _invalidateOtherBuckets() {
    for (final bucket in OrderBucket.values) {
      if (bucket != arg) {
        ref.invalidate(vendorOrdersControllerProvider(bucket));
      }
    }
  }
}

final vendorOrdersControllerProvider =
    AsyncNotifierProvider.family<
      VendorOrdersController,
      Paginated<OrderModel>,
      OrderBucket
    >(VendorOrdersController.new);
