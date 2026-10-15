import 'package:dineroo_mobile/manager/repositories/manager_menus_repository.dart';
import 'package:dineroo_mobile/manager/repositories/manager_products_repository.dart';
import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_menus_service.dart';
import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_menus_tab.dart';
import 'package:dineroo_mobile/manager/views/catalog/manager_catalog_products_tab.dart';
import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _restaurantId = 'restaurant-1';

void main() {
  group('catalogue availability while suspended', () {
    testWidgets('menu toggles are enabled for an active restaurant', (
      tester,
    ) async {
      final menusVM = await _loadedMenusViewModel();

      await tester.pumpWidget(
        _harness(
          menusVM: menusVM,
          child: const ManagerCatalogMenusTab(restaurantId: _restaurantId),
        ),
      );

      expect(_switchAt(tester).onChanged, isNotNull);
    });

    testWidgets('menu toggles are disabled and explain why when suspended', (
      tester,
    ) async {
      final menusVM = await _loadedMenusViewModel();

      await tester.pumpWidget(
        _harness(
          menusVM: menusVM,
          child: const ManagerCatalogMenusTab(
            restaurantId: _restaurantId,
            isSuspended: true,
          ),
        ),
      );

      expect(_switchAt(tester).onChanged, isNull);

      await tester.tap(find.byType(AppSwitch));
      await tester.pump();

      expect(
        find.text(ManagerSuspensionNotice.lockedActionReason),
        findsOneWidget,
      );
      expect(menusVM.menus.single.available, isTrue);
    });

    testWidgets('product toggles are disabled and explain why when suspended', (
      tester,
    ) async {
      final productsVM = await _loadedProductsViewModel();

      await tester.pumpWidget(
        _harness(
          productsVM: productsVM,
          child: const ManagerCatalogProductsTab(
            restaurantId: _restaurantId,
            isSuspended: true,
          ),
        ),
      );

      expect(_switchAt(tester).onChanged, isNull);

      await tester.tap(find.byType(AppSwitch));
      await tester.pump();

      expect(find.text(ManagerSuspensionNotice.lockedActionReason), findsOneWidget);
      expect(productsVM.products.single.available, isTrue);
    });
  });

  group('a suspension landing mid-session', () {
    test('rolls the menu toggle back and surfaces the refusal', () async {
      final menusVM = await _loadedMenusViewModel(
        service: _FakeMenusService(refuseAsSuspended: true),
      );

      await expectLater(
        menusVM.toggleAvailability(_restaurantId, 'menu-1'),
        throwsA(isA<RestaurantSuspendedException>()),
      );
      expect(menusVM.menus.single.available, isTrue);
    });

    test('rolls the product toggle back and surfaces the refusal', () async {
      final productsVM = await _loadedProductsViewModel(
        service: _FakeProductsService(refuseAsSuspended: true),
      );

      await expectLater(
        productsVM.toggleAvailability(_restaurantId, 'product-1'),
        throwsA(isA<RestaurantSuspendedException>()),
      );
      expect(productsVM.products.single.available, isTrue);
    });

    testWidgets('is shown as the banner message, not a raw error', (
      tester,
    ) async {
      final menusVM = await _loadedMenusViewModel(
        service: _FakeMenusService(refuseAsSuspended: true),
      );
      final restaurantVM = ManagerRestaurantViewModel(
        ManagerRestaurantRepository(
          service: _FakeRestaurantService(
            suspension: const {
              'reason': 'SERVICE_QUALITY',
              'suspendedAt': '2026-08-18T10:15:30Z',
            },
          ),
        ),
      );

      await tester.pumpWidget(
        _harness(
          menusVM: menusVM,
          restaurantVM: restaurantVM,
          child: const ManagerCatalogMenusTab(restaurantId: _restaurantId),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('CONFIRMER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(RestaurantSuspendedException.message), findsOneWidget);
      expect(find.text('Erreur lors de la mise à jour du menu.'), findsNothing);
      expect(restaurantVM.isSuspended, isTrue);
    });
  });
}

Switch _switchAt(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch));

Widget _harness({
  required Widget child,
  ManagerCatalogMenusViewModel? menusVM,
  ManagerCatalogProductsViewModel? productsVM,
  ManagerRestaurantViewModel? restaurantVM,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ManagerCatalogMenusViewModel>.value(
        value: menusVM ?? ManagerCatalogMenusViewModel(
          ManagerMenusRepository(service: _FakeMenusService()),
        ),
      ),
      ChangeNotifierProvider<ManagerCatalogProductsViewModel>.value(
        value: productsVM ?? ManagerCatalogProductsViewModel(
          ManagerProductsRepository(service: _FakeProductsService()),
        ),
      ),
      ChangeNotifierProvider<ManagerRestaurantViewModel>.value(
        value: restaurantVM ?? ManagerRestaurantViewModel(
          ManagerRestaurantRepository(service: _FakeRestaurantService()),
        ),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<ManagerCatalogMenusViewModel> _loadedMenusViewModel({
  _FakeMenusService? service,
}) async {
  final viewModel = ManagerCatalogMenusViewModel(
    ManagerMenusRepository(service: service ?? _FakeMenusService()),
  );
  await viewModel.fetchMenus(_restaurantId);
  return viewModel;
}

Future<ManagerCatalogProductsViewModel> _loadedProductsViewModel({
  _FakeProductsService? service,
}) async {
  final viewModel = ManagerCatalogProductsViewModel(
    ManagerProductsRepository(service: service ?? _FakeProductsService()),
  );
  await viewModel.fetchProducts(_restaurantId);
  return viewModel;
}

class _FakeMenusService extends ManagerMenusService {
  _FakeMenusService({this.refuseAsSuspended = false});

  final bool refuseAsSuspended;

  @override
  Future<List<Map<String, dynamic>>> fetchMenus(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [
      {
        'id': 'menu-1',
        'name': 'Menu Poulet',
        'description': 'Poulet braisé',
        'price': 45000,
        'imageUrl': 'https://cdn.test/menu.png',
        'available': true,
      },
    ];
  }

  @override
  Future<void> updateAvailability(
    String restaurantId,
    String menuId,
    bool available,
  ) async {
    if (refuseAsSuspended) throw const RestaurantSuspendedException();
  }
}

class _FakeProductsService extends ManagerProductsService {
  _FakeProductsService({this.refuseAsSuspended = false});

  final bool refuseAsSuspended;

  @override
  Future<List<Map<String, dynamic>>> fetchProducts(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [
      {
        'id': 'product-1',
        'name': 'Attiéké',
        'description': 'Semoule de manioc',
        'price': 15000,
        'imageUrl': 'https://cdn.test/product.png',
        'category': 'PLAT',
        'available': true,
        'canBeSoldAlone': true,
      },
    ];
  }

  @override
  Future<void> updateAvailability(
    String restaurantId,
    String productId,
    bool available,
  ) async {
    if (refuseAsSuspended) throw const RestaurantSuspendedException();
  }
}

class _FakeRestaurantService extends ManagerRestaurantService {
  _FakeRestaurantService({this.suspension});

  final Map<String, dynamic>? suspension;

  @override
  Future<Map<String, dynamic>> fetchRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return {
      'id': restaurantId,
      'name': 'Chez Mariam',
      'imageUrl': 'https://cdn.test/restaurant.png',
      if (suspension != null) 'suspension': suspension,
    };
  }
}
