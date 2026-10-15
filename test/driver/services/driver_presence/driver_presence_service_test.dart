import 'package:dineroo_mobile/driver/services/driver_presence/driver_presence_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('DriverPresenceService', () {
    test('fetchDriverById returns driver data', () async {
      final service = DriverPresenceService(
        dio: _dio((options) {
          expect(options.method, 'GET');
          expect(options.uri.path, '/v1/drivers/driver-1');
          return _response(options, {'id': 'driver-1', 'status': 'ONLINE'});
        }),
      );

      final result = await service.fetchDriverById(driverId: 'driver-1');

      expect(result['status'], 'ONLINE');
    });

    test('updateDriverStatus sends status and returns response body', () async {
      final service = DriverPresenceService(
        dio: _dio((options) {
          expect(options.method, 'PUT');
          expect(options.uri.path, '/v1/drivers/driver-1');
          expect(options.data, {'status': 'AVAILABLE'});
          return _response(options, {'id': 'driver-1', 'status': 'AVAILABLE'});
        }),
      );

      final result = await service.updateDriverStatus(
        driverId: 'driver-1',
        status: 'AVAILABLE',
      );

      expect(result['status'], 'AVAILABLE');
    });

    test('updateDriverStatus returns fallback when backend has empty body', () async {
      final service = DriverPresenceService(
        dio: _dio((options) => _response(options, null)),
      );

      final result = await service.updateDriverStatus(
        driverId: 'driver-1',
        status: 'OFFLINE',
      );

      expect(result, {'driverId': 'driver-1', 'status': 'OFFLINE'});
    });

    test('throws on unsuccessful responses', () async {
      final service = DriverPresenceService(
        dio: _dio((options) => _response(options, {'error': 'nope'}, statusCode: 500)),
      );

      await expectLater(
        service.fetchDriverById(driverId: 'driver-1'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.updateDriverStatus(driverId: 'driver-1', status: 'ONLINE'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

Dio _dio(Response<dynamic> Function(RequestOptions options) responder) {
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
