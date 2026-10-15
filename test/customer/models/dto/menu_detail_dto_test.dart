import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/dto/menu_detail_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuDetailDto', () {
    test('parses json with nested products', () {
      final dto = MenuDetailDto.fromJson({
        'id': 'menu-1',
        'name': 'Menu Poulet',
        'price': 50,
        'imageUrl': 'https://example.com/menu.png',
        'description': 'Poulet avec boisson',
        'products': [
          {
            'id': 'product-1',
            'name': 'Poulet',
            'price': 35,
            'imageUrl': 'https://example.com/product.png',
            'productType': 'product',
            'restaurantId': 'restaurant-1',
            'restaurantName': 'Dineroo Food',
            'available': true,
          },
        ],
      });

      expect(dto.id, 'menu-1');
      expect(dto.price, 50.0);
      expect(dto.products, hasLength(1));
      expect(dto.products.single.name, 'Poulet');
    });

    test('throws when price is missing', () {
      expect(
        () => MenuDetailDto.fromJson({'products': <Map<String, dynamic>>[]}),
        throwsException,
      );
    });

    test('converts to domain menu detail', () {
      final menu = MenuDetailDto(
        id: 'menu-1',
        name: 'Menu Poulet',
        price: 50,
        imageUrl: 'https://example.com/menu.png',
        description: 'Poulet avec boisson',
        products: const [],
      ).toDomain();

      expect(menu, isA<MenuDetail>());
      expect(menu.id, 'menu-1');
      expect(menu.products, isEmpty);
    });
  });
}
