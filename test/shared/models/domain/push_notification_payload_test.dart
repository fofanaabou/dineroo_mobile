import 'package:dineroo_mobile/shared/enums/push_notification_data_keys.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNotificationPayload', () {
    test('parses typed payload data', () {
      final payload = PushNotificationPayload.fromData({
        PushNotificationDataKeys.type: 'driver_delivery_assigned',
        PushNotificationDataKeys.orderId: 1,
        PushNotificationDataKeys.deliveryId: 'delivery-1',
        PushNotificationDataKeys.status: 'ASSIGNED',
      });

      expect(payload.type, PushNotificationType.driverDeliveryAssigned);
      expect(payload.orderId, '1');
      expect(payload.deliveryId, 'delivery-1');
      expect(payload.status, 'ASSIGNED');
    });

    test('uses nulls for missing or unsupported values', () {
      final payload = PushNotificationPayload.fromData({
        PushNotificationDataKeys.type: 'unsupported',
      });

      expect(payload.type, isNull);
      expect(payload.orderId, isNull);
      expect(payload.deliveryId, isNull);
      expect(payload.status, isNull);
    });
  });
}
