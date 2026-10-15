import 'package:dineroo_mobile/shared/common/widgets/app_quantity_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppQuantitySelector', () {
    testWidgets('displays quantity and handles add/remove taps', (
      tester,
    ) async {
      var addCount = 0;
      var removeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppQuantitySelector(
              quantity: 3,
              onAdd: () => addCount++,
              onRemove: () => removeCount++,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));

      expect(addCount, 1);
      expect(removeCount, 1);
    });

    testWidgets('does not handle taps when disabled', (tester) async {
      var addCount = 0;
      var removeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppQuantitySelector(
              quantity: 1,
              onAdd: () => addCount++,
              onRemove: () => removeCount++,
              isDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));

      expect(addCount, 0);
      expect(removeCount, 0);
    });
  });
}
