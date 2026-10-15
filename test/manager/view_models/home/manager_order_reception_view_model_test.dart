import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ManagerOrderReceptionViewModel', () {
    testWidgets('syncs restaurant orders from current manager context', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(service);
      final context = await _pumpContext(tester);

      await viewModel.syncWithServer(context);

      expect(service.fetchedRestaurantId, 'restaurant-1');
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.allOrders.map((o) => o.id), ['new-1', 'ready-1']);
      expect(viewModel.orders.map((o) => o.id), ['new-1']);
      expect(viewModel.newOrdersCount, 1);
      expect(viewModel.readyOrdersCount, 1);
    });

    testWidgets('does not fetch when manager has no restaurant', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(service);
      final context = await _pumpContext(tester, withOrganization: false);

      await viewModel.syncWithServer(context);

      expect(service.fetchedRestaurantId, isNull);
      expect(viewModel.orders, isEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('accepts, rejects, updates and removes orders', () async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(service);
      viewModel.allOrders.addAll([_order('new-1'), _order('new-2')]);
      viewModel.orders.addAll([_order('new-1'), _order('new-2')]);

      expect(await viewModel.acceptOrder('restaurant-1', 'new-1'), isTrue);
      expect(service.acceptedOrderId, 'new-1');
      expect(viewModel.orders.map((o) => o.id), ['new-2']);

      expect(await viewModel.rejectOrder('restaurant-1', 'new-2'), isTrue);
      expect(service.rejectedOrderId, 'new-2');
      expect(viewModel.orders, isEmpty);

      expect(
        await viewModel.updateStatus(
          restaurantId: 'restaurant-1',
          orderId: 'ready-1',
          status: 'READY_FOR_PICKUP',
        ),
        isTrue,
      );
      expect(service.updatedStatus, 'READY_FOR_PICKUP');
    });

    test('validatePickupOtp returns message on success', () async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(service);

      final result = await viewModel.validatePickupOtp(
        orderId: 'order-1',
        code: '1234',
        restaurantId: 'restaurant-id',
      );

      expect(result, 'Code validé avec succès.');
      expect(viewModel.isLoading, isFalse);
    });

    test('validatePickupOtp returns null on failure', () async {
      final service = _FakeManagerOrderService();
      service.throwOnPickupOtp = true;
      final viewModel = _viewModel(service);

      final result = await viewModel.validatePickupOtp(
        orderId: 'order-1',
        code: '0000',
        restaurantId: 'restaurant-id',
      );

      expect(result, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    testWidgets('realtime events trigger a guarded sync', (tester) async {
      final service = _FakeManagerOrderService();
      final viewModel = _viewModel(service);
      final context = await _pumpContext(tester);

      await viewModel.handleRealtimeOrder(
        OrderEvent(
          restaurantId: 'restaurant-1',
          customerId: 'customer-1',
          orderId: 'new-1',
          status: 'PAYMENT_CONFIRMED',
        ),
        context,
      );

      expect(service.fetchCalls, 1);
      expect(viewModel.orders.length, 1);
    });
  });
}

ManagerOrderReceptionViewModel _viewModel(_FakeManagerOrderService service) {
  return ManagerOrderReceptionViewModel(
    repository: ManagerOrderRepository(service: service),
  );
}

Future<BuildContext> _pumpContext(
  WidgetTester tester, {
  Organization? organization,
  bool withOrganization = true,
}) async {
  organization ??= withOrganization
      ? Organization(id: 'restaurant-1', name: 'Chez Mariam')
      : null;
  final currentUserVM = CurrentUserViewModel()
    ..setUser(
      User(
        id: 'manager-1',
        firstName: 'Aminata',
        lastName: 'Diallo',
        phoneNumber: '620000000',
        role: 'RESTAURANT_MANAGER',
        isTemporaryPin: false,
        organization: organization,
      ),
    );
  late BuildContext capturedContext;
  await tester.pumpWidget(
    ChangeNotifierProvider<CurrentUserViewModel>.value(
      value: currentUserVM,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return capturedContext;
}

class _FakeManagerOrderService extends ManagerOrderService {
  String? fetchedRestaurantId;
  String? acceptedOrderId;
  String? rejectedOrderId;
  String? updatedStatus;
  int fetchCalls = 0;
  String? pickupOtpResult;
  bool throwOnPickupOtp = false;

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    fetchedRestaurantId = restaurantId;
    fetchCalls++;
    return [
      _orderJson('new-1', 'PAYMENT_CONFIRMED'),
      _orderJson('ready-1', 'READY_FOR_PICKUP'),
    ];
  }

  @override
  Future<void> acceptOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    acceptedOrderId = orderId;
  }

  @override
  Future<void> rejectOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    rejectedOrderId = orderId;
  }

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    updatedStatus = status;
  }

  @override
  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    if (throwOnPickupOtp) {
      throw Exception('Code de récupération invalide.');
    }
    return pickupOtpResult ?? 'Code validé avec succès.';
  }
}

Map<String, dynamic> _orderJson(String id, String status) {
  return {
    'id': id,
    'shortId': id,
    'name': 'Commande $id',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
    'totalPrice': 10000,
    'serviceFee': 1000,
    'deliveryFee': 2000,
    'status': status,
    'createdDate': '2026-01-01T10:00:00Z',
    'lastModifiedDate': '2026-01-01T10:05:00Z',
    'items': const [],
    'customerId': 'customer-1',
  };
}

Order _order(String id) {
  return Order(
    id: id,
    shortId: id,
    name: 'Commande $id',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Mariam',
    totalPrice: 10000,
    serviceFee: 1000,
    deliveryFee: 2000,
    deliveryContact: const OrderDeliveryContact(
      firstName: 'Aminata',
      lastName: 'Diallo',
      phoneNumber: '620000000',
      address: 'Kaloum',
      district: 'Centre',
      commune: 'Kaloum',
    ),
    status: OrderStatus.paymentConfirmed,
    createdDate: DateTime.utc(2026, 1, 1),
    lastModifiedDate: DateTime.utc(2026, 1, 1, 10, 5),
    items: const [],
    customerId: 'customer-1',
  );
}
