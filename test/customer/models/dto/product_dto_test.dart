import 'package:dineroo_mobile/customer/models/dto/product_dto.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductDto', () {
    test('parses json and converts numeric price to double', () {
      final dto = ProductDto.fromJson({
        'id': 'product-1',
        'name': 'Burger',
        'price': 35,
        'imageUrl': 'https://example.com/burger.png',
        'productType': 'product',
        'restaurantId': 'restaurant-1',
        'restaurantName': 'Dineroo Food',
        'available': true,
      });

      expect(dto.id, 'product-1');
      expect(dto.name, 'Burger');
      expect(dto.price, 35.0);
      expect(dto.available, isTrue);
    });

    test('uses safe defaults for nullable json fields except price', () {
      final dto = ProductDto.fromJson({'price': 10.5});

      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.imageUrl, '');
      expect(dto.productType, '');
      expect(dto.restaurantId, '');
      expect(dto.restaurantName, '');
      expect(dto.available, isFalse);
    });

    test('throws when price is missing', () {
      expect(() => ProductDto.fromJson({'name': 'Burger'}), throwsException);
    });

    test('converts to domain product', () {
      final product = ProductDto(
        id: 'product-1',
        name: 'Burger',
        price: 35,
        imageUrl: 'https://example.com/burger.png',
        productType: 'product',
        restaurantId: 'restaurant-1',
        restaurantName: 'Dineroo Food',
        available: false,
      ).toDomain();

      expect(product, isA<Product>());
      expect(product.id, 'product-1');
      expect(product.category, 'product');
      expect(product.available, isFalse);
    });
  });
}
