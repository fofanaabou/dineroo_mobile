import 'package:dineroo_mobile/shared/common/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppChip', () {
    testWidgets('renders text and configured colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(
              text: 'Ouvert',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final text = tester.widget<Text>(find.text('Ouvert'));

      expect(decoration.color, Colors.green);
      expect(text.style?.color, Colors.white);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
