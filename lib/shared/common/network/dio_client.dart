import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/observability/tracing_interceptor.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/services/auth/session_expiry_service.dart';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthInterceptor extends Interceptor {
  static String? _cachedAccessToken;
  static Future<Map<String, dynamic>?>? _refreshInFlight;

  static String? get cachedAccessToken => _cachedAccessToken;

  static Future<void> cacheAccessToken(String token) async {
    _cachedAccessToken = token;
    SessionExpiryService.markActive();
  }

  static Future<void> clearCachedToken() async {
    _cachedAccessToken = null;
  }

  static Future<Map<String, dynamic>?> refreshTokens(String refreshToken) {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final request = _refreshTokens(refreshToken);
    _refreshInFlight = request;
    request.whenComplete(() => _refreshInFlight = null);
    return request;
  }

  static Future<Map<String, dynamic>?> _refreshTokens(
    String refreshToken,
  ) async {
    final url = ApiUriBuilder.build(ApiConstants.userRefreshToken());
    final response = await Dio(_defaultDioOptions()).post(
      url.toString(),
      data: {'refreshToken': refreshToken},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == HttpStatusCode.ok.code) {
      logger.i('[Auth] Token refreshed successfully');
      SessionExpiryService.markActive();
      return response.data as Map<String, dynamic>?;
    }

    logger.e(
      '[Auth] Token refresh failed: ${response.statusCode}',
      error: response.data,
    );
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _attachAccessToken(options).then(
      (_) => handler.next(options),
      onError: (Object error, StackTrace stackTrace) {
        logger.w(
          '[Dio] Failed to attach access token',
          error: error,
          stackTrace: stackTrace,
        );
        handler.next(options);
      },
    );
  }

  Future<void> _attachAccessToken(RequestOptions options) async {
    String? token = _cachedAccessToken;
    final authBox = await Hive.openBox('auth');

    if (token == null) {
      token = authBox.get('accessToken') as String?;
      if (token != null && token.isNotEmpty) {
        _cachedAccessToken = token;
      }
    }

    if (token != null && token.isNotEmpty && _isJwtExpired(token)) {
      _cachedAccessToken = null;
      final refreshToken = authBox.get('refreshToken') as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshedTokens = await AuthInterceptor.refreshTokens(
          refreshToken,
        );
        token = await _persistRefreshedTokens(authBox, refreshedTokens);
        if (token == null || token.isEmpty) {
          await _clearStoredSession(
            authBox,
            '[Dio] Expired access token could not be refreshed — tokens cleared',
          );
          return;
        }
      } else {
        await _clearStoredSession(
          authBox,
          '[Dio] Expired access token without refresh token — tokens cleared',
        );
        return;
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  bool _isJwtExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  Future<String?> _persistRefreshedTokens(
    Box authBox,
    Map<String, dynamic>? refreshedTokens,
  ) async {
    final newAccessToken = refreshedTokens?['accessToken'] as String?;
    if (newAccessToken == null || newAccessToken.isEmpty) return null;

    _cachedAccessToken = newAccessToken;
    await authBox.put('accessToken', newAccessToken);

    final newRefreshToken = refreshedTokens?['refreshToken'] as String?;
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await authBox.put('refreshToken', newRefreshToken);
    }

    final newIdToken = refreshedTokens?['idToken'] as String?;
    if (newIdToken != null && newIdToken.isNotEmpty) {
      await authBox.put('idToken', newIdToken);
    }

    return newAccessToken;
  }

  Future<void> _clearStoredSession(Box authBox, String message) async {
    _cachedAccessToken = null;
    await authBox.clear();
    logger.w(message);
    unawaited(SessionExpiryService.notifyExpired());
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 403) {
      logger.w('[Dio] 403 Forbidden — access denied');
    }

    if (err.response?.statusCode == 401) {
      _cachedAccessToken = null;

      late final Box authBox;
      try {
        authBox = await Hive.openBox('auth');
      } catch (e, stack) {
        logger.e(
          '[Dio] Failed to open auth box while handling 401',
          error: e,
          stackTrace: stack,
        );
        handler.next(err);
        return;
      }

      final refreshToken = authBox.get('refreshToken') as String?;
      final failedAuthorization =
          err.requestOptions.headers['Authorization'] as String?;

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshedTokens = await AuthInterceptor.refreshTokens(
            refreshToken,
          );
          final newAccessToken = await _persistRefreshedTokens(
            authBox,
            refreshedTokens,
          );
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryDio = Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );
            try {
              final response = await retryDio.fetch(err.requestOptions);
              handler.resolve(response);
            } on DioException catch (retryError) {
              logger.w(
                '[Dio] Request retry failed after token refresh '
                '(status: ${retryError.response?.statusCode})',
              );
              handler.next(retryError);
            }
            return;
          }
        } catch (e, stack) {
          logger.e('[Dio] Token refresh failed', error: e, stackTrace: stack);
        }
      }

      final latestAccessToken = authBox.get('accessToken') as String?;
      if (latestAccessToken != null &&
          latestAccessToken.isNotEmpty &&
          failedAuthorization != 'Bearer $latestAccessToken') {
        _cachedAccessToken = latestAccessToken;
        err.requestOptions.headers['Authorization'] =
            'Bearer $latestAccessToken';
        final retryDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
        try {
          final response = await retryDio.fetch(err.requestOptions);
          handler.resolve(response);
        } on DioException catch (retryError) {
          logger.w(
            '[Dio] Request retry failed with latest token '
            '(status: ${retryError.response?.statusCode})',
          );
          handler.next(retryError);
        }
        return;
      }

      await _clearStoredSession(
        authBox,
        '[Dio] 401 Unauthorized — tokens cleared',
      );
    }

    handler.next(err);
  }
}

Dio createDioClient() {
  final dio = Dio(_defaultDioOptions());
  // Tracing first so its span wraps the auth token work and closes last.
  dio.interceptors.add(TracingInterceptor());
  dio.interceptors.add(AuthInterceptor());
  return dio;
}

Dio createPublicDioClient() {
  final dio = Dio(_defaultDioOptions());
  dio.interceptors.add(TracingInterceptor());
  return dio;
}

BaseOptions _defaultDioOptions() {
  return BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  );
}
