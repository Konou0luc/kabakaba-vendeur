import 'package:dio/dio.dart';

enum ApiErrorKind {
  /// Pas de réseau, DNS en échec, serveur injoignable.
  offline,
  timeout,

  /// 401 : session expirée ou identifiants refusés.
  unauthenticated,

  /// 403 : compte suspendu, PIN verrouillé, action interdite au vendeur.
  forbidden,
  notFound,

  /// 400 / 422 : la requête a été refusée pour une raison métier.
  invalidRequest,
  conflict,

  /// 429 : trop de requêtes (throttling côté API).
  tooManyRequests,
  server,
  cancelled,
  unknown,
}

/// Erreur d'API normalisée.
///
/// Toute la couche données ne remonte que ce type : les widgets n'ont jamais à
/// connaître `DioException`, ni à fouiller un corps de réponse pour trouver un
/// message. `message` est déjà rédigé en français et affichable tel quel.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  /// `requestId` renvoyé par l'API, à citer dans un signalement de bug.
  final String? requestId;

  /// Messages de validation détaillés (`message` est alors un résumé).
  final List<String> details;

  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.requestId,
    this.details = const [],
  });

  bool get isRetryable =>
      kind == ApiErrorKind.offline ||
      kind == ApiErrorKind.timeout ||
      kind == ApiErrorKind.server;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final body = response?.data;
    final parsed = body is Map<String, dynamic> ? body : const {};

    final requestId =
        parsed['requestId'] as String? ??
        response?.headers.value('x-request-id');

    final details = _extractDetails(parsed['message']);
    final serverMessage = details.length == 1 ? details.first : null;

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return ApiException(
          kind: ApiErrorKind.offline,
          message:
              'Impossible de joindre le serveur. Vérifie ta connexion internet.',
          requestId: requestId,
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          kind: ApiErrorKind.timeout,
          message: 'Le serveur met trop de temps à répondre. Réessaie.',
          requestId: requestId,
        );
      case DioExceptionType.cancel:
        return ApiException(
          kind: ApiErrorKind.cancelled,
          message: 'Requête annulée.',
          requestId: requestId,
        );
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.unknown:
        // Cronet / JNI renvoie parfois `type: unknown` et `message: null`
        // sans réponse HTTP : ce n'est pas une erreur métier.
        if (response == null) {
          return ApiException(
            kind: ApiErrorKind.offline,
            message:
                'Impossible de joindre le serveur. Vérifie ta connexion internet.',
            requestId: requestId,
          );
        }
    }

    final kind = _kindFromStatus(statusCode);
    return ApiException(
      kind: kind,
      message: serverMessage ?? _fallbackMessage(kind),
      statusCode: statusCode,
      requestId: requestId,
      details: details,
    );
  }

  static ApiErrorKind _kindFromStatus(int? statusCode) => switch (statusCode) {
    400 || 422 => ApiErrorKind.invalidRequest,
    401 => ApiErrorKind.unauthenticated,
    403 => ApiErrorKind.forbidden,
    404 => ApiErrorKind.notFound,
    409 => ApiErrorKind.conflict,
    429 => ApiErrorKind.tooManyRequests,
    _ when statusCode != null && statusCode >= 500 => ApiErrorKind.server,
    _ => ApiErrorKind.unknown,
  };

  static String _fallbackMessage(ApiErrorKind kind) => switch (kind) {
    ApiErrorKind.invalidRequest => 'Les informations envoyées sont invalides.',
    ApiErrorKind.unauthenticated =>
      'Ta session a expiré. Reconnecte-toi pour continuer.',
    ApiErrorKind.forbidden => 'Cette action ne t’est pas autorisée.',
    ApiErrorKind.notFound => 'Élément introuvable.',
    ApiErrorKind.conflict =>
      'Cette opération est en conflit avec l’état actuel.',
    ApiErrorKind.tooManyRequests =>
      'Trop de tentatives. Patiente un instant avant de réessayer.',
    ApiErrorKind.server =>
      'Le serveur a rencontré une erreur. Réessaie dans un instant.',
    _ => 'Une erreur est survenue. Réessaie.',
  };

  /// `message` vaut une chaîne (erreur métier) ou un tableau (validation
  /// `class-validator`) selon la route appelée.
  static List<String> _extractDetails(Object? message) {
    if (message is String && message.isNotEmpty) return [message];
    if (message is List) {
      return message
          .whereType<Object>()
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  String toString() =>
      'ApiException(${kind.name}, status: $statusCode, requestId: $requestId): $message';
}

/// Convertit toute `DioException` échappée d'un appel en `ApiException`, en
/// préservant la pile d'origine pour ne pas perdre le point d'appel réel.
Future<T> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error, stackTrace) {
    Error.throwWithStackTrace(ApiException.fromDio(error), stackTrace);
  }
}
