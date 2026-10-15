import 'package:dineroo_mobile/shared/realtime/realtime_lifecycle_observer.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_stomp_client.dart';

void main() {
  group('RealtimeLifecycleObserver', () {
    StompRealtimeService? service;

    setUp(() async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
      StompRealtimeService.clientFactory = (config) =>
          FakeStompClient(config: config);
      service = StompRealtimeService();
      await service!.connect(token: 'test', userRole: 'DRIVER');
      await Future(() {});
      RealtimeLifecycleObserver.stompServiceOverride = service;
    });

    tearDown(() {
      StompRealtimeService.clientFactory = null;
      RealtimeLifecycleObserver.stompServiceOverride = null;
    });

    test('reconnects on resume', () {
      final observer = RealtimeLifecycleObserver();
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(service!.isConnected, true);
    });

    test('stays connected on inactive', () {
      final observer = RealtimeLifecycleObserver();
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);

      expect(service!.isConnected, true);
    });

    test('stays connected on hidden', () {
      final observer = RealtimeLifecycleObserver();
      observer.didChangeAppLifecycleState(AppLifecycleState.hidden);

      expect(service!.isConnected, true);
    });

    test('disconnects on pause without clearing session', () {
      final observer = RealtimeLifecycleObserver();
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(service!.isConnected, false);
    });

    test('disconnects on detached clearing session', () {
      final observer = RealtimeLifecycleObserver();
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(service!.isConnected, false);
    });
  });
}
