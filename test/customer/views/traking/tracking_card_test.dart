import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/views/traking/tracking_card.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('TrackingCard', () {
    testWidgets('renders expanded tracking details and delivery code', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: TrackingCard(
            order: _order(status: OrderStatus.readyForPickup),
            driverContact: Contact(
              name: 'Mamadou Bah',
              phoneNumber: '',
              imageUrl: '',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Commande #A123'), findsOneWidget);
      expect(find.text('Chez Mariam'), findsOneWidget);
      expect(find.text('Code à donner au livreur'), findsOneWidget);
      // Delivery contact phone (9999) differs from the connected account's
      // own phone (0000) — the code must come from the delivery contact,
      // matching what the driver expects (regression test for V1-700).
      expect(find.text('9999'), findsOneWidget);
      expect(find.text('0000'), findsNothing);
      expect(find.text('Statut de la commande'), findsOneWidget);
      expect(find.text('Commande passée'), findsOneWidget);
      expect(find.text('Commande confirmée'), findsOneWidget);
      expect(find.text('En cours de livraison'), findsOneWidget);
      expect(find.text('Mamadou Bah'), findsOneWidget);
      expect(
        find.text('Un livreur va récupérer votre commande'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders failure status without delivery code or driver contact',
      (tester) async {
        await tester.pumpWidget(
          _TestApp(
            child: TrackingCard(order: _order(status: OrderStatus.rejected)),
          ),
        );
        await tester.pump();

        expect(find.text('Commande #A123'), findsOneWidget);
        expect(find.text('Chez Mariam'), findsOneWidget);
        expect(find.text('Code à donner au livreur'), findsNothing);
        expect(find.text('Commande refusée'), findsOneWidget);
        expect(find.text('En cours de livraison'), findsNothing);
      },
    );
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    final currentUserViewModel = CurrentUserViewModel()
      ..setUser(
        User(
          id: 'customer-1',
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'CUSTOMER',
          isTemporaryPin: false,
          organization: Organization(id: '', name: 'Mon Restaurant'),
        ),
      );

    return ChangeNotifierProvider<CurrentUserViewModel>.value(
      value: currentUserViewModel,
      child: MaterialApp(
        home: Scaffold(body: Stack(children: [const SizedBox.expand(), child])),
      ),
    );
  }
}

Order _order({
  required OrderStatus status,
  String restaurantName = 'Chez Mariam',
}) {
  return Order(
    id: 'order-1',
    shortId: 'A123',
    name: '',
    restaurantId: 'restaurant-1',
    restaurantName: restaurantName,
    totalPrice: 35000,
    serviceFee: 1000,
    deliveryFee: 5000,
    deliveryContact: const OrderDeliveryContact(
      firstName: 'Aminata',
      lastName: 'Diallo',
      phoneNumber: '629999999',
      address: 'Rue 12',
      district: 'Kipé',
      commune: 'Ratoma',
    ),
    status: status,
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
    ],
    comment: null,
    customerId: 'customer-1',
  );
}
