import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/paginated.dart';
import '../../vendor/data/vendor_profile_repository.dart';
import '../domain/menu_item.dart';

abstract interface class CatalogRepository {
  Future<Paginated<MenuItemModel>> fetchMenu({
    required String vendorId,
    int page,
    int limit,
  });

  Future<MenuItemModel> createItem({
    required String vendorId,
    required String name,
    String? description,
    required int priceTickets,
    int? preparationTime,
  });

  Future<MenuItemModel> setAvailable(String itemId, bool isAvailable);

  Future<void> deleteItem(String itemId);
}

class CatalogRepositoryImpl implements CatalogRepository {
  final Dio _dio;

  CatalogRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<Paginated<MenuItemModel>> fetchMenu({
    required String vendorId,
    int page = 1,
    int limit = 50,
  }) {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.menuItems,
        queryParameters: {
          'vendorId': vendorId,
          'page': page,
          'limit': limit,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Menu absent de la réponse');
      }
      return Paginated.fromJson(body, MenuItemModel.fromJson);
    });
  }

  @override
  Future<MenuItemModel> createItem({
    required String vendorId,
    required String name,
    String? description,
    required int priceTickets,
    int? preparationTime,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.menuItems,
        data: {
          'vendorId': vendorId,
          'name': name,
          'type': MenuItemType.fixed.wireValue,
          'priceTickets': priceTickets,
          'description': ?description,
          'preparationTime': ?preparationTime,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Article créé introuvable dans la réponse');
      }
      return MenuItemModel.fromJson(body);
    });
  }

  @override
  Future<MenuItemModel> setAvailable(String itemId, bool isAvailable) {
    return guardApiCall(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.menuItemById(itemId),
        data: {'isAvailable': isAvailable},
      );
      final body = response.data;
      if (body == null) {
        throw const PayloadException('Article mis à jour introuvable');
      }
      return MenuItemModel.fromJson(body);
    });
  }

  @override
  Future<void> deleteItem(String itemId) {
    return guardApiCall(() async {
      await _dio.delete(ApiEndpoints.menuItemById(itemId));
    });
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(ref.watch(apiClientProvider));
});

final vendorMenuProvider = FutureProvider<Paginated<MenuItemModel>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  return ref
      .watch(catalogRepositoryProvider)
      .fetchMenu(vendorId: vendor.id, limit: 50);
});
