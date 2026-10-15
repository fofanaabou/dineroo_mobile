import 'package:dio/dio.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('DriverDeliveryService', () {
    test('assignDriver succeeds with body', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) {
          expect(options.method, 'PUT');
          expect(options.data, {'driverId': 'd1', 'deliveryId': 'del1'});
          return _response(options, {'driverId': 'd1', 'status': 'assigned'});
        }),
      );

      final result = await service.assignDriver(
        driverId: 'd1',
        deliveryId: 'del1',
      );

      expect(result['driverId'], 'd1');
      expect(result['status'], 'assigned');
    });

    test('assignDriver returns defaults when body empty', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, null)),
      );

      final result = await service.assignDriver(
        driverId: 'd1',
        deliveryId: 'del1',
      );

      expect(result['driverId'], 'd1');
      expect(result['deliveryId'], 'del1');
      expect(result['driverStatus'], 'ONLINE');
      expect(result['deliveryStatus'], 'PENDING');
    });

    test('assignDriver throws on non-200', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, 'error', statusCode: 500)),
      );

      await expectLater(
        service.assignDriver(driverId: 'd1', deliveryId: 'del1'),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchDeliveriesByDriverId succeeds with list', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) {
          expect(options.method, 'GET');
          return _response(options, [{'id': 'del1'}]);
        }),
      );

      final result = await service.fetchDeliveriesByDriverId(driverId: 'd1');
      expect(result, [{'id': 'del1'}]);
    });

    test('fetchDeliveriesByDriverId returns empty when body empty', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, null)),
      );

      final result = await service.fetchDeliveriesByDriverId(driverId: 'd1');
      expect(result, []);
    });

    test('fetchDeliveriesByDriverId throws on non-200', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, 'error', statusCode: 500)),
      );

      await expectLater(
        service.fetchDeliveriesByDriverId(driverId: 'd1'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateDeliveryStatus succeeds with body', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) {
          expect(options.method, 'PUT');
          expect(options.data, {'status': 'DELIVERED'});
          return _response(options, {
            'deliveryId': 'del1',
            'status': 'DELIVERED',
          });
        }),
      );

      final result = await service.updateDeliveryStatus(
        deliveryId: 'del1',
        status: 'DELIVERED',
      );

      expect(result['deliveryId'], 'del1');
      expect(result['status'], 'DELIVERED');
    });

    test('updateDeliveryStatus returns defaults when body empty', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, null)),
      );

      final result = await service.updateDeliveryStatus(
        deliveryId: 'del1',
        status: 'DELIVERED',
      );

      expect(result['deliveryId'], 'del1');
      expect(result['status'], 'DELIVERED');
    });

    test('updateDeliveryStatus throws on non-200', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, 'error', statusCode: 500)),
      );

      await expectLater(
        service.updateDeliveryStatus(deliveryId: 'del1', status: 'DELIVERED'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateDeliveryStatus includes driverId and coordinates in body',
        () async {
      final service = DriverDeliveryService(
        dio: _dio((options) {
          expect(options.data, {
            'status': 'PICKED_UP',
            'driverId': 'd1',
            'latitude': 9.6412,
            'longitude': -13.5784,
          });
          return _response(options, {
            'deliveryId': 'del1',
            'status': 'PICKED_UP',
          });
        }),
      );

      final result = await service.updateDeliveryStatus(
        deliveryId: 'del1',
        status: 'PICKED_UP',
        driverId: 'd1',
        latitude: 9.6412,
        longitude: -13.5784,
      );

      expect(result['deliveryId'], 'del1');
      expect(result['status'], 'PICKED_UP');
    });

    test('updateDeliveryStatus extracts message from error body', () async {
      final service = DriverDeliveryService(
        dio: _dio(
          (options) => _response(
            options,
            {'message': 'Code de récupération invalide.'},
            statusCode: 400,
          ),
        ),
      );

      expectLater(
        service.updateDeliveryStatus(deliveryId: 'del1', status: 'PICKED_UP'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Code de récupération invalide.'),
          ),
        ),
      );
    });

    test('fetchDeliveriesByDriverId passes statuses query param', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) {
          expect(options.uri.queryParameters['statuses'], 'ASSIGNED,PICKED_UP');
          return _response(options, [{'id': 'del1'}]);
        }),
      );

      final result = await service.fetchDeliveriesByDriverId(
        driverId: 'd1',
        statuses: const ['ASSIGNED', 'PICKED_UP'],
      );

      expect(result, [{'id': 'del1'}]);
    });

    test('fetchDeliveriesByDriverId returns empty for non-list response',
        () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, {'id': 'del1'})),
      );

      final result = await service.fetchDeliveriesByDriverId(driverId: 'd1');

      expect(result, []);
    });

    test('_extractErrorMessage returns null for null body', () async {
      final service = DriverDeliveryService(
        dio: _dio((options) => _response(options, null, statusCode: 400)),
      );

      await expectLater(
        service.updateDeliveryStatus(deliveryId: 'del1', status: 'PICKED_UP'),
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
