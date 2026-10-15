import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class ProductService {
  final Dio _dio;

  ProductService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> fetchProductDetail(
    String restaurantId,
    String productId,
  ) async {
    try {
      final response = await _dio.get(
        ApiUriBuilder.build(
          ApiConstants.restaurantCatalogueProductById(restaurantId, productId),
        ).toString(),
      );

      if (response.statusCode == HttpStatusCode.ok.code) {
        final data = response.data;
        return data is String
            ? jsonDecode(data) as Map<String, dynamic>
            : data as Map<String, dynamic>;
      }

      logger.e(
        'Failed to load product detail (status code: ${response.statusCode})',
        error: response.data,
      );
      throw Exception(
        'Failed to load product detail (status code: ${response.statusCode})',
      );
    } catch (e, stack) {
      logger.e('Failed to load product detail', error: e, stackTrace: stack);
      throw Exception('Failed to load product detail (error: $e)');
    }
  }
}
