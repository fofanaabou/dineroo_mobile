import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('SharedOrderService', () {
    group('fetchOrderById', () {
      test('returns parsed JSON on 200', () async {
        final service = SharedOrderService(
          dio: _dio(
            (options) => _response(options, {'id': 'order-1', 'status': 'pending'}),
          ),
        );

        final result = await service.fetchOrderById('order-1');

        expect(result['id'], 'order-1');
        expect(result['status'], 'pending');
      });

      test('retries on gateway timeout and succeeds on second attempt',
          () async {
        var attempts = 0;
        final service = SharedOrderService(
          dio: _dio((options) {
            attempts++;
            if (attempts == 1) {
              return _response(options, 'timeout', statusCode: 504);
            }
            return _response(options, {'id': 'order-1'});
          }),
        );

        final result = await service.fetchOrderById('order-1');

        expect(result['id'], 'order-1');
        expect(attempts, 2);
      });

      test('throws timeout exception after max gateway timeout retries',
          () async {
        final service = SharedOrderService(
          dio: _dio((options) => _response(options, 'timeout', statusCode: 504)),
        );

        try {
          await service.fetchOrderById('order-1');
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Erreur de connexion'));
        }
      });

      test('throws connection error on non-200 status after retries', () async {
        final service = SharedOrderService(
          dio: _dio((options) => _response(options, 'not found', statusCode: 404)),
        );

        try {
          await service.fetchOrderById('order-1');
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Erreur de connexion'));
        }
      });

      test('retries on network error and succeeds on second attempt', () async {
        var attempts = 0;
        final service = SharedOrderService(
          dio: _dio((options) {
            attempts++;
            if (attempts == 1) {
              throw Exception('Network error');
            }
            return _response(options, {'id': 'order-1'});
          }),
        );

        final result = await service.fetchOrderById('order-1');

        expect(result['id'], 'order-1');
        expect(attempts, 2);
      });

      test('throws connection error when max retries exceeded', () async {
        final service = SharedOrderService(
          dio: _dio((_) => throw Exception('Network error')),
        );

        try {
          await service.fetchOrderById('order-1');
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Erreur de connexion'));
        }
      });
    });

    group('fetchOrdersByIds', () {
      test('returns empty list for empty input', () async {
        final service = SharedOrderService(
          dio: _dio((options) => _response(options, [])),
        );

        final result = await service.fetchOrdersByIds([]);

        expect(result, isEmpty);
      });

      test('returns parsed list on 200', () async {
        final service = SharedOrderService(
          dio: _dio((options) {
            expect(options.method, 'POST');
            expect(options.uri.toString(), contains('/orders/batch'));
            return _response(options, [
              {'id': 'order-1'},
              {'id': 'order-2'},
            ]);
          }),
        );

        final result = await service.fetchOrdersByIds(['order-1', 'order-2']);

        expect(result, hasLength(2));
        expect(result[0]['id'], 'order-1');
      });

      test('throws on non-200 status', () async {
        final service = SharedOrderService(
          dio: _dio((options) => _response(options, 'error', statusCode: 500)),
        );

        try {
          await service.fetchOrdersByIds(['order-1']);
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Erreur de connexion'));
        }
      });

      test('throws on network error', () async {
        final service = SharedOrderService(
          dio: _dio((_) => throw Exception('No connection')),
        );

        try {
          await service.fetchOrdersByIds(['order-1']);
          fail('Expected exception');
        } catch (e) {
          expect(e.toString(), contains('Erreur de connexion'));
        }
      });
    });
  });
}

Dio _dio(Response<dynamic> Function(RequestOptions options) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(responder(options));
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
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
