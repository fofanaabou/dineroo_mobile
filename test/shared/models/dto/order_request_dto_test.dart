import 'dart:convert';
import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/selected_menu_item.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/shared/models/dto/order_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('order_request_dto_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('OrderRequestDto.fromCart', () {
    test(
      'serializes configured menu and product selections for validation',
      () {
        final selectedMenuItem = _selectedItem(
          groupId: 'side',
          menuItemId: 'rice-item',
          productId: 'rice',
          productName: 'Riz',
          additionalPrice: 500,
        );
        final selectedProductItem = _selectedItem(
          groupId: 'sauce',
          menuItemId: 'piment-item',
          productId: 'piment',
          productName: 'Piment',
          additionalPrice: 250,
          productChoicesJson: jsonEncode([
            {
              'groupId': 'heat',
              'groupName': 'heat',
              'itemId': 'extra-hot',
              'itemName': 'Extra hot',
              'additionalPrice': 0.0,
              'quantity': 1,
            },
          ]),
        );
        final cart = CartGroup(
          restaurantId: 'restaurant-1',
          restaurantName: 'Chez Fatou',
          deliveryAddress: 'Rue 1',
          items: [
            CartItem(
              product: _product(id: 'menu-1', category: 'menu', price: 10000),
              quantity: 2,
              menuBasePrice: 10000,
              selectedMenuItems: [selectedMenuItem],
            ),
            CartItem(
              product: _product(
                id: 'product-1',
                category: 'product',
                price: 8000,
              ),
              menuBasePrice: 8000,
              selectedMenuItems: [selectedProductItem],
            ),
            CartItem(
              product: _product(
                id: 'simple-1',
                category: 'product',
                price: 3000,
              ),
            ),
          ],
        );

        final dto = OrderRequestDto.fromCart(
          cart: cart,
          currentUser: _user(),
          cartVM: _EstimatedCartViewModel(),
          comment: 'Sans piment',
        );

        expect(dto.totalPrice, 31500);
        expect(dto.serviceFee, 1500);
        expect(dto.deliveryFee, 2000);
        expect(dto.restaurantId, 'restaurant-1');
        expect(dto.customerId, 'customer-1');
        expect(dto.status, 'PENDING');
        expect(dto.comment, 'Sans piment');
        expect(dto.deliveryContact['phoneNumber'], '+224620000000');

        final menuItem = dto.orderItems[0];
        expect(menuItem['productId'], isNull);
        expect(menuItem['menuId'], 'menu-1');
        expect(menuItem['price'], 10500);
        expect(menuItem['selectedMenuItems'], [
          {
            'groupId': 'side',
            'groupName': 'side',
            'menuItemId': 'rice-item',
            'productId': 'rice',
            'productName': 'Riz',
            'additionalPrice': 500.0,
          },
        ]);

        final productItem = dto.orderItems[1];
        expect(productItem['productId'], 'product-1');
        expect(productItem['menuId'], isNull);
        expect(productItem['price'], 8250);
        expect(productItem['selectedMenuItems'].single['productChoices'], [
          {
            'groupId': 'heat',
            'groupName': 'heat',
            'itemId': 'extra-hot',
            'itemName': 'Extra hot',
            'additionalPrice': 0.0,
            'quantity': 1,
          },
        ]);

        final simpleItem = dto.orderItems[2];
        expect(simpleItem['productId'], 'simple-1');
        expect(simpleItem['menuId'], isNull);
        expect(simpleItem.containsKey('selectedMenuItems'), isFalse);
        expect(dto.toJson()['orderItems'], dto.orderItems);
      },
    );

    test('omits malformed persisted choices without crashing', () {
      final selectedProductItem = _selectedItem(
        groupId: 'sauce',
        menuItemId: 'piment-item',
        productId: 'piment',
        productName: 'Piment',
        additionalPrice: 250,
        productChoicesJson: '{not-json',
      );
      final cart = CartGroup(
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        deliveryAddress: 'Rue 1',
        items: [
          CartItem(
            product: _product(id: 'product-1', price: 8000),
            menuBasePrice: 8000,
            selectedMenuItems: [selectedProductItem],
          ),
        ],
      );

      final dto = OrderRequestDto.fromCart(
        cart: cart,
        currentUser: _user(),
        cartVM: _EstimatedCartViewModel(),
        comment: '',
      );

      final selectedMenuItems =
          (dto.orderItems.single['selectedMenuItems'] as List).single
              as Map<String, dynamic>;
      expect(selectedMenuItems.containsKey('productChoices'), isFalse);
    });

    test('throws when pricing estimation is unavailable', () {
      final cart = CartGroup(
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Fatou',
        deliveryAddress: 'Rue 1',
        items: [CartItem(product: _product(id: 'product-1'))],
      );

      expect(
        () => OrderRequestDto.fromCart(
          cart: cart,
          currentUser: _user(),
          cartVM: _EstimatedCartViewModel(total: null),
          comment: '',
        ),
        throwsStateError,
      );
    });
  });
}

class _EstimatedCartViewModel extends CartViewModel {
  _EstimatedCartViewModel({this.total = 31500});

  final double? total;

  @override
  double? totalFor(CartGroup group) => total;

  @override
  double? serviceFeeFor(CartGroup group) => total == null ? null : 1500;

  @override
  double? deliveryFeeFor(CartGroup group) => total == null ? null : 2000;

  @override
  String? get deliveryPhoneNumber => '620000000';

  @override
  String? get deliveryAddress => 'Rue 1';

  @override
  String? get deliveryDistrict => 'Kipé';

  @override
  String? get deliveryCommune => 'Ratoma';

  @override
  String? get deliveryInstructions => 'Devant la pharmacie';

  @override
  String? get deliveryFirstName => 'Aminata';

  @override
  String? get deliveryLastName => 'Diallo';
}

Product _product({
  required String id,
  String category = 'product',
  double price = 10000,
}) {
  return Product(
    id: id,
    name: id,
    price: price,
    imageUrl: 'https://example.com/$id.jpg',
    category: category,
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Fatou',
  );
}

SelectedMenuItem _selectedItem({
  required String groupId,
  required String menuItemId,
  required String productId,
  required String productName,
  double additionalPrice = 0,
  String? productChoicesJson,
}) {
  return SelectedMenuItem(
    groupId: groupId,
    groupName: groupId,
    menuItemId: menuItemId,
    productId: productId,
    productName: productName,
    additionalPrice: additionalPrice,
    productChoicesJson: productChoicesJson,
  );
}

User _user() {
  return User(
    id: 'customer-1',
    firstName: 'Aminata',
    lastName: 'Diallo',
    phoneNumber: '620000000',
    role: 'CUSTOMER',
    isTemporaryPin: false,
  );
}
