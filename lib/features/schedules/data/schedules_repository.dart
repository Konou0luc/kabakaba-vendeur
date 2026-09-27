import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../vendor/data/vendor_profile_repository.dart';
import '../domain/vendor_schedule.dart';

abstract interface class SchedulesRepository {
  Future<List<VendorSchedule>> fetchAll(String vendorId);

  Future<VendorSchedule> create({
    required String vendorId,
    required Weekday day,
    required String startTime,
    required String endTime,
  });

  Future<void> delete({required String vendorId, required String scheduleId});
}

class SchedulesRepositoryImpl implements SchedulesRepository {
  final Dio _dio;

  SchedulesRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<List<VendorSchedule>> fetchAll(String vendorId) {
    return guardApiCall(() async {
      final response = await _dio.get(ApiEndpoints.vendorSchedules(vendorId));
      final raw = response.data;
      final list = raw is List
          ? raw
          : raw is Map
          ? raw['data']
          : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((item) => VendorSchedule.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    });
  }

  @override
  Future<VendorSchedule> create({
    required String vendorId,
    required Weekday day,
    required String startTime,
    required String endTime,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorSchedules(vendorId),
        data: {
          'day': day.wireValue,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Plage horaire absente de la réponse');
      }
      return VendorSchedule.fromJson(body);
    });
  }

  @override
  Future<void> delete({
    required String vendorId,
    required String scheduleId,
  }) {
    return guardApiCall(() async {
      await _dio.delete(ApiEndpoints.vendorScheduleById(vendorId, scheduleId));
    });
  }
}

final schedulesRepositoryProvider = Provider<SchedulesRepository>((ref) {
  return SchedulesRepositoryImpl(ref.watch(apiClientProvider));
});

final vendorSchedulesProvider = FutureProvider<List<VendorSchedule>>((
  ref,
) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  return ref.watch(schedulesRepositoryProvider).fetchAll(vendor.id);
});
