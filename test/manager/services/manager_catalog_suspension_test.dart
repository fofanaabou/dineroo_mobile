import 'package:dineroo_mobile/manager/services/manager_menu_detail_service.dart';
import 'package:dineroo_mobile/manager/services/manager_menus_service.dart';
import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('menu availability', () {
    test('maps the suspension guard 403 to a typed exception', () async {
      final service = ManagerMenusService(dio: _dioRejectingWith(_suspended));

      await expectLater(
        service.updateAvailability('restaurant-1', 'menu-1', false),
        throwsA(isA<RestaurantSuspendedException>()),
      );
    });

    test('leaves an unrelated 403 as a generic failure', () async {
      final service = ManagerMenusService(
        dio: _dioRejectingWith(_otherForbidden),
      );

      await expectLater(
        service.updateAvailability('restaurant-1', 'menu-1', false),
        throwsA(isNot(isA<RestaurantSuspendedException>())),
      );
    });

    test('leaves a server failure as a generic failure', () async {
      final service = ManagerMenusService(
        dio: _dioRejectingWith(_serverError),
      );

      await expectLater(
        service.updateAvailability('restaurant-1', 'menu-1', false),
        throwsA(isNot(isA<RestaurantSuspendedException>())),
      );
    });
  });

  group('product availability', () {
    test('maps the suspension guard 403 to a typed exception', () async {
      final service = ManagerProductsService(
        dio: _dioRejectingWith(_suspended),
      );

      await expectLater(
        service.updateAvailability('restaurant-1', 'product-1', false),
        throwsA(isA<RestaurantSuspendedException>()),
      );
    });

    test('leaves an unrelated 403 as a generic failure', () async {
      final service = ManagerProductsService(
        dio: _dioRejectingWith(_otherForbidden),
      );

      await expectLater(
        service.updateAvailability('restaurant-1', 'product-1', false),
        throwsA(isNot(isA<RestaurantSuspendedException>())),
      );
    });
  });

  group('menu item availability', () {
    test('maps the suspension guard 403 to a typed exception', () async {
      final service = ManagerMenuDetailService(
        dio: _dioRejectingWith(_suspended),
      );

      await expectLater(
        service.updateItemAvailability(
          'restaurant-1',
          'menu-1',
          'group-1',
          'item-1',
          false,
        ),
        throwsA(isA<RestaurantSuspendedException>()),
      );
    });

    test('leaves an unrelated 403 as a generic failure', () async {
      final service = ManagerMenuDetailService(
        dio: _dioRejectingWith(_otherForbidden),
      );

      await expectLater(
        service.updateItemAvailability(
          'restaurant-1',
          'menu-1',
          'group-1',
          'item-1',
          false,
        ),
        throwsA(isNot(isA<RestaurantSuspendedException>())),
      );
    });
  });
}

const _suspended = (403, {
  'type': 'RESTAURANT_SUSPENDED',
  'title': 'Restaurant suspendu',
  'status': 403,
  'detail': 'Votre restaurant est suspendu. Contactez le support Dineroo.',
});

const _otherForbidden = (403, {'type': 'AccessDeniedException'});

const _serverError = (500, {'detail': 'boom'});

Dio _dioRejectingWith((int, Map<String, dynamic>) failure) {
  final (statusCode, body) = failure;
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
        ),
      ),
    ),
  );
  return dio;
}
