import 'package:dineroo_mobile/customer/models/dto/restaurant_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestaurantDto', () {
    test('parses JSON with opening hours and numeric distance', () {
      final dto = RestaurantDto.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
        'description': 'Cuisine locale',
        'phone': 620000000,
        'distanceKm': 3,
        'openingHours': [
          {
            'day': 'TUESDAY',
            'timeRanges': [
              {'start': '10:00', 'end': '20:00'},
            ],
          },
        ],
      });

      expect(dto.id, 'restaurant-1');
      expect(dto.name, 'Chez Fatou');
      expect(dto.phone, '620000000');
      expect(dto.distanceKm, 3.0);
      expect(dto.openingHours.single.day, 'TUESDAY');
      expect(dto.openingHours.single.timeRanges.single.end, '20:00');
    });

    test('uses safe defaults for nullable fields', () {
      final dto = RestaurantDto.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
      });

      expect(dto.description, isNull);
      expect(dto.phone, '');
      expect(dto.openingHours, isEmpty);
      expect(dto.distanceKm, isNull);
    });

    test('converts to domain restaurant', () {
      final restaurant = RestaurantDto.fromJson({
        'id': 'restaurant-1',
        'name': 'Chez Fatou',
        'imageUrl': 'https://example.com/restaurant.jpg',
        'description': null,
        'phone': '620000000',
        'distanceKm': 1.5,
        'openingHours': [
          {
            'day': 'WEDNESDAY',
            'timeRanges': [
              {'start': '09:00', 'end': '19:00'},
            ],
          },
        ],
      }).toDomain();

      expect(restaurant.id, 'restaurant-1');
      expect(restaurant.description, '');
      expect(restaurant.distanceKm, 1.5);
      expect(restaurant.openingHours.single.day, 'WEDNESDAY');
      expect(restaurant.openingHours.single.timeRanges.single.start, '09:00');
    });
  });
}
