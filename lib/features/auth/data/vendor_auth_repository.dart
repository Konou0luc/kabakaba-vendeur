import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../../../shared/models/auth_models.dart';
import '../../../shared/models/vendor_model.dart';

abstract class VendorAuthRepository {
  Future<Map<String, dynamic>> sendOtp(String phone);
  Future<AuthResponse> verifyOtp(String phone, String code);
  Future<VendorModel> getVendorProfile();
  Future<void> toggleAvailability(bool isOpen);
  Future<void> logout();
  bool hasTokens();
  bool get hasPinSet;
  String? getLastPhone();
  Future<void> saveLastPhone(String phone);
}

class VendorAuthRepositoryImpl implements VendorAuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  VendorAuthRepositoryImpl(this._apiClient, this._tokenStorage);

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authSendOtp,
        data: {'phone': phone},
      );
      await _tokenStorage.saveLastPhone(phone);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<AuthResponse> verifyOtp(String phone, String code) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authVerifyOtp,
        data: {'phone': phone, 'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      if (user?['role'] != 'VENDOR') {
        throw Exception(
          'Ce numéro n’est pas associé à un compte vendeur. Demande à un administrateur de créer le compte vendeur avant de te connecter.',
        );
      }
      final vendorId = user?['id'] as String? ?? '';
      final auth = AuthResponse(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        vendorId: vendorId,
      );
      await _tokenStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: vendorId,
        vendorId: vendorId,
      );
      return auth;
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<VendorModel> getVendorProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vendorsMe);
      return VendorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<void> toggleAvailability(bool isOpen) async {
    try {
      await _apiClient.patch(ApiEndpoints.vendorsMe, data: {'isOpen': isOpen});
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.authLogout);
    } catch (_) {
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  @override
  bool hasTokens() => _tokenStorage.hasTokens();

  @override
  bool get hasPinSet => _tokenStorage.hasPinSet;

  @override
  String? getLastPhone() => _tokenStorage.getLastPhone();

  @override
  Future<void> saveLastPhone(String phone) =>
      _tokenStorage.saveLastPhone(phone);
}

final vendorAuthRepositoryProvider = Provider<VendorAuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return VendorAuthRepositoryImpl(apiClient, tokenStorage);
});
