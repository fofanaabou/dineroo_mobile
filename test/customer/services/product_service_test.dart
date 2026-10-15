import 'dart:convert';

import 'package:dineroo_mobile/customer/services/restaurant/product_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('ProductService', () {
    test(
      'fetchProductDetail uses catalogue product endpoint and parses map data',
      () async {
        final service = ProductService(
          dio: _dio((options) {
            expect(options.method, 'GET');
            expect(
              options.uri.path,
              '/v1/restaurants/restaurant-1/catalogue/products/product-1',
            );
            return _response(options, {'id': 'product-1', 'name': 'Burger'});
          }),
        );

        final result = await service.fetchProductDetail(
          'restaurant-1',
          'product-1',
        );

        expect(result, {'id': 'product-1', 'name': 'Burger'});
      },
    );

    test('fetchProductDetail decodes JSON string responses', () async {
      final service = ProductService(
        dio: _dio(
          (options) => _response(options, jsonEncode({'id': 'product-1'})),
        ),
      );

      final result = await service.fetchProductDetail(
        'restaurant-1',
        'product-1',
      );

      expect(result['id'], 'product-1');
    });

    test('fetchProductDetail throws on non-200 and network failures', () async {
      final nonOkService = ProductService(
        dio: _dio((options) => _response(options, 'nope', statusCode: 404)),
      );

      await expectLater(
        nonOkService.fetchProductDetail('restaurant-1', 'product-1'),
        throwsA(isA<Exception>()),
      );

      final failingService = ProductService(
        dio: _dio((options) => throw DioException(requestOptions: options)),
      );

      await expectLater(
        failingService.fetchProductDetail('restaurant-1', 'product-1'),
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
