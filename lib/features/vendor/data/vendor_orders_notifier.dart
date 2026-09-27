import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/order_model.dart';

class VendorOrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  ApiClient get _repo => ref.read(apiClientProvider);

  @override
  Future<List<OrderModel>> build() => _fetch();

  Future<List<OrderModel>> _fetch() async {
    final response = await _repo.get(
      ApiEndpoints.orders,
      queryParameters: {'page': 1, 'limit': 50},
    );
    final raw = response.data;
    final list = raw is Map ? raw['data'] ?? raw : raw;
    return (list as List? ?? const [])
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> accept(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.patch(
        ApiEndpoints.orderById(id),
        data: {'status': 'ACCEPTED'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refuse(String id, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repo.post(
        '${ApiEndpoints.orderById(id)}/refund',
        data: {'reason': reason},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> cancel(String id, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repo.patch(
        ApiEndpoints.orderById(id),
        data: {'status': 'CANCELLED_VENDOR'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markPreparing(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.patch(
        ApiEndpoints.orderById(id),
        data: {'status': 'IN_PREPARATION'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markReady(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.patch(
        ApiEndpoints.orderById(id),
        data: {'status': 'READY'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refund(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.post(
        '${ApiEndpoints.orderById(id)}/refund',
        data: {'reason': 'Remboursement vendeur'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> confirmReceived(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.patch(
        ApiEndpoints.orderById(id),
        data: {'status': 'RECEIVED'},
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final vendorOrdersNotifierProvider =
    AsyncNotifierProvider<VendorOrdersNotifier, List<OrderModel>>(
  VendorOrdersNotifier.new,
);
