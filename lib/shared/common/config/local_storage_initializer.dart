import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initializeLocalStorage() async {
  // hive_flutter resolves the documents directory itself on mobile and uses
  // IndexedDB on web, where path_provider has no implementation.
  await Hive.initFlutter();

  await Hive.openBox<String>('recentSearches');

  Hive.registerAdapter(DeliveryAddressAdapter());
  await Hive.openBox<DeliveryAddress>('deliveryAddressBox');

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(SelectedMenuItemAdapter());
  await Hive.openBox<CartItem>('cartBox');
}
