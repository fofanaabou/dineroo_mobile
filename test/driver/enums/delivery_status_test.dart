import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryStatus', () {
    test('parses API values with pending fallback', () {
      expect(DeliveryStatus.fromApi(' assigned '), DeliveryStatus.assigned);
      expect(DeliveryStatus.fromApi('PICKED_UP'), DeliveryStatus.pickedUp);
      expect(DeliveryStatus.fromApi('DELIVERED'), DeliveryStatus.delivered);
      expect(DeliveryStatus.fromApi('CANCELED'), DeliveryStatus.canceled);
      expect(DeliveryStatus.fromApi('PENDING'), DeliveryStatus.pending);
      expect(DeliveryStatus.fromApi(null), DeliveryStatus.pending);
      expect(DeliveryStatus.fromApi('unsupported'), DeliveryStatus.pending);
    });

    test('exposes api values', () {
      expect(DeliveryStatus.pending.apiValue, 'PENDING');
      expect(DeliveryStatus.assigned.apiValue, 'ASSIGNED');
      expect(DeliveryStatus.pickedUp.apiValue, 'PICKED_UP');
      expect(DeliveryStatus.delivered.apiValue, 'DELIVERED');
      expect(DeliveryStatus.canceled.apiValue, 'CANCELED');
    });
  });
}
