import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory hiveDir;
  late CartViewModel viewModel;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('cart_view_model_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CartItemAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SelectedMenuItemAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  setUp(() async {
    await Hive.box<DeliveryAddress>('deliveryAddressBox').clear();
    viewModel = CartViewModel();
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    viewModel.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('CartViewModel', () {
    test('starts with empty local cart state', () {
      expect(viewModel.items, isEmpty);
      expect(viewModel.restaurantId, isNull);
      expect(viewModel.restaurantName, isNull);
      expect(viewModel.deliveryLabel, isNull);
      expect(viewModel.hasCustomerPosition, isFalse);
      expect(viewModel.hasDeliveryAddressForEstimation, isFalse);
      expect(viewModel.groupedCarts, isEmpty);
    });

    test('opens a user cart box and restores saved delivery address', () async {
      await Hive.box<DeliveryAddress>(
        'deliveryAddressBox',
      ).put('current', _delivery());

      await viewModel.openUserCartBox('user-restore');

      expect(viewModel.items, isEmpty);
      expect(viewModel.deliveryLabel, 'Rue 1, Kipé, Ratoma');
      expect(viewModel.deliveryDisplayName, 'Aminata Diallo');
      expect(viewModel.deliveryPhoneNumber, '620000000');
      expect(viewModel.isDeliveryConfirmedForCurrentOrder, isFalse);
    });

    test(
      'adds products, enriches restaurant fields and groups carts',
      () async {
        await viewModel.openUserCartBox('user-add');

        viewModel.addProduct(
          _product(id: 'product-1', restaurantId: '', restaurantName: ''),
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
          quantity: 2,
        );
        viewModel.addProduct(
          _product(id: 'product-1', restaurantId: '', restaurantName: ''),
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
          quantity: 3,
        );
        viewModel.addProduct(
          _product(id: 'product-2', restaurantId: 'restaurant-2'),
          restaurantId: 'restaurant-2',
          restaurantName: 'Le Patio',
        );

        expect(viewModel.restaurantId, 'restaurant-1');
        expect(viewModel.restaurantName, 'Chez Fatou');
        expect(viewModel.items, hasLength(2));
        expect(viewModel.items.first.quantity, 5);
        expect(viewModel.items.first.product.restaurantId, 'restaurant-1');
        expect(viewModel.items.first.product.restaurantName, 'Chez Fatou');
        expect(viewModel.groupedCarts, hasLength(2));
        expect(viewModel.groupedCarts.first.restaurantName, 'Chez Fatou');
        expect(viewModel.cart.items, viewModel.items);
      },
    );

    test(
      'updates quantities and removes products from the local cart',
      () async {
        await viewModel.openUserCartBox('user-quantity');
        final product = _product();
        viewModel.addProduct(
          product,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );

        viewModel.incrementQuantity(product);
        expect(viewModel.items.single.quantity, 2);

        viewModel.decrementQuantityByProduct(product);
        viewModel.decrementQuantityByProduct(product);
        expect(viewModel.items.single.quantity, 1);

        viewModel.removeProduct(product);
        expect(viewModel.items, isEmpty);
      },
    );

    test('sets, consumes and clears delivery contact', () async {
      await viewModel.openUserCartBox('user-delivery');

      viewModel.setDeliveryContact(_delivery());

      expect(viewModel.deliveryLabel, 'Rue 1, Kipé, Ratoma');
      expect(viewModel.deliveryAddress, 'Rue 1');
      expect(viewModel.deliveryDistrict, 'Kipé');
      expect(viewModel.deliveryCommune, 'Ratoma');
      expect(viewModel.deliveryInstructions, 'Devant la pharmacie');
      expect(viewModel.deliveryFirstName, 'Aminata');
      expect(viewModel.deliveryLastName, 'Diallo');
      expect(viewModel.isDeliveryConfirmedForCurrentOrder, isTrue);
      expect(viewModel.hasDeliveryAddressForEstimation, isTrue);

      viewModel.consumeDeliveryConfirmation();
      expect(viewModel.isDeliveryConfirmedForCurrentOrder, isFalse);

      viewModel.clearDeliveryAddress();
      expect(viewModel.deliveryLabel, isNull);
      expect(viewModel.hasDeliveryAddressForEstimation, isFalse);
      expect(
        Hive.box<DeliveryAddress>('deliveryAddressBox').get('current'),
        isNull,
      );
    });

    test('clears the cart and resets restaurant state', () async {
      await viewModel.openUserCartBox('user-clear');
      viewModel.addProduct(
        _product(),
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );
      viewModel.commentController.text = 'Sans piment';
      viewModel.setDeliveryContact(_delivery());

      await viewModel.clearCart();

      expect(viewModel.items, isEmpty);
      expect(viewModel.commentController.text, isEmpty);
      expect(viewModel.restaurantId, isNull);
      expect(viewModel.restaurantName, isNull);
      expect(viewModel.isDeliveryConfirmedForCurrentOrder, isFalse);
      expect(viewModel.groupedCarts, isEmpty);
    });

    test('removes one restaurant group and keeps other groups', () async {
      await viewModel.openUserCartBox('user-groups');
      viewModel.addProduct(
        _product(id: 'product-1'),
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );
      viewModel.addProduct(
        _product(
          id: 'product-2',
          restaurantId: 'restaurant-2',
          restaurantName: 'Le Patio',
        ),
        restaurantId: 'restaurant-2',
        restaurantName: 'Le Patio',
      );

      viewModel.removeCartGroup('restaurant-1');

      expect(viewModel.items, hasLength(1));
      expect(viewModel.items.single.product.id, 'product-2');
      expect(viewModel.groupedCarts.single.restaurantId, 'restaurant-2');
      expect(viewModel.isDeliveryConfirmedForCurrentOrder, isFalse);
    });

    test('tracks unavailable items by normalized product name', () async {
      await viewModel.openUserCartBox('user-unavailable');
      final product = _product(name: 'Burger');
      viewModel.addProduct(
        product,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );

      viewModel.markUnavailableItems('restaurant-1', ['  burger  ', '']);

      expect(viewModel.isUnavailableItem(viewModel.items.single), isTrue);

      viewModel.clearUnavailableItemsForRestaurant('restaurant-1');
      expect(viewModel.isUnavailableItem(viewModel.items.single), isFalse);
    });

    test(
      'refreshes persisted cart item image urls from restaurant detail',
      () async {
        viewModel.dispose();
        viewModel = CartViewModel(
          restaurantService: _FakeRestaurantService({
            'id': 'restaurant-1',
            'name': 'Chez Fatou',
            'menus': [
              {
                'id': 'menu-1',
                'imageUrl': 'https://wasabi.test/menu-1-fresh.jpg',
              },
            ],
            'products': [
              {
                'id': 'product-1',
                'imageUrl': 'https://wasabi.test/product-1-fresh.jpg',
              },
            ],
          }),
        );
        await viewModel.openUserCartBox('user-refresh-images');
        viewModel.addProduct(
          _product(imageUrl: 'https://stale.test/product.jpg'),
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );
        viewModel.addConfiguredMenu(
          menuProduct: _product(
            id: 'menu-1',
            category: 'menu',
            imageUrl: 'https://stale.test/menu.jpg',
          ),
          selectedItems: [
            _selectedMenuItem(
              groupId: 'side',
              menuItemId: 'riz-item',
              productId: 'riz',
              productName: 'Riz',
            ),
          ],
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );

        await viewModel.refreshCartImagesForRestaurant('restaurant-1');

        expect(
          viewModel.items.first.product.imageUrl,
          'https://wasabi.test/product-1-fresh.jpg',
        );
        expect(
          viewModel.items.last.product.imageUrl,
          'https://wasabi.test/menu-1-fresh.jpg',
        );
      },
    );

    test(
      'merges configured menus only when the selected items match',
      () async {
        await viewModel.openUserCartBox('user-configured-menu');
        final menu = _product(id: 'menu-1', category: 'menu');
        final firstSelection = [
          _selectedMenuItem(
            groupId: 'side',
            menuItemId: 'riz-item',
            productId: 'riz',
            productName: 'Riz',
            additionalPrice: 500,
          ),
        ];
        final secondSelection = [
          _selectedMenuItem(
            groupId: 'side',
            menuItemId: 'frites-item',
            productId: 'frites',
            productName: 'Frites',
            additionalPrice: 1000,
          ),
        ];

        viewModel.addConfiguredMenu(
          menuProduct: menu,
          selectedItems: firstSelection,
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );
        viewModel.addConfiguredMenu(
          menuProduct: menu,
          selectedItems: firstSelection,
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
          quantity: 2,
        );
        viewModel.addConfiguredMenu(
          menuProduct: menu,
          selectedItems: secondSelection,
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );

        expect(viewModel.items, hasLength(2));
        expect(viewModel.items.first.quantity, 3);
        expect(viewModel.items.first.isConfiguredMenu, isTrue);
        expect(viewModel.items.first.unitPrice, 10500);
        expect(viewModel.items.last.unitPrice, 11000);
        expect(viewModel.groupedCarts.single.subtotal, 42500);
        await _waitForHiveWrites();
      },
    );

    test(
      'configured products keep independent quantities and item controls',
      () async {
        await viewModel.openUserCartBox('user-configured-product');
        final product = _product(id: 'product-1', price: 8000);
        final item = _selectedMenuItem(
          groupId: 'sauce',
          menuItemId: 'piment-item',
          productId: 'piment',
          productName: 'Piment',
          additionalPrice: 250,
        );

        viewModel.addConfiguredProduct(
          product: product,
          selectedItems: [item],
          basePrice: 8000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );
        final configuredItem = viewModel.items.single;

        expect(configuredItem.isConfiguredProduct, isTrue);
        expect(configuredItem.unitPrice, 8250);

        viewModel.incrementItem(configuredItem);
        expect(viewModel.items.single.quantity, 2);

        viewModel.decrementQuantity(configuredItem);
        expect(viewModel.items.single.quantity, 1);

        viewModel.removeItem(configuredItem);
        expect(viewModel.items, isEmpty);
        await _waitForHiveWrites();
      },
    );

    test(
      'merges configured menus whose selections are provided in any order',
      () async {
        await viewModel.openUserCartBox('user-menu-order');
        final menu = _product(id: 'menu-1', category: 'menu');
        final selection = [
          _selectedMenuItem(
            groupId: 'side',
            menuItemId: 'riz-item',
            productId: 'riz',
            productName: 'Riz',
            additionalPrice: 500,
          ),
          _selectedMenuItem(
            groupId: 'drink',
            menuItemId: 'jus-item',
            productId: 'jus',
            productName: 'Jus',
            additionalPrice: 1000,
          ),
        ];
        final reversed = List<SelectedMenuItem>.from(selection.reversed);

        viewModel.addConfiguredMenu(
          menuProduct: menu,
          selectedItems: selection,
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );
        viewModel.addConfiguredMenu(
          menuProduct: menu,
          selectedItems: reversed,
          menuBasePrice: 10000,
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
        );

        expect(viewModel.items, hasLength(1));
        expect(viewModel.items.single.quantity, 2);
        await _waitForHiveWrites();
      },
    );

    test('does not merge a plain add into a configured product line', () async {
      await viewModel.openUserCartBox('user-configured-plain');
      final product = _product(id: 'product-1', price: 8000);
      final selection = [
        _selectedMenuItem(
          groupId: 'sauce',
          menuItemId: 'piment-item',
          productId: 'piment',
          productName: 'Piment',
          additionalPrice: 250,
        ),
      ];

      viewModel.addConfiguredProduct(
        product: product,
        selectedItems: selection,
        basePrice: 8000,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );
      viewModel.addProduct(
        product,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
      );

      expect(viewModel.items, hasLength(2));
      expect(viewModel.items.first.isConfiguredProduct, isTrue);
      expect(viewModel.items.last.isConfiguredProduct, isFalse);
      expect(viewModel.items.last.quantity, 1);
      await _waitForHiveWrites();
    });

    test('decrementQuantity targets the exact cart line when the same product '
        'has multiple configured variants', () async {
      await viewModel.openUserCartBox('user-decrement-variant');
      final product = _product(id: 'product-1', price: 8000);
      final firstSelection = [
        _selectedMenuItem(
          groupId: 'sauce',
          menuItemId: 'piment-item',
          productId: 'piment',
          productName: 'Piment',
          additionalPrice: 250,
        ),
      ];
      final secondSelection = [
        _selectedMenuItem(
          groupId: 'sauce',
          menuItemId: 'mayo-item',
          productId: 'mayo',
          productName: 'Mayo',
          additionalPrice: 100,
        ),
      ];

      viewModel.addConfiguredProduct(
        product: product,
        selectedItems: firstSelection,
        basePrice: 8000,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        quantity: 3,
      );
      viewModel.addConfiguredProduct(
        product: product,
        selectedItems: secondSelection,
        basePrice: 8000,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        quantity: 3,
      );

      viewModel.decrementQuantity(viewModel.items.last);

      expect(viewModel.items.first.quantity, 3);
      expect(viewModel.items.last.quantity, 2);
      await _waitForHiveWrites();
    });
  });
}

