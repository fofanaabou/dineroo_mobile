@TestOn('vm')
library;

import 'package:dineroo_mobile/shared/views/location/location_permission_blocked_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _showDialog(
  WidgetTester tester, {
  required VoidCallback onOpenSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LocationPermissionBlockedDialog(
                onOpenSettings: onOpenSettings,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('LocationPermissionBlockedDialog on a native platform', () {
    testWidgets('opens the device settings and closes on confirm', (
      tester,
    ) async {
      var openedSettings = 0;
      await _showDialog(tester, onOpenSettings: () => openedSettings++);

      await tester.tap(find.text('ALLER AUX PARAMÈTRES'));
      await tester.pumpAndSettle();

      expect(openedSettings, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('closes on cancel without opening the settings', (
      tester,
    ) async {
      var openedSettings = 0;
      await _showDialog(tester, onOpenSettings: () => openedSettings++);

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(openedSettings, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
