import 'dart:async';
import 'dart:io';

import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:dineroo_mobile/shared/common/observability/tracing_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' show ReadOnlySpan;

import 'in_memory_span_exporter.dart';

void main() {
  HttpServer? server;

  /// Starts a loopback server that runs [handler] for each request and returns its base URL.
  Future<String> startServer(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    final started = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server = started;
    unawaited(() async {
      await for (final request in started) {
        await handler(request);
      }
    }());
    return 'http://${started.address.host}:${started.port}';
  }

  Future<void> respondWith(HttpRequest request, int statusCode) {
    request.response.statusCode = statusCode;
    return request.response.close();
  }

  Dio client() => Dio()..interceptors.add(TracingInterceptor());

  setUp(() => dotenv.testLoad(fileInput: ''));

  tearDown(() async {
    AppTelemetry.reset();
    await server?.close(force: true);
    server = null;
  });

  group('while tracing is disabled', () {
    test('sends the request untouched and succeeds', () async {
      String? receivedTraceparent;
      final baseUrl = await startServer((request) {
        receivedTraceparent = request.headers.value('traceparent');
        return respondWith(request, HttpStatus.ok);
      });

      final response = await client().get('$baseUrl/ping');

      expect(response.statusCode, HttpStatus.ok);
      expect(receivedTraceparent, isNull);
    });

    test('lets the error through untouched', () async {
      String? receivedTraceparent;
      final baseUrl = await startServer((request) {
        receivedTraceparent = request.headers.value('traceparent');
        return respondWith(request, HttpStatus.badGateway);
      });

      await expectLater(
        client().get('$baseUrl/boom'),
        throwsA(isA<DioException>()),
      );
      expect(receivedTraceparent, isNull);
    });
  });

  group('once tracing is enabled', () {
    late InMemorySpanExporter exporter;

    setUp(() {
      exporter = InMemorySpanExporter();
      AppTelemetry.initWithExporter(exporter, serviceVersion: 'test-version');
    });

    List<ReadOnlySpan> exportedSpans() {
      AppTelemetry.forceFlush();
      return exporter.spans;
    }

    test(
      'injects the traceparent of the span it ends with an ok status',
      () async {
        String? receivedTraceparent;
        final baseUrl = await startServer((request) {
          receivedTraceparent = request.headers.value('traceparent');
          return respondWith(request, HttpStatus.ok);
        });

        await client().get('$baseUrl/ping');

        final span = exportedSpans().single;
        expect(span.name, 'HTTP GET');
        expect(span.kind, SpanKind.client);
        expect(span.endTime, isNotNull);
        expect(span.status.code, StatusCode.ok);
        expect(span.attributes.get('http.response.status_code'), HttpStatus.ok);
        expect(
          receivedTraceparent,
          '00-${span.spanContext.traceId}-${span.spanContext.spanId}-01',
        );
      },
    );

    test(
      'ends the span with an error status and the exception when the server fails',
      () async {
        final baseUrl = await startServer(
          (request) => respondWith(request, HttpStatus.internalServerError),
        );

        await expectLater(
          client().get('$baseUrl/boom'),
          throwsA(isA<DioException>()),
        );

        final span = exportedSpans().single;
        expect(span.endTime, isNotNull);
        expect(span.status.code, StatusCode.error);
        expect(
          span.attributes.get('http.response.status_code'),
          HttpStatus.internalServerError,
        );
        expect(span.events.map((event) => event.name), ['exception']);
      },
    );

    test(
      'ends the span with an error status and no http status when the connection fails',
      () async {
        // Bind then close a server to get a port that refuses connections.
        final closedServer = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final unreachableUrl =
            'http://${closedServer.address.host}:${closedServer.port}';
        await closedServer.close(force: true);

        await expectLater(
          client().get('$unreachableUrl/unreachable'),
          throwsA(isA<DioException>()),
        );

        final span = exportedSpans().single;
        expect(span.endTime, isNotNull);
        expect(span.status.code, StatusCode.error);
        expect(span.attributes.get('http.response.status_code'), isNull);
        expect(span.events.map((event) => event.name), ['exception']);
      },
    );

    test('exports the url without its query string and fragment', () async {
      final baseUrl = await startServer(
        (request) => respondWith(request, HttpStatus.ok),
      );

      await client().get('$baseUrl/verify?token=secret-token&otp=123456#frag');

      final span = exportedSpans().single;
      expect(span.attributes.get('url.full'), '$baseUrl/verify');
    });

    test('exports the url without user info', () async {
      final baseUrl = await startServer(
        (request) => respondWith(request, HttpStatus.ok),
      );
      final urlWithUserInfo = baseUrl.replaceFirst('://', '://user:secret@');

      await client().get('$urlWithUserInfo/ping');

      final span = exportedSpans().single;
      expect(span.attributes.get('url.full'), '$baseUrl/ping');
    });

    test(
      'does not leak the query string through the recorded exception',
      () async {
        final baseUrl = await startServer(
          (request) => respondWith(request, HttpStatus.internalServerError),
        );

        await expectLater(
          client().get('$baseUrl/verify?token=secret-token'),
          throwsA(isA<DioException>()),
        );

        final exceptionEvent = exportedSpans().single.events.single;
        final exportedText = [
          exceptionEvent.name,
          ...exceptionEvent.attributes.map((attribute) => '${attribute.value}'),
        ].join(' ');
        expect(exportedText, isNot(contains('secret-token')));
      },
    );
  });
}
