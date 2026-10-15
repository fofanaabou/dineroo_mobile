import 'package:dineroo_mobile/customer/models/extensions/menu_extensions.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuExtensions', () {
    test('converts menu to cart-compatible product', () {
      final menu = Menu(
        id: 'menu-1',
        name: 'Menu Burger',
        price: 55,
        imageUrl: 'https://example.com/menu.png',
        available: true,
      );

      final product = menu.toProduct(
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
      );

      expect(product.id, 'menu-1');
      expect(product.name, 'Menu Burger');
      expect(product.price, 55.0);
      expect(product.category, 'menu');
      expect(product.restaurantId, 'restaurant-1');
      expect(product.restaurantName, 'Dineroo Food');
    });
  });
}
