import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class DriverPresenceService {
  final Dio _dio;

  DriverPresenceService({Dio? dio}) : _dio = dio ?? createDioClient();
  Future<Map<String, dynamic>> fetchDriverById({
    required String driverId,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.driverById(driverId));

    try {
      final res = await _dio.get(
        url.toString(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final statusCode = res.statusCode ?? 0;
      if (statusCode < HttpStatusCode.ok.code ||
          statusCode >= HttpStatusCode.multipleChoices.code) {
        logger.e('fetchDriverById failed', error: res.data);
        throw Exception('Fetch driver failed ($statusCode)');
      }

      return res.data as Map<String, dynamic>;
    } catch (e, stack) {
      logger.e(
        '[DriverPresenceService] fetchDriverById error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.driverById(driverId));

    try {
      final res = await _dio.put(
        url.toString(),
        data: {'status': status},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final statusCode = res.statusCode ?? 0;
      if (statusCode < HttpStatusCode.ok.code ||
          statusCode >= HttpStatusCode.multipleChoices.code) {
        logger.e('updateDriverStatus failed', error: res.data);
        throw Exception('Update driver status failed ($statusCode)');
      }

      if (res.data == null || res.data.toString().isEmpty) {
        return {'driverId': driverId, 'status': status};
      }

      return res.data as Map<String, dynamic>;
    } catch (e, stack) {
      logger.e(
        '[DriverPresenceService] updateDriverStatus error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
