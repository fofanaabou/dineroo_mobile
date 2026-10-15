import 'dart:async';

import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/realtime/handlers/customer_order_realtime_service.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/order_details_service.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:dineroo_mobile/shared/view_models/order/order_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDetailViewModel', () {
    test('fetches order and details with loading notifications', () async {
      final orderService = _FakeSharedOrderService();
      final detailsService = _FakeOrderDetailsService();
      final viewModel = _viewModel(orderService, detailsService);
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.init('order-1');

      expect(orderService.requestedOrderIds, ['order-1']);
      expect(orderService.contexts, [ApiContext.restaurant]);
      expect(detailsService.requestedOrderIds, ['order-1']);
      expect(viewModel.order?.id, 'order-1');
      expect(viewModel.order?.status, OrderStatus.accepted);
      expect(viewModel.orderDetails?.driverDetails?.fullName, 'Mamadou Bah');
      expect(viewModel.error, isNull);
      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });

    test('stores a friendly error when fetch fails', () async {
      final orderService = _FakeSharedOrderService()..error = Exception('down');
      final viewModel = _viewModel(orderService, _FakeOrderDetailsService());

      await viewModel.fetchOrderById('order-1');

      expect(viewModel.order, isNull);
      expect(viewModel.orderDetails, isNull);
      expect(viewModel.error, 'Échec du chargement de la commande');
      expect(viewModel.isLoading, isFalse);
    });

    test('subscribes to realtime and refreshes matching events', () async {
      final orderService = _FakeSharedOrderService();
      final detailsService = _FakeOrderDetailsService();
      final realtimeService = _FakeCustomerOrderRealtimeService();
      final fetchedOrders = <Order>[];
      final realtimeEvents = <OrderEvent>[];
      final viewModel = _viewModel(
        orderService,
        detailsService,
        realtimeService: realtimeService,
      );

      await viewModel.initWithRealtime(
        'order-1',
        'customer-1',
        onOrderFetched: fetchedOrders.add,
        onRealtimeEvent: realtimeEvents.add,
      );

      expect(realtimeService.subscriptions.single, ('customer-1', 'order-1'));
      expect(fetchedOrders.single.id, 'order-1');

      orderService.status = 'READY_FOR_PICKUP';
      realtimeService.emit(
        OrderEvent(
          orderId: 'order-1',
          status: 'READY_FOR_PICKUP',
          restaurantId: 'restaurant-1',
          customerId: 'customer-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(realtimeEvents.single.status, 'READY_FOR_PICKUP');
      expect(viewModel.order?.status, OrderStatus.readyForPickup);
      expect(orderService.requestedOrderIds, ['order-1', 'order-1']);
      expect(fetchedOrders.last.status, OrderStatus.readyForPickup);
    });

    test('ignores realtime events for other orders', () async {
      final orderService = _FakeSharedOrderService();
      final realtimeService = _FakeCustomerOrderRealtimeService();
      final realtimeEvents = <OrderEvent>[];
      final viewModel = _viewModel(
        orderService,
        _FakeOrderDetailsService(),
        realtimeService: realtimeService,
      );

      await viewModel.initWithRealtime(
        'order-1',
        'customer-1',
        onRealtimeEvent: realtimeEvents.add,
      );

      realtimeService.emit(
        OrderEvent(
          orderId: 'other-order',
          status: 'DELIVERED',
          restaurantId: 'restaurant-1',
          customerId: 'customer-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(realtimeEvents, isEmpty);
      expect(viewModel.order?.status, OrderStatus.accepted);
      expect(orderService.requestedOrderIds, ['order-1']);
    });
  });
}

OrderDetailViewModel _viewModel(
  _FakeSharedOrderService orderService,
  _FakeOrderDetailsService detailsService, {
  _FakeCustomerOrderRealtimeService? realtimeService,
}) {
  return OrderDetailViewModel(
    sharedOrderService: orderService,
    orderDetailsRepository: OrderDetailsRepository(service: detailsService),
    customerRealtimeService: realtimeService,
    apiContext: ApiContext.restaurant,
  );
}

class _FakeSharedOrderService extends SharedOrderService {
  final requestedOrderIds = <dynamic>[];
  final contexts = <ApiContext?>[];
  Object? error;
  String status = 'ACCEPTED';

  @override
  Future<Map<String, dynamic>> fetchOrderById(
    dynamic orderId, {
    ApiContext? context,
  }) async {
    requestedOrderIds.add(orderId);
    contexts.add(context);
    final error = this.error;
    if (error != null) throw error;
    return _orderJson(id: orderId.toString(), status: status);
  }
}

class _FakeOrderDetailsService extends OrderDetailsService {
  final requestedOrderIds = <String>[];

  @override
  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    requestedOrderIds.add(orderId);
    return {
      'orderId': orderId,
      'driverDetails': {
        'id': 'driver-1',
        'firstName': 'Mamadou',
        'lastName': 'Bah',
        'phoneNumber': '620000000',
      },
      'customerDetails': {'phone': '621111111', 'name': 'Aminata Diallo'},
    };
  }
}

class _FakeCustomerOrderRealtimeService
    implements CustomerOrderRealtimeService {
  final _controller = StreamController<OrderEvent>.broadcast();
  final subscriptions = <(String customerId, String orderId)>[];

  @override
  Stream<OrderEvent> get stream => _controller.stream;

  @override
  Future<void> subscribeToOrderStatus({
    required String customerId,
    required String orderId,
  }) async {
    subscriptions.add((customerId, orderId));
  }

  void emit(OrderEvent event) => _controller.add(event);

  @override
  void clearCurrentSubscription() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _orderJson({required String id, required String status}) =>
    {
      'id': id,
      'shortId': 'A123',
      'name': 'Déjeuner',
      'restaurantId': 'restaurant-1',
      'restaurantName': 'Chez Fatou',
      'totalPrice': 35000,
      'serviceFee': 1000,
      'deliveryFee': 5000,
      'status': status,
      'createdDate': '2026-01-01T10:00:00Z',
      'lastModifiedDate': '2026-01-01T10:05:00Z',
      'comment': 'Sans piment',
      'customerId': 'customer-1',
      'deliveryContact': {
        'phoneNumber': '620000000',
        'address': 'Rue 1',
        'district': 'Kaloum',
        'commune': 'Conakry',
        'firstName': 'Aminata',
        'lastName': 'Diallo',
      },
      'orderItems': [
        {
          'id': 42,
          'orderId': id,
          'productId': 'product-1',
          'imageUrl': '',
          'quantity': 2,
          'price': 15000,
          'name': 'Burger',
        },
      ],
    };
