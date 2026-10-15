import 'package:dineroo_mobile/shared/views/base_main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns to previous tab after programmatic tab switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BaseMainView(
          navItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Commandes',
            ),
          ],
          screenBuilder: (index) {
            if (index == 0) {
              return Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          BaseMainView.switchTo(context, 1, addToHistory: true),
                      child: const Text('Ouvrir commandes'),
                    ),
                  );
                },
              );
            }

            return const Center(child: Text('Espace commandes'));
          },
        ),
      ),
    );

    expect(find.text('Ouvrir commandes'), findsOneWidget);

    await tester.tap(find.text('Ouvrir commandes'));
    await tester.pumpAndSettle();

    expect(find.text('Espace commandes'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir commandes'), findsOneWidget);
  });
}
