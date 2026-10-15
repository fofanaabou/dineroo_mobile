import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/cart_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;
  late CartViewModel cartViewModel;
  var cartBoxIndex = 0;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('cart_item_tile_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CartItemAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  setUp(() async {
    await Hive.box<DeliveryAddress>('deliveryAddressBox').clear();
    cartViewModel = CartViewModel();
    await cartViewModel.openUserCartBox('tile-user-${cartBoxIndex++}');
  });

  tearDown(() async {
    cartViewModel.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  tearDownAll(() async {
    // Avoid closing Hive explicitly here: flutter_tester can hang while a
    // widget-owned box is finalizing async writes. The test process is isolated.
  });

  group('CartItemTile', () {
    testWidgets('renders product info and updates quantity controls', (
      tester,
    ) async {
      cartViewModel.addProduct(
        _product(),
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        quantity: 2,
      );

      await tester.pumpWidget(_TileHarness(cartViewModel));

      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('15 000 GNF'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      expect(cartViewModel.items.single.quantity, 3);

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(cartViewModel.items.single.quantity, 2);
    });

    testWidgets('asks for confirmation before deleting the last item', (
      tester,
    ) async {
      cartViewModel.addProduct(
        _product(),
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );

      await tester.pumpWidget(_TileHarness(cartViewModel));

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Supprimer l\'article'), findsOneWidget);
      expect(find.textContaining('Burger'), findsWidgets);

      await tester.tap(find.text('SUPPRIMER'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(cartViewModel.items, isEmpty);
      expect(find.text('Burger supprimé du panier'), findsOneWidget);
    });

    testWidgets('shows unavailable state and removes unavailable item', (
      tester,
    ) async {
      cartViewModel.addProduct(
        _product(),
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        quantity: 3,
      );
      cartViewModel.markUnavailableItems('restaurant-1', ['burger']);

      await tester.pumpWidget(_TileHarness(cartViewModel));

      expect(find.text('Indisponible'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(cartViewModel.items, isEmpty);
      expect(find.text('3 x Burger supprimés du panier'), findsOneWidget);
    });
  });
}

Product _product() {
  return Product(
    id: 'product-1',
    name: 'Burger',
    price: 15000,
    imageUrl: '',
    category: 'product',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Fatou',
  );
}

class _TileHarness extends StatelessWidget {
  final CartViewModel cartViewModel;

  const _TileHarness(this.cartViewModel);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CartItemTile(
          item: cartViewModel.items.single,
          cartVM: cartViewModel,
        ),
      ),
    );
  }
}