Future<void> _waitForHiveWrites() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Product _product({
  String id = 'product-1',
  String name = 'Burger',
  double price = 15000,
  String category = 'product',
  String restaurantId = 'restaurant-1',
  String restaurantName = 'Chez Fatou',
  String imageUrl = 'https://example.com/product.jpg',
}) {
  return Product(
    id: id,
    name: name,
    price: price,
    imageUrl: imageUrl,
    category: category,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
  );
}

class _FakeRestaurantService extends RestaurantService {
  final Map<String, dynamic> response;

  _FakeRestaurantService(this.response);

  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async => response;
}

SelectedMenuItem _selectedMenuItem({
  required String groupId,
  required String menuItemId,
  required String productId,
  required String productName,
  double additionalPrice = 0,
}) {
  return SelectedMenuItem(
    groupId: groupId,
    groupName: groupId,
    menuItemId: menuItemId,
    productId: productId,
    productName: productName,
    additionalPrice: additionalPrice,
  );
}

DeliveryAddress _delivery() {
  return DeliveryAddress(
    phoneNumber: '620000000',
    address: 'Rue 1',
    district: 'Kipé',
    commune: 'Ratoma',
    instructions: 'Devant la pharmacie',
    firstName: 'Aminata',
    lastName: 'Diallo',
  );
}
