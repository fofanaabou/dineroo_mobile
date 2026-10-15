import 'package:dineroo_mobile/driver/views/home/delivery_confirmation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _enterCode(WidgetTester tester, String code) async {
  final textFields = find.byType(TextField);
  for (int i = 0; i < code.length; i++) {
    await tester.enterText(textFields.at(i), code[i]);
    await tester.pump();
  }
}

void main() {
  group('DeliveryConfirmationView', () {
    testWidgets('renders title and instructions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
          ),
        ),
      );

      expect(find.text('Confirmation de livraison'), findsOneWidget);
      expect(
        find.text('Veuillez saisir le code à 4 chiffres du client'),
        findsOneWidget,
      );
      expect(find.text('VALIDER'), findsOneWidget);
    });

    testWidgets('shows the order number of the delivery being confirmed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
            orderId: '3f2a9c1e-7b4d-4e8a-9c2f-1a2b3c4d5e6f',
          ),
        ),
      );

      expect(find.text('Commande #1a2b3c4d5e6f'), findsOneWidget);
    });

    testWidgets('hides the order number when it is unknown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
            orderId: '  ',
          ),
        ),
      );

      expect(find.textContaining('Commande'), findsNothing);
    });

    testWidgets('shows error when expectedCode is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '',
          ),
        ),
      );

      await _enterCode(tester, '1234');

      expect(
        find.text('Code client indisponible. Veuillez réessayer.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when code is incorrect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
          ),
        ),
      );

      await _enterCode(tester, '0000');

      expect(
        find.text('Code incorrect. Veuillez réessayer.'),
        findsOneWidget,
      );
    });

    testWidgets('navigates to success when code is correct', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
          ),
        ),
      );

      await _enterCode(tester, '1234');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bravo'), findsOneWidget);
    });

    testWidgets('shows tip bottom sheet when link is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryConfirmationView(
            deliveryFee: 5.0,
            expectedCode: '1234',
          ),
        ),
      );

      await tester.tap(find.text("Le client ne trouve pas le code"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Astuce'), findsOneWidget);
    });
  });
}
