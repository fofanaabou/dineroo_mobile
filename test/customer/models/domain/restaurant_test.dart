import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/enums/suspension_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Restaurant', () {
    test('parses JSON with opening hours and distance', () {
      final restaurant = Restaurant.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
        'description': 'Cuisine locale',
        'phone': '620000000',
        'distanceKm': 2,
        'openingHours': [
          {
            'day': 'MONDAY',
            'timeRanges': [
              {'start': '08:00', 'end': '18:00'},
            ],
          },
        ],
      });

      expect(restaurant.id, 'restaurant-1');
      expect(restaurant.name, 'Chez Fatou');
      expect(restaurant.description, 'Cuisine locale');
      expect(restaurant.phone, '620000000');
      expect(restaurant.distanceKm, 2.0);
      expect(restaurant.openingHours.single.day, 'MONDAY');
      expect(restaurant.openingHours.single.timeRanges.single.start, '08:00');
    });

    test('uses safe defaults for optional fields', () {
      final restaurant = Restaurant.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
      });

      expect(restaurant.description, '');
      expect(restaurant.phone, '');
      expect(restaurant.openingHours, isEmpty);
      expect(restaurant.distanceKm, isNull);
      expect(restaurant.suspension, isNull);
      expect(restaurant.isSuspended, isFalse);
    });

    test('parses the suspension sent under the RESTAURANT context', () {
      final restaurant = Restaurant.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
        'suspension': {
          'reason': 'INCOMPLETE_ORDERS',
          'suspendedAt': '2026-08-18T10:15:30Z',
        },
      });

      expect(restaurant.isSuspended, isTrue);
      expect(
        restaurant.suspension!.reason,
        SuspensionReason.incompleteOrders,
      );
    });

    test('does not crash on a reason added server-side', () {
      final restaurant = Restaurant.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
        'suspension': {'reason': 'BRAND_NEW_REASON', 'suspendedAt': 'garbage'},
      });

      expect(restaurant.isSuspended, isTrue);
      expect(restaurant.suspension!.reason, SuspensionReason.other);
    });
  });
}
