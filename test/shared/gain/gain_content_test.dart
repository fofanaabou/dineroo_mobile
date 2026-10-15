import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/gain/earnings_summary.dart';
import 'package:dineroo_mobile/shared/gain/gain_content.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp({
    EarningsSummary summary = const EarningsSummary(
      availableAmount: 12500,
      totalEarned: 20000,
      paidAmount: 7500,
      completedOrdersCount: 10,
      currency: 'GNF',
    ),
    bool isLoading = false,
    bool hasError = false,
    User? currentUser,
  }) {
    final vm = CurrentUserViewModel();
    if (currentUser != null) {
      vm.setUser(currentUser);
    }
    return ChangeNotifierProvider<CurrentUserViewModel>.value(
      value: vm,
      child: MaterialApp(
        home: Scaffold(
          body: GainContent(
            summary: summary,
            isLoading: isLoading,
            hasError: hasError,
            onRefresh: () async {},
            onRetry: () {},
            onWithdraw: () {},
          ),
        ),
      ),
    );
  }

  group('GainContent', () {
    testWidgets('renders loading state without amount', (tester) async {
      await tester.pumpWidget(buildTestApp(isLoading: true));
      await tester.pump();

      expect(find.text('Gains'), findsOneWidget);
      expect(find.text('Montant Disponible'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('12\u202f500 GNF'), findsNothing);
    });

    testWidgets('renders available amount for driver', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('12\u202f500 GNF'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('7\u202f500 GNF'), findsOneWidget);
      expect(find.text('20\u202f000 GNF'), findsOneWidget);
      expect(find.text('Courses termin\u00e9es'), findsOneWidget);
      expect(
        find.text('Calcul\u00e9 sur les courses livr\u00e9es.'),
        findsOneWidget,
      );
      expect(find.text('RETIRER MON ARGENT'), findsOneWidget);
    });

    testWidgets('shows manager-specific text', (tester) async {
      final manager = User(
        id: 'm1',
        firstName: 'M',
        lastName: 'G',
        phoneNumber: '620000000',
        role: 'RESTAURANT_MANAGER',
        isTemporaryPin: false,
      );
      await tester.pumpWidget(buildTestApp(currentUser: manager));
      await tester.pump();

      expect(find.text('Commandes termin\u00e9es'), findsOneWidget);
      expect(
        find.text(
          'Calcul\u00e9 sur les commandes livr\u00e9es ou termin\u00e9es.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(buildTestApp(hasError: true));
      await tester.pump();

      expect(
        find.text('Impossible de charger vos gains pour le moment.'),
        findsOneWidget,
      );
      expect(find.byType(AppErrorRetry), findsOneWidget);
    });
  });
}
