import 'package:dio/dio.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('ManagerOrderService', () {
    test('fetches restaurant orders and order details', () async {
      final requested = <Uri>[];
      final service = ManagerOrderService(
        dio: _dio((options) {
          requested.add(options.uri);
          if (options.uri.path.endsWith('/orders/order-1')) {
            return _response(options, {'id': 'order-1'});
          }
          return _response(options, [
            {'id': 'order-1'},
          ]);
        }),
      );

      final orders = await service.fetchOrdersByRestaurant(
        'restaurant-1',
        context: ApiContext.restaurant,
      );
      final order = await service.fetchOrderById(
        'order-1',
        context: ApiContext.restaurant,
      );

      expect(orders.single['id'], 'order-1');
      expect(order['id'], 'order-1');
      expect(requested.first.queryParameters['sort'], 'desc');
    });

    test('accepts, rejects and updates order status', () async {
      final requests = <RequestOptions>[];
      final service = ManagerOrderService(
        dio: _dio((options) {
          requests.add(options);
          return _response(options, null, statusCode: 204);
        }),
      );

      await service.acceptOrder(restaurantId: 'restaurant-1', orderId: 'o1');
      await service.rejectOrder(restaurantId: 'restaurant-1', orderId: 'o1');
      await service.updateOrderStatus(
        restaurantId: 'restaurant-1',
        orderId: 'o1',
        status: 'READY_FOR_PICKUP',
      );

      expect(requests.map((r) => r.method), ['PUT', 'PUT', 'PUT']);
      expect(requests[0].uri.path, contains('/accept'));
      expect(requests[1].uri.path, contains('/reject'));
      expect(requests[2].data, {'status': 'READY_FOR_PICKUP'});
    });

    test('validatePickupOtp returns message on success', () async {
      final service = ManagerOrderService(
        dio: _dio(
          (options) => _response(options, {'message': 'Code validé avec succès.'}),
        ),
      );

      final message = await service.validatePickupOtp(
        orderId: 'order-1',
        code: '1234',
        restaurantId: 'restaurant-id',
      );

      expect(message, 'Code validé avec succès.');
    });

    test('validatePickupOtp throws on error response', () async {
      final service = ManagerOrderService(
        dio: _dio(
          (options) => _response(
            options,
            {'message': 'Code de récupération invalide.'},
            statusCode: 400,
          ),
        ),
      );

      await expectLater(
        service.validatePickupOtp(
          orderId: 'order-1',
          code: '0000',
          restaurantId: 'restaurant-id',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when backend responses are not successful', () async {
      final service = ManagerOrderService(
        dio: _dio((options) => _response(options, 'nope', statusCode: 500)),
      );

      await expectLater(
        service.fetchOrderById('order-1', context: ApiContext.restaurant),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.acceptOrder(restaurantId: 'restaurant-1', orderId: 'order-1'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.updateOrderStatus(
          restaurantId: 'restaurant-1',
          orderId: 'order-1',
          status: 'READY_FOR_PICKUP',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('validatePickupOtp uses default message when no message in body', () async {
      final service = ManagerOrderService(
        dio: _dio(
          (options) => _response(options, {'unrelated': 'data'}),
        ),
      );

      final message = await service.validatePickupOtp(
        orderId: 'order-1',
        code: '1234',
        restaurantId: 'restaurant-id',
      );

      expect(message, 'Code validé avec succès.');
    });

    test('fetchOrdersByRestaurant throws on DioException', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, error: Exception('Network error')),
          ),
        ),
      );
      final service = ManagerOrderService(dio: dio);

      await expectLater(
        service.fetchOrdersByRestaurant('restaurant-1', context: ApiContext.restaurant),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchOrderById throws on DioException', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, error: Exception('Network error')),
          ),
        ),
      );
      final service = ManagerOrderService(dio: dio);

      await expectLater(
        service.fetchOrderById('order-1', context: ApiContext.restaurant),
        throwsA(isA<Exception>()),
      );
    });

    test('rejectOrder and acceptOrder rethrow on DioException', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, error: Exception('Network error')),
          ),
        ),
      );
      final service = ManagerOrderService(dio: dio);

      await expectLater(
        service.acceptOrder(restaurantId: 'restaurant-1', orderId: 'o1'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.rejectOrder(restaurantId: 'restaurant-1', orderId: 'o1'),
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
