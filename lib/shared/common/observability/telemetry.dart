import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:opentelemetry/api.dart' hide SpanExporter;
import 'package:opentelemetry/sdk.dart'
    show
        BatchSpanProcessor,
        CollectorExporter,
        Resource,
        SpanExporter,
        TracerProviderBase;

/// OpenTelemetry tracing for the mobile app.
///
/// Client spans (see [TracingInterceptor]) are exported to the observability Alloy OTLP/HTTP
/// receiver -> Tempo, and the W3C `traceparent` is propagated to the backend, so a user action
/// on the phone links to its backend trace. Errors/crashes are handled separately by Sentry ->
/// GlitchTip; this only covers traces (the division of labour in the observability spec).
///
/// No-op when `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` is unset (local dev without an obs stack),
/// mirroring the admin app's Faro init.
class AppTelemetry {
  AppTelemetry._();

  static TracerProviderBase? _provider;
  static Tracer? _tracer;
  static final TextMapPropagator _propagator = W3CTraceContextPropagator();

  static bool get isEnabled => _tracer != null;
  static Tracer? get tracer => _tracer;
  static TextMapPropagator get propagator => _propagator;

  /// Initialise the global tracer provider. Safe to call once at startup; a no-op when the
  /// OTLP endpoint isn't configured. [serviceVersion] tags spans with the app release.
  static void init({required String serviceVersion}) {
    if (_tracer != null) return; // idempotent

    final endpoint = dotenv.env['OTEL_EXPORTER_OTLP_TRACES_ENDPOINT'];
    if (endpoint == null || endpoint.isEmpty) return; // tracing disabled

    final provider = _buildProvider(
      CollectorExporter(Uri.parse(endpoint)),
      serviceVersion: serviceVersion,
    );
    registerGlobalTracerProvider(provider);
    _use(provider);
  }

  /// Exports the spans still buffered by the batch processor.
  ///
  /// The processor only exports on a timer, so the spans of the user's last actions would be
  /// lost if the OS suspends or kills the app before the next tick. The export is started, not
  /// awaited: the SDK exposes no completion signal.
  static void forceFlush() => _provider?.forceFlush();

  /// Starts tracing with [exporter] instead of the OTLP collector.
  ///
  /// The global tracer provider can be registered only once per isolate, so this skips it to
  /// let tests start and [reset] tracing repeatedly.
  @visibleForTesting
  static void initWithExporter(
    SpanExporter exporter, {
    required String serviceVersion,
  }) {
    if (_tracer != null) return;
    _use(_buildProvider(exporter, serviceVersion: serviceVersion));
  }

  /// Flushes and shuts down the current provider, returning to the disabled state.
  @visibleForTesting
  static void reset() {
    _provider?.shutdown();
    _provider = null;
    _tracer = null;
  }

  static TracerProviderBase _buildProvider(
    SpanExporter exporter, {
    required String serviceVersion,
  }) {
    final environment = dotenv.env['SENTRY_ENVIRONMENT'] ?? 'production';

    return TracerProviderBase(
      resource: Resource([
        Attribute.fromString('service.name', 'dineroo-mobile'),
        Attribute.fromString('service.version', serviceVersion),
        Attribute.fromString('deployment.environment', environment),
      ]),
      processors: [BatchSpanProcessor(exporter)],
    );
  }

  static void _use(TracerProviderBase provider) {
    _provider = provider;
    _tracer = provider.getTracer('dineroo-mobile');
  }
}
