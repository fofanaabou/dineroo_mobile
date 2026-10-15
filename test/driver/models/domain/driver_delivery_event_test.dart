import 'package:dineroo_mobile/driver/models/domain/driver_delivery_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverDeliveryEvent', () {
    test('parses json with safe defaults', () {
      final event = DriverDeliveryEvent.fromJson({
        'deliveryId': 'delivery-1',
        'orderId': 'order-1',
        'deliveryAddress': 'Client',
        'pickupAddress': 'Restaurant',
        'restaurantName': 'Dineroo Food',
        'estimatedDeliveryDistance': 3,
        'deliveryFee': 12000,
        'driverIds': ['driver-1', 2],
      });

      expect(event.deliveryId, 'delivery-1');
      expect(event.orderId, 'order-1');
      expect(event.deliveryAddress, 'Client');
      expect(event.pickupAddress, 'Restaurant');
      expect(event.restaurantName, 'Dineroo Food');
      expect(event.estimatedDeliveryDistance, 3);
      expect(event.deliveryFee, 12000);
      expect(event.driverIds, ['driver-1', '2']);
    });

    test('serializes to json', () {
      final event = _event();

      expect(event.toJson(), {
        'deliveryId': 'delivery-1',
        'orderId': 'order-1',
        'deliveryAddress': 'Client',
        'pickupAddress': 'Restaurant',
        'restaurantName': 'Dineroo Food',
        'estimatedDeliveryDistance': 3.5,
        'deliveryFee': 12000.0,
        'driverIds': ['driver-1'],
      });
    });

    test('copyWith updates selected fields and keeps the rest', () {
      final updated = _event().copyWith(
        restaurantName: 'Nouveau resto',
        deliveryFee: 15000,
      );

      expect(updated.deliveryId, 'delivery-1');
      expect(updated.orderId, 'order-1');
      expect(updated.restaurantName, 'Nouveau resto');
      expect(updated.deliveryFee, 15000);
      expect(updated.driverIds, ['driver-1']);
    });

    test('toString contains useful delivery information', () {
      expect(_event().toString(), contains('delivery-1'));
      expect(_event().toString(), contains('Dineroo Food'));
    });
  });
}

DriverDeliveryEvent _event() {
  return DriverDeliveryEvent(
    deliveryId: 'delivery-1',
    orderId: 'order-1',
    deliveryAddress: 'Client',
    pickupAddress: 'Restaurant',
    restaurantName: 'Dineroo Food',
    estimatedDeliveryDistance: 3.5,
    deliveryFee: 12000,
    driverIds: ['driver-1'],
  );
}
