import 'package:dineroo_mobile/shared/common/widgets/app_progress_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppProgressButton', () {
    testWidgets('renders label with remaining seconds and handles tap', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(
          AppProgressButton(
            progress: 0.5,
            remainingSeconds: 12,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Accepter (12)'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      expect(tapped, isTrue);
    });

    testWidgets('clamps negative and overflowing progress values', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          AppProgressButton(progress: -1, label: 'Confirmer', onPressed: () {}),
        ),
      );

      var progressBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(progressBox.widthFactor, 0);
      expect(find.text('Confirmer'), findsOneWidget);

      await tester.pumpWidget(
        buildSubject(AppProgressButton(progress: 2, onPressed: () {})),
      );

      progressBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(progressBox.widthFactor, 1);
    });
  });
}
