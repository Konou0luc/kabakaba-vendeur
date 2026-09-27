import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/paginated.dart';
import '../../../shared/models/order_model.dart';

/// Regroupement des commandes tel qu'affiché par les onglets.
///
/// Chaque file est une requête filtrée côté serveur, pas un `where` appliqué
/// à une liste locale : c'est ce qui permet de paginer réellement et d'avoir
/// des compteurs justes au-delà des premières commandes.
enum OrderBucket {
  incoming('Nouvelles', [OrderStatus.pending]),
  preparing('Préparation', [OrderStatus.accepted, OrderStatus.inPreparation]),
  ready('Prêtes', [OrderStatus.ready]),
  history('Historique', [
    OrderStatus.received,
    OrderStatus.autoReceived,
    OrderStatus.refused,
    OrderStatus.cancelledVendor,
    OrderStatus.cancelledStudent,
    OrderStatus.refunded,
  ]);

  final String label;
  final List<OrderStatus> statuses;
  const OrderBucket(this.label, this.statuses);

  String get statusesQuery => statuses.map((s) => s.wireValue).join(',');

  /// File où atterrit une commande après changement de statut.
  static OrderBucket? forStatus(OrderStatus status) {
    for (final bucket in OrderBucket.values) {
      if (bucket.statuses.contains(status)) return bucket;
    }
    return null;
  }
}

abstract interface class OrdersRepository {
  Future<Paginated<OrderModel>> fetchOrders({
    required OrderBucket bucket,
    int page,
    int limit,
  });

  /// Change le statut d'une commande (`PATCH /orders/:id`).
  Future<OrderModel> updateStatus(
    String orderId,
    OrderStatus status, {
    String? reason,
  });

  /// Remboursement après remise (`POST /orders/:id/refund`).
  ///
  /// À ne pas confondre avec un refus : cet appel **débite le solde du
  /// vendeur** et, si le solde est insuffisant, ouvre une créance qui bloque
  /// les retraits. Un refus de commande passe par `updateStatus(refused)`.
  Future<void> refund(String orderId, {required String reason});
}

class OrdersRepositoryImpl implements OrdersRepository {
  final Dio _dio;

  OrdersRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<Paginated<OrderModel>> fetchOrders({
    required OrderBucket bucket,
    int page = 1,
    int limit = 20,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.orders,
        queryParameters: {
          'page': page,
          'limit': limit,
          'statuses': bucket.statusesQuery,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Liste de commandes absente de la réponse');
      }
      return Paginated.fromJson(body, OrderModel.fromJson);
    });
  }

  @override
  Future<OrderModel> updateStatus(
    String orderId,
    OrderStatus status, {
    String? reason,
  }) {
    return guardApiCall(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.orderById(orderId),
        data: {
          'status': status.wireValue,
          // Le motif choisi par le vendeur est transmis : il est affiché à
          // l'étudiant et conservé dans l'historique de la commande.
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Commande absente de la réponse');
      }
      return OrderModel.fromJson(body);
    });
  }

  @override
  Future<void> refund(String orderId, {required String reason}) {
    return guardApiCall(() async {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orderRefund(orderId),
        data: {'reason': reason},
      );
    });
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(ref.watch(apiClientProvider));
});

/// Commandes agrégées pour l'écran statistiques.
///
/// Le backend n'expose pas de KPI vendeur : on charge chaque file jusqu'à
/// 100 éléments. Les totaux restent donc une approximation au-delà de ce
/// plafond, mais plus une invention calculée sur les 50 dernières commandes
/// mélangées.
final vendorStatsOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repository = ref.watch(ordersRepositoryProvider);
  final pages = await Future.wait([
    for (final bucket in OrderBucket.values)
      repository.fetchOrders(bucket: bucket, limit: 100),
  ]);
  return [for (final page in pages) ...page.items];
});
