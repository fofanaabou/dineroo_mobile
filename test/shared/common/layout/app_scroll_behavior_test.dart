import 'dart:ui' show PointerDeviceKind;

import 'package:dineroo_mobile/shared/common/layout/app_scroll_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list(ScrollController controller, {ScrollBehavior? behavior}) {
  return MaterialApp(
    scrollBehavior: behavior,
    home: Scaffold(
      body: ListView(
        controller: controller,
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 100, child: Text('row $i')),
        ],
      ),
    ),
  );
}

Future<void> _dragWithMouse(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    const Offset(200, 300),
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveBy(const Offset(0, -200));
  await gesture.up();
  await tester.pump();
}

void main() {
  group('AppScrollBehavior', () {
    test('accepts mouse, trackpad and stylus drags', () {
      const behavior = AppScrollBehavior();

      expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
      expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
      expect(behavior.dragDevices, contains(PointerDeviceKind.stylus));
      expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    });

    testWidgets('scrolls a list dragged with a mouse', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _list(controller, behavior: const AppScrollBehavior()),
      );

      await _dragWithMouse(tester);

      expect(controller.offset, greaterThan(0));
    });

    testWidgets('control: the default behavior ignores a mouse drag', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_list(controller));

      await _dragWithMouse(tester);

      expect(controller.offset, 0);
    });
  });
}
