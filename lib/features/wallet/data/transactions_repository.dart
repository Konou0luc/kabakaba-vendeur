import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/paginated.dart';
import '../../../shared/models/transaction_model.dart';

abstract interface class TransactionsRepository {
  Future<Paginated<TransactionModel>> fetchTransactions({int page, int limit});
}

class TransactionsRepositoryImpl implements TransactionsRepository {
  final Dio _dio;

  TransactionsRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<Paginated<TransactionModel>> fetchTransactions({
    int page = 1,
    int limit = 20,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Historique absent de la réponse');
      }
      return Paginated.fromJson(body, TransactionModel.fromJson);
    });
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepositoryImpl(ref.watch(apiClientProvider));
});

/// Derniers mouvements, pour l'aperçu du portefeuille.
final recentTransactionsProvider = FutureProvider<Paginated<TransactionModel>>((
  ref,
) {
  return ref
      .watch(transactionsRepositoryProvider)
      .fetchTransactions(limit: 10);
});

/// Historique complet, paginé.
class TransactionHistoryController
    extends AsyncNotifier<Paginated<TransactionModel>> {
  static const _pageSize = 20;
  bool _isLoadingMore = false;

  TransactionsRepository get _repository =>
      ref.read(transactionsRepositoryProvider);

  @override
  Future<Paginated<TransactionModel>> build() {
    return _repository.fetchTransactions(limit: _pageSize);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _repository.fetchTransactions(limit: _pageSize),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final next = await _repository.fetchTransactions(
        page: current.nextPage,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        current.appendPage(next, identify: (item) => item.id),
      );
    } finally {
      _isLoadingMore = false;
    }
  }
}

final transactionHistoryControllerProvider =
    AsyncNotifierProvider<
      TransactionHistoryController,
      Paginated<TransactionModel>
    >(TransactionHistoryController.new);
