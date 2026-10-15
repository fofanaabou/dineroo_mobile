import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerProductsService {
  final Dio _dio;

  ManagerProductsService({Dio? dio}) : _dio = dio ?? createDioClient();
  Future<List<Map<String, dynamic>>> fetchProducts(
    String restaurantId, {
    required ApiContext context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantCatalogueProducts(restaurantId),
      context: context,
    );
    try {
      final response = await _dio.get(url.toString());

      if (response.statusCode == HttpStatusCode.ok.code) {
        return (response.data as List).cast<Map<String, dynamic>>();
      } else {
        logger.e(
          '[Manager] Failed to fetch products (status: ${response.statusCode})',
          error: response.data,
        );
        throw Exception(
          'Failed to fetch products (status: ${response.statusCode})',
        );
      }
    } catch (e, stack) {
      logger.e('Error fetching manager products', error: e, stackTrace: stack);
      throw Exception('Failed to fetch products (error: $e)');
    }
  }

  Future<void> updateAvailability(
    String restaurantId,
    String productId,
    bool available,
  ) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantProductById(restaurantId, productId),
    );

    try {
      final res = await _dio.patch(
        url.toString(),
        data: {'available': available},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (res.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          '[Manager] Failed to update product availability '
          '(status: ${res.statusCode})',
          error: res.data,
        );
        throw Exception('Failed to update product availability');
      }
    } on DioException catch (e, stack) {
      if (RestaurantSuspendedException.matchesResponse(
        e.response?.statusCode,
        e.response?.data,
      )) {
        logger.w('Product availability refused: restaurant is suspended');
        throw const RestaurantSuspendedException();
      }
      logger.e(
        'Error updating product availability',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Failed to update product availability (error: $e)');
    } catch (e, stack) {
      logger.e(
        'Error updating product availability',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Failed to update product availability (error: $e)');
    }
  }
}
