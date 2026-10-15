import 'dart:io';

import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;
  late PushNotificationService service;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp(
      'push_notification_service_test_',
    );
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    service = PushNotificationService()..debugResetForTesting();
    if (Hive.isBoxOpen('push_sync')) {
      await Hive.box('push_sync').clear();
    }
  });

  tearDown(() {
    service.debugResetForTesting();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('PushNotificationService', () {
    test('stores and clears pending opened messages', () {
      service.debugQueueOpenedMessage({'orderId': 'order-1'});

      expect(service.takePendingOpenedMessage(), {'orderId': 'order-1'});
      expect(service.takePendingOpenedMessage(), isNull);
    });

    test('emits opened messages when queued', () async {
      final emitted = expectLater(
        service.openedMessages,
        emits({'deliveryId': 'delivery-1'}),
      );

      service.debugQueueOpenedMessage({'deliveryId': 'delivery-1'});

      await emitted;
    });

    test('stores pending navigation payload defensively and clears it', () {
      final payload = {'orderId': 'order-1'};

      service.savePendingNavigationPayload(payload);
      payload['orderId'] = 'mutated';

      expect(service.takePendingNavigationPayload(), {'orderId': 'order-1'});
      expect(service.takePendingNavigationPayload(), isNull);
    });

    test('previews short and long tokens', () {
      expect(service.debugTokenPreview('short-token'), 'short-token');
      expect(
        service.debugTokenPreview('1234567890abcdefghijklmnop'),
        '12345678...ijklmnop',
      );
    });

    test('detects push types that need realtime fallback', () {
      expect(
        service.debugShouldTriggerRealtimeFallbackFromPush({
          'type': 'driver_delivery_assigned',
        }),
        isTrue,
      );
      expect(
        service.debugShouldTriggerRealtimeFallbackFromPush({
          'type': 'delivery_assigned',
        }),
        isTrue,
      );
      expect(
        service.debugShouldTriggerRealtimeFallbackFromPush({
          'type': 'order_ready',
        }),
        isFalse,
      );
      expect(service.debugShouldTriggerRealtimeFallbackFromPush({}), isFalse);
    });

    test('queues local notification payload when it contains JSON map', () {
      service.debugHandleLocalNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{"orderId":"order-1","status":"ready"}',
        ),
      );

      expect(service.takePendingOpenedMessage(), {
        'orderId': 'order-1',
        'status': 'ready',
      });
    });

    test('ignores empty, non-map, and invalid local notification payloads', () {
      service.debugHandleLocalNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );
      service.debugHandleLocalNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '["not", "a", "map"]',
        ),
      );
      service.debugHandleLocalNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{invalid-json',
        ),
      );

      expect(service.takePendingOpenedMessage(), isNull);
    });

    test(
      'decides whether silent token sync is needed from last sync timestamp',
      () async {
        expect(await service.debugShouldSilentlySyncDeviceToken(), isTrue);

        await service.debugMarkSilentPushSyncNow();
        expect(await service.debugShouldSilentlySyncDeviceToken(), isFalse);

        final syncBox = await Hive.openBox('push_sync');
        await syncBox.put(
          'lastPushSyncAt',
          DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        );
        expect(await service.debugShouldSilentlySyncDeviceToken(), isTrue);

        await syncBox.put('lastPushSyncAt', 'not-a-date');
        expect(await service.debugShouldSilentlySyncDeviceToken(), isTrue);
      },
    );
  });
}
