import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('ManagerProductsService', () {
    test('fetchProducts returns typed products with context', () async {
      final service = ManagerProductsService(
        dio: _dio((options) {
          expect(options.method, 'GET');
          expect(
            options.uri.path,
            '/v1/restaurants/restaurant-1/catalogue/products',
          );
          expect(options.uri.queryParameters['context'], 'RESTAURANT');
          return _response(options, [
            {'id': 'product-1', 'available': true},
          ]);
        }),
      );

      final result = await service.fetchProducts(
        'restaurant-1',
        context: ApiContext.restaurant,
      );

      expect(result.single['id'], 'product-1');
    });

    test('updateAvailability sends availability payload', () async {
      final service = ManagerProductsService(
        dio: _dio((options) {
          expect(options.method, 'PATCH');
          expect(options.uri.path, '/v1/restaurants/restaurant-1/products/product-1');
          expect(options.data, {'available': false});
          return _response(options, null);
        }),
      );

      await service.updateAvailability('restaurant-1', 'product-1', false);
    });

    test('throws when fetch or update fails', () async {
      final service = ManagerProductsService(
        dio: _dio((options) => _response(options, 'error', statusCode: 500)),
      );

      await expectLater(
        service.fetchProducts('restaurant-1', context: ApiContext.restaurant),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.updateAvailability('restaurant-1', 'product-1', true),
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
