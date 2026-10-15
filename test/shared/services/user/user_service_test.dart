import 'dart:io';

import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('UserService', () {
    test('creates a user through Dio and reports non-ok responses', () async {
      final dio = _dio(statusCode: 200);
      final service = UserService(publicDio: dio);

      await service.createUser({'firstName': 'Aminata'});

      final failingService = UserService(publicDio: _dio(statusCode: 400));
      await expectLater(
        failingService.createUser({'firstName': 'Aminata'}),
        throwsA(isA<Exception>()),
      );
    });

    test('does not reuse the authenticated Dio for public endpoints', () async {
      final authenticatedRequests = <RequestOptions>[];
      final service = UserService(
        dio: _dioWithResponder((options) {
          authenticatedRequests.add(options);
          return _response(options, null);
        }),
        publicDio: _dioWithResponder((options) {
          return _response(options, {'id': 'user-1'});
        }),
      );

      await service.getUserByPhone('620000000');

      expect(authenticatedRequests, isEmpty);
    });

    test('uploads user files through multipart Dio requests', () async {
      final file = await File(
        '${Directory.systemTemp.path}/identity-test.txt',
      ).writeAsString('id');
      addTearDown(() async {
        if (file.existsSync()) await file.delete();
      });

      final service = UserService(dio: _dio(statusCode: 200));

      await service.uploadUserFile(
        userId: 'user-1',
        file: file,
        fileType: 'IDENTITY',
      );
    });

    test('updates and fetches users through injected Dio clients', () async {
      final requests = <RequestOptions>[];
      final service = UserService(
        dio: _dioWithResponder((options) {
          requests.add(options);
          return _response(options, null);
        }),
        publicDio: _dioWithResponder((options) {
          requests.add(options);
          if (options.method == 'GET') {
            return _response(options, {'id': 'user-1'});
          }
          return _response(options, null);
        }),
      );

      await service.updateUser(
        userId: 'user-1',
        firstName: 'Aminata',
        lastName: 'Diallo',
        telephone: '620000000',
      );
      final user = await service.getUserByPhone('620000000');

      expect(user['id'], 'user-1');
      expect(requests.map((r) => r.method), ['PUT', 'GET']);
      expect(requests.first.data['firstName'], 'Aminata');
    });

    test('sends and validates verification codes', () async {
      final bodies = <Map<String, dynamic>>[];
      final service = UserService(
        publicDio: _dioWithResponder((options) {
          bodies.add(Map<String, dynamic>.from(options.data as Map));
          return _response(options, null, statusCode: 204);
        }),
      );

      await service.sendVerificationCode(
        userId: 'user-1',
        telephone: '620000000',
      );
      await service.validateCode(userId: 'user-1', code: '1234');

      expect(bodies, [
        {'id': 'user-1', 'telephone': '620000000'},
        {'id': 'user-1', 'code': '1234'},
      ]);
    });

    test('resets pin by phone and id and surfaces failures', () async {
      final bodies = <Map<String, dynamic>>[];
      final service = UserService(
        dio: _dioWithResponder((options) {
          bodies.add(Map<String, dynamic>.from(options.data as Map));
          return _response(options, null, statusCode: 204);
        }),
        publicDio: _dioWithResponder((options) {
          bodies.add(Map<String, dynamic>.from(options.data as Map));
          return _response(options, null, statusCode: 204);
        }),
      );

      await service.resetCodePinWithPhone(
        telephone: '620000000',
        codePin: '4321',
      );
      await service.resetCodePinWithId(userId: 'user-1', codePin: '1234');

      expect(bodies, [
        {'codePin': '4321'},
        {'codePin': '1234'},
      ]);

      final failingService = UserService(
        dio: _dioWithResponder(
          (options) => _response(options, null, statusCode: 400),
        ),
      );
      await expectLater(
        failingService.resetCodePinWithId(userId: 'user-1', codePin: '1234'),
        throwsA(isA<Exception>()),
      );
    });

    test('registers and deletes push tokens through Dio', () async {
      final requests = <String>[];
      final service = UserService(
        dio: _dio(
          statusCode: 204,
          onRequest: (options) => requests.add(options.method),
        ),
      );

      await service.registerDeviceToken(
        userId: 'user-1',
        token: 'token-1',
        platform: 'ios',
      );
      await service.deleteDeviceToken(
        userId: 'user-1',
        token: 'token-1',
        platform: 'ios',
      );

      expect(requests, ['POST', 'DELETE']);
    });
  });
}

Dio _dio({required int statusCode, void Function(RequestOptions)? onRequest}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: statusCode >= 400 ? {'error': 'failed'} : {'ok': true},
          ),
        );
      },
    ),
  );
  return dio;
}

Dio _dioWithResponder(Response<dynamic> Function(RequestOptions) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(responder(options)),
    ),
  );
  return dio;
}

Response<dynamic> _response(
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
