import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:dineroo_mobile/driver/models/domain/driver_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverDelivery', () {
    test('parses json maps, numbers, dates, and status', () {
      final delivery = DriverDelivery.fromJson({
        'id': 'delivery-1',
        'orderId': 'order-1',
        'driverId': 'driver-1',
        'status': ' picked_up ',
        'pickupAddress': {
          'address': 'Restaurant',
          'district': 'Kipé',
          'commune': 'Ratoma',
        },
        'deliveryAddress': {
          'address': 'Maison',
          'district': 'Nongo',
          'commune': 'Ratoma',
        },
        'fee': 15000,
        'distanceKm': '4.5',
        'driverAssignedAt': '2026-01-01T10:00:00Z',
        'pickedUpAt': '2026-01-01T10:15:00Z',
        'createdAt': '2026-01-01T09:30:00Z',
      });

      expect(delivery.id, 'delivery-1');
      expect(delivery.orderId, 'order-1');
      expect(delivery.driverId, 'driver-1');
      expect(delivery.status, DeliveryStatus.pickedUp);
      expect(delivery.deliveryFee, 15000);
      expect(delivery.estimatedDeliveryDistance, 4.5);
      expect(delivery.driverAssignedAt, DateTime.parse('2026-01-01T10:00:00Z'));
      expect(delivery.pickedUpAt, DateTime.parse('2026-01-01T10:15:00Z'));
      expect(delivery.createdAt, DateTime.parse('2026-01-01T09:30:00Z'));
      expect(delivery.pickupAddressLabel, 'Restaurant, Kipé, Ratoma');
      expect(delivery.deliveryAddressLabel, 'Maison, Nongo, Ratoma');
    });

    test('parses json encoded and plain string addresses', () {
      final delivery = DriverDelivery.fromJson({
        'status': 'ASSIGNED',
        'pickupAddress': '{"address":"Resto","district":"Miniere"}',
        'deliveryAddress': 'Adresse libre',
      });

      expect(delivery.pickupAddressLabel, 'Resto, Miniere');
      expect(delivery.deliveryAddressLabel, 'Adresse libre');
    });

    test('parses pickupOtpCode from json', () {
      final delivery = DriverDelivery.fromJson({
        'status': 'ASSIGNED',
        'pickupOtpCode': '1234',
      });

      expect(delivery.pickupOtpCode, '1234');
    });

    test('allows null pickupOtpCode', () {
      final delivery = DriverDelivery.fromJson({
        'status': 'ASSIGNED',
      });

      expect(delivery.pickupOtpCode, isNull);
    });

    test('uses safe defaults for unsupported values', () {
      final delivery = DriverDelivery.fromJson({
        'status': 'unknown',
        'pickupAddress': '',
        'deliveryAddress': 42,
        'fee': 'not-a-number',
        'distanceKm': null,
        'createdAt': 'invalid-date',
      });

      expect(delivery.id, '');
      expect(delivery.orderId, '');
      expect(delivery.status, DeliveryStatus.pending);
      expect(delivery.pickupAddressLabel, '');
      expect(delivery.deliveryAddressLabel, '');
      expect(delivery.deliveryFee, isNull);
      expect(delivery.estimatedDeliveryDistance, isNull);
      expect(delivery.createdAt, isNull);
    });
  });
}
