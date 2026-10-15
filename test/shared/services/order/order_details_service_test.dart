import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('OrderDetailsService', () {
    test('returns order details on success', () async {
      final service = OrderDetailsService(
        dio: _dio((options) {
          expect(options.method, 'GET');
          expect(options.uri.path, '/v1/order-details');
          expect(options.uri.queryParameters['orderId'], 'order-1');
          return _response(options, {'orderId': 'order-1', 'driverId': 'driver-1'});
        }),
      );

      final result = await service.fetchOrderDetails('order-1');

      expect(result?['driverId'], 'driver-1');
    });

    test('returns null when order details do not exist yet', () async {
      final service = OrderDetailsService(
        dio: _dio((options) => _response(options, {'error': 'not found'}, statusCode: 404)),
      );

      final result = await service.fetchOrderDetails('order-1');

      expect(result, isNull);
    });

    test('retries gateway timeout and then succeeds', () async {
      var calls = 0;
      final service = OrderDetailsService(
        dio: _dio((options) {
          calls++;
          if (calls == 1) {
            return _response(options, 'timeout', statusCode: 504);
          }
          return _response(options, {'orderId': 'order-1'});
        }),
      );

      final result = await service.fetchOrderDetails('order-1');

      expect(calls, 2);
      expect(result?['orderId'], 'order-1');
    });

    test('throws after repeated gateway timeouts', () async {
      final service = OrderDetailsService(
        dio: _dio((options) => _response(options, 'timeout', statusCode: 504)),
      );

      await expectLater(
        service.fetchOrderDetails('order-1'),
        throwsA(predicate((e) => e.toString().contains('Délai'))),
      );
    });

    test('throws network error after exhausting retries', () async {
      var attempts = 0;
      final service = OrderDetailsService(
        dio: _dio((options) {
          attempts++;
          if (attempts == 1) {
            return _response(options, 'timeout', statusCode: 504);
          }
          return _response(options, 'timeout', statusCode: 504);
        }),
      );

      await expectLater(
        service.fetchOrderDetails('order-1'),
        throwsA(predicate((e) => e.toString().contains('Délai'))),
      );
    });
    test('retries on DioException and rethrows after exhausting retries', () async {
      var attempts = 0;
      final service = OrderDetailsService(
        dio: _dio((options) {
          attempts++;
          throw DioException(requestOptions: options, error: Exception('Timeout'));
        }),
      );

      await expectLater(
        service.fetchOrderDetails('order-1'),
        throwsA(isA<Exception>()),
      );
      expect(attempts, 2);
    });

    test('succeeds on second attempt after DioException', () async {
      var attempts = 0;
      final service = OrderDetailsService(
        dio: _dio((options) {
          attempts++;
          if (attempts == 1) {
            throw DioException(requestOptions: options, error: Exception('Timeout'));
          }
          return _response(options, {'orderId': 'order-1'});
        }),
      );

      final result = await service.fetchOrderDetails('order-1');

      expect(attempts, 2);
      expect(result?['orderId'], 'order-1');
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
