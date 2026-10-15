import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class SharedOrderService {
  final Dio _dio;

  SharedOrderService({Dio? dio}) : _dio = dio ?? createDioClient();

  static const int _maxAttempts = 2;

  Future<Map<String, dynamic>> fetchOrderById(
    dynamic orderId, {
    ApiContext? context,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.orderById('$orderId'),
      context: context,
    );

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          url.toString(),
          options: Options(
            validateStatus: (status) =>
                status != null &&
                status != HttpStatusCode.unauthorized.code &&
                status != HttpStatusCode.forbidden.code &&
                (status == HttpStatusCode.gatewayTimeout.code ||
                    (status >= 200 && status < 500)),
          ),
        );

        if (response.statusCode == HttpStatusCode.ok.code) {
          return response.data as Map<String, dynamic>;
        }

        final isGatewayTimeout =
            response.statusCode == HttpStatusCode.gatewayTimeout.code;
        final canRetry = isGatewayTimeout && attempt < _maxAttempts;

        if (canRetry) {
          logger.w(
            '[SharedOrderService] fetchOrderById timeout for $orderId '
            '(attempt $attempt/$_maxAttempts), retrying...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        if (isGatewayTimeout) {
          logger.w(
            '[SharedOrderService] fetchOrderById timeout for $orderId '
            '(attempt $attempt/$_maxAttempts)',
            error: response.data,
          );
          throw Exception('Délai d\'attente dépassé pour la commande');
        }

        logger.e(
          'Failed to fetch order (status: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Failed to fetch order');
      } catch (e, stack) {
        final isLastAttempt = attempt == _maxAttempts;
        if (!isLastAttempt) {
          logger.w(
            '[SharedOrderService] fetchOrderById temporary failure for $orderId '
            '(attempt $attempt/$_maxAttempts), retrying...',
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        logger.w('Error while fetching order', error: e, stackTrace: stack);
        throw Exception('Erreur de connexion réseau ou serveur');
      }
    }

    throw Exception('Erreur de connexion réseau ou serveur');
  }

  Future<List<Map<String, dynamic>>> fetchOrdersByIds(
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty) return [];

    final url = ApiUriBuilder.build(ApiConstants.ordersBatch());

    try {
      final response = await _dio.post(
        url.toString(),
        data: orderIds,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'Failed to fetch orders batch (status: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Failed to fetch orders batch');
      }

      final decoded = response.data as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      logger.w(
        'Error while fetching orders batch',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Erreur de connexion réseau ou serveur');
    }
  }
}
