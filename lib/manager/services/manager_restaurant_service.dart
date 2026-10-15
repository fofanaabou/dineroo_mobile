import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerRestaurantService {
  final Dio _dio;

  ManagerRestaurantService({Dio? dio}) : _dio = dio ?? createDioClient();
  Future<Map<String, dynamic>> fetchRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantById(restaurantId),
      context: context,
    );
    try {
      final response = await _dio.get(url.toString());

      if (response.statusCode == HttpStatusCode.ok.code) {
        return response.data as Map<String, dynamic>;
      }

      logger.e(
        'Failed to load restaurant data: ${response.statusCode} - ${response.data}',
      );
      final message = response.data is Map
          ? (response.data as Map)['detail'] ?? 'Erreur lors du chargement (${response.statusCode})'
          : 'Erreur lors du chargement (${response.statusCode})';
      throw Exception(message);
    } on DioException catch (e) {
      logger.e('Failed to load restaurant data', error: e);
      if (e.response?.statusCode == 404) {
        throw Exception('Ce restaurant n\'est pas encore disponible.');
      }
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      throw Exception(
        detail?.toString() ?? 'Erreur de connexion réseau ou serveur',
      );
    }
  }

  Future<void> updateOpeningHours(
    String restaurantId,
    List<Map<String, dynamic>> openingHours,
  ) async {
    final url = ApiUriBuilder.build(ApiConstants.restaurantById(restaurantId));
    try {
      await _dio.patch(
        url.toString(),
        data: {'openingHours': openingHours},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      logger.i('Opening hours updated successfully for restaurant $restaurantId');
    } on DioException catch (e) {
      if (RestaurantSuspendedException.matchesResponse(
        e.response?.statusCode,
        e.response?.data,
      )) {
        logger.w('Opening hours update refused: restaurant is suspended');
        throw const RestaurantSuspendedException();
      }
      logger.e('Failed to update opening hours', error: e);
      if (e.response?.statusCode == 404) {
        throw Exception('Ce restaurant n\'est pas encore disponible. Veuillez réessayer plus tard.');
      }
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      throw Exception(detail?.toString() ?? 'Erreur lors de la mise à jour des horaires.');
    } catch (e, stack) {
      logger.e('Exception updating opening hours', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
