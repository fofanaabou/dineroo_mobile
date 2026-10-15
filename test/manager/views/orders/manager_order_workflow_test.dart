import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/manager/views/orders/manager_orders_tab_history.dart';
import 'package:dineroo_mobile/manager/views/orders/manager_orders_tab_ongoing.dart';
import 'package:dineroo_mobile/manager/views/orders/ready/manager_order_tab_ready_card.dart' as ready_card;
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets(
    'moves an accepted order from preparation to ready then history after OTP',
    (tester) async {
      final service = _FakeManagerOrderService(initialStatus: 'ACCEPTED');
      final listVM = ManagerOrderListViewModel(
        ManagerOrderRepository(service: service),
      );

      await tester.pumpWidget(
        _WorkflowTestApp(
          service: service,
          listVM: listVM,
          child: const ManagerOrdersTabOngoing(),
        ),
      );
      await listVM.fetchOrdersByRestaurant(
        tester.element(find.byType(ManagerOrdersTabOngoing)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('#A123'), findsOneWidget);
      expect(find.text('Marquer prête'), findsOneWidget);

      await tester.tap(find.text('Marquer prête'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.updatedStatuses, contains('READY'));
      expect(_currentStatus(listVM), OrderStatus.readyForPickup);

      await tester.pumpWidget(
        _WorkflowTestApp(
          service: service,
          listVM: listVM,
          child: _ReadyOrdersView(listVM: listVM),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('#A123'), findsOneWidget);
      expect(find.text('Remettre au livreur'), findsOneWidget);

      await tester.tap(find.text('Remettre au livreur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.tap(find.text('VALIDER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.validatedPickupOtpCode, '1234');
      expect(_currentStatus(listVM), OrderStatus.pickedUp);

      await tester.pumpWidget(
        _WorkflowTestApp(
          service: service,
          listVM: listVM,
          child: const ManagerOrdersTabHistory(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('#A123'), findsOneWidget);
      expect(find.text('Détail'), findsOneWidget);
      expect(find.text('Remettre au livreur'), findsNothing);
    },
  );
}

OrderStatus _currentStatus(ManagerOrderListViewModel listVM) {
  return listVM.orders.singleWhere((order) => order.id == 'order-1').status;
}

class _ReadyOrdersView extends StatelessWidget {
  final ManagerOrderListViewModel listVM;

  const _ReadyOrdersView({required this.listVM});

  @override
  Widget build(BuildContext context) {
    final readyOrders = listVM.orders
        .where((o) => o.status == OrderStatus.readyForPickup)
        .toList();
    return ListView(
      children: readyOrders
          .map(
            (o) => ready_card.ManagerOrderTabReadyCard(
              order: o,
              driver: Contact(name: 'Test Driver', phoneNumber: '620000000'),
            ),
          )
          .toList(),
    );
  }
}

class _WorkflowTestApp extends StatelessWidget {
  final _FakeManagerOrderService service;
  final ManagerOrderListViewModel listVM;
  final Widget child;

  const _WorkflowTestApp({
    required this.service,
    required this.listVM,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserVM = CurrentUserViewModel()
      ..setUser(
        User(
          id: 'manager-1',
          firstName: 'Mariam',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
          organization: Organization(id: 'restaurant-1', name: 'Chez Mariam'),
        ),
      );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: service),
          ),
        ),
        ChangeNotifierProvider<ManagerOrderListViewModel>.value(value: listVM),
      ],
      child: MaterialApp(home: Scaffold(body: SizedBox(width: 430, child: child))),
    );
  }
}

class _FakeManagerOrderService extends ManagerOrderService {
  final String initialStatus;
  final List<String> updatedStatuses = [];
  String? validatedPickupOtpCode;

  _FakeManagerOrderService({required this.initialStatus});

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [_orderJson(status: initialStatus)];
  }

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    updatedStatuses.add(status);
  }

  @override
  Future<String> validatePickupOtp({
    required String orderId,
    required String code,
    String? validatedBy,
    required String restaurantId,
  }) async {
    validatedPickupOtpCode = code;
    return 'Code validé avec succès.';
  }
}

Map<String, dynamic> _orderJson({required String status}) {
  return {
    'id': 'order-1',
    'shortId': 'A123',
    'name': '',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
    'totalPrice': 35000,
    'serviceFee': 1000,
    'deliveryFee': 5000,
    'status': status,
    'createdDate': '2026-01-03T09:05:00Z',
    'lastModifiedDate': '2026-01-03T09:10:00Z',
    'items': const [
      {
        'id': 1,
        'orderId': 'order-1',
        'productId': 'product-1',
        'menuId': null,
        'imageUrl': '',
        'quantity': 1,
        'price': 30000,
        'name': 'Burger',
        'restaurantId': 'restaurant-1',
        'restaurantName': 'Chez Mariam',
      },
    ],
    'customerId': 'customer-1',
  };
}
