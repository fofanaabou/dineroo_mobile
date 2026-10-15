import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class MenuService {
  final Dio _dio;

  MenuService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> fetchMenuDetail(
    String restaurantId,
    String menuId,
  ) async {
    try {
      final response = await _dio.get(
        ApiUriBuilder.build(
          ApiConstants.restaurantCatalogueMenuById(restaurantId, menuId),
        ).toString(),
      );

      if (response.statusCode == HttpStatusCode.ok.code) {
        return response.data as Map<String, dynamic>;
      } else {
        logger.e(
          'Failed to load menu detail (status code: ${response.statusCode})',
          error: response.data,
        );
        throw Exception(
          'Failed to load menu detail (status code: ${response.statusCode})',
        );
      }
    } catch (e, stack) {
      logger.e('Failed to load menu detail', error: e, stackTrace: stack);
      throw Exception('Failed to load menu detail (error: $e)');
    }
  }
}
