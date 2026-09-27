import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import 'api_endpoints.dart';
import 'session_state.dart';
import 'token_storage.dart';

enum _RefreshResult { success, rejected, unavailable }

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  final VoidCallback? onSessionExpired;

  ApiClient(this._dio, this._tokenStorage, {this.onSessionExpired}) {
    _setupDio();
  }

  Dio get dio => _dio;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.join('\n');
        }
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Impossible de joindre le serveur. Vérifie ta connexion.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Le serveur met trop de temps à répondre. Réessaie.';
      }
    }
    return 'Une erreur est survenue. Réessaie.';
  }

  void _setupDio() {
    _dio.options.baseUrl = AppConfig.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.addAll([
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = _tokenStorage.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final requestPath = error.requestOptions.path;
          final isPublicAuthRequest = [
            ApiEndpoints.authSendOtp,
            ApiEndpoints.authVerifyOtp,
            ApiEndpoints.authLoginEmail,
          ].any(requestPath.endsWith);
          if (error.response?.statusCode == 401 && !isPublicAuthRequest) {
            final alreadyRetried =
                error.requestOptions.extra['didRefreshAccessToken'] == true;
            final refreshResult = alreadyRetried
                ? _RefreshResult.rejected
                : await _refreshToken();
            if (refreshResult == _RefreshResult.success) {
              final requestOptions = error.requestOptions;
              requestOptions.extra['didRefreshAccessToken'] = true;
              final accessToken = _tokenStorage.getAccessToken();
              requestOptions.headers['Authorization'] = 'Bearer $accessToken';
              try {
                final response = await _dio.fetch(requestOptions);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            } else {
              if (refreshResult == _RefreshResult.rejected) {
                await _clearAuthAndRedirect();
              }
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
  }

  Future<_RefreshResult> _refreshToken() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return _RefreshResult.rejected;

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      final response = await refreshDio.post(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final userId = _tokenStorage.getUserId() ?? '';

        if (newAccessToken != null && newRefreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            userId: userId,
          );
          return _RefreshResult.success;
        }
      }
      return _RefreshResult.rejected;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return _RefreshResult.rejected;
      }
      return _RefreshResult.unavailable;
    } catch (_) {
      return _RefreshResult.unavailable;
    }
  }

  Future<void> _clearAuthAndRedirect() async {
    await _tokenStorage.clearTokens();
    onSessionExpired?.call();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio();
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    dio,
    tokenStorage,
    onSessionExpired: () {
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
});
