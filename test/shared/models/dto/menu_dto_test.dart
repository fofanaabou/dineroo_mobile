import 'package:dineroo_mobile/shared/models/dto/menu_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuDto', () {
    test('parses JSON and converts int price to double', () {
      final dto = MenuDto.fromJson({
        'id': 'menu-1',
        'name': 'Menu midi',
        'price': 25000,
        'imageUrl': 'https://example.com/menu.jpg',
        'available': true,
      });

      expect(dto.id, 'menu-1');
      expect(dto.name, 'Menu midi');
      expect(dto.price, 25000.0);
      expect(dto.imageUrl, 'https://example.com/menu.jpg');
      expect(dto.available, isTrue);
    });

    test('uses safe defaults except for required price', () {
      final dto = MenuDto.fromJson({'price': 1000.5});

      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.price, 1000.5);
      expect(dto.imageUrl, '');
      expect(dto.available, isFalse);
    });

    test('throws when price is missing', () {
      expect(() => MenuDto.fromJson({}), throwsException);
    });

    test('converts to domain menu', () {
      final menu = MenuDto(
        id: 'menu-1',
        name: 'Menu midi',
        price: 25000,
        imageUrl: 'https://example.com/menu.jpg',
        available: true,
      ).toDomain();

      expect(menu.id, 'menu-1');
      expect(menu.name, 'Menu midi');
      expect(menu.price, 25000);
      expect(menu.imageUrl, 'https://example.com/menu.jpg');
      expect(menu.available, isTrue);
    });
  });
}
