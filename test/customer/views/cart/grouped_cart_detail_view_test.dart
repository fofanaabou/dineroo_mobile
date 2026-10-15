import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/grouped_cart_detail_view.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory hiveDir;
  late CartViewModel cartViewModel;
  var cartBoxIndex = 0;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp(
      'grouped_cart_detail_view_test_',
    );
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
    cartViewModel = CartViewModel(restaurantService: _FakeRestaurantService());
    await cartViewModel.openUserCartBox('detail-user-${cartBoxIndex++}');
  });

  tearDown(() async {
    cartViewModel.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  group('GroupedCartDetailView', () {
    testWidgets(
      'keeps a stable scroll extent down to the bottom of a long cart on iOS',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        for (var i = 0; i < 10; i++) {
          cartViewModel.addProduct(
            _product(i),
            restaurantId: 'restaurant-1',
            restaurantName: 'Chez Fatou',
          );
        }

        await tester.pumpWidget(_DetailHarness(cartViewModel));
        await tester.pump();

        final scrollable = find.byType(Scrollable).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final initialMaxExtent = position.maxScrollExtent;
        final extents = <double>{};

        await tester.fling(scrollable, const Offset(0, -600), 2500);
        for (var i = 0; i < 120; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          extents.add(position.maxScrollExtent);
        }

        expect(extents, {initialMaxExtent});
        expect(position.pixels, initialMaxExtent);
        expect(
          find.text('Ajouter un commentaire').hitTestable(),
          findsOneWidget,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}

Product _product(int index) {
  return Product(
    id: 'product-$index',
    name: 'Produit $index',
    price: 15000,
    imageUrl: '',
    category: 'product',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Fatou',
  );
}

class _DetailHarness extends StatelessWidget {
  final CartViewModel cartViewModel;

  const _DetailHarness(this.cartViewModel);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartViewModel>.value(value: cartViewModel),
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
        ChangeNotifierProvider(
          create: (_) => RestaurantViewModel(
            RestaurantRepository(
              service: _FakeRestaurantService(),
              listService: RestaurantListService(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: GroupedCartDetailView(group: cartViewModel.groupedCarts.single),
      ),
    );
  }
}

class _FakeRestaurantService extends RestaurantService {
  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async => {
    'id': id,
    'name': 'Chez Fatou',
    'menus': const [],
    'products': const [],
    'openingHours': const [],
  };

  @override
  Future<bool> restaurantIsOpen(String id) async => true;
}
