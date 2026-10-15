import 'package:dineroo_mobile/shared/common/layout/adaptive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

const _probe = Key('probe');

Widget _app() => MaterialApp(
  home: Scaffold(
    body: AdaptiveContent(
      maxWidth: 420,
      child: const SizedBox(key: _probe, width: double.infinity, height: 10),
    ),
  ),
);

void main() {
  group('AdaptiveContent', () {
    testWidgets('leaves the child untouched on a compact window', (
      tester,
    ) async {
      setWindowSize(tester, 390);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 390);
    });

    testWidgets('caps and centers the child on a medium window', (
      tester,
    ) async {
      setWindowSize(tester, 700);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 420);
      expect(tester.getCenter(find.byKey(_probe)).dx, closeTo(350, 0.5));
    });

    testWidgets('caps and centers the child on an expanded window', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(_app());

      expect(tester.getSize(find.byKey(_probe)).width, 420);
      expect(tester.getCenter(find.byKey(_probe)).dx, closeTo(600, 0.5));
    });

    testWidgets('does not widen a child narrower than the maximum', (
      tester,
    ) async {
      setWindowSize(tester, 1200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveContent(
              maxWidth: 420,
              child: const SizedBox(key: _probe, width: 200, height: 10),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(_probe)).width, 200);
    });
  });
}
