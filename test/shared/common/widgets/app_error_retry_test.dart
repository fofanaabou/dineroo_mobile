import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorRetry', () {
    testWidgets('renders message and triggers retry action', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorRetry(
              message: 'Impossible de charger',
              onPressed: () => retryCount++,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Impossible de charger'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));

      expect(retryCount, 1);
    });
  });
}
