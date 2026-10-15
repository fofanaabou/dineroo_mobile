import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSwitch', () {
    testWidgets('calls onChanged when toggled', (tester) async {
      bool? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSwitch(
              value: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));

      expect(changedValue, isTrue);
    });

    testWidgets('displays loader instead of switch while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSwitch(value: false, onChanged: (_) {}, isLoading: true),
          ),
        ),
      );

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('routes taps to onDisabledTap instead of onChanged', (
      tester,
    ) async {
      var changed = 0;
      var disabledTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSwitch(
              value: true,
              isDisabled: true,
              onChanged: (_) => changed++,
              onDisabledTap: () => disabledTaps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppSwitch));
      await tester.pump();

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(changed, 0);
      expect(disabledTaps, 1);
    });

    testWidgets('keeps the component palette when disabled and on', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSwitch(
              value: true,
              isDisabled: true,
              onChanged: (_) {},
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: const Color(0xFFE0E0E0),
              activeTrackColor: Colors.green,
            ),
          ),
        ),
      );

      final rendered = tester.widget<Switch>(find.byType(Switch));

      expect(rendered.inactiveThumbColor, Colors.grey);
      expect(rendered.inactiveTrackColor, const Color(0xFFE0E0E0));
      expect(rendered.activeThumbColor, Colors.grey);
      expect(rendered.activeTrackColor, const Color(0xFFE0E0E0));
    });
  });
}
