import 'dart:io';

import 'package:dineroo_mobile/shared/exceptions/restaurant_unavailable_exception.dart';
import 'package:dineroo_mobile/customer/repositories/restaurant_repository.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_list_service.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_list_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/models/domain/pagination_params.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('restaurant_vm_test_');
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('recentSearches')) {
      await Hive.openBox<String>('recentSearches');
    }
    await Hive.box<String>('recentSearches').clear();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('recentSearches')) {
      await Hive.box<String>('recentSearches').clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  group('RestaurantViewModel', () {
    test('fetches restaurant details and caches open status', () async {
      final service = _FakeRestaurantService()..openStatus = true;
      final viewModel = RestaurantViewModel(_repository(service));

      await viewModel.fetch('restaurant-1');
      final isOpen = await viewModel.restaurantIsOpen('restaurant-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.restaurant?.id, 'restaurant-1');
      expect(isOpen, isFalse);
      expect(service.openStatusCalls, 0);
    });

    test('surfaces a failed open-status check instead of reporting closed', () async {
      final service = _FakeRestaurantService()
        ..openStatus = false
        ..throwOnOpenStatus = true;
      final viewModel = RestaurantViewModel(_repository(service));

      await expectLater(
        viewModel.refreshRestaurantOpenStatus('restaurant-1'),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.error, isNotNull);
    });

    test('reports an open restaurant from a successful check', () async {
      final service = _FakeRestaurantService()..openStatus = true;
      final viewModel = RestaurantViewModel(_repository(service));

      final isOpen = await viewModel.refreshRestaurantOpenStatus(
        'restaurant-1',
      );

      expect(isOpen, isTrue);
      expect(viewModel.error, isNull);
    });

    test('flags an unavailable restaurant without a technical error', () async {
      final service = _FakeRestaurantService()..fetchError =
          const RestaurantUnavailableException('restaurant-1');
      final viewModel = RestaurantViewModel(_repository(service));

      await viewModel.fetch('restaurant-1');

      expect(viewModel.isUnavailable, isTrue);
      expect(viewModel.error, RestaurantUnavailableException.message);
      expect(viewModel.isLoading, isFalse);
      expect(await viewModel.restaurantIsOpen('restaurant-1'), isFalse);
    });

    test('does not flag a technical failure as unavailable', () async {
      final service = _FakeRestaurantService()
        ..fetchError = Exception('offline');
      final viewModel = RestaurantViewModel(_repository(service));

      await viewModel.fetch('restaurant-1');

      expect(viewModel.isUnavailable, isFalse);
      expect(viewModel.error, isNotNull);
      expect(viewModel.error, isNot(RestaurantUnavailableException.message));
    });

    test('clears the unavailable flag once the restaurant is back', () async {
      final service = _FakeRestaurantService()..fetchError =
          const RestaurantUnavailableException('restaurant-1');
      final viewModel = RestaurantViewModel(_repository(service));

      await viewModel.fetch('restaurant-1');
      expect(viewModel.isUnavailable, isTrue);

      service.fetchError = null;
      await viewModel.fetch('restaurant-1');

      expect(viewModel.isUnavailable, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.restaurant?.id, 'restaurant-1');
    });
  });

  group('RestaurantListViewModel', () {
    test(
      'fetches, refreshes and paginates restaurants with location',
      () async {
        final listService = _FakeRestaurantListService();
        final location = LocationViewModel()
          ..setPosition(const LatLng(9.6, -13.6));
        final viewModel = RestaurantListViewModel(
          _repository(_FakeRestaurantService(), listService),
          location,
        );

        await viewModel.fetchRestaurants();

        expect(viewModel.restaurants.map((r) => r.id), ['restaurant-1']);
        expect(viewModel.canLoadMore, isTrue);
        expect(listService.lastLat, 9.6);
        expect(listService.lastLon, -13.6);

        await viewModel.loadMore();

        expect(viewModel.restaurants.map((r) => r.id), [
          'restaurant-1',
          'restaurant-2',
        ]);
        expect(viewModel.canLoadMore, isFalse);

        await viewModel.fetchRestaurants(refresh: true);

        expect(viewModel.restaurants.map((r) => r.id), ['restaurant-1']);
      },
    );

    test('searches, deduplicates recent searches and clears them', () async {
      final viewModel = RestaurantListViewModel(
        _repository(_FakeRestaurantService(), _FakeRestaurantListService()),
        LocationViewModel(),
      );

      await viewModel.searchRestaurants('Pizza');
      await viewModel.searchRestaurants('pizza');
      await viewModel.searchRestaurants('Pizza Poulet');

      expect(viewModel.currentSearch, 'Pizza Poulet');
      expect(viewModel.recentSearches, ['Pizza Poulet']);

      await viewModel.resetSearch();
      expect(viewModel.currentSearch, isNull);

      viewModel.clearRecentSearches();
      expect(viewModel.recentSearches, isEmpty);
    });

    test('stores fetch errors without throwing', () async {
      final listService = _FakeRestaurantListService()..throwOnFetch = true;
      final viewModel = RestaurantListViewModel(
        _repository(_FakeRestaurantService(), listService),
        LocationViewModel(),
      );

      await viewModel.fetchRestaurants();

      expect(viewModel.restaurants, isEmpty);
      expect(viewModel.error, contains('fetch failed'));
      expect(viewModel.isLoading, isFalse);
    });
  });
}

RestaurantRepository _repository(
  RestaurantService service, [
  RestaurantListService? listService,
]) {
  return RestaurantRepository(
    service: service,
    listService: listService ?? _FakeRestaurantListService(),
  );
}

class _FakeRestaurantService extends RestaurantService {
  bool openStatus = false;
  bool throwOnOpenStatus = false;
  int openStatusCalls = 0;
  Object? fetchError;

  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async {
    final error = fetchError;
    if (error != null) throw error;

    return {
      'id': id,
      'name': 'Chez Mariam',
      'address': 'Kaloum',
      'phone': '620000000',
      'imageUrl': 'image.png',
      'description': 'Cuisine guinéenne',
      'menus': const [],
      'products': const [],
      'openingHours': const [],
    };
  }

  @override
  Future<bool> restaurantIsOpen(String id) async {
    openStatusCalls++;
    if (throwOnOpenStatus) throw Exception('open failed');
    return openStatus;
  }
}

class _FakeRestaurantListService extends RestaurantListService {
  bool throwOnFetch = false;
  double? lastLat;
  double? lastLon;

  @override
  Future<Map<String, dynamic>> fetchRestaurants(
    PaginationParams params, {
    double? lat,
    double? lon,
  }) async {
    if (throwOnFetch) throw Exception('fetch failed');
    lastLat = lat;
    lastLon = lon;
    final page = params.page;
    return {
      'items': [
        {
          'id': 'restaurant-$page',
          'name': 'Restaurant $page',
          'imageUrl': 'image$page.png',
          'phoneNumber': '62000000$page',
          'openingHours': const [],
          'distanceKm': page,
        },
      ],
      'page': {'number': page, 'size': 10, 'totalPages': 2, 'totalElements': 2},
    };
  }
}
