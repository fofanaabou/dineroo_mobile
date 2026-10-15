import 'package:dineroo_mobile/customer/models/dto/restaurant_detail_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestaurantDetailDto', () {
    test('parses JSON with menus, products and opening hours', () {
      final dto = RestaurantDetailDto.fromJson(_json());

      expect(dto.id, 'restaurant-1');
      expect(dto.name, 'Chez Fatou');
      expect(dto.description, 'Cuisine locale');
      expect(dto.menus.single.name, 'Menu midi');
      expect(dto.products.single.name, 'Jus');
      expect(dto.openingHours.single.day, 'THURSDAY');
    });

    test(
      'uses empty lists and default description when optional lists missing',
      () {
        final dto = RestaurantDetailDto.fromJson({
          'id': 'restaurant-1',
          'name': 'Chez Fatou',
          'address': 'Kaloum',
          'phone': null,
          'imageUrl': 'https://example.com/restaurant.jpg',
        });

        expect(dto.description, '');
        expect(dto.phone, isNull);
        expect(dto.menus, isEmpty);
        expect(dto.products, isEmpty);
        expect(dto.openingHours, isEmpty);
      },
    );

    test('converts to domain restaurant detail', () {
      final detail = RestaurantDetailDto.fromJson(_json()).toDomain();

      expect(detail.id, 'restaurant-1');
      expect(detail.phone, '620000000');
      expect(detail.menus.single.id, 'menu-1');
      expect(detail.products.single.id, 'product-1');
      expect(detail.openingHours.single.timeRanges.single.end, '22:00');
    });
  });
}

Map<String, dynamic> _json() => {
  'id': 'restaurant-1',
  'name': 'Chez Fatou',
  'address': 'Kaloum',
  'phone': '620000000',
  'description': 'Cuisine locale',
  'imageUrl': 'https://example.com/restaurant.jpg',
  'menus': [
    {
      'id': 'menu-1',
      'name': 'Menu midi',
      'price': 25000,
      'imageUrl': 'https://example.com/menu.jpg',
      'available': true,
    },
  ],
  'products': [
    {
      'id': 'product-1',
      'name': 'Jus',
      'price': 10000,
      'category': 'drink',
      'imageUrl': 'https://example.com/product.jpg',
      'available': true,
    },
  ],
  'openingHours': [
    {
      'day': 'THURSDAY',
      'timeRanges': [
        {'start': '11:00', 'end': '22:00'},
      ],
    },
  ],
};
