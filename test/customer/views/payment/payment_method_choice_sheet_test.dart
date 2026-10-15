import 'package:dineroo_mobile/customer/enums/checkout_payment_method.dart';
import 'package:dineroo_mobile/customer/views/payment/payment_method_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentMethodChoiceSheet', () {
    testWidgets(
      'defaults to wallet and shows remaining amount when balance is partial',
      (tester) async {
        await tester.pumpWidget(
          const _Harness(orderTotal: 35000, walletBalance: 10000),
        );

        expect(find.text('Mode de paiement'), findsOneWidget);
        expect(find.text('Wallet Dineroo'), findsOneWidget);
        expect(find.text('Solde Wallet'), findsOneWidget);
        expect(find.text('Reste à payer'), findsOneWidget);
        expect(_textContainingNormalized('10 000 GNF'), findsOneWidget);
        expect(_textContainingNormalized('25 000 GNF'), findsWidgets);

        await tester.tap(find.text('Mobile Money'));
        await tester.pump();

        expect(_textContainingNormalized('Payer 35 000 GNF'), findsOneWidget);
      },
    );

    testWidgets('disables wallet when balance is zero', (tester) async {
      await tester.pumpWidget(
        const _Harness(orderTotal: 35000, walletBalance: 0),
      );

      expect(find.text('Aucun solde disponible'), findsOneWidget);
      expect(find.text('Reste à payer'), findsNothing);
      expect(_textContainingNormalized('Payer 35 000 GNF'), findsOneWidget);
    });

    testWidgets('falls back to Mobile Money when wallet becomes inactive', (
      tester,
    ) async {
      var walletBalance = 10000.0;

      await tester.pumpWidget(
        _Harness(orderTotal: 35000, walletBalance: walletBalance),
      );
      expect(_textContainingNormalized('Payer 25 000 GNF'), findsOneWidget);

      walletBalance = 0;
      await tester.pumpWidget(
        _Harness(orderTotal: 35000, walletBalance: walletBalance),
      );

      expect(find.text('Aucun solde disponible'), findsOneWidget);
      expect(_textContainingNormalized('Payer 35 000 GNF'), findsOneWidget);
    });

    testWidgets('returns selected payment method on confirm', (tester) async {
      CheckoutPaymentMethod? selected;

      await tester.pumpWidget(
        _OpenHarness(onSelected: (method) => selected = method),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Mobile Money'));
      await tester.pump();
      await tester.tap(_textContainingNormalized('Payer 35 000 GNF'));
      await tester.pumpAndSettle();

      expect(selected, CheckoutPaymentMethod.djomy);
    });
  });
}

class _Harness extends StatelessWidget {
  final double orderTotal;
  final double walletBalance;

  const _Harness({required this.orderTotal, required this.walletBalance});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PaymentMethodChoiceSheet(
          orderTotal: orderTotal,
          walletBalance: walletBalance,
          currency: 'GNF',
        ),
      ),
    );
  }
}

Finder _textContainingNormalized(String expected) {
  return find.byWidgetPredicate((widget) {
    final text = widget is Text ? widget.data : null;
    return _normalize(text).contains(expected);
  });
}

String _normalize(String? value) {
  return value
          ?.replaceAll('\u00A0', ' ')
          .replaceAll('\u202F', ' ')
          .replaceAll(RegExp(r'\s+'), ' ') ??
      '';
}

class _OpenHarness extends StatelessWidget {
  final ValueChanged<CheckoutPaymentMethod?> onSelected;

  const _OpenHarness({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final method = await PaymentMethodChoiceSheet.open(
                  context: context,
                  orderTotal: 35000,
                  walletBalance: 10000,
                  currency: 'GNF',
                );
                onSelected(method);
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
  }
}
