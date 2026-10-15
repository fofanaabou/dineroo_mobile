import 'package:dineroo_mobile/shared/views/adaptive_nav_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/window_size_helper.dart';

const _items = [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
];

Widget _app({
  int currentIndex = 0,
  ValueChanged<int>? onSelected,
  bool showNavigation = true,
}) => MaterialApp(
  home: AdaptiveNavScaffold(
    currentIndex: currentIndex,
    onSelected: onSelected ?? (_) {},
    items: _items,
    showNavigation: showNavigation,
    body: const Center(child: Text('contenu')),
  ),
);

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

void main() {
  group('AdaptiveNavScaffold', () {
    testWidgets('uses the bottom bar on a compact window', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('uses a labelled rail on a medium window', (tester) async {
      setWindowSize(tester, 700);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.all);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('uses an extended rail on an expanded window', (tester) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app());

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(_rail(tester).extended, isTrue);
    });

    testWidgets('switches layout exactly at the 600 and 840 breakpoints', (
      tester,
    ) async {
      Future<void> pumpAt(double width) async {
        setWindowSize(tester, width);
        await tester.pumpWidget(_app());
      }

      await pumpAt(599);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await pumpAt(600);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(_rail(tester).extended, isFalse);

      await pumpAt(839);
      expect(_rail(tester).extended, isFalse);

      await pumpAt(840);
      expect(_rail(tester).extended, isTrue);
    });

    for (final width in [390.0, 700.0, 1200.0]) {
      testWidgets('reports the tapped destination at ${width}px', (
        tester,
      ) async {
        final selected = <int>[];
        setWindowSize(tester, width);
        await tester.pumpWidget(_app(onSelected: selected.add));

        await tester.tap(find.text('Commandes'));
        await tester.pump();

        expect(selected, [1]);
      });
    }

    testWidgets('marks the current destination as selected', (tester) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app(currentIndex: 1));
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );

      setWindowSize(tester, 700);
      await tester.pumpWidget(_app(currentIndex: 1));
      expect(_rail(tester).selectedIndex, 1);
    });

    testWidgets('hides all navigation when showNavigation is false', (
      tester,
    ) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app(showNavigation: false));
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);

      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app(showNavigation: false));
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets(
      'gives the body the full width when navigation is hidden at runtime',
      (tester) async {
        setWindowSize(tester, 1200);
        await tester.pumpWidget(_app());
        expect(tester.getCenter(find.text('contenu')).dx, greaterThan(600));

        await tester.pumpWidget(_app(showNavigation: false));

        expect(find.byType(NavigationRail), findsNothing);
        expect(tester.getCenter(find.text('contenu')).dx, closeTo(600, 0.5));
      },
    );

    testWidgets('rejects fewer than two destinations when built', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNavScaffold(
            currentIndex: 0,
            onSelected: (_) {},
            items: [_items.first],
            body: const SizedBox(),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
