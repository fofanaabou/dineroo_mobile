import 'package:dineroo_mobile/shared/common/widgets/app_text_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AppTextArea', () {
    testWidgets('renders default label and hint', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildSubject(AppTextArea(controller: controller)),
      );

      expect(find.text('Commentaires (facultatif)'), findsOneWidget);
      expect(find.text('Écrivez ici…'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('updates controller text and enforces max length', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildSubject(
          AppTextArea(
            controller: controller,
            label: 'Note',
            hintText: 'Ajouter une note',
            maxLength: 5,
            maxLines: 2,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abcdef');

      expect(find.text('Note'), findsOneWidget);
      expect(controller.text, 'abcde');
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 2);
    });
  });
}
