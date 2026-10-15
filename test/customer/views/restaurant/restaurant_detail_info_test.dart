import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant_detail.dart';
import 'package:dineroo_mobile/customer/views/restaurant/detail/restaurant_detail_info.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product product({required String id, bool canBeSoldAlone = true}) {
    return Product(
      id: id,
      name: id,
      price: 10000,
      imageUrl: '',
      category: 'plats',
      restaurantId: 'restaurant-1',
      restaurantName: 'Hanoi',
      canBeSoldAlone: canBeSoldAlone,
    );
  }

  testWidgets('counts only products that can be sold alone', (tester) async {
    final restaurant = RestaurantDetail(
      id: 'restaurant-1',
      name: 'Hanoi',
      address: '',
      phone: '',
      description: '',
      imageUrl: '',
      menus: [
        Menu(
          id: 'menu-1',
          name: 'Menu midi',
          price: 10000,
          imageUrl: '',
          available: true,
        ),
      ],
      products: [
        product(id: 'standalone-1'),
        product(id: 'standalone-2'),
        product(id: 'menu-only', canBeSoldAlone: false),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RestaurantDetailInfo(restaurant: restaurant)),
      ),
    );

    expect(find.text('1 menu'), findsOneWidget);
    expect(find.text('2 produits'), findsOneWidget);
    expect(find.text('3 produits'), findsNothing);
  });
}
