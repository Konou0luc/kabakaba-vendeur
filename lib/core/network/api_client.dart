import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../storage/session_store.dart';
import 'api_endpoints.dart';
import 'vendor_http_client.dart';

/// Résultat d'une tentative de renouvellement de session.
enum _RefreshOutcome {
  /// Nouveaux jetons obtenus : la requête d'origine peut être rejouée.
  renewed,

  /// Le serveur a refusé le refresh token : la session est morte.
  rejected,

  /// Échec temporaire (réseau, 5xx) : la session n'est pas invalidée, on
  /// laisse simplement remonter l'erreur d'origine.
  unavailable,
}

/// Client HTTP de l'application.
///
/// Ne réexpose pas les verbes de Dio : un wrapper qui se contente de
/// transmettre ses arguments n'apporte rien et double la surface à maintenir.
/// La valeur est ici dans les intercepteurs (jeton, renouvellement,
/// journalisation) ; les dépôts utilisent `dio` directement.
class ApiClient {
  final Dio dio;
  final SessionStore _sessionStore;

  /// Dio séparé, sans intercepteur, pour le renouvellement : sinon un 401 sur
  /// `/auth/refresh` relancerait un renouvellement, à l'infini.
  final Dio _refreshDio;

  /// Appelé une seule fois quand la session est définitivement perdue.
  final FutureOr<void> Function() onSessionExpired;

  /// Un seul renouvellement à la fois : quand cinq requêtes parallèles
  /// prennent un 401 ensemble, elles doivent partager la même tentative.
  /// Sans ça, la rotation des refresh tokens côté serveur considère les
  /// tentatives concurrentes comme un rejeu de jeton volé et révoque toute la
  /// famille — déconnectant le vendeur en pleine utilisation.
  Future<_RefreshOutcome>? _inFlightRefresh;

  ApiClient({
    required SessionStore sessionStore,
    required this.onSessionExpired,
    Dio? dio,
    Dio? refreshDio,
  }) : _sessionStore = sessionStore,
       dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio() {
    _configure(this.dio, attachAdapter: dio == null);
    _configure(_refreshDio, attachAdapter: refreshDio == null);
    _installInterceptors();
  }

  void _configure(Dio target, {required bool attachAdapter}) {
    if (attachAdapter) attachVendorHttpAdapter(target);
    target.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      ..headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
  }

  void _installInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    if (AppConfig.enableNetworkLogs) {
      // Jamais en release : ces traces contiennent l'en-tête Authorization
      // et les corps de réponse complets.
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          // Les corps d'auth portent mot de passe, OTP et PIN.
          requestBody: false,
          responseBody: true,
          compact: true,
          maxWidth: 100,
        ),
      );
    }
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isPublicAuthPath(options.path)) {
      final accessToken = _sessionStore.snapshot.accessToken;
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;

    final shouldAttemptRefresh =
        error.response?.statusCode == 401 &&
        !_isPublicAuthPath(request.path) &&
        request.extra[_retriedFlag] != true;

    if (!shouldAttemptRefresh) return handler.next(error);

    final outcome = await _refreshSession();

    switch (outcome) {
      case _RefreshOutcome.renewed:
        try {
          handler.resolve(await _replay(request));
        } on DioException catch (replayError) {
          handler.next(replayError);
        }
      case _RefreshOutcome.rejected:
        await _sessionStore.clearTokens();
        await onSessionExpired();
        handler.next(error);
      case _RefreshOutcome.unavailable:
        handler.next(error);
    }
  }

  Future<Response<dynamic>> _replay(RequestOptions request) {
    final accessToken = _sessionStore.snapshot.accessToken;
    return dio.fetch(
      request
        ..extra[_retriedFlag] = true
        ..headers['Authorization'] = 'Bearer $accessToken',
    );
  }

  Future<_RefreshOutcome> _refreshSession() {
    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<_RefreshOutcome> _performRefresh() async {
    final refreshToken = _sessionStore.snapshot.refreshToken;
    if (refreshToken == null) return _RefreshOutcome.rejected;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      final accessToken = response.data?['accessToken'] as String?;
      final renewedRefreshToken = response.data?['refreshToken'] as String?;
      if (accessToken == null || renewedRefreshToken == null) {
        return _RefreshOutcome.rejected;
      }

      await _sessionStore.saveTokens(
        accessToken: accessToken,
        refreshToken: renewedRefreshToken,
      );
      return _RefreshOutcome.renewed;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      // 401/403 : le serveur a tranché, la session est perdue. Tout le reste
      // (coupure réseau, 502 de Vercel au réveil…) est passager et ne doit
      // pas déconnecter le vendeur.
      return status == 401 || status == 403
          ? _RefreshOutcome.rejected
          : _RefreshOutcome.unavailable;
    }
  }

  static const _retriedFlag = 'kabakaba.didRetryAfterRefresh';

  static bool _isPublicAuthPath(String path) =>
      ApiEndpoints.publicAuthPaths.any(path.endsWith);
}

/// Passe à `true` quand l'API a rejeté à la fois le jeton d'accès et son
/// jeton de renouvellement. Le routeur écoute cet état pour renvoyer vers
/// l'écran de connexion.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    sessionStore: ref.watch(sessionStoreProvider),
    onSessionExpired: () {
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
});
