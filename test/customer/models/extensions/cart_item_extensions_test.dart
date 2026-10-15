import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/extensions/cart_item_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartItemToJson', () {
    test('serializes cart item with product information and quantity', () {
      final item = CartItem(
        quantity: 3,
        product: Product(
          id: 'product-1',
          name: 'Burger',
          price: 35,
          imageUrl: 'https://example.com/burger.png',
          category: 'product',
          restaurantId: 'restaurant-1',
          restaurantName: 'Dineroo Food',
        ),
      );

      expect(item.toJson(), {
        'product_id': 'product-1',
        'name': 'Burger',
        'price': 35.0,
        'category': 'product',
        'quantity': 3,
      });
    });
  });
}
