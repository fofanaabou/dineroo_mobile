import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBackButton does nothing on the root route', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppBackButton())),
    );

    await tester.tap(find.byType(AppBackButton));
    await tester.pump();

    expect(find.byType(AppBackButton), findsOneWidget);
  });

  testWidgets('AppBackButton pops when a previous route exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: AppBackButton()),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });
}
