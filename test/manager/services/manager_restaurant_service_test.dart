import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TestServer testServer;

  tearDown(() async {
    await testServer.close();
  });

  Future<ManagerRestaurantService> serviceWithServer(
    FutureOr<void> Function(HttpRequest request) handler, {
    Dio? dio,
  }) async {
    testServer = await _TestServer.start(handler);
    dotenv.testLoad(fileInput: 'API_BASE_URL=${testServer.baseUrl}');
    return ManagerRestaurantService(dio: dio ?? Dio());
  }

  group('ManagerRestaurantService', () {
    test('fetchRestaurant returns restaurant data with manager context', () async {
      final service = await serviceWithServer((request) {
        expect(request.method, 'GET');
        expect(request.uri.path, '/v1/restaurants/restaurant-1');
        expect(request.uri.queryParameters['context'], 'RESTAURANT');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'id': 'restaurant-1', 'openingHours': []}));
        return request.response.close();
      });

      final result = await service.fetchRestaurant(
        'restaurant-1',
        context: ApiContext.restaurant,
      );

      expect(result['id'], 'restaurant-1');
    });

    test('fetchRestaurant maps 404 to onboarding message', () async {
      final service = await serviceWithServer((request) {
        request.response.statusCode = HttpStatus.notFound;
        return request.response.close();
      });

      await expectLater(
        service.fetchRestaurant('restaurant-1', context: ApiContext.restaurant),
        throwsA(predicate((e) => e.toString().contains('pas encore disponible'))),
      );
    });

    test('fetchRestaurant uses response detail when Dio does not throw', () async {
      final dio = Dio(BaseOptions(validateStatus: (_) => true));
      final service = await serviceWithServer((request) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'detail': 'payload invalide'}));
        return request.response.close();
      }, dio: dio);

      await expectLater(
        service.fetchRestaurant('restaurant-1', context: ApiContext.restaurant),
        throwsA(predicate((e) => e.toString().contains('payload invalide'))),
      );
    });

    test('updateOpeningHours sends opening hours payload', () async {
      Map<String, dynamic>? body;
      final service = await serviceWithServer((request) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/v1/restaurants/restaurant-1');
        body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
        request.response.statusCode = HttpStatus.ok;
        return request.response.close();
      });

      await service.updateOpeningHours('restaurant-1', [
        {'day': 'MONDAY', 'open': '09:00', 'close': '18:00'},
      ]);

      expect(body, {
        'openingHours': [
          {'day': 'MONDAY', 'open': '09:00', 'close': '18:00'},
        ],
      });
    });

    test('updateOpeningHours maps 404 and backend detail errors', () async {
      var call = 0;
      final service = await serviceWithServer((request) {
        call++;
        if (call == 1) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'detail': 'horaires invalides'}));
        }
        return request.response.close();
      });

      await expectLater(
        service.updateOpeningHours('restaurant-1', []),
        throwsA(predicate((e) => e.toString().contains('réessayer plus tard'))),
      );
      await expectLater(
        service.updateOpeningHours('restaurant-1', []),
        throwsA(predicate((e) => e.toString().contains('horaires invalides'))),
      );
    });

    test('updateOpeningHours maps the suspension guard 403', () async {
      final service = await serviceWithServer((request) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'type': 'RESTAURANT_SUSPENDED',
              'title': 'Restaurant suspendu',
              'status': 403,
              'detail': 'Votre restaurant est suspendu.',
            }),
          );
        return request.response.close();
      });

      await expectLater(
        service.updateOpeningHours('restaurant-1', []),
        throwsA(isA<RestaurantSuspendedException>()),
      );
    });

    test('leaves an unrelated 403 as a generic failure', () async {
      final service = await serviceWithServer((request) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'type': 'AccessDeniedException',
              'detail': 'accès refusé',
            }),
          );
        return request.response.close();
      });

      await expectLater(
        service.updateOpeningHours('restaurant-1', []),
        throwsA(isNot(isA<RestaurantSuspendedException>())),
      );
    });
  });
}

class _TestServer {
  final HttpServer server;

  _TestServer(this.server);

  String get baseUrl => 'http://${server.address.host}:${server.port}';

  static Future<_TestServer> start(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(() async {
      await for (final request in server) {
        await handler(request);
      }
    }());
    return _TestServer(server);
  }

  Future<void> close() => server.close(force: true);
}
