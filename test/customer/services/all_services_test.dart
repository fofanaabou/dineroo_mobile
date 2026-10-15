import 'package:dio/dio.dart';
import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/customer/services/order/order_list_service.dart';
import 'package:dineroo_mobile/customer/services/order/order_service.dart';
import 'package:dineroo_mobile/customer/services/payment/payment_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/menu_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_params.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('RestaurantService', () {
    test('fetchRestaurant returns parsed JSON on success', () async {
      final service = RestaurantService(
        dio: _dio((options) {
          return _response(options, {'id': 'r1', 'name': 'Chez Mariam'});
        }),
      );
      final result = await service.fetchRestaurant('r1');
      expect(result['id'], 'r1');
      expect(result['name'], 'Chez Mariam');
    });

    test('fetchRestaurant throws on non-200', () async {
      final service = RestaurantService(dio: _dio((options) => _response(options, 'Not found', statusCode: 404)));
      expect(() => service.fetchRestaurant('r1'), throwsA(isA<Exception>()));
    });
  });

  group('RestaurantListService', () {
    test('fetchRestaurants returns parsed JSON', () async {
      final service = RestaurantListService(
        dio: _dio((options) {
          expect(options.uri.queryParameters, contains('page'));
          return _response(options, {'items': [], 'total': 0});
        }),
      );
      final result = await service.fetchRestaurants(PaginationParams(page: 1));
      expect(result['total'], 0);
    });

    test('fetchRestaurants includes lat/lon when provided', () async {
      final service = RestaurantListService(
        dio: _dio((options) {
          expect(options.uri.queryParameters['lat'], '9.5');
          expect(options.uri.queryParameters['lon'], '-13.7');
          return _response(options, {'items': []});
        }),
      );
      await service.fetchRestaurants(PaginationParams(), lat: 9.5, lon: -13.7);
    });

    test('fetchRestaurants throws on non-200', () async {
      final service = RestaurantListService(dio: _dio((options) => _response(options, 'Fail', statusCode: 500)));
      expect(
        () => service.fetchRestaurants(PaginationParams()),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentService', () {
    test('createPayment returns parsed JSON on success', () async {
      final service = PaymentService(
        dio: _dio((options) {
          expect(options.method, 'POST');
          expect(options.validateStatus(401), isFalse);
          expect(options.validateStatus(403), isFalse);
          expect(options.validateStatus(400), isTrue);
          return _response(options, {'id': 'pay-1', 'status': 'PENDING'}, statusCode: 201);
        }),
      );
      final result = await service.createPayment({'amount': 12500});
      expect(result['id'], 'pay-1');
    });

    test('createPayment throws on non-201', () async {
      final service = PaymentService(dio: _dio((options) => _response(options, 'Bad', statusCode: 400)));
      expect(() => service.createPayment({}), throwsA(isA<Exception>()));
    });

    test('getPayment returns parsed JSON on success', () async {
      final service = PaymentService(
        dio: _dio((options) {
          expect(options.method, 'GET');
          return _response(options, {'id': 'pay-1'});
        }),
      );
      final result = await service.getPayment('pay-1');
      expect(result['id'], 'pay-1');
    });
  });

  group('OrderListService', () {
    test('fetchOrders returns parsed list on success', () async {
      final service = OrderListService(
        dio: _dio((options) {
          expect(options.uri.toString(), contains('customers/c-1'));
          return _response(options, [{'id': 'o1'}]);
        }),
      );
      final result = await service.fetchOrders('c-1');
      expect(result.length, 1);
      expect(result.first['id'], 'o1');
    });

    test('fetchOrders throws on non-200', () async {
      final service = OrderListService(dio: _dio((options) => _response(options, 'Error', statusCode: 500)));
      expect(() => service.fetchOrders('c-1'), throwsA(isA<Exception>()));
    });
  });

  group('OrderService', () {
    test('estimateOrder returns parsed JSON', () async {
      final service = OrderService(
        dio: _dio((options) {
          expect(options.method, 'POST');
          expect(options.validateStatus(401), isFalse);
          expect(options.validateStatus(403), isFalse);
          expect(options.validateStatus(400), isTrue);
          return _response(options, {'total': 12500});
        }),
      );
      final result = await service.estimateOrder(
        items: [{'productId': 'p1', 'quantity': 2}],
        restaurantLocation: {'lat': 9.5},
        customerLocation: {'lat': 9.6},
      );
      expect(result['total'], 12500);
    });

    test('estimateOrder throws OrderEstimationException on non-200', () async {
      final service = OrderService(dio: _dio((options) => _response(options, 'Error', statusCode: 400)));
      expect(
        () => service.estimateOrder(
          items: [],
          restaurantLocation: {},
          customerLocation: {},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('createOrder returns parsed JSON on 201', () async {
      final service = OrderService(
        dio: _dio((options) {
          expect(options.method, 'POST');
          expect(options.validateStatus(401), isFalse);
          expect(options.validateStatus(403), isFalse);
          expect(options.validateStatus(409), isTrue);
          return _response(options, {'id': 'order-1'}, statusCode: 201);
        }),
      );
      final result = await service.createOrder({'items': []});
      expect(result['id'], 'order-1');
    });

    test('createOrder throws OrderCreationException on non-201', () async {
      final service = OrderService(
        dio: _dio((options) => _response(options, {'items': ['Burger']}, statusCode: 409)),
      );
      expect(() => service.createOrder({}), throwsA(isA<Exception>()));
    });

    test('createOrder extracts validation errors from bad request body', () async {
      final service = OrderService(
        dio: _dio((options) => _response(
          options,
          {
            'error': 'Sélection invalide',
            'message': 'La sélection ne respecte pas les règles du menu.',
            'errors': ['Option obligatoire manquante'],
          },
          statusCode: 400,
        )),
      );

      try {
        await service.createOrder({});
        fail('Expected OrderCreationException');
      } on OrderCreationException catch (e) {
        expect(e.statusCode, 400);
        expect(e.unavailableItems, isEmpty);
        expect(e.validationErrors, ['Option obligatoire manquante']);
      }
    });

    test('createOrder carries the error code of a refused order', () async {
      final service = OrderService(
        dio: _dio((options) => _response(
          options,
          {
            'error': 'Restaurant indisponible',
            'code': 'RESTAURANT_SUSPENDED',
            'message': 'Ce restaurant n\'accepte plus de commandes.',
          },
          statusCode: 409,
        )),
      );

      try {
        await service.createOrder({});
        fail('Expected OrderCreationException');
      } on OrderCreationException catch (e) {
        expect(e.statusCode, 409);
        expect(e.code, 'RESTAURANT_SUSPENDED');
        expect(e.isRestaurantUnavailable, isTrue);
      }
    });

    test('createOrder leaves the error code null when absent', () async {
      final service = OrderService(
        dio: _dio((options) => _response(
          options,
          {'items': ['Burger']},
          statusCode: 409,
        )),
      );

      try {
        await service.createOrder({});
        fail('Expected OrderCreationException');
      } on OrderCreationException catch (e) {
        expect(e.code, isNull);
        expect(e.isRestaurantUnavailable, isFalse);
        expect(e.unavailableItems, ['Burger']);
      }
    });

    test('createOrder converts network errors to Exception', () async {
      final service = OrderService(dio: _dioThrows(Exception('Network down')));
      expect(() => service.createOrder({}), throwsA(isA<Exception>()));
    });
  });

  group('MenuService', () {
    test('fetchMenuDetail returns parsed JSON on success', () async {
      final service = MenuService(
        dio: _dio((options) {
          expect(
            options.uri.toString(),
            contains('restaurants/r1/catalogue/menus/m1'),
          );
          return _response(options, {'id': 'm1', 'name': 'Menu test'});
        }),
      );
      final result = await service.fetchMenuDetail('r1', 'm1');
      expect(result['name'], 'Menu test');
    });

    test('fetchMenuDetail throws on non-200', () async {
      final service = MenuService(dio: _dio((options) => _response(options, 'Not found', statusCode: 404)));
      expect(
        () => service.fetchMenuDetail('r1', 'm1'),
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

Dio _dioThrows(Object error) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(requestOptions: options, error: error),
      ),
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
