import 'package:dineroo_mobile/customer/exceptions/order_creation_exception.dart';
import 'package:dineroo_mobile/customer/exceptions/order_estimation_exception.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/utils/date_utils.dart' as app_date;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
    await initializeDateFormatting('fr_FR');
  });

  group('ApiUriBuilder', () {
    test('builds API uri with query parameters and context', () {
      final uri = ApiUriBuilder.build(
        '/orders',
        queryParameters: {'page': '1'},
        context: ApiContext.customer,
      );

      expect(uri.path, endsWith('/orders'));
      expect(uri.queryParameters['page'], '1');
      expect(uri.queryParameters['context'], 'CUSTOMER');
    });

    test('omits query parameters when none are provided', () {
      final uri = ApiUriBuilder.build('/health');

      expect(uri.path, endsWith('/health'));
      expect(uri.queryParameters, isEmpty);
    });
  });

  group('date_utils', () {
    test('formats date time with French abbreviated month', () {
      final formatted = app_date.formatDateTime(DateTime(2026, 1, 3, 9, 5));

      expect(formatted, contains('03'));
      expect(formatted, contains('09:05'));
    });
  });

  group('order exceptions', () {
    test('OrderCreationException keeps response details', () {
      final exception = OrderCreationException(
        statusCode: 409,
        body: 'conflict',
        unavailableItems: ['Burger'],
      );

      expect(exception.statusCode, 409);
      expect(exception.body, 'conflict');
      expect(exception.unavailableItems, ['Burger']);
      expect(exception.toString(), 'OrderCreationException(statusCode: 409)');
    });

    test('OrderEstimationException keeps response details', () {
      final exception = OrderEstimationException(
        statusCode: 500,
        body: 'server error',
      );

      expect(exception.statusCode, 500);
      expect(exception.body, 'server error');
      expect(exception.toString(), 'OrderEstimationException(statusCode: 500)');
    });
  });
}
