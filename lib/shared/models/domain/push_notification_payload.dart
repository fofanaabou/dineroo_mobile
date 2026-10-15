import 'package:dineroo_mobile/shared/enums/push_notification_data_keys.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';

class PushNotificationPayload {
  final PushNotificationType? type;
  final String? orderId;
  final String? deliveryId;
  final String? status;

  const PushNotificationPayload({
    this.type,
    this.orderId,
    this.deliveryId,
    this.status,
  });

  factory PushNotificationPayload.fromData(Map<String, dynamic> data) {
    return PushNotificationPayload(
      type: PushNotificationType.fromWireValue(
        data[PushNotificationDataKeys.type]?.toString(),
      ),
      orderId: data[PushNotificationDataKeys.orderId]?.toString(),
      deliveryId: data[PushNotificationDataKeys.deliveryId]?.toString(),
      status: data[PushNotificationDataKeys.status]?.toString(),
    );
  }
}
