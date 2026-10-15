import 'package:dineroo_mobile/manager/views/home/manager_home_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagerHomeEmptyState', () {
    testWidgets('renders illustration and texts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ManagerHomeEmptyState())),
      );

      expect(find.text('Aucune commande pour le moment'), findsOneWidget);
      expect(
        find.text(
          'Les nouvelles commandes apparaîtront ici dès qu’elles seront passées.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.near_me_outlined), findsOneWidget);
      expect(find.byIcon(Icons.door_front_door_outlined), findsOneWidget);
    });
  });
}
