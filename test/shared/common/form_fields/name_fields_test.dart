import 'package:dineroo_mobile/shared/common/form_fields/first_name_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/last_name_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FirstNameField renders label, hint and updates controller', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FirstNameField(controller: controller)),
      ),
    );

    expect(find.text('PRÉNOM'), findsOneWidget);
    expect(find.text('Fatou'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Aminata');

    expect(controller.text, 'Aminata');
  });

  testWidgets('LastNameField renders disabled field', (tester) async {
    final controller = TextEditingController(text: 'Diallo');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LastNameField(controller: controller, enabled: false),
        ),
      ),
    );

    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('Diallo'), findsWidgets);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
  });
}
