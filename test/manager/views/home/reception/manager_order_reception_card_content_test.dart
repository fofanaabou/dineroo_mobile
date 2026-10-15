import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/manager/repositories/manager_order_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_order_service.dart';
import 'package:dineroo_mobile/manager/view_models/home/manager_order_reception_view_model.dart';
import 'package:dineroo_mobile/manager/views/home/reception/manager_order_reception_card_content.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ManagerOrderReceptionCardContent', () {
    testWidgets('renders new order details and disabled actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(
          order: _order(comment: 'Sans piment'),
          enabled: false,
          onAccept: () {},
          onReject: () {},
        ),
      );

      expect(find.text('NOUVEAU'), findsOneWidget);
      expect(find.text('Commande #A123'), findsOneWidget);
      expect(find.text('35 000 GNF'), findsOneWidget);
      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('+ 1 autre'), findsOneWidget);
      expect(find.text('Commentaire'), findsOneWidget);
      expect(find.text('Sans piment'), findsOneWidget);
      expect(find.text('REFUSER'), findsOneWidget);
      expect(find.text('ACCEPTER'), findsOneWidget);
    });

    testWidgets('accepts an order through the manager provider', (
      tester,
    ) async {
      final service = _FakeManagerOrderService();
      var acceptedCallbackCount = 0;

      await tester.pumpWidget(
        _Harness(
          order: _order(),
          service: service,
          onAccept: () => acceptedCallbackCount++,
          onReject: () {},
        ),
      );

      await tester.tap(find.text('ACCEPTER'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.accepted, [('restaurant-1', 'order-1')]);
      expect(acceptedCallbackCount, 1);
      expect(find.text('Commande acceptée'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when accepting an order fails', (
      tester,
    ) async {
      final service = _FakeManagerOrderService(acceptFails: true);
      var acceptedCallbackCount = 0;

      await tester.pumpWidget(
        _Harness(
          order: _order(),
          service: service,
          onAccept: () => acceptedCallbackCount++,
          onReject: () {},
        ),
      );

      await tester.tap(find.text('ACCEPTER'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.accepted, [('restaurant-1', 'order-1')]);
      expect(acceptedCallbackCount, 0);
      expect(find.text('Impossible d\'accepter la commande.'), findsOneWidget);
    });

    testWidgets('rejects an order after confirmation', (tester) async {
      final service = _FakeManagerOrderService();
      var rejectedCallbackCount = 0;

      await tester.pumpWidget(
        _Harness(
          order: _order(),
          service: service,
          onAccept: () {},
          onReject: () => rejectedCallbackCount++,
        ),
      );

      await tester.tap(find.text('REFUSER'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Refuser la commande'), findsOneWidget);

      await tester.tap(find.text('OUI, REFUSER'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.rejected, [('restaurant-1', 'order-1')]);
      expect(rejectedCallbackCount, 1);
      expect(find.text('Commande refusée'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when rejecting an order fails', (
      tester,
    ) async {
      final service = _FakeManagerOrderService(rejectFails: true);
      var rejectedCallbackCount = 0;

      await tester.pumpWidget(
        _Harness(
          order: _order(),
          service: service,
          onAccept: () {},
          onReject: () => rejectedCallbackCount++,
        ),
      );

      await tester.tap(find.text('REFUSER'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OUI, REFUSER'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.rejected, [('restaurant-1', 'order-1')]);
      expect(rejectedCallbackCount, 0);
      expect(
        find.text('Erreur lors du refus de la commande'),
        findsOneWidget,
      );
    });
  });
}

class _Harness extends StatelessWidget {
  final Order order;
  final _FakeManagerOrderService service;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool enabled;

  _Harness({
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.enabled = true,
    _FakeManagerOrderService? service,
  }) : service = service ?? _FakeManagerOrderService();

  @override
  Widget build(BuildContext context) {
    final currentUserViewModel = CurrentUserViewModel()
      ..setUser(
        User(
          id: 'manager-1',
          firstName: 'Mariama',
          lastName: 'Bah',
          phoneNumber: '620000000',
          role: 'RESTAURANT_MANAGER',
          isTemporaryPin: false,
          organization: Organization(id: 'restaurant-1', name: 'Chez Mariam'),
        ),
      );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserViewModel,
        ),
        ChangeNotifierProvider<ManagerOrderReceptionViewModel>(
          create: (_) => ManagerOrderReceptionViewModel(
            repository: ManagerOrderRepository(service: service),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ManagerOrderReceptionCardContent(
            order: order,
            enabled: enabled,
            onAccept: onAccept,
            onReject: onReject,
          ),
        ),
      ),
    );
  }
}

class _FakeManagerOrderService extends ManagerOrderService {
  final accepted = <(String restaurantId, String orderId)>[];
  final rejected = <(String restaurantId, String orderId)>[];
  final bool acceptFails;
  final bool rejectFails;

  _FakeManagerOrderService({this.acceptFails = false, this.rejectFails = false});

  @override
  Future<void> acceptOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    accepted.add((restaurantId, orderId));
    if (acceptFails) {
      throw Exception('Accept failed');
    }
  }

  @override
  Future<void> rejectOrder({
    required String restaurantId,
    required String orderId,
  }) async {
    rejected.add((restaurantId, orderId));
    if (rejectFails) {
      throw Exception('Reject failed');
    }
  }
}

Order _order({String? comment}) {
  return Order(
    id: 'order-1',
    shortId: 'A123',
    restaurantId: 'restaurant-1',
    restaurantName: 'Chez Mariam',
    totalPrice: 35000,
    serviceFee: 1000,
    deliveryFee: 5000,
    deliveryContact: const OrderDeliveryContact(
      phoneNumber: '620000000',
      address: 'Rue 1',
      district: 'Kipé',
      firstName: 'Aminata',
    ),
    status: OrderStatus.created,
    createdDate: DateTime(2026, 1, 1),
    lastModifiedDate: DateTime(2026, 1, 1, 0, 5),
    comment: comment,
    items: [
      OrderItem(
        id: 1,
        orderId: 'order-1',
        productId: 'product-1',
        imageUrl: '',
        quantity: 2,
        price: 15000,
        name: 'Burger',
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Mariam',
      ),
      OrderItem(
        id: 2,
        orderId: 'order-1',
        productId: 'product-2',
        imageUrl: '',
        quantity: 1,
        price: 5000,
        name: 'Frites',
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Mariam',
      ),
    ],
  );
}
