@TestOn('browser')
library;

import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PushNotificationService service;

  setUp(() => service = PushNotificationService()..debugResetForTesting());

  tearDown(() => service.debugResetForTesting());

  group('PushNotificationService in a browser', () {
    test('initialize completes without initializing Firebase push', () async {
      await expectLater(service.initialize(), completes);
    });

    test(
      'unregisterUserDeviceToken completes so logout is not blocked',
      () async {
        await expectLater(
          service.unregisterUserDeviceToken('user-1'),
          completes,
        );
      },
    );
  });
}
