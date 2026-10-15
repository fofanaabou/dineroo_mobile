import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class OrderListService {
  final Dio _dio;

  OrderListService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<List<Map<String, dynamic>>> fetchOrders(String customerId) async {
    final url = ApiUriBuilder.build(ApiConstants.customerOrders(customerId));

    try {
      final response = await _dio.get(url.toString());
      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'Failed to fetch orders (status: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Failed to fetch orders');
      }

      final List<dynamic> jsonList = response.data as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      logger.e('Error while fetching orders', error: e, stackTrace: stack);
      throw Exception('Erreur de connexion réseau ou serveur');
    }
  }
}
