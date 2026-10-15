import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/extensions/menu_detail_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuDetailToProduct', () {
    test('converts menu detail to cart-compatible product', () {
      const menu = MenuDetail(
        id: 'menu-1',
        name: 'Menu Burger',
        price: 55,
        imageUrl: 'https://example.com/menu.png',
        description: 'Burger avec boisson',
        products: [],
      );

      final product = menu.toProduct(
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
      );

      expect(product.id, 'menu-1');
      expect(product.name, 'Menu Burger');
      expect(product.price, 55.0);
      expect(product.imageUrl, 'https://example.com/menu.png');
      expect(product.category, 'menu');
      expect(product.restaurantName, 'Dineroo Food');
    });
  });
}
