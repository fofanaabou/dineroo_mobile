import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'package:dineroo_mobile/driver/repositories/driver_delivery_repository.dart';
import 'package:dineroo_mobile/driver/repositories/driver_order_repository.dart';
import 'package:dineroo_mobile/driver/services/delivery/driver_delivery_service.dart';
import 'package:dineroo_mobile/driver/view_models/driver_order_history_view_model.dart';
import 'package:dineroo_mobile/customer/services/restaurant/restaurant_service.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverOrderHistoryViewModel', () {
    test('sets an error when no driver is authenticated', () async {
      final harness = _Harness();

      await harness.viewModel.fetchOrders();

      expect(harness.viewModel.hasError, isTrue);
      expect(harness.viewModel.items, isEmpty);
      expect(harness.viewModel.failedOrdersCount, 0);
    });

    test(
      'loads delivered and canceled deliveries with matching orders',
      () async {
        final harness = _Harness.withDriver();
        harness.deliveryService.deliveries = [
          _deliveryJson('delivery-1', 'order-old', 'DELIVERED'),
          _deliveryJson('delivery-2', 'order-new', 'CANCELED'),
        ];
        harness.orderService.ordersById = {
          'order-old': _orderJson('order-old', '2026-01-01T10:00:00Z'),
          'order-new': _orderJson('order-new', '2026-01-02T10:00:00Z'),
        };
        final loadingStates = <bool>[];
        harness.viewModel.addListener(
          () => loadingStates.add(harness.viewModel.isLoading),
        );

        await harness.viewModel.fetchOrders();

        expect(harness.deliveryService.requestedDriverIds, ['driver-1']);
        expect(harness.deliveryService.requestedStatuses.single, [
          DeliveryStatus.delivered.apiValue,
          DeliveryStatus.canceled.apiValue,
        ]);
        expect(harness.orderService.requestedBatchIds.single, [
          'order-old',
          'order-new',
        ]);
        expect(harness.viewModel.items.map((item) => item.order.id), [
          'order-new',
          'order-old',
        ]);
        expect(harness.viewModel.orders, hasLength(2));
        expect(
          harness.viewModel.itemForOrder(harness.viewModel.orders.first),
          isNotNull,
        );
        expect(harness.viewModel.hasError, isFalse);
        expect(harness.viewModel.hasPartialError, isFalse);
        expect(loadingStates.first, isTrue);
        expect(loadingStates.last, isFalse);
      },
    );

    test('refreshes history order images from restaurant detail', () async {
      final harness = _Harness.withDriver();
      harness.deliveryService.deliveries = [
        _deliveryJson('delivery-1', 'order-1', 'DELIVERED'),
      ];
      harness.orderService.ordersById = {
        'order-1': _orderJson(
          'order-1',
          '2026-01-01T10:00:00Z',
          imageUrl: 'https://stale.test/product.jpg',
        ),
      };
      harness.restaurantService.response = {
        'id': 'restaurant-1',
        'menus': const [],
        'products': [
          {'id': 'product-1', 'imageUrl': 'https://wasabi.test/product.jpg'},
        ],
      };

      await harness.viewModel.fetchOrders();

      expect(
        harness.viewModel.orders.single.items.single.imageUrl,
        'https://wasabi.test/product.jpg',
      );
    });

    test('counts deliveries whose order was not returned by batch', () async {
      final harness = _Harness.withDriver();
      harness.deliveryService.deliveries = [
        _deliveryJson('delivery-1', 'order-1', 'DELIVERED'),
        _deliveryJson('delivery-2', 'missing-order', 'DELIVERED'),
      ];
      harness.orderService.ordersById = {
        'order-1': _orderJson('order-1', '2026-01-01T10:00:00Z'),
      };

      await harness.viewModel.fetchOrders();

      expect(harness.viewModel.items, hasLength(1));
      expect(harness.viewModel.failedOrdersCount, 1);
      expect(harness.viewModel.hasPartialError, isTrue);
    });

    test('clears items and exposes an error when loading fails', () async {
      final harness = _Harness.withDriver();
      harness.deliveryService.error = Exception('delivery down');

      await harness.viewModel.fetchOrders();

      expect(harness.viewModel.items, isEmpty);
      expect(harness.viewModel.hasError, isTrue);
      expect(harness.viewModel.failedOrdersCount, 0);
      expect(harness.viewModel.isLoading, isFalse);
    });
  });
}

