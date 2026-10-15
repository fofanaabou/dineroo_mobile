import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/extensions/product_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductCategoryExtension', () {
    test('identifies menu products', () {
      final product = _product(category: 'menu');

      expect(product.isMenu, isTrue);
      expect(product.isProduct, isFalse);
    });

    test('identifies non-menu products as products', () {
      final product = _product(category: 'product');

      expect(product.isMenu, isFalse);
      expect(product.isProduct, isTrue);
    });
  });
}

Product _product({required String category}) {
  return Product(
    id: 'product-1',
    name: 'Burger',
    price: 35,
    imageUrl: 'https://example.com/burger.png',
    category: category,
    restaurantId: 'restaurant-1',
    restaurantName: 'Dineroo Food',
  );
}
