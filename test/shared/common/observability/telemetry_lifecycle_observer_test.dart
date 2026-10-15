import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:dineroo_mobile/shared/common/observability/telemetry_lifecycle_observer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_span_exporter.dart';

void main() {
  group('TelemetryLifecycleObserver', () {
    late InMemorySpanExporter exporter;

    setUp(() {
      dotenv.testLoad(fileInput: '');
      exporter = InMemorySpanExporter();
      AppTelemetry.initWithExporter(exporter, serviceVersion: '1.0.0');
      AppTelemetry.tracer!.startSpan('last-user-action').end();
    });

    tearDown(AppTelemetry.reset);

    for (final state in [
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      test('flushes the buffered spans when the app is ${state.name}', () {
        TelemetryLifecycleObserver().didChangeAppLifecycleState(state);

        expect(exporter.spans.map((span) => span.name), ['last-user-action']);
      });
    }

    for (final state in [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
    ]) {
      test('keeps the spans buffered when the app is ${state.name}', () {
        TelemetryLifecycleObserver().didChangeAppLifecycleState(state);

        expect(exporter.spans, isEmpty);
      });
    }
  });
}
