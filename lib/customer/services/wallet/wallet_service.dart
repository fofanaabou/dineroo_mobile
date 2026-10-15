import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class WalletService {
  final Dio _dio;

  WalletService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> getWallet(String customerId) async {
    final uri = ApiUriBuilder.build(ApiConstants.walletByCustomerId(customerId));

    try {
      final response = await _dio.get(
        uri.toString(),
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      if (response.statusCode == HttpStatusCode.ok.code) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Get wallet failed (code ${response.statusCode})');
    } catch (e, stack) {
      logger.e('[WALLET][GET] error', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
