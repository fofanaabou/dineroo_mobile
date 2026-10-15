import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartGroup', () {
    test('calculates subtotal from item prices and quantities', () {
      final group = CartGroup(
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
        deliveryAddress: 'Kaloum',
        items: [
          CartItem(product: _product(id: 'p1', price: 20), quantity: 2),
          CartItem(product: _product(id: 'p2', price: 15.5), quantity: 3),
        ],
      );

      expect(group.subtotal, 86.5);
    });

    test('returns estimation items with quantity and price only', () {
      final group = CartGroup(
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
        deliveryAddress: 'Kaloum',
        items: [CartItem(product: _product(price: 12), quantity: 4)],
      );

      expect(group.estimationItems, [
        {'quantity': 4, 'price': 12.0},
      ]);
    });

    test('omits malformed persisted choices from estimation items', () {
      final group = CartGroup(
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
        deliveryAddress: 'Kaloum',
        items: [
          CartItem(
            product: _product(id: 'menu-1', category: 'menu', price: 10000),
            quantity: 1,
            menuBasePrice: 10000,
            selectedMenuItems: [
              SelectedMenuItem(
                groupId: 'side',
                groupName: 'Accompagnement',
                menuItemId: 'riz-item',
                productId: 'riz',
                productName: 'Riz',
                additionalPrice: 500,
                productChoicesJson: '{not-json',
              ),
            ],
          ),
        ],
      );

      final selectedMenuItems =
          (group.estimationItems.single['selectedMenuItems'] as List).single
              as Map<String, dynamic>;
      expect(selectedMenuItems.containsKey('productChoices'), isFalse);
    });
  });
}

Product _product({
  String id = 'product-1',
  double price = 10,
  String category = 'product',
}) {
  return Product(
    id: id,
    name: 'Poulet',
    price: price,
    imageUrl: 'https://example.com/product.png',
    category: category,
    restaurantId: 'restaurant-1',
    restaurantName: 'Dineroo Food',
  );
}
