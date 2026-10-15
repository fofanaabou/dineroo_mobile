import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';

class ManagerMenuDetailService {
  final Dio _dio;

  ManagerMenuDetailService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> fetchMenuDetail(
    String restaurantId,
    String menuId,
  ) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantCatalogueMenuById(restaurantId, menuId),
      context: ApiContext.restaurant,
    );
    try {
      final res = await _dio.get(url.toString());
      if (res.statusCode == HttpStatusCode.ok.code) {
        final data = res.data;
        return data is String
            ? jsonDecode(data) as Map<String, dynamic>
            : data as Map<String, dynamic>;
      }
      logger.e(
        '[Manager] Failed to fetch menu detail (status: ${res.statusCode})',
        error: res.data,
      );
      throw Exception(
        'Failed to fetch menu detail (status: ${res.statusCode})',
      );
    } catch (e, stack) {
      logger.e('Error fetching menu detail', error: e, stackTrace: stack);
      throw Exception('Failed to fetch menu detail (error: $e)');
    }
  }

  Future<void> updateItemAvailability(
    String restaurantId,
    String menuId,
    String groupId,
    String itemId,
    bool available,
  ) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantCatalogueItemAvailability(
        restaurantId,
        menuId,
        groupId,
        itemId,
      ),
    );
    try {
      final res = await _dio.patch(
        url.toString(),
        data: {'available': available},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          '[Manager] Failed to update item availability '
          '(status: ${res.statusCode})',
          error: res.data,
        );
        throw Exception('Failed to update item availability');
      }
    } on DioException catch (e, stack) {
      if (RestaurantSuspendedException.matchesResponse(
        e.response?.statusCode,
        e.response?.data,
      )) {
        logger.w('Item availability refused: restaurant is suspended');
        throw const RestaurantSuspendedException();
      }
      logger.e('Error updating item availability', error: e, stackTrace: stack);
      throw Exception('Failed to update item availability (error: $e)');
    } catch (e, stack) {
      logger.e('Error updating item availability', error: e, stackTrace: stack);
      throw Exception('Failed to update item availability (error: $e)');
    }
  }
}
