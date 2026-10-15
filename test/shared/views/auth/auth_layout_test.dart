import 'package:dineroo_mobile/shared/views/auth/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthLayout', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Connexion',
            subtitle: 'Veuillez vous connecter',
            children: const [Text('child')],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Veuillez vous connecter'), findsOneWidget);
      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('renders back button when requested', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Test',
            showBackButton: true,
            children: const [],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('prefers subtitleWidget over subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Test',
            subtitle: 'fallback',
            subtitleWidget: const Text('custom subtitle'),
            children: const [],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('custom subtitle'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    });
  });
}
