import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class DriverDeliveryService {
  final Dio _dio;

  DriverDeliveryService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> assignDriver({
    required String driverId,
    required String deliveryId,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.deliveryAssignDriver());

    try {
      final response = await _dio.put(
        url.toString(),
        data: {'driverId': driverId, 'deliveryId': deliveryId},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          '[DriverDeliveryService] assignDriver failed '
          '[${response.statusCode}]',
          error: response.data,
        );
        throw Exception(
          'Assign driver failed (${response.statusCode}): ${response.data}',
        );
      }

      if (response.data == null || response.data.toString().isEmpty) {
        return {
          'driverId': driverId,
          'deliveryId': deliveryId,
          'driverStatus': 'ONLINE',
          'deliveryStatus': 'PENDING',
        };
      }

      return response.data as Map<String, dynamic>;
    } catch (e, stack) {
      logger.e(
        '[DriverDeliveryService] assignDriver error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<List<dynamic>> fetchDeliveriesByDriverId({
    required String driverId,
    List<String>? statuses,
  }) async {
    final queryParameters = <String, String>{
      if (statuses != null && statuses.isNotEmpty)
        'statuses': statuses.join(','),
    };
    final url = ApiUriBuilder.build(
      ApiConstants.driverDeliveries(driverId),
      queryParameters: queryParameters,
    );

    try {
      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status != HttpStatusCode.unauthorized.code &&
              status != HttpStatusCode.forbidden.code &&
              status < 500,
        ),
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          '[DriverDeliveryService] fetchDeliveriesByDriverId failed '
          '[${response.statusCode}]',
          error: response.data,
        );
        throw Exception(
          'Fetch deliveries by driver failed (${response.statusCode}): ${response.data}',
        );
      }

      final decoded = response.data;
      if (decoded is List) return decoded;
      return <dynamic>[];
    } catch (e, stack) {
      logger.e(
        '[DriverDeliveryService] fetchDeliveriesByDriverId error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? driverId,
    double? latitude,
    double? longitude,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.deliveryStatus(deliveryId));

    try {
      final response = await _dio.put(
        url.toString(),
        data: {
          'status': status,
          if (driverId != null) 'driverId': driverId,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
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

      if (response.statusCode != HttpStatusCode.ok.code) {
        final message = _extractErrorMessage(response.data);
        logger.e(
          '[DriverDeliveryService] updateDeliveryStatus failed '
          '[${response.statusCode}]',
          error: response.data,
        );
        throw Exception(message ?? 'Update delivery status failed');
      }

      if (response.data == null || response.data.toString().isEmpty) {
        return {'deliveryId': deliveryId, 'status': status};
      }

      return response.data as Map<String, dynamic>;
    } catch (e, stack) {
      logger.e(
        '[DriverDeliveryService] updateDeliveryStatus error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  String? _extractErrorMessage(dynamic body) {
    if (body == null || body.toString().trim().isEmpty) return null;
    if (body is Map<String, dynamic>) {
      return body['message']?.toString();
    }
    return null;
  }
}
