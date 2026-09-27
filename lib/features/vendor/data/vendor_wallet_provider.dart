import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/transaction_model.dart';

final vendorTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final response = await ref
      .read(apiClientProvider)
      .get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: {'page': 1, 'limit': 100},
      );
  final payload = response.data?['data'];
  return payload is List
      ? payload
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList()
      : <TransactionModel>[];
});
