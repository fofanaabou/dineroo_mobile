import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/services/auth/session_expiry_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;
  late HttpServer server;
  late String baseUrl;
  late int refreshRequests;
  late List<String?> protectedAuthorizations;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('dio_client_test_');
    Hive.init(hiveDir.path);
    await AuthInterceptor.clearCachedToken();
    refreshRequests = 0;
    protectedAuthorizations = [];
  });

  tearDown(() async {
    await server.close(force: true);
    await Hive.close();
    await AuthInterceptor.clearCachedToken();
    SessionExpiryService.reset();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  Future<void> startServer(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.host}:${server.port}';
    dotenv.testLoad(fileInput: 'API_BASE_URL=$baseUrl');
    unawaited(() async {
      await for (final request in server) {
        await handler(request);
      }
    }());
  }

  String jwtWithExpiration(DateTime expiration) {
    String encodePart(Map<String, dynamic> part) =>
        base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

    return '${encodePart({'alg': 'none'})}.${encodePart({'exp': expiration.millisecondsSinceEpoch ~/ 1000})}.';
  }

  test('adds the stored access token to outgoing requests', () async {
    await startServer((request) {
      protectedAuthorizations.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true}));
      return request.response.close();
    });
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', 'stored-token');

    final response = await createDioClient().get('$baseUrl/protected');

    expect(response.statusCode, HttpStatus.ok);
    expect(protectedAuthorizations, ['Bearer stored-token']);
    expect(AuthInterceptor.cachedAccessToken, 'stored-token');
  });

  test('refreshes tokens on 401 and retries the original request', () async {
    await startServer((request) async {
      if (request.uri.path == '/v1/users/token/refresh') {
        refreshRequests++;
        final body = await utf8.decoder.bind(request).join();
        expect(jsonDecode(body), {'refreshToken': 'refresh-token'});
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
              'idToken': 'new-id-token',
            }),
          );
        return request.response.close();
      }

      protectedAuthorizations.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      if (protectedAuthorizations.last == 'Bearer new-access-token') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'retried': true}));
      } else {
        request.response.statusCode = HttpStatus.unauthorized;
      }
      return request.response.close();
    });
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', 'expired-access-token');
    await authBox.put('refreshToken', 'refresh-token');

    final response = await createDioClient().get('$baseUrl/protected');

    expect(response.data, {'retried': true});
    expect(refreshRequests, 1);
    expect(protectedAuthorizations, [
      'Bearer expired-access-token',
      'Bearer new-access-token',
    ]);
    expect(authBox.get('accessToken'), 'new-access-token');
    expect(authBox.get('refreshToken'), 'new-refresh-token');
    expect(authBox.get('idToken'), 'new-id-token');
  });

  test(
    'refreshes an expired stored token before sending the request',
    () async {
      await startServer((request) async {
        if (request.uri.path == '/v1/users/token/refresh') {
          refreshRequests++;
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'accessToken': 'fresh-access-token',
                'refreshToken': 'fresh-refresh-token',
              }),
            );
          return request.response.close();
        }

        protectedAuthorizations.add(
          request.headers.value(HttpHeaders.authorizationHeader),
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}));
        return request.response.close();
      });
      final authBox = await Hive.openBox('auth');
      await authBox.put(
        'accessToken',
        jwtWithExpiration(DateTime.now().subtract(const Duration(minutes: 1))),
      );
      await authBox.put('refreshToken', 'refresh-token');

      final response = await createDioClient().get('$baseUrl/protected');

      expect(response.data, {'ok': true});
      expect(refreshRequests, 1);
      expect(protectedAuthorizations, ['Bearer fresh-access-token']);
      expect(authBox.get('accessToken'), 'fresh-access-token');
      expect(authBox.get('refreshToken'), 'fresh-refresh-token');
    },
  );

  test(
    'clears session when proactive refresh fails for an expired stored token',
    () async {
      var sessionExpiredNotifications = 0;
      SessionExpiryService.configure(
        onExpired: () => sessionExpiredNotifications++,
      );

      await startServer((request) async {
        if (request.uri.path == '/v1/users/token/refresh') {
          refreshRequests++;
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'error': 'invalid_grant',
                'error_description': 'Token is not active',
              }),
            );
          return request.response.close();
        }

        protectedAuthorizations.add(
          request.headers.value(HttpHeaders.authorizationHeader),
        );
        request.response.statusCode = HttpStatus.unauthorized;
        return request.response.close();
      });
      final authBox = await Hive.openBox('auth');
      await authBox.put(
        'accessToken',
        jwtWithExpiration(DateTime.now().subtract(const Duration(minutes: 1))),
      );
      await authBox.put('refreshToken', 'inactive-refresh-token');

      await expectLater(
        createDioClient().get('$baseUrl/protected'),
        throwsA(isA<DioException>()),
      );

      expect(refreshRequests, 1);
      expect(protectedAuthorizations, [isNull]);
      expect(authBox.get('accessToken'), isNull);
      expect(authBox.get('refreshToken'), isNull);
      expect(AuthInterceptor.cachedAccessToken, isNull);
      expect(sessionExpiredNotifications, 1);
    },
  );

  test('clears stored tokens when refresh fails', () async {
    await startServer((request) {
      if (request.uri.path == '/v1/users/token/refresh') {
        refreshRequests++;
        request.response.statusCode = HttpStatus.unauthorized;
      } else {
        request.response.statusCode = HttpStatus.unauthorized;
      }
      return request.response.close();
    });
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', 'expired-access-token');
    await authBox.put('refreshToken', 'bad-refresh-token');

    await expectLater(
      createDioClient().get('$baseUrl/protected'),
      throwsA(isA<DioException>()),
    );

    expect(refreshRequests, 1);
    expect(authBox.get('accessToken'), isNull);
    expect(authBox.get('refreshToken'), isNull);
    expect(AuthInterceptor.cachedAccessToken, isNull);
  });

  test('logs 403 without attempting token refresh', () async {
    await startServer((request) {
      request.response.statusCode = HttpStatus.forbidden;
      return request.response.close();
    });
    await expectLater(
      createDioClient().get('$baseUrl/protected'),
      throwsA(isA<DioException>()),
    );
  });

  test(
    'retries with latest token from box when refresh returns null',
    () async {
      await startServer((request) async {
        if (request.uri.path == '/v1/users/token/refresh') {
          refreshRequests++;
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'accessToken': null}));
          return request.response.close();
        }
        protectedAuthorizations.add(
          request.headers.value(HttpHeaders.authorizationHeader),
        );
        if (protectedAuthorizations.last == 'Bearer newer-token') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'retried': true}));
        } else {
          request.response.statusCode = HttpStatus.unauthorized;
        }
        return request.response.close();
      });
      final authBox = await Hive.openBox('auth');
      await authBox.put('refreshToken', 'refresh-token');
      await AuthInterceptor.cacheAccessToken('old-token');
      await authBox.put('accessToken', 'newer-token');

      final response = await createDioClient().get('$baseUrl/protected');

      expect(response.data, {'retried': true});
      expect(refreshRequests, 1);
      expect(protectedAuthorizations, [
        'Bearer old-token',
        'Bearer newer-token',
      ]);
    },
  );

  test('shares one refresh request across concurrent 401 responses', () async {
    final refreshCompleter = Completer<void>();
    await startServer((request) async {
      if (request.uri.path == '/v1/users/token/refresh') {
        refreshRequests++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'accessToken': 'shared-access-token'}));
        await request.response.close();
        refreshCompleter.complete();
        return;
      }

      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      protectedAuthorizations.add(authorization);
      if (authorization == 'Bearer shared-access-token') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}));
      } else {
        request.response.statusCode = HttpStatus.unauthorized;
      }
      return request.response.close();
    });
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', 'expired-access-token');
    await authBox.put('refreshToken', 'refresh-token');
    final dio = createDioClient();

    final responses = await Future.wait([
      dio.get('$baseUrl/protected'),
      dio.get('$baseUrl/protected'),
    ]);
    await refreshCompleter.future;

    expect(
      responses.map((response) => response.statusCode),
      everyElement(HttpStatus.ok),
    );
    expect(refreshRequests, 1);
    expect(
      protectedAuthorizations.where(
        (authorization) => authorization == 'Bearer shared-access-token',
      ),
      hasLength(2),
    );
  });
}
