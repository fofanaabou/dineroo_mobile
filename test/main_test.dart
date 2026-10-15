import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/main.dart' as app;
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');

    final dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CartItemAdapter());
    }

    await Hive.openBox<String>('recentSearches');
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
    await Hive.openBox<CartItem>('cartBox');
  });

  testWidgets('DinerooApp renders MaterialApp', (tester) async {
    await tester.pumpWidget(const app.DinerooApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      tester
          .element(find.byType(MaterialApp))
          .read<ManagerRestaurantViewModel>(),
      isA<ManagerRestaurantViewModel>(),
    );
  });
}
