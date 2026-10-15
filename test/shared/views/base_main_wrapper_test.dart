import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/window_size_helper.dart';

// The manager role is used because its nav items are plain icons (no providers needed).
Widget _wrapper() => MaterialApp(
  home: BaseMainWrapper(
    selectedIndex: 1,
    role: UserRole.manager,
    child: const Center(child: Text('page')),
  ),
);

void main() {
  group('BaseMainWrapper', () {
    testWidgets('shows the bottom bar on a compact window', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_wrapper());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('shows the extended rail on an expanded window', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_wrapper());

      expect(find.byType(BottomNavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(rail.selectedIndex, 1);
      expect(find.text('page'), findsOneWidget);
    });
  });
}
