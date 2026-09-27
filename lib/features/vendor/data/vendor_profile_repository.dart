import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../shared/models/vendor_model.dart';

/// Profil de la cantine : lecture et mise à jour.
abstract interface class VendorProfileRepository {
  Future<VendorModel> fetchProfile();

  /// Ouvre ou ferme la cantine aux commandes.
  Future<VendorModel> setOpen(bool isOpen);

  /// Champs modifiables par le vendeur lui-même, tels qu'acceptés par
  /// `PATCH /vendors/me`.
  Future<VendorModel> updateProfile({
    String? canteenName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
  });
}

class VendorProfileRepositoryImpl implements VendorProfileRepository {
  final Dio _dio;

  VendorProfileRepositoryImpl(ApiClient apiClient) : _dio = apiClient.dio;

  @override
  Future<VendorModel> fetchProfile() {
    return guardApiCall(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.vendorsMe,
      );
      return VendorModel.fromJson(_requireBody(response));
    });
  }

  @override
  Future<VendorModel> setOpen(bool isOpen) => _patch({'isOpen': isOpen});

  @override
  Future<VendorModel> updateProfile({
    String? canteenName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
  }) {
    // Seuls les champs réellement édités partent : envoyer `null` sur les
    // autres effacerait leur valeur côté serveur.
    return _patch({
      'canteenName': ?canteenName,
      'description': ?description,
      'logoUrl': ?logoUrl,
      'bannerUrl': ?bannerUrl,
    });
  }

  Future<VendorModel> _patch(Map<String, Object?> body) {
    return guardApiCall(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.vendorsMe,
        data: body,
      );
      return VendorModel.fromJson(_requireBody(response));
    });
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const PayloadException('Profil vendeur absent de la réponse');
    }
    return body;
  }
}

final vendorProfileRepositoryProvider = Provider<VendorProfileRepository>((
  ref,
) {
  return VendorProfileRepositoryImpl(ref.watch(apiClientProvider));
});

/// Profil de la cantine courante.
///
/// Source unique du solde et de `withdrawalBlocked` : à invalider après tout
/// mouvement d'argent (retrait, remboursement, passage d'une commande en
/// `READY`) pour que le solde affiché reste celui du serveur.
final currentVendorProvider = FutureProvider<VendorModel>((ref) {
  return ref.watch(vendorProfileRepositoryProvider).fetchProfile();
});
