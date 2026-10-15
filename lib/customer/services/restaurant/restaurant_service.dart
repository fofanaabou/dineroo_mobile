import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class RestaurantService {
  final Dio _dio;

  RestaurantService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> fetchRestaurant(String id) async {
    try {
      final response = await _dio.get(
        ApiUriBuilder.build(ApiConstants.restaurantById(id)).toString(),
      );

      if (response.statusCode == HttpStatusCode.ok.code) {
        return response.data as Map<String, dynamic>;
      }

      if (response.statusCode == HttpStatusCode.notFound.code) {
        throw RestaurantUnavailableException(id);
      }

      logger.e(
        'Failed to load restaurant (status code: ${response.statusCode})',
        error: response.data,
      );
      throw Exception(
        'Failed to load restaurant (status code: ${response.statusCode})',
      );
    } on RestaurantUnavailableException {
      rethrow;
    } on DioException catch (e, stack) {
      if (e.response?.statusCode == HttpStatusCode.notFound.code) {
        logger.i('Restaurant $id is unavailable');
        throw RestaurantUnavailableException(id);
      }
      logger.e('Failed to load restaurant', error: e, stackTrace: stack);
      throw Exception('Failed to load restaurant (error: $e)');
    } catch (e, stack) {
      logger.e('Failed to load restaurant', error: e, stackTrace: stack);
      throw Exception('Failed to load restaurant (error: $e)');
    }
  }

  Future<bool> restaurantIsOpen(String id) async {
    try {
      final data = await fetchRestaurant(id);
      final restaurant = Restaurant.fromJson(data);
      return OpeningHoursHelper.restaurantIsOpen(restaurant.openingHours);
    } on RestaurantUnavailableException {
      logger.i('Restaurant $id is unavailable — reported as closed');
      return false;
    }
  }
}
