import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:dio/dio.dart';
import 'package:opentelemetry/api.dart';

/// Writes propagation headers (the W3C `traceparent`) into a plain map carrier.
class _HeaderSetter implements TextMapSetter<Map<String, dynamic>> {
  const _HeaderSetter();

  @override
  void set(Map<String, dynamic> carrier, String key, String value) {
    carrier[key] = value;
  }
}

/// Opens a client span for each dio request, injects `traceparent` so the backend continues
/// the same trace (linking mobile -> backend in Tempo), and closes the span on response/error.
///
/// A no-op while tracing is disabled ([AppTelemetry.isEnabled] is false), so it's safe to add
/// to every dio client unconditionally.
class TracingInterceptor extends Interceptor {
  static const String _spanKey = 'otel_span';
  static const _HeaderSetter _setter = _HeaderSetter();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tracer = AppTelemetry.tracer;
    if (tracer == null) {
      handler.next(options);
      return;
    }

    final method = options.method.toUpperCase();
    final span = tracer.startSpan(
      'HTTP $method',
      kind: SpanKind.client,
      attributes: [
        Attribute.fromString('http.request.method', method),
        Attribute.fromString('url.full', _withoutSensitiveParts(options.uri)),
        Attribute.fromString('server.address', options.uri.host),
      ],
    );

    // Continue the trace on the backend: inject traceparent into the outgoing headers.
    AppTelemetry.propagator.inject(
      contextWithSpan(Context.current, span),
      options.headers,
      _setter,
    );

    options.extra[_spanKey] = span;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions, statusCode: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final span = err.requestOptions.extra[_spanKey];
    if (span is Span) {
      final code = err.response?.statusCode;
      if (code != null) {
        span.setAttribute(Attribute.fromInt('http.response.status_code', code));
      }
      span
        ..setStatus(StatusCode.error, err.message ?? err.type.name)
        ..recordException(err, stackTrace: err.stackTrace)
        ..end();
    }
    handler.next(err);
  }

  /// Spans are exported to Tempo, so keep only scheme, host, port and path: the user info, query
  /// string and fragment can carry tokens, OTPs, emails or other identifiers.
  static String _withoutSensitiveParts(Uri uri) => Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();

  void _finish(RequestOptions options, {int? statusCode}) {
    final span = options.extra[_spanKey];
    if (span is! Span) return;
    if (statusCode != null) {
      span.setAttribute(Attribute.fromInt('http.response.status_code', statusCode));
    }
    span
      ..setStatus(StatusCode.ok)
      ..end();
  }
}
