import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/gain/earnings_summary.dart';
import 'package:dineroo_mobile/shared/gain/payout_summary.dart';

class EarningsService {
  final Dio _dio;

  EarningsService({Dio? dio}) : _dio = dio ?? createDioClient();

  static const int _maxAttempts = 2;

  Future<EarningsSummary> fetchRestaurantEarnings(String restaurantId) async {
    return _fetchWithPayouts(
      earningsPath: ApiConstants.restaurantEarnings(restaurantId),
      payoutSummaryPath: ApiConstants.restaurantPayoutSummary(restaurantId),
    );
  }

  Future<EarningsSummary> fetchDriverEarnings(String driverId) async {
    return _fetchWithPayouts(
      earningsPath: ApiConstants.driverEarnings(driverId),
      payoutSummaryPath: ApiConstants.driverPayoutSummary(driverId),
    );
  }

  Future<EarningsSummary> _fetchWithPayouts({
    required String earningsPath,
    required String payoutSummaryPath,
  }) async {
    final earnings = await _fetch(earningsPath);
    final payouts = await _fetchPayoutSummary(payoutSummaryPath);
    return earnings.applyPaidAmount(payouts.paidAmount);
  }

  Future<EarningsSummary> _fetch(String path) async {
    final decoded = await _fetchJson(path, logPrefix: 'earnings');
    return EarningsSummary.fromJson(decoded);
  }

  Future<PayoutSummary> _fetchPayoutSummary(String path) async {
    final decoded = await _fetchJson(path, logPrefix: 'payout summary');
    return PayoutSummary.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _fetchJson(
    String path, {
    required String logPrefix,
  }) async {
    final url = ApiUriBuilder.build(path);

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          url.toString(),
          options: Options(
            headers: {'Content-Type': 'application/json'},
            validateStatus: (status) =>
                status != null &&
                ((status >= 200 && status < 300) || status >= 500),
          ),
        );

        if (response.statusCode == HttpStatusCode.ok.code) {
          return response.data as Map<String, dynamic>;
        }

        final statusCode = response.statusCode ?? 0;
        final canRetry = statusCode >= 500 && attempt < _maxAttempts;
        if (canRetry) {
          logger.w(
            '[EarningsService] $logPrefix failed [$statusCode] '
            '(attempt $attempt/$_maxAttempts), retrying...',
            error: response.data,
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        logger.e(
          '[EarningsService] $logPrefix failed [$statusCode]',
          error: response.data,
        );
        throw Exception('Failed to fetch $logPrefix');
      } catch (e, stack) {
        if (attempt < _maxAttempts) {
          logger.w(
            '[EarningsService] $logPrefix temporary error '
            '(attempt $attempt/$_maxAttempts), retrying...',
            error: e,
            stackTrace: stack,
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        logger.e(
          '[EarningsService] $logPrefix error',
          error: e,
          stackTrace: stack,
        );
        rethrow;
      }
    }

    throw Exception('Failed to fetch $logPrefix');
  }
}
