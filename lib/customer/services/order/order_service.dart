import 'package:dio/dio.dart';
import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/customer/exceptions/order_estimation_exception.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class OrderService {
  final Dio _dio;

  OrderService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> estimateOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> restaurantLocation,
    required Map<String, dynamic> customerLocation,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.orderEstimate());

    final response = await _dio.post(
      url.toString(),
      data: {
        'items': items,
        'restaurantLocation': restaurantLocation,
        'customerLocation': customerLocation,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) =>
            status != null &&
            status != HttpStatusCode.unauthorized.code &&
            status != HttpStatusCode.forbidden.code &&
            (status >= 400 ||
                (status >= 200 && status < 300)),
      ),
    );

    if (response.statusCode != HttpStatusCode.ok.code) {
      throw OrderEstimationException(
        statusCode: response.statusCode ?? 0,
        body: response.data.toString(),
      );
    }

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    final url = ApiUriBuilder.build(ApiConstants.orders);

    try {
      final response = await _dio.post(
        url.toString(),
        data: orderData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              (status >= 400 || (status >= 200 && status < 300)),
        ),
      );

      if (response.statusCode != HttpStatusCode.created.code) {
        final body = response.data.toString();
        logger.e(
          'Order creation failed (status code: ${response.statusCode})',
          error: response.data,
        );
        throw OrderCreationException(
          statusCode: response.statusCode ?? 0,
          body: body,
          code: _extractString(response.data, 'code'),
          unavailableItems: _extractList(response.data, 'items'),
          validationErrors: _extractList(response.data, 'errors'),
        );
      }

      logger.i('Order created successfully');
      return response.data as Map<String, dynamic>;
    } on OrderCreationException {
      rethrow;
    } catch (e, stack) {
      logger.e('Error while creating the order', error: e, stackTrace: stack);
      throw Exception('Erreur de connexion réseau ou serveur');
    }
  }

  String? _extractString(dynamic body, String key) {
    if (body is! Map<String, dynamic>) return null;
    return body[key]?.toString();
  }

  List<String> _extractList(dynamic body, String key) {
    try {
      final decoded = body is Map<String, dynamic> ? body : null;
      if (decoded is! Map<String, dynamic>) return [];
      final values = decoded[key];
      if (values is! List) return [];
      return values.map((item) => item.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
