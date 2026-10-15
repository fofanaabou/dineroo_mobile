import 'package:dineroo_mobile/customer/views/cart/cart_summary_row.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartSummaryRow', () {
    testWidgets('displays formatted amount when available', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CartSummaryRow(label: 'Total', amount: 12500)),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('12 500 GNF'), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('displays fallback dash when amount is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CartSummaryRow(label: 'Livraison', amount: null),
          ),
        ),
      );

      expect(find.text('Livraison'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('displays loader while loading without amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CartSummaryRow(
              label: 'Service',
              amount: null,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Service'), findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('-'), findsNothing);
    });
  });
}
