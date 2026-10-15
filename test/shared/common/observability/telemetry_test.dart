import 'dart:async';
import 'dart:io';

import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opentelemetry/api.dart';

import 'in_memory_span_exporter.dart';

void main() {
  test(
    'is disabled and exposes no tracer when the OTLP endpoint is unset',
    () {
      dotenv.testLoad(fileInput: '');

      AppTelemetry.init(serviceVersion: '1.0.0');

      expect(AppTelemetry.isEnabled, isFalse);
      expect(AppTelemetry.tracer, isNull);
    },
  );

  test('exposes a W3C trace context propagator', () {
    expect(AppTelemetry.propagator, isA<W3CTraceContextPropagator>());
  });

  group('when the OTLP endpoint is configured', () {
    late HttpServer collectorServer;

    setUpAll(() async {
      collectorServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        await for (final request in collectorServer) {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
        }
      }());
      final endpoint =
          'http://${collectorServer.address.host}:${collectorServer.port}';
      dotenv.testLoad(
        fileInput:
            'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$endpoint\n'
            'SENTRY_ENVIRONMENT=staging',
      );

      AppTelemetry.init(serviceVersion: '1.2.3');
    });

    tearDownAll(() async {
      AppTelemetry.reset();
      await collectorServer.close(force: true);
    });

    test('enables tracing and registers a tracer', () {
      expect(AppTelemetry.isEnabled, isTrue);
      expect(AppTelemetry.tracer, isNotNull);
    });

    test('is idempotent - re-initialising keeps the existing tracer', () {
      final tracer = AppTelemetry.tracer;

      AppTelemetry.init(serviceVersion: 'ignored-version');

      expect(AppTelemetry.tracer, same(tracer));
    });
  });

  group('forceFlush', () {
    late InMemorySpanExporter exporter;

    setUp(() {
      dotenv.testLoad(fileInput: '');
      exporter = InMemorySpanExporter();
    });

    tearDown(AppTelemetry.reset);

    test('exports the spans still buffered by the batch processor', () {
      AppTelemetry.initWithExporter(exporter, serviceVersion: '1.0.0');
      AppTelemetry.tracer!.startSpan('buffered').end();
      expect(exporter.spans, isEmpty);

      AppTelemetry.forceFlush();

      expect(exporter.spans.map((span) => span.name), ['buffered']);
    });

    test('does nothing while tracing is disabled', () {
      expect(AppTelemetry.isEnabled, isFalse);

      expect(AppTelemetry.forceFlush, returnsNormally);
    });
  });
}
