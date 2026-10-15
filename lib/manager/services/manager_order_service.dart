import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class ManagerOrderService {
  final Dio _dio;

  ManagerOrderService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantOrdersByRestaurantId(restaurantId),
      queryParameters: {'sort': 'desc'},
      context: context,
    );

    try {
      final response = await _dio.get(
        url.toString(),
        options: Options(
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );
      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'Manager fetchOrdersByRestaurant failed',
          error: response.data,
        );
        throw Exception('Failed to fetch restaurant orders');
      }

      final List<dynamic> jsonList = response.data as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      logger.e('Error fetching restaurant orders', error: e, stackTrace: stack);
      throw Exception('Error fetching restaurant orders');
    }
  }

  Future<Map<String, dynamic>> fetchOrderById(
    String orderId, {
    required ApiContext context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.orderById(orderId),
      context: context,
    );

    try {
      final response = await _dio.get(
        url.toString(),
        options: Options(
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );
      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e('Manager fetch order failed', error: response.data);
        throw Exception('Failed to fetch order details');
      }

      return response.data as Map<String, dynamic>;
    } catch (e, stack) {
      logger.e('Error fetching manager order', error: e, stackTrace: stack);
      throw Exception('Error fetching manager order');
    }
  }

  Future<void> acceptOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    await _updateOrderAction(
      restaurantId: restaurantId,
      orderId: orderId,
      action: 'accept',
    );
  }

  Future<void> rejectOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    await _updateOrderAction(
      restaurantId: restaurantId,
      orderId: orderId,
      action: 'reject',
    );
  }

  Future<void> _updateOrderAction({
    required String restaurantId,
    required String orderId,
    required String action,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantOrderAction(restaurantId, orderId, action),
    );

    try {
      final response = await _dio.put(
        url.toString(),
        options: Options(
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );

      if (response.statusCode == HttpStatusCode.ok.code ||
          response.statusCode == HttpStatusCode.noContent.code) {
        return;
      }

      logger.e(
        'Order $action failed [${response.statusCode}]',
        error: response.data,
      );
      throw Exception(
        'Order $action failed [${response.statusCode}]: ${response.data}',
      );
    } catch (e, stack) {
      logger.e('Error performing order $action', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.restaurantOrderStatus(restaurantId, orderId),
    );

    try {
      final response = await _dio.put(
        url.toString(),
        data: {'status': status},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );

      if (response.statusCode == HttpStatusCode.ok.code ||
          response.statusCode == HttpStatusCode.noContent.code) {
        return;
      }

      logger.e(
        'Order update failed [${response.statusCode}]',
        error: response.data,
      );
      throw Exception(
        'Order update failed [${response.statusCode}]: ${response.data}',
      );
    } catch (e, stack) {
      logger.e('Order update failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.deliveryValidatePickupOtp(orderId),
    );

    try {
      final response = await _dio.put(
        url.toString(),
        data: {
          'code': code,
          if (validatedBy != null) 'validatedBy': validatedBy,
          'restaurantId': restaurantId,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );

      final decoded = response.data;
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;

      if (response.statusCode == HttpStatusCode.ok.code) {
        return message ?? 'Code validé avec succès.';
      }

      logger.e(
        'Pickup OTP validation failed [${response.statusCode}]',
        error: response.data,
      );
      throw Exception(message ?? 'Code de récupération invalide.');
    } catch (e, stack) {
      logger.e('Pickup OTP validation failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
