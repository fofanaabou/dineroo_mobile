import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';

class ManagerMenusService {
  final Dio _dio;

  ManagerMenusService({Dio? dio}) : _dio = dio ?? createDioClient();
  Future<List<Map<String, dynamic>>> fetchMenus(
    String restaurantId, {
    required ApiContext context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantCatalogueMenus(restaurantId),
      context: context,
    );
    try {
      final res = await _dio.get(url.toString());

      if (res.statusCode == HttpStatusCode.ok.code) {
        return (res.data as List).cast<Map<String, dynamic>>();
      } else {
        logger.e(
          '[Manager] Failed to fetch menus (status: ${res.statusCode})',
          error: res.data,
        );
        throw Exception('Failed to fetch menus (status: ${res.statusCode})');
      }
    } catch (e, stack) {
      logger.e('Error fetching manager menus', error: e, stackTrace: stack);
      throw Exception('Failed to fetch menus (error: $e)');
    }
  }

  Future<void> updateAvailability(
    String restaurantId,
    String menuId,
    bool available,
  ) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantMenuById(restaurantId, menuId),
    );

    try {
      final res = await _dio.patch(
        url.toString(),
        data: {'available': available},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          '[Manager] Failed to update menu availability '
          '(status: ${res.statusCode})',
          error: res.data,
        );
        throw Exception('Failed to update menu availability');
      }
    } on DioException catch (e, stack) {
      if (RestaurantSuspendedException.matchesResponse(
        e.response?.statusCode,
        e.response?.data,
      )) {
        logger.w('Menu availability refused: restaurant is suspended');
        throw const RestaurantSuspendedException();
      }
      logger.e('Error updating menu availability', error: e, stackTrace: stack);
      throw Exception('Failed to update menu availability (error: $e)');
    } catch (e, stack) {
      logger.e('Error updating menu availability', error: e, stackTrace: stack);
      throw Exception('Failed to update menu availability (error: $e)');
    }
  }
}
