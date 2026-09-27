import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/paginated.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<Paginated<AppNotification>> fetchAll({int page, int limit});

  Future<void> markRead(String id);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final Dio _dio;

  NotificationsRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<Paginated<AppNotification>> fetchAll({
    int page = 1,
    int limit = 30,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Notifications absentes de la réponse');
      }
      return Paginated.fromJson(body, AppNotification.fromJson);
    });
  }

  @override
  Future<void> markRead(String id) {
    return guardApiCall(() async {
      await _dio.patch(
        ApiEndpoints.notificationById(id),
        data: {'isRead': true},
      );
    });
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(ref.watch(apiClientProvider));
});

final vendorNotificationsProvider = FutureProvider<Paginated<AppNotification>>((
  ref,
) {
  return ref.watch(notificationsRepositoryProvider).fetchAll();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref
          .watch(vendorNotificationsProvider)
          .valueOrNull
          ?.items
          .where((item) => !item.isRead)
          .length ??
      0;
});
