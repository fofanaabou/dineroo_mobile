import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderEvent', () {
    test('parses json and exposes status enum', () {
      final event = OrderEvent.fromJson({
        'restaurantId': 1,
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'status': 'READY',
      });

      expect(event.restaurantId, '1');
      expect(event.customerId, 'customer-1');
      expect(event.orderId, 'order-1');
      expect(event.status, 'READY');
      expect(event.statusEnum, OrderStatus.readyForPickup);
    });

    test('serializes to json and string', () {
      final event = OrderEvent(
        restaurantId: 'restaurant-1',
        customerId: 'customer-1',
        orderId: 'order-1',
        status: 'PENDING',
      );

      expect(event.toJson(), {
        'restaurantId': 'restaurant-1',
        'customerId': 'customer-1',
        'orderId': 'order-1',
        'status': 'PENDING',
      });
      expect(event.toString(), contains('order-1'));
      expect(event.toString(), contains('PENDING'));
    });

    test('uses empty string defaults', () {
      final event = OrderEvent.fromJson({});

      expect(event.restaurantId, '');
      expect(event.customerId, '');
      expect(event.orderId, '');
      expect(event.status, '');
    });
  });
}
