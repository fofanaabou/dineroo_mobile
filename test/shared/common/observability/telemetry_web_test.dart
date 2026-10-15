@TestOn('browser')
library;

import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppTelemetry.reset);

  group('AppTelemetry in a browser', () {
    // The OTLP collector answers a browser's CORS preflight with 405 and no CORS headers, so
    // every upload is blocked and floods the console. Tracing stays off until it allows the origin.
    test('stays disabled even when an OTLP endpoint is configured', () {
      dotenv.testLoad(
        fileInput:
            'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://collector.test/v1/traces',
      );

      AppTelemetry.init(serviceVersion: '1.0.0');

      expect(AppTelemetry.isEnabled, isFalse);
      expect(AppTelemetry.tracer, isNull);
    });
  });
}
