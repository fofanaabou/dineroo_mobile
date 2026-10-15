import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/day_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayEditor', () {
    testWidgets('renders a closed day when no ranges are provided', (
      tester,
    ) async {
      final savedRanges = <List<Map<String, dynamic>>>[];

      await tester.pumpWidget(
        _TestApp(
          child: DayEditor(day: 'Lundi', onSave: savedRanges.add),
        ),
      );

      expect(find.text('Lundi'), findsOneWidget);
      expect(find.text('Fermé'), findsOneWidget);
      expect(find.text('Ajouter une autre plage'), findsNothing);
      expect(savedRanges, isEmpty);
    });

    testWidgets('renders initial ranges and adds then removes a second range', (
      tester,
    ) async {
      final savedRanges = <List<Map<String, dynamic>>>[];

      await tester.pumpWidget(
        _TestApp(
          child: DayEditor(
            day: 'Mardi',
            initialRanges: const [
              {'start': '09:00', 'end': '18:30'},
            ],
            onSave: savedRanges.add,
          ),
        ),
      );

      expect(find.text('Ouvert'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('6:30 PM'), findsOneWidget);
      expect(find.text('Ajouter une autre plage'), findsOneWidget);

      await tester.tap(find.text('Ajouter une autre plage'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter une autre plage'), findsNothing);
      expect(find.text('--:--'), findsNWidgets(2));
      expect(find.byTooltip('Supprimer cette plage horaire'), findsOneWidget);

      await tester.tap(find.byTooltip('Supprimer cette plage horaire'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter une autre plage'), findsOneWidget);
      expect(savedRanges.last, const [
        {'start': '09:00', 'end': '18:30'},
      ]);
    });

    testWidgets('saves an empty range list when toggled closed', (
      tester,
    ) async {
      final savedRanges = <List<Map<String, dynamic>>>[];

      await tester.pumpWidget(
        _TestApp(
          child: DayEditor(
            day: 'Mercredi',
            initialRanges: const [
              {'start': '08:00', 'end': '12:00'},
            ],
            onSave: savedRanges.add,
          ),
        ),
      );

      await tester.tap(find.text('Ouvert'));
      await tester.pumpAndSettle();

      expect(find.text('Fermé'), findsOneWidget);
      expect(savedRanges.single, isEmpty);
    });

    testWidgets("shows the Aujourd'hui badge and orange border for today", (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: DayEditor(
            day: 'Jeudi',
            isToday: true,
            initialRanges: const [
              {'start': '09:00', 'end': '18:00'},
            ],
            onSave: (_) {},
          ),
        ),
      );

      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('Ouvert'), findsOneWidget);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(
        decoration.border!.isUniform,
        isTrue,
        reason: "la card 'aujourd’hui' doit avoir une bordure complète",
      );
    });

    testWidgets('does not highlight a non-today day', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DayEditor(
            day: 'Vendredi',
            initialRanges: const [
              {'start': '09:00', 'end': '18:00'},
            ],
            onSave: (_) {},
          ),
        ),
      );

      expect(find.text("Aujourd'hui"), findsNothing);
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((container.decoration! as BoxDecoration).border, isNull);
    });
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: child));
  }
}
