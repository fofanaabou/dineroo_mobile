import 'dart:convert';

import 'package:dineroo_mobile/manager/models/manager_menu_detail.dart';
import 'package:dineroo_mobile/manager/services/manager_menu_detail_service.dart';
import 'package:dineroo_mobile/manager/view_models/catalog/manager_catalog_menu_detail_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('ManagerMenuDetail', () {
    test(
      'parses menu structure with groups and items from catalogue payload',
      () {
        final detail = ManagerMenuDetail.fromJson(_menuJson());

        expect(detail.id, 'menu-1');
        expect(detail.name, 'Menu midi');
        expect(detail.description, 'Plat + boisson');
        expect(detail.imageUrl, 'https://img/menu.jpg');
        expect(detail.basePrice, 10000);
        expect(detail.available, isTrue);
        expect(detail.groups.single.name, 'Accompagnement');
        expect(detail.groups.single.required, isTrue);
        expect(detail.groups.single.minSelections, 1);
        expect(detail.groups.single.maxSelections, 2);
        expect(detail.groups.single.items.single.productName, 'Riz');
        expect(detail.groups.single.items.single.additionalPrice, 500);
      },
    );

    test('uses safe defaults for missing optional fields', () {
      final detail = ManagerMenuDetail.fromJson({'groups': <Object>[]});

      expect(detail.id, isEmpty);
      expect(detail.name, isEmpty);
      expect(detail.basePrice, 0);
      expect(detail.available, isTrue);
      expect(detail.groups, isEmpty);
    });
  });

  group('ManagerMenuDetailService', () {
    test(
      'fetchMenuDetail uses restaurant-context catalogue endpoint',
      () async {
        final service = ManagerMenuDetailService(
          dio: _dio((options) {
            expect(options.method, 'GET');
            expect(
              options.uri.path,
              '/v1/restaurants/restaurant-1/catalogue/menus/menu-1',
            );
            expect(options.uri.queryParameters['context'], 'RESTAURANT');
            return _response(options, jsonEncode(_menuJson()));
          }),
        );

        final result = await service.fetchMenuDetail('restaurant-1', 'menu-1');

        expect(result['id'], 'menu-1');
      },
    );

    test('updateItemAvailability sends item availability payload', () async {
      final service = ManagerMenuDetailService(
        dio: _dio((options) {
          expect(options.method, 'PATCH');
          expect(
            options.uri.path,
            '/v1/restaurants/restaurant-1/catalogue/menus/menu-1/groups/group-1/items/item-1',
          );
          expect(options.data, {'available': false});
          return _response(options, null);
        }),
      );

      await service.updateItemAvailability(
        'restaurant-1',
        'menu-1',
        'group-1',
        'item-1',
        false,
      );
    });

    test('throws when fetch or update fails', () async {
      final service = ManagerMenuDetailService(
        dio: _dio((options) => _response(options, 'error', statusCode: 500)),
      );

      await expectLater(
        service.fetchMenuDetail('restaurant-1', 'menu-1'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.updateItemAvailability(
          'restaurant-1',
          'menu-1',
          'group-1',
          'item-1',
          true,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ManagerCatalogMenuDetailViewModel', () {
    test(
      'fetches menu detail and toggles item availability optimistically',
      () async {
        final service = _FakeManagerMenuDetailService(response: _menuJson());
        final viewModel = ManagerCatalogMenuDetailViewModel(
          service,
          'restaurant-1',
        );

        await viewModel.fetchMenuDetail('menu-1');
        final item = viewModel.menuDetail!.groups.single.items.single;

        expect(viewModel.hasError, isFalse);
        expect(item.available, isTrue);

        final result = await viewModel.toggleItemAvailability(
          'group-1',
          'item-1',
        );

        expect(result, isTrue);
        expect(item.available, isFalse);
        expect(service.updates.single, (
          'restaurant-1',
          'menu-1',
          'group-1',
          'item-1',
          false,
        ));
        viewModel.dispose();
      },
    );

    test('rolls back availability when update fails', () async {
      final service = _FakeManagerMenuDetailService(
        response: _menuJson(),
        updateError: Exception('downstream'),
      );
      final viewModel = ManagerCatalogMenuDetailViewModel(
        service,
        'restaurant-1',
      );
      await viewModel.fetchMenuDetail('menu-1');
      final item = viewModel.menuDetail!.groups.single.items.single;

      final result = await viewModel.toggleItemAvailability(
        'group-1',
        'item-1',
      );

      expect(result, isFalse);
      expect(item.available, isTrue);
      viewModel.dispose();
    });

    test(
      'toggles availability only within the provided group when item ids repeat',
      () async {
        final service = _FakeManagerMenuDetailService(
          response: _twoGroupMenuJson(),
        );
        final viewModel = ManagerCatalogMenuDetailViewModel(
          service,
          'restaurant-1',
        );
        await viewModel.fetchMenuDetail('menu-1');

        final firstGroupItem = viewModel.menuDetail!.groups.first.items.first;
        final secondGroupItem = viewModel.menuDetail!.groups.last.items.first;

        final result = await viewModel.toggleItemAvailability(
          'group-2',
          'shared-item',
        );

        expect(result, isTrue);
        expect(firstGroupItem.available, isTrue);
        expect(secondGroupItem.available, isFalse);
        viewModel.dispose();
      },
    );

    test('rolls back and rethrows when the restaurant is suspended', () async {
      final service = _FakeManagerMenuDetailService(
        response: _menuJson(),
        updateError: const RestaurantSuspendedException(),
      );
      final viewModel = ManagerCatalogMenuDetailViewModel(
        service,
        'restaurant-1',
      );
      await viewModel.fetchMenuDetail('menu-1');
      final item = viewModel.menuDetail!.groups.single.items.single;

      await expectLater(
        viewModel.toggleItemAvailability('group-1', 'item-1'),
        throwsA(isA<RestaurantSuspendedException>()),
      );
      expect(item.available, isTrue);
      viewModel.dispose();
    });

    test('sets error state when detail fetch fails', () async {
      final viewModel = ManagerCatalogMenuDetailViewModel(
        _FakeManagerMenuDetailService(fetchError: Exception('boom')),
        'restaurant-1',
      );

      await viewModel.fetchMenuDetail('menu-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.menuDetail, isNull);
      viewModel.dispose();
    });
  });
}

Map<String, dynamic> _menuJson() => {
  'id': 'menu-1',
  'name': 'Menu midi',
  'description': 'Plat + boisson',
  'imageUrl': 'https://img/menu.jpg',
  'basePrice': 10000,
  'available': true,
  'groups': [
    {
      'id': 'group-1',
      'name': 'Accompagnement',
      'required': true,
      'minSelections': 1,
      'maxSelections': 2,
      'displayOrder': 3,
      'items': [
        {
          'id': 'item-1',
          'productId': 'riz',
          'productName': 'Riz',
          'productImageUrl': 'https://img/riz.jpg',
          'additionalPrice': 500,
          'displayOrder': 4,
          'available': true,
        },
      ],
    },
  ],
};

Map<String, dynamic> _twoGroupMenuJson() => {
  'id': 'menu-1',
  'name': 'Menu midi',
  'basePrice': 10000,
  'available': true,
  'groups': [
    {
      'id': 'group-1',
      'name': 'Accompagnement',
      'required': true,
      'minSelections': 1,
      'maxSelections': 1,
      'items': [
        {
          'id': 'shared-item',
          'productId': 'riz',
          'productName': 'Riz',
          'additionalPrice': 500,
          'available': true,
        },
      ],
    },
    {
      'id': 'group-2',
      'name': 'Sauce',
      'required': false,
      'minSelections': 0,
      'maxSelections': 1,
      'items': [
        {
          'id': 'shared-item',
          'productId': 'piment',
          'productName': 'Piment',
          'additionalPrice': 100,
          'available': true,
        },
      ],
    },
  ],
};

Dio _dio(Response<dynamic> Function(RequestOptions options) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(responder(options)),
    ),
  );
  return dio;
}

Response<dynamic> _response(
  RequestOptions options,
  Object? data, {
  int statusCode = 200,
}) {
  return Response<dynamic>(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}

class _FakeManagerMenuDetailService extends ManagerMenuDetailService {
  final Map<String, dynamic>? response;
  final Object? fetchError;
  final Object? updateError;
  final updates = <(String, String, String, String, bool)>[];

  _FakeManagerMenuDetailService({
    this.response,
    this.fetchError,
    this.updateError,
  });

  @override
  Future<Map<String, dynamic>> fetchMenuDetail(
    String restaurantId,
    String menuId,
  ) async {
    final failure = fetchError;
    if (failure != null) throw failure;
    return response!;
  }

  @override
  Future<void> updateItemAvailability(
    String restaurantId,
    String menuId,
    String groupId,
    String itemId,
    bool available,
  ) async {
    updates.add((restaurantId, menuId, groupId, itemId, available));
    final failure = updateError;
    if (failure != null) throw failure;
  }
}
