import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class PaymentService {
  final Dio _dio;

  PaymentService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    final uri = ApiUriBuilder.build(ApiConstants.payments);

    try {
      final response = await _dio.post(
        uri.toString(),
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              (status >= 400 || (status >= 200 && status < 300)),
        ),
      );

      return _decodeOrThrow(
        response,
        HttpStatusCode.created.code,
        'Create payment failed',
      );
    } catch (e, stack) {
      logger.e('[PAYMENT][POST] error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPayment(String id) async {
    final uri = ApiUriBuilder.build(ApiConstants.paymentById(id));

    try {
      final response = await _dio.get(uri.toString());

      return _decodeOrThrow(
        response,
        HttpStatusCode.ok.code,
        'Get payment failed',
      );
    } catch (e, stack) {
      logger.e('[PAYMENT][GET] error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Map<String, dynamic> _decodeOrThrow(
    Response<dynamic> response,
    int okCode,
    String message,
  ) {
    if (response.statusCode == okCode) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('$message (code ${response.statusCode})');
  }
}
