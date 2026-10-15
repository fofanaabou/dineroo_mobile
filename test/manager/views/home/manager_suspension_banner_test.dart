import 'package:dineroo_mobile/manager/views/home/manager_suspension_banner.dart';
import 'package:dineroo_mobile/shared/enums/suspension_reason.dart';
import 'package:dineroo_mobile/shared/models/domain/suspension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required SuspensionReason reason,
    VoidCallback? onContactSupport,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerSuspensionBanner(
            suspension: Suspension(
              reason: reason,
              suspendedAt: DateTime.utc(2026, 8, 18, 10, 15),
            ),
            onContactSupport: onContactSupport,
          ),
        ),
      ),
    );
  }

  testWidgets('states the suspension, its reason and the support prompt', (
    tester,
  ) async {
    await pumpBanner(tester, reason: SuspensionReason.incompleteOrders);

    expect(find.text('Restaurant suspendu'), findsOneWidget);
    expect(
      find.text('Articles manquants dans les commandes livrées'),
      findsOneWidget,
    );
    expect(
      find.text('Contactez le support Dineroo pour plus d\'informations.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a generic label for a reason added server-side', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      reason: SuspensionReason.fromApiValue('BRAND_NEW_REASON'),
    );

    expect(find.text('Restaurant suspendu'), findsOneWidget);
    expect(find.text('Autre'), findsOneWidget);
  });

  testWidgets('contacts support when tapped', (tester) async {
    var contacted = 0;

    await pumpBanner(
      tester,
      reason: SuspensionReason.contractBreach,
      onContactSupport: () => contacted++,
    );

    await tester.tap(find.text('Restaurant suspendu'));
    await tester.pump();

    expect(contacted, 1);
  });
}
