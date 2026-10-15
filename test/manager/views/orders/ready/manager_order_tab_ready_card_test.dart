import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/view_models/orders/manager_order_list_view_model.dart';
import 'package:dineroo_mobile/manager/views/orders/ready/manager_order_tab_ready_card.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ManagerOrderTabReadyCard', () {
    testWidgets('renders ready order summary without assigned driver', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(child: ManagerOrderTabReadyCard(order: _order())),
      );

      expect(find.text('Remise de la commande'), findsOneWidget);
      expect(find.text('#A123'), findsOneWidget);
      expect(find.text('2 articles'), findsOneWidget);
      expect(find.text('Livreur assigné'), findsNothing);
      expect(find.text('Détail'), findsOneWidget);
      expect(find.text('Remettre au livreur'), findsOneWidget);
    });

    testWidgets('renders assigned driver without phone plugin path', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ManagerOrderTabReadyCard(
            order: _order(),
            driver: Contact(name: 'Mamadou Bah', phoneNumber: '', imageUrl: ''),
          ),
        ),
      );

      expect(find.text('Livreur assigné'), findsOneWidget);
      expect(find.text('Mamadou Bah'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('shows driver loader while assignment is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ManagerOrderTabReadyCard(
            order: _order(),
            isLoadingDriver: true,
          ),
        ),
      );

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('Livreur assigné'), findsNothing);
    });

    testWidgets('closes pickup code dialog when cancelling', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ManagerOrderTabReadyCard(
            order: _order(),
            driver: _testDriver,
          ),
        ),
      );

      await tester.tap(find.text('Remettre au livreur'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('validates pickup code before moving ready order to history', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      final orderListVM = ManagerOrderListViewModel(
        ManagerOrderRepository(service: service),
      );

      await tester.pumpWidget(
        _TestApp(
          service: service,
          orderListVM: orderListVM,
          child: ManagerOrderTabReadyCard(order: _order(), driver: _testDriver),
        ),
      );
      await orderListVM.fetchOrdersByRestaurant(
        tester.element(find.byType(ManagerOrderTabReadyCard)),
      );
      await tester.pump();

      await tester.tap(find.text('Remettre au livreur'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(service.validatedPickupOtpCode, '1234');
      expect(
        orderListVM.orders.singleWhere((order) => order.id == 'order-1').status,
        OrderStatus.pickedUp,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;
  final _FakeManagerOrderService? service;
  final ManagerOrderListViewModel? orderListVM;

  const _TestApp({required this.child, this.service, this.orderListVM});

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
    final managerService = service ?? _FakeManagerOrderService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserVM,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: managerService),
          ),
        ),
        ChangeNotifierProvider<ManagerOrderListViewModel>.value(
          value:
              orderListVM ??
              ManagerOrderListViewModel(
                ManagerOrderRepository(service: managerService),
              ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: SizedBox(width: 420, child: child)),
      ),
    );
  }
}

class _FakeManagerOrderService extends ManagerOrderService {
  String? validatedPickupOtpCode;
  String? updatedStatus;

  @override
  Future<List<Map<String, dynamic>>> fetchOrdersByRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return [_orderJson()];
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

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    updatedStatus = status;
  }
}

Map<String, dynamic> _orderJson() {
  return {
    'id': 'order-1',
    'shortId': 'A123',
    'name': '',
    'restaurantId': 'restaurant-1',
    'restaurantName': 'Chez Mariam',
    'totalPrice': 35000,
    'serviceFee': 1000,
    'deliveryFee': 5000,
    'status': 'READY_FOR_PICKUP',
    'createdDate': '2026-01-03T09:05:00Z',
    'lastModifiedDate': '2026-01-03T09:10:00Z',
    'items': const [],
    'customerId': 'customer-1',
  };
}

Order _order() {
  return Order(
    id: 'order-1',
    shortId: 'A123',
    name: '',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Mariam',
    totalPrice: 35000,
    serviceFee: 1000,
    deliveryFee: 5000,
    deliveryContact: const OrderDeliveryContact(
      firstName: 'Aminata',
      lastName: 'Diallo',
      phoneNumber: '620000000',
      address: 'Rue 12',
      district: 'Kipé',
      commune: 'Ratoma',
    ),
    status: OrderStatus.readyForPickup,
    createdDate: DateTime(2026, 1, 3, 9, 5),
    lastModifiedDate: DateTime(2026, 1, 3, 9, 10),
    items: [
      OrderItem(
        id: 1,
        orderId: 'order-1',
        name: 'Burger',
        imageUrl: '',
        quantity: 1,
        price: 30000,
        productId: 'product-1',
        menuId: null,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Mariam',
      ),
      OrderItem(
        id: 2,
        orderId: 'order-1',
        name: 'Frites',
        imageUrl: '',
        quantity: 1,
        price: 5000,
        productId: 'product-2',
        menuId: null,
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Mariam',
      ),
    ],
    comment: null,
    customerId: 'customer-1',
  );
}

final _testDriver = Contact(name: 'Test Driver', phoneNumber: '620000000');
