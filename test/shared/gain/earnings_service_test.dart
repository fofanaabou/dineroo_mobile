import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dineroo_mobile/shared/gain/earnings_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late List<String> paths;

  tearDown(() async {
    await server.close(force: true);
  });

  Future<EarningsService> startService(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    paths = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.host}:${server.port}';
    dotenv.testLoad(fileInput: 'API_BASE_URL=$baseUrl');
    unawaited(() async {
      await for (final request in server) {
        paths.add(request.uri.path);
        await handler(request);
      }
    }());
    return EarningsService(dio: Dio());
  }

  group('EarningsService', () {
    test('fetchRestaurantEarnings combines earnings with paid amount', () async {
      final service = await startService((request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json;
        if (request.uri.path.endsWith('/earnings')) {
          request.response.write(jsonEncode({
            'totalEarned': 1000,
            'completedOrdersCount': 4,
            'currency': 'GNF',
          }));
        } else {
          request.response.write(jsonEncode({'paidAmount': 250}));
        }
        return request.response.close();
      });

      final summary = await service.fetchRestaurantEarnings('restaurant-1');

      expect(paths, [
        '/v1/restaurant-orders/restaurant-1/earnings',
        '/v1/payouts/restaurants/restaurant-1/summary',
      ]);
      expect(summary.totalEarned, 1000);
      expect(summary.paidAmount, 250);
      expect(summary.availableAmount, 750);
      expect(summary.completedOrdersCount, 4);
    });

    test('fetchDriverEarnings clamps negative available amount to zero', () async {
      final service = await startService((request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json;
        if (request.uri.path.endsWith('/earnings')) {
          request.response.write(jsonEncode({'totalEarned': '100', 'completedOrdersCount': 1}));
        } else {
          request.response.write(jsonEncode({'paidAmount': '150'}));
        }
        return request.response.close();
      });

      final summary = await service.fetchDriverEarnings('driver-1');

      expect(paths, [
        '/v1/drivers/driver-1/earnings',
        '/v1/payouts/drivers/driver-1/summary',
      ]);
      expect(summary.availableAmount, 0);
      expect(summary.paidAmount, 150);
    });

    test('retries once on server errors before succeeding', () async {
      var earningsAttempts = 0;
      final service = await startService((request) {
        if (request.uri.path.endsWith('/earnings')) {
          earningsAttempts++;
          if (earningsAttempts == 1) {
            request.response.statusCode = HttpStatus.internalServerError;
            return request.response.close();
          }
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'totalEarned': 500, 'completedOrdersCount': 2}));
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'paidAmount': 100}));
        }
        return request.response.close();
      });

      final summary = await service.fetchRestaurantEarnings('restaurant-1');

      expect(earningsAttempts, 2);
      expect(summary.availableAmount, 400);
    });

    test('throws after repeated failures', () async {
      final service = await startService((request) {
        request.response.statusCode = HttpStatus.internalServerError;
        return request.response.close();
      });

      await expectLater(
        service.fetchRestaurantEarnings('restaurant-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
