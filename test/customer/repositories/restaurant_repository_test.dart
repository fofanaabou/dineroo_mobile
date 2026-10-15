import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
    await initializeDateFormatting('fr_FR');
  });

  group('RestaurantRepository.getRestaurant', () {
    test('returns the detail when the restaurant is reachable', () async {
      final repository = _repository(
        _dio((options) => _response(options, _restaurantJson)),
      );

      final restaurant = await repository.getRestaurant('restaurant-1');

      expect(restaurant.id, 'restaurant-1');
      expect(restaurant.name, 'Chez Fatou');
    });

    test('throws RestaurantUnavailableException on 404', () async {
      final repository = _repository(_dio(_notFound));

      await expectLater(
        repository.getRestaurant('restaurant-1'),
        throwsA(isA<RestaurantUnavailableException>()),
      );
    });

    test('never names a suspension to the customer', () async {
      final repository = _repository(_dio(_notFound));

      try {
        await repository.getRestaurant('restaurant-1');
        fail('Expected RestaurantUnavailableException');
      } on RestaurantUnavailableException catch (e) {
        expect(e.restaurantId, 'restaurant-1');
        expect(e.toString(), RestaurantUnavailableException.message);
        expect(e.toString().toLowerCase(), isNot(contains('suspend')));
      }
    });

    test('keeps a technical failure distinct from unavailability', () async {
      final repository = _repository(
        _dio((options) => _response(options, 'boom', statusCode: 500)),
      );

      await expectLater(
        repository.getRestaurant('restaurant-1'),
        throwsA(isNot(isA<RestaurantUnavailableException>())),
      );
    });

    test('throws RestaurantUnavailableException when Dio raises the 404', () async {
      final repository = _repository(_dioRejecting(statusCode: 404));

      await expectLater(
        repository.getRestaurant('restaurant-1'),
        throwsA(isA<RestaurantUnavailableException>()),
      );
    });

    test('keeps a raised server failure distinct from unavailability', () async {
      final repository = _repository(_dioRejecting(statusCode: 500));

      await expectLater(
        repository.getRestaurant('restaurant-1'),
        throwsA(isNot(isA<RestaurantUnavailableException>())),
      );
    });
  });

  group('RestaurantRepository.restaurantIsOpen', () {
    test('reports an unavailable restaurant as closed', () async {
      final repository = _repository(_dio(_notFound));

      expect(await repository.restaurantIsOpen('restaurant-1'), isFalse);
    });

    test('surfaces a technical failure instead of reporting closed', () async {
      final repository = _repository(_dioRejecting(statusCode: 500));

      await expectLater(
        repository.restaurantIsOpen('restaurant-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('reads the open status from the opening hours', () async {
      final repository = _repository(
        _dio(
          (options) => _response(options, {
            ..._restaurantJson,
            'openingHours': [
              {
                'day': _todayKey,
                'timeRanges': [
                  {'start': '00:00', 'end': '23:59'},
                ],
              },
            ],
          }),
        ),
      );

      expect(await repository.restaurantIsOpen('restaurant-1'), isTrue);
    });
  });
}

const _restaurantJson = {
  'id': 'restaurant-1',
  'name': 'Chez Fatou',
  'address': 'Kaloum',
  'imageUrl': 'https://cdn.test/restaurant.png',
};

final String _todayKey = DateFormat('EEEE').format(DateTime.now()).toUpperCase();

Response<dynamic> _notFound(RequestOptions options) =>
    _response(options, {'detail': 'Not found'}, statusCode: 404);

Dio _dioRejecting({required int statusCode}) {
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
            data: {'detail': 'failed'},
          ),
        ),
      ),
    ),
  );
  return dio;
}

RestaurantRepository _repository(Dio dio) {
  return RestaurantRepository(
    service: RestaurantService(dio: dio),
    listService: RestaurantListService(dio: dio),
  );
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
