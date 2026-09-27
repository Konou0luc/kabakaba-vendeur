import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/storage/session_store.dart';
import '../domain/vendor_session.dart';

/// Accès aux routes d'authentification vendeur.
///
/// Seul endroit de l'app qui connaît la forme des corps de requête et de
/// réponse de `/auth/vendor/*`, et seul endroit qui écrit dans `SessionStore`.
abstract interface class VendorAuthRepository {
  /// Étape 1 : valide téléphone + mot de passe et déclenche l'envoi de l'OTP.
  Future<ActivationChallenge> startActivation({
    required String phone,
    required String password,
  });

  /// Renvoie un nouveau code SMS pour l'activation en cours. Le jeton d'étape
  /// suffit : le mot de passe n'a pas à être conservé côté client.
  Future<ActivationChallenge> resendActivationOtp({
    required String onboardingToken,
    required String phone,
  });

  /// Étape 2 : vérifie le code reçu par SMS.
  Future<PinSetupGrant> verifyActivationOtp({
    required String onboardingToken,
    required String code,
  });

  /// Étape 3 : pose le code PIN et ouvre la session.
  Future<VendorSession> completeActivation({
    required String pinSetupToken,
    required String pin,
    required String phone,
  });

  /// Connexions suivantes.
  Future<VendorSession> loginWithPin({
    required String phone,
    required String pin,
  });

  /// Ferme la session en conservant le numéro et l'existence du PIN, pour que
  /// la reconnexion se fasse au PIN seul.
  Future<void> logout();

  /// Oublie l'appareil : la prochaine connexion repassera par l'activation.
  Future<void> forgetDevice();
}

class VendorAuthRepositoryImpl implements VendorAuthRepository {
  final Dio _dio;
  final SessionStore _sessionStore;

  VendorAuthRepositoryImpl(ApiClient apiClient, this._sessionStore)
    : _dio = apiClient.dio;

  @override
  Future<ActivationChallenge> startActivation({
    required String phone,
    required String password,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorActivateStart,
        data: {'phone': phone, 'password': password},
      );
      final body = _requireBody(response);
      return ActivationChallenge(
        onboardingToken: body.requireString('onboardingToken'),
        phoneMasked: body.stringOr('phoneMasked', phone),
        pinLength: body.intOr('pinLength', 4),
      );
    });
  }

  @override
  Future<ActivationChallenge> resendActivationOtp({
    required String onboardingToken,
    required String phone,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorActivateResendOtp,
        data: {'onboardingToken': onboardingToken},
      );
      final body = _requireBody(response);
      return ActivationChallenge(
        // Le serveur renvoie un jeton rafraîchi : c'est celui-ci qu'il faut
        // conserver, l'ancien pouvant expirer avant le nouveau code.
        onboardingToken: body.requireString('onboardingToken'),
        phoneMasked: body.stringOr('phoneMasked', phone),
        pinLength: body.intOr('pinLength', 4),
      );
    });
  }

  @override
  Future<PinSetupGrant> verifyActivationOtp({
    required String onboardingToken,
    required String code,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorActivateVerifyOtp,
        data: {'onboardingToken': onboardingToken, 'code': code},
      );
      final body = _requireBody(response);
      return PinSetupGrant(
        pinSetupToken: body.requireString('pinSetupToken'),
        pinLength: body.intOr('pinLength', 4),
      );
    });
  }

  @override
  Future<VendorSession> completeActivation({
    required String pinSetupToken,
    required String pin,
    required String phone,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorActivateSetPin,
        data: {'pinSetupToken': pinSetupToken, 'pin': pin},
      );
      return _openSession(_requireBody(response), phone: phone);
    });
  }

  @override
  Future<VendorSession> loginWithPin({
    required String phone,
    required String pin,
  }) {
    return guardApiCall(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vendorLoginPin,
        data: {'phone': phone, 'pin': pin},
      );
      return _openSession(_requireBody(response), phone: phone);
    });
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.authLogout);
    } on DioException {
      // La révocation côté serveur est un bonus : si le réseau est coupé, la
      // déconnexion locale doit aboutir quand même. Le refresh token
      // restant expirera de lui-même sous 7 jours.
    } finally {
      await _sessionStore.clearTokens();
    }
  }

  @override
  Future<void> forgetDevice() async {
    await logout();
    await _sessionStore.forgetVendor();
  }

  /// Enregistre les jetons puis mémorise le numéro et le fait qu'un PIN
  /// existe désormais pour cet appareil.
  Future<VendorSession> _openSession(
    Map<String, dynamic> body, {
    required String phone,
  }) async {
    final user = body.nested('user');
    final vendor = body.nested('vendor');

    await _sessionStore.saveTokens(
      accessToken: body.requireString('accessToken'),
      refreshToken: body.requireString('refreshToken'),
      userId: user?.optionalString('id'),
      vendorId: vendor?.optionalString('id'),
    );
    await _sessionStore.rememberVendor(phone: phone, pinConfigured: true);

    return VendorSession(
      userId: user?.stringOr('id', '') ?? '',
      vendorId: vendor?.stringOr('id', '') ?? '',
      canteenName: vendor?.stringOr('canteenName', 'Ma cantine') ?? 'Ma cantine',
      phone: phone,
    );
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const PayloadException('Réponse vide du serveur d’authentification');
    }
    return body;
  }
}

final vendorAuthRepositoryProvider = Provider<VendorAuthRepository>((ref) {
  return VendorAuthRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  );
});
