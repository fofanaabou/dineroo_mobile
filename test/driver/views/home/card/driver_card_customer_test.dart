import 'package:dineroo_mobile/driver/views/home/card/driver_card_customer.dart';
import 'package:dineroo_mobile/driver/views/home/delivery_confirmation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'opens the delivery confirmation with the order number of the delivery',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DriverCardCustomer(
                    customerName: 'Aminata Diallo',
                    customerPhone: '+224620001234',
                    orderId: '3f2a9c1e-7b4d-4e8a-9c2f-1a2b3c4d5e6f',
                    onPrimaryAction: () {},
                    onClose: () {},
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Je livre la commande'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OUI'));
      await tester.pumpAndSettle();

      expect(find.byType(DeliveryConfirmationView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DeliveryConfirmationView),
          matching: find.text('Commande #1a2b3c4d5e6f'),
        ),
        findsOneWidget,
      );
    },
  );
}
