import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final restaurant = Restaurant(
    id: 'restaurant-1',
    name: 'Hanoi',
    imageUrl: '',
    description: '',
    phone: '',
  );

  Product product({
    required String id,
    required String name,
    required String category,
    bool canBeSoldAlone = true,
  }) {
    return Product(
      id: id,
      name: name,
      price: 10000,
      imageUrl: '',
      category: category,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      canBeSoldAlone: canBeSoldAlone,
    );
  }

  Widget app(List<Product> products) {
    return MaterialApp(
      home: Scaffold(
        body: ProductList(products: products, restaurant: restaurant),
      ),
    );
  }

  testWidgets('shows only products that can be sold alone', (tester) async {
    await tester.pumpWidget(
      app([
        product(id: 'p1', name: 'Poulet yassa', category: 'plats'),
        product(
          id: 'p2',
          name: 'Riz menu uniquement',
          category: 'accompagnements',
          canBeSoldAlone: false,
        ),
      ]),
    );
    await tester.pump();

    expect(find.text('Poulet yassa'), findsOneWidget);
    expect(find.text('Riz menu uniquement'), findsNothing);
    expect(find.text('Plats'), findsOneWidget);
    expect(find.text('Accompagnements'), findsNothing);
  });
}
