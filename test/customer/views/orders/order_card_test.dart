import 'package:dineroo_mobile/customer/views/orders/order_card.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('renders ongoing order details and actions', (tester) async {
    await tester.pumpWidget(_TestApp(child: OrderCard(order: _order())));
    await tester.pump();

    expect(find.text('Commande #A123'), findsOneWidget);
    expect(find.text('Chez Mariam'), findsOneWidget);
    expect(find.text('Détail'), findsOneWidget);
    expect(find.text('Suivre'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().replaceAll(RegExp(r'\s'), ' ').contains(
              '41 000 GNF',
            ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders history status and only detail action', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: OrderCard(order: _order(status: OrderStatus.delivered)),
      ),
    );
    await tester.pump();

    expect(find.text(OrderStatus.delivered.label), findsOneWidget);
    expect(find.text('Détail'), findsOneWidget);
    expect(find.text('Suivre'), findsNothing);
  });

  testWidgets('uses footer and can hide restaurant name and price', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: OrderCard(
          order: _order(),
          showRestaurantName: false,
          hidePrice: true,
          footer: const Text('Footer personnalisé'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Footer personnalisé'), findsOneWidget);
    expect(find.text('Chez Mariam'), findsNothing);
    expect(find.text('Détail'), findsNothing);
    expect(find.text('Suivre'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: SizedBox(width: 420, child: child)),
    );
  }
}

Order _order({OrderStatus status = OrderStatus.accepted}) {
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
      address: 'Rue 12',
      district: 'Kipé',
      commune: 'Ratoma',
      firstName: 'Aminata',
      lastName: 'Diallo',
    ),
    status: status,
    createdDate: DateTime(2026, 1, 3, 9, 5),
    lastModifiedDate: DateTime(2026, 1, 3, 9, 5),
    items: [
      OrderItem(
        id: 1,
        orderId: 'order-1',
        name: 'Burger',
        imageUrl: '',
        quantity: 2,
        price: 15000,
        productId: 'product-1',
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
        restaurantId: 'restaurant-1',
        restaurantName: 'Chez Mariam',
      ),
    ],
    customerId: 'customer-1',
  );
}
