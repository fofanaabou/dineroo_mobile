import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('AuthService', () {
    test('verifies code and returns response data', () async {
      final service = AuthService(
        publicDio: _dio(statusCode: 200, data: {'id': 'u1'}),
      );

      final data = await service.verifyCode('1234');

      expect(data['id'], 'u1');
    });

    test('maps verification status codes to user-facing exceptions', () async {
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 404)).verifyCode('0000'),
        throwsA(predicate((e) => e.toString().contains('Code invalide'))),
      );
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 409)).verifyCode('0000'),
        throwsA(predicate((e) => e.toString().contains('déjà un compte'))),
      );
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 400)).verifyCode('0000'),
        throwsA(predicate((e) => e.toString().contains('Échec'))),
      );
    });

    test('verifyCode handles DioException cancellation', () async {
      await expectLater(
        AuthService(
          publicDio: _dioThrows(_cancelledDioException()),
        ).verifyCode('0000'),
        throwsA(predicate((e) => e.toString().contains('cancelled'))),
      );
    });

    test('verifyCode handles network DioException', () async {
      await expectLater(
        AuthService(
          publicDio: _dioThrows(_connectionDioException()),
        ).verifyCode('0000'),
        throwsA(predicate((e) => e.toString().contains('connexion réseau'))),
      );
    });

    test('logs in and maps login failures', () async {
      final service = AuthService(
        publicDio: _dio(statusCode: 200, data: {'accessToken': 'token'}),
      );

      final data = await service.login({'telephone': '620000000'});

      expect(data['accessToken'], 'token');
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 404)).login({}),
        throwsA(predicate((e) => e.toString().contains('Compte introuvable'))),
      );
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 401)).login({}),
        throwsA(predicate((e) => e.toString().contains('PIN invalide'))),
      );
      await expectLater(
        AuthService(
          publicDio: _dio(statusCode: 400, data: 'account disabled'),
        ).login({}),
        throwsA(predicate((e) => e.toString().contains('désactivé'))),
      );
    });

    test('login handles non-disabled bad request', () async {
      await expectLater(
        AuthService(
          publicDio: _dio(statusCode: 400, data: 'other error'),
        ).login({}),
        throwsA(
          predicate((e) => e.toString().contains('Informations de connexion')),
        ),
      );
    });

    test('login handles non-standard status codes', () async {
      await expectLater(
        AuthService(publicDio: _dio(statusCode: 500)).login({}),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );
    });

    test('login handles DioException cancellation', () async {
      await expectLater(
        AuthService(publicDio: _dioThrows(_cancelledDioException())).login({}),
        throwsA(predicate((e) => e.toString().contains('Login cancelled'))),
      );
    });

    test('login handles network DioException', () async {
      await expectLater(
        AuthService(publicDio: _dioThrows(_connectionDioException())).login({}),
        throwsA(predicate((e) => e.toString().contains('connexion réseau'))),
      );
    });

    test(
      'logout calls server endpoint and ignores non-204 or Dio errors',
      () async {
        final okRequests = <RequestOptions>[];
        await AuthService(
          dio: _dioWithResponder((options) {
            okRequests.add(options);
            return _responseFor(options, null, statusCode: 204);
          }),
        ).logout();
        expect(okRequests.single.uri.path, '/v1/users/me/logout');

        await AuthService(
          dio: _dioWithResponder(
            (options) => _responseFor(options, null, statusCode: 400),
          ),
        ).logout();
        await AuthService(dio: _dioThrows(_connectionDioException())).logout();
      },
    );

    test(
      'does not reuse authenticated Dio for public auth endpoints',
      () async {
        final authenticatedRequests = <RequestOptions>[];
        final service = AuthService(
          dio: _dioWithResponder((options) {
            authenticatedRequests.add(options);
            return _responseFor(options, null);
          }),
          publicDio: _dioWithResponder(
            (options) => _responseFor(options, {'accessToken': 'token'}),
          ),
        );

        await service.login({'telephone': '620000000'});

        expect(authenticatedRequests, isEmpty);
      },
    );
  });
}

Dio _dio({required int statusCode, Object? data}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data ?? {'error': 'failed'},
          ),
        );
      },
    ),
  );
  return dio;
}

Dio _dioThrows(DioException exception) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(exception);
      },
    ),
  );
  return dio;
}

Dio _dioWithResponder(
  Response<dynamic> Function(RequestOptions options) responder,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(responder(options)),
    ),
  );
  return dio;
}

Response<dynamic> _responseFor(
  RequestOptions options,
  Object? data, {
  int statusCode = 200,
}) {
  return Response<dynamic>(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}

DioException _cancelledDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth'),
    type: DioExceptionType.cancel,
  );
}

DioException _connectionDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth'),
    type: DioExceptionType.connectionError,
  );
}
