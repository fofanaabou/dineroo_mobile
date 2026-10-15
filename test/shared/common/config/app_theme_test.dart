import 'package:dineroo_mobile/shared/common/config/app_theme.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

final _longMessage = List.filled(
  40,
  'Un message de dialogue assez long pour s\'étendre sur toute la largeur.',
).join(' ');

Future<void> _openFromButton(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  setWindowSize(tester, 1200, 800);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => open(context),
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
  group('buildAppTheme', () {
    testWidgets('caps dialogs at 560px on a wide window', (tester) async {
      await _openFromButton(
        tester,
        (context) => showDialog<void>(
          context: context,
          builder: (_) => AppDialog(title: 'Titre', message: _longMessage),
        ),
      );

      // The AlertDialog widget spans the window including its insets; the cap applies to the
      // dialog surface, its first Material.
      final surface = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first;
      expect(tester.getSize(surface).width, lessThanOrEqualTo(560));
    });

    testWidgets('keeps bottom sheets within 640px on a wide window', (
      tester,
    ) async {
      await _openFromButton(
        tester,
        (context) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
        ),
      );

      final surface = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first;
      expect(tester.getSize(surface).width, lessThanOrEqualTo(640));
    });

    test('keeps the existing brand styling', () {
      final theme = buildAppTheme();

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.appBarTheme.backgroundColor, Colors.white);
    });
  });
}
