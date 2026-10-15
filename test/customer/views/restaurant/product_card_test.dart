import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/restaurant/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class TestCartViewModel extends CartViewModel {
  bool addProductCalled = false;

  @override
  void addProduct(
    Product product, {
    required String restaurantId,
    required String restaurantName,
    int quantity = 1,
  }) {
    addProductCalled = true;
  }
}

Widget createTestApp(Widget body, {CartViewModel? cartViewModel}) {
  Widget child = body;
  if (cartViewModel != null) {
    child = ChangeNotifierProvider<CartViewModel>.value(
      value: cartViewModel,
      child: body,
    );
  }
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('product_card_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  final product = Product(
    id: 'p1',
    name: 'Pizza',
    price: 10.0,
    imageUrl: '',
    category: 'Plat',
    restaurantId: 'r1',
    restaurantName: 'Chez Mariam',
  );

  final restaurant = Restaurant(
    id: 'r1',
    name: 'Chez Mariam',
    imageUrl: '',
    description: '',
    phone: '',
  );

  testWidgets('renders product name for available product', (tester) async {
    await tester.pumpWidget(
      createTestApp(ProductCard(product: product, restaurant: restaurant)),
    );
    await tester.pump();
    expect(find.text('Pizza'), findsOneWidget);
  });

  testWidgets('renders unavailable overlay when product is unavailable', (
    tester,
  ) async {
    final unavailableProduct = product.copyWith(available: false);

    await tester.pumpWidget(
      createTestApp(
        ProductCard(product: unavailableProduct, restaurant: restaurant),
      ),
    );
    await tester.pump();

    expect(find.text('INDISPONIBLE'), findsOneWidget);
  });

  testWidgets('calls addProduct when add icon is tapped', (tester) async {
    final cartViewModel = TestCartViewModel();

    await tester.pumpWidget(
      createTestApp(
        ProductCard(product: product, restaurant: restaurant),
        cartViewModel: cartViewModel,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(cartViewModel.addProductCalled, isTrue);
  });
}
