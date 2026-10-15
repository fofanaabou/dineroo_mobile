import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';

class OrderDetailsService {
  final Dio _dio;

  OrderDetailsService({Dio? dio}) : _dio = dio ?? createDioClient();

  static const int _maxAttempts = 2;

  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    final url = ApiUriBuilder.build(
      ApiConstants.orderDetails,
      queryParameters: {'orderId': orderId},
    );

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          url.toString(),
          options: Options(
            validateStatus: (status) =>
                status == HttpStatusCode.notFound.code ||
                status == HttpStatusCode.gatewayTimeout.code ||
                (status != null && status >= 200 && status < 300),
          ),
        );

        if (response.statusCode == HttpStatusCode.notFound.code) {
          logger.i(
            'No order-details found for order $orderId (probably not assigned yet)',
          );
          return null;
        }

        if (response.statusCode == HttpStatusCode.ok.code) {
          return response.data as Map<String, dynamic>;
        }

        final isGatewayTimeout =
            response.statusCode == HttpStatusCode.gatewayTimeout.code;
        final canRetry = isGatewayTimeout && attempt < _maxAttempts;

        if (canRetry) {
          logger.w(
            '[OrderDetailsService] timeout for $orderId '
            '(attempt $attempt/$_maxAttempts), retrying...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        if (isGatewayTimeout) {
          logger.w(
            '[OrderDetailsService] timeout for $orderId '
            '(attempt $attempt/$_maxAttempts)',
            error: response.data,
          );
          throw Exception('Délai d\'attente dépassé pour les détails de la commande');
        }

        logger.e(
          'Failed to fetch order-details [${response.statusCode}]',
          error: response.data,
        );
        throw Exception('Failed to fetch order-details');
      } catch (e, stack) {
        final isLastAttempt = attempt == _maxAttempts;
        if (!isLastAttempt) {
          logger.w(
            '[OrderDetailsService] temporary failure for $orderId '
            '(attempt $attempt/$_maxAttempts), retrying...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        logger.w(
          'Error while fetching order-details',
          error: e,
          stackTrace: stack,
        );
        rethrow;
      }
    }

    throw Exception('Failed to fetch order-details');
  }
}
