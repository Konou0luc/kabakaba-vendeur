import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';

abstract interface class DevicesRepository {
  Future<void> register({required String deviceToken, required String platform});

  Future<void> unregister(String deviceToken);
}

class DevicesRepositoryImpl implements DevicesRepository {
  final Dio _dio;

  DevicesRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<void> register({
    required String deviceToken,
    required String platform,
  }) {
    return guardApiCall(() async {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.devices,
        data: {'deviceToken': deviceToken, 'platform': platform},
      );
    });
  }

  @override
  Future<void> unregister(String deviceToken) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.devices,
        queryParameters: {'deviceToken': deviceToken},
      );
    } catch (_) {}
  }
}

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepositoryImpl(ref.watch(apiClientProvider));
});
