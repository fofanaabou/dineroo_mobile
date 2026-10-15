import 'package:dineroo_mobile/shared/common/widgets/app_time_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppTimeBox', () {
    testWidgets('displays placeholder when time is null', (tester) async {
      await tester.pumpWidget(buildSubject(const AppTimeBox(time: null)));

      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('displays formatted time and handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(
          AppTimeBox(
            time: const TimeOfDay(hour: 9, minute: 5),
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('9:05 AM'), findsOneWidget);

      await tester.tap(find.byType(AppTimeBox));
      expect(tapped, isTrue);
    });

    testWidgets('applies custom visual values', (tester) async {
      const borderColor = Colors.red;

      await tester.pumpWidget(
        buildSubject(
          const AppTimeBox(
            time: null,
            height: 50,
            backgroundColor: Colors.yellow,
            borderColor: borderColor,
            borderWidth: 2,
            textStyle: TextStyle(color: Colors.blue),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      final text = tester.widget<Text>(find.text('--:--'));

      expect(container.constraints?.maxHeight, 50);
      expect(decoration.color, Colors.yellow);
      expect(decoration.border, Border.all(color: borderColor, width: 2));
      expect(text.style?.color, Colors.blue);
    });
  });
}