class _Harness {
  final _FakeDriverDeliveryService deliveryService;
  final _FakeSharedOrderService orderService;
  final _FakeRestaurantService restaurantService;
  final DriverOrderHistoryViewModel viewModel;

  _Harness._(
    this.deliveryService,
    this.orderService,
    this.restaurantService,
    this.viewModel,
  );

  factory _Harness() => _buildHarness(withDriver: false);

  factory _Harness.withDriver() => _buildHarness(withDriver: true);
}

_Harness _buildHarness({required bool withDriver}) {
  final currentUserViewModel = CurrentUserViewModel();
  if (withDriver) {
    currentUserViewModel.setUser(
      User(
        id: 'driver-1',
        firstName: 'Mamadou',
        lastName: 'Bah',
        phoneNumber: '620000000',
        role: 'DRIVER',
        isTemporaryPin: false,
      ),
    );
  }

  final deliveryService = _FakeDriverDeliveryService();
  final orderService = _FakeSharedOrderService();
  final restaurantService = _FakeRestaurantService();
  final viewModel = DriverOrderHistoryViewModel(
    DriverDeliveryRepository(service: deliveryService),
    DriverOrderRepository(
      orderService: orderService,
      orderDetailsRepository: OrderDetailsRepository(
        service: _FakeOrderDetailsService(),
      ),
      restaurantService: restaurantService,
    ),
    currentUserViewModel,
  );
  return _Harness._(
    deliveryService,
    orderService,
    restaurantService,
    viewModel,
  );
}

class _FakeDriverDeliveryService extends DriverDeliveryService {
  final requestedDriverIds = <String>[];
  final requestedStatuses = <List<String>?>[];
  List<Map<String, dynamic>> deliveries = [];
  Object? error;

  @override
  Future<List<dynamic>> fetchDeliveriesByDriverId({
    required String driverId,
    List<String>? statuses,
  }) async {
    requestedDriverIds.add(driverId);
    requestedStatuses.add(statuses);
    final error = this.error;
    if (error != null) throw error;
    return deliveries;
  }
}

class _FakeSharedOrderService extends SharedOrderService {
  final requestedBatchIds = <List<String>>[];
  Map<String, Map<String, dynamic>> ordersById = {};

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByIds(
    List<String> orderIds,
  ) async {
    requestedBatchIds.add(orderIds);
    return [
      for (final orderId in orderIds)
        if (ordersById.containsKey(orderId)) ordersById[orderId]!,
    ];
  }
}

class _FakeOrderDetailsService extends OrderDetailsService {}

class _FakeRestaurantService extends RestaurantService {
  Map<String, dynamic> response = const {};

  @override
  Future<Map<String, dynamic>> fetchRestaurant(String id) async => response;
}

Map<String, dynamic> _deliveryJson(String id, String orderId, String status) =>
    {
      'id': id,
      'orderId': orderId,
      'driverId': 'driver-1',
      'status': status,
      'pickupAddress': {'address': 'Restaurant', 'district': 'Kaloum'},
      'deliveryAddress': {'address': 'Client', 'district': 'Kipé'},
      'fee': 5000,
      'distanceKm': 4.2,
      'assignedAt': '2026-01-01T10:00:00Z',
    };

Map<String, dynamic> _orderJson(
  String id,
  String createdDate, {
  String imageUrl = '',
}) => {
  'id': id,
  'shortId': id.substring(id.length - 3),
  'restaurantId': 'restaurant-1',
  'restaurantName': 'Chez Fatou',
  'totalPrice': 35000,
  'status': 'DELIVERED',
  'createdDate': createdDate,
  'lastModifiedDate': createdDate,
  'deliveryContact': {'phoneNumber': '620000000', 'address': 'Rue 1'},
  'orderItems': [
    {
      'id': 1,
      'orderId': id,
      'productId': 'product-1',
      'imageUrl': imageUrl,
      'quantity': 1,
      'price': 15000,
      'name': 'Burger',
    },
  ],
};
