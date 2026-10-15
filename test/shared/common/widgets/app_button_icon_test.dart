import 'package:dineroo_mobile/shared/common/widgets/app_button_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButtonIcon', () {
    testWidgets('renders icon and handles taps when enabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButtonIcon(
              icon: Icons.add,
              onTap: () => taps++,
              backgroundColor: Colors.red,
              iconColor: Colors.white,
              size: 20,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(taps, 1);
      expect(avatar.radius, 20);
      expect(avatar.backgroundColor, Colors.red);
    });

    testWidgets('does not handle taps when disabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButtonIcon(
              icon: Icons.remove,
              onTap: () => taps++,
              backgroundColor: Colors.red,
              iconColor: Colors.white,
              isDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(taps, 0);
      expect(opacity.opacity, 0.5);
    });
  });
}
