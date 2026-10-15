import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_params.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class RestaurantListService {
  final Dio _dio;

  RestaurantListService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> fetchRestaurants(
    PaginationParams params, {
    double? lat,
    double? lon,
  }) async {
    try {
      final uri = ApiUriBuilder.build(
        ApiConstants.restaurants,
        queryParameters: {
          ...params.toQueryParams(),
          if (lat != null) 'lat': lat.toString(),
          if (lon != null) 'lon': lon.toString(),
        },
      );

      final response = await _dio.get(uri.toString());

      if (response.statusCode == HttpStatusCode.ok.code) {
        return response.data as Map<String, dynamic>;
      } else {
        logger.e(
          'Failed to load restaurants (code ${response.statusCode})',
          error: response.data,
        );
        throw Exception(
          'Failed to load restaurants (code ${response.statusCode})',
        );
      }
    } catch (e, stack) {
      logger.e('Failed to load restaurants', error: e, stackTrace: stack);
      throw Exception('Failed to load restaurants (error $e)');
    }
  }
}
