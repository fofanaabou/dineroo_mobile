import 'dart:convert';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'fake_stomp_client.dart';

void main() {
  late StompRealtimeService service;
  late FakeStompClient fakeClient;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
    fakeClient = FakeStompClient(config: StompConfig(url: ''));
    StompRealtimeService.clientFactory = (config) {
      fakeClient = FakeStompClient(config: config);
      return fakeClient;
    };
    service = StompRealtimeService();
  });

  tearDown(() async {
    StompRealtimeService.clientFactory = null;
    await service.disconnect();
  });

  group('initial state', () {
    test('is not connected', () {
      expect(service.isConnected, false);
    });
  });

  group('connect', () {
    test('creates client and connects', () async {
      await service.connect(
        token: 'test-token',
        userRole: 'DRIVER',
        restaurantId: 'rest-1',
        userId: 'user-1',
      );

      expect(service.isConnected, true);
    });

    test('does not connect if already connected', () async {
      await service.connect(token: 'test-token', userRole: 'DRIVER');
      await service.connect(token: 'test-token2', userRole: 'MANAGER');

      expect(service.isConnected, true);
    });
  });

  group('subscribe', () {
    test('subscribes to destination when connected', () async {
      await service.connect(token: 'test-token', userRole: 'DRIVER');
      await Future(() {});

      String? receivedBody;
      await service.subscribe(
        destination: '/topic/drivers/user-1',
        onMessage: (body) {
          receivedBody = body;
        },
      );

      expect(receivedBody, isNull);

      final callback = fakeClient.subscriptions['/topic/drivers/user-1'];
      expect(callback, isNotNull);

      callback!.call(StompFrame(command: 'MESSAGE', body: '{"key":"val"}'));
      expect(receivedBody, '{"key":"val"}');
    });

    test('defers subscription when not connected', () async {
      await service.subscribe(destination: '/topic/test', onMessage: (_) {});

      await service.connect(token: 'test-token', userRole: 'DRIVER');
      await Future(() {});
      await Future(() {});

      final callback = fakeClient.subscriptions['/topic/test'];
      expect(callback, isNotNull);
    });
  });

  group('unsubscribe', () {
    test('removes subscription from active subscriptions', () async {
      await service.connect(token: 'test-token', userRole: 'DRIVER');
      await Future(() {});

      await service.subscribe(
        destination: '/topic/drivers/user-1',
        onMessage: (_) {},
      );

      service.unsubscribe('/topic/drivers/user-1');

      expect(fakeClient.subscriptions['/topic/drivers/user-1'], isNull);
    });
  });

  group('disconnect', () {
    test('disconnects and clears session', () async {
      await service.connect(token: 'test-token', userRole: 'DRIVER');
      expect(service.isConnected, true);

      await service.disconnect();
      expect(service.isConnected, false);
    });
  });

  group('sendDriverLocation', () {
    test('sends driver location when connected', () async {
      await service.connect(
        token: 'test-token',
        userRole: 'DRIVER',
        userId: 'driver-1',
      );

      service.sendDriverLocation(
        driverId: 'driver-1',
        longitude: 10.5,
        latitude: 20.3,
      );

      expect(fakeClient.sentMessages.length, 1);
      expect(fakeClient.sentMessages[0]['destination'], '/app/driver-location');
      final body = jsonDecode(fakeClient.sentMessages[0]['body'] as String);
      expect(body['driverId'], 'driver-1');
      expect(body['longitude'], 10.5);
      expect(body['latitude'], 20.3);
    });

    test('does not send when not connected', () async {
      service.sendDriverLocation(
        driverId: 'driver-1',
        longitude: 10.5,
        latitude: 20.3,
      );

      expect(fakeClient.sentMessages, isEmpty);
    });
  });
}
