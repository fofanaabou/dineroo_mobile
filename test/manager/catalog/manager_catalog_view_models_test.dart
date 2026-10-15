import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/manager/repositories/manager_menus_repository.dart';
import 'package:dineroo_mobile/manager/repositories/manager_products_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_menus_service.dart';
import 'package:dineroo_mobile/manager/services/manager_products_service.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menus_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_products_view_model.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagerCatalogMenusViewModel', () {
    test('fetches menus and toggles availability optimistically', () async {
      final repository = _FakeMenusRepository(
        menus: [_menu(id: 'menu-1', available: true)],
      );
      final viewModel = ManagerCatalogMenusViewModel(repository);

      await viewModel.fetchMenus('restaurant-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.menus.single.id, 'menu-1');

      final updated = await viewModel.toggleAvailability(
        'restaurant-1',
        'menu-1',
      );

      expect(updated, isTrue);
      expect(viewModel.menus.single.available, isFalse);
      expect(repository.updatedAvailabilities.single, (
        'restaurant-1',
        'menu-1',
        false,
      ));
    });

    test('rolls menu availability back when repository update fails', () async {
      final repository = _FakeMenusRepository(
        menus: [_menu(id: 'menu-1', available: true)],
        updateError: Exception('network'),
      );
      final viewModel = ManagerCatalogMenusViewModel(repository);

      await viewModel.fetchMenus('restaurant-1');
      final updated = await viewModel.toggleAvailability(
        'restaurant-1',
        'menu-1',
      );

      expect(updated, isFalse);
      expect(viewModel.menus.single.available, isTrue);
    });

    test('sets error state when menu fetch fails', () async {
      final viewModel = ManagerCatalogMenusViewModel(
        _FakeMenusRepository(fetchError: Exception('boom')),
      );

      await viewModel.fetchMenus('restaurant-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.menus, isEmpty);
    });
  });

  group('ManagerCatalogProductsViewModel', () {
    test('fetches products and toggles availability optimistically', () async {
      final repository = _FakeProductsRepository(
        products: [_product(id: 'product-1', available: true)],
      );
      final viewModel = ManagerCatalogProductsViewModel(repository);

      await viewModel.fetchProducts('restaurant-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.products.single.name, 'Poulet');

      final updated = await viewModel.toggleAvailability(
        'restaurant-1',
        'product-1',
      );

      expect(updated, isTrue);
      expect(viewModel.products.single.available, isFalse);
      expect(repository.updatedAvailabilities.single, (
        'restaurant-1',
        'product-1',
        false,
      ));
    });

    test(
      'rolls product availability back when repository update fails',
      () async {
        final repository = _FakeProductsRepository(
          products: [_product(id: 'product-1', available: true)],
          updateError: Exception('network'),
        );
        final viewModel = ManagerCatalogProductsViewModel(repository);

        await viewModel.fetchProducts('restaurant-1');
        final updated = await viewModel.toggleAvailability(
          'restaurant-1',
          'product-1',
        );

        expect(updated, isFalse);
        expect(viewModel.products.single.available, isTrue);
      },
    );

    test('sets error state when product fetch fails', () async {
      final viewModel = ManagerCatalogProductsViewModel(
        _FakeProductsRepository(fetchError: Exception('boom')),
      );

      await viewModel.fetchProducts('restaurant-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.products, isEmpty);
    });

    test('exposes only products that can be sold alone', () async {
      final repository = _FakeProductsRepository(
        products: [
          _product(id: 'standalone-product', available: true),
          _product(
            id: 'menu-only-product',
            available: true,
            canBeSoldAlone: false,
          ),
        ],
      );
      final viewModel = ManagerCatalogProductsViewModel(repository);

      await viewModel.fetchProducts('restaurant-1');

      expect(viewModel.allProducts, hasLength(2));
      expect(viewModel.products, hasLength(1));
      expect(viewModel.products.single.id, 'standalone-product');
    });
  });
}

class _FakeMenusRepository extends ManagerMenusRepository {
  _FakeMenusRepository({
    this.menus = const [],
    this.fetchError,
    this.updateError,
  }) : super(service: ManagerMenusService());

  final List<Menu> menus;
  final Object? fetchError;
  final Object? updateError;
  final List<(String restaurantId, String menuId, bool available)>
  updatedAvailabilities = [];

  @override
  Future<List<Menu>> fetchMenus(String restaurantId) async {
    if (fetchError != null) throw fetchError!;
    return menus;
  }

  @override
  Future<void> updateAvailability(
    String restaurantId,
    String menuId,
    bool available,
  ) async {
    updatedAvailabilities.add((restaurantId, menuId, available));
    if (updateError != null) throw updateError!;
  }
}

class _FakeProductsRepository extends ManagerProductsRepository {
  _FakeProductsRepository({
    this.products = const [],
    this.fetchError,
    this.updateError,
  }) : super(service: ManagerProductsService());

  final List<Product> products;
  final Object? fetchError;
  final Object? updateError;
  final List<(String restaurantId, String productId, bool available)>
  updatedAvailabilities = [];

  @override
  Future<List<Product>> fetchProducts(String restaurantId) async {
    if (fetchError != null) throw fetchError!;
    return products;
  }

  @override
  Future<void> updateAvailability(
    String restaurantId,
    String productId,
    bool available,
  ) async {
    updatedAvailabilities.add((restaurantId, productId, available));
    if (updateError != null) throw updateError!;
  }
}

Menu _menu({required String id, required bool available}) {
  return Menu(
    id: id,
    name: 'Menu midi',
    price: 12000,
    imageUrl: 'https://example.com/menu.jpg',
    available: available,
  );
}

Product _product({
  required String id,
  required bool available,
  bool canBeSoldAlone = true,
}) {
  return Product(
    id: id,
    name: 'Poulet',
    price: 10000,
    imageUrl: 'https://example.com/product.jpg',
    category: 'product',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Fatou',
    available: available,
    canBeSoldAlone: canBeSoldAlone,
  );
}
