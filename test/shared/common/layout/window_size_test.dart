import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

void main() {
  group('WindowSize.fromWidth', () {
    test('is compact below 600', () {
      expect(WindowSize.fromWidth(0), WindowSize.compact);
      expect(WindowSize.fromWidth(390), WindowSize.compact);
      expect(WindowSize.fromWidth(599.9), WindowSize.compact);
    });

    test('is medium from 600 up to 840', () {
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(768), WindowSize.medium);
      expect(WindowSize.fromWidth(839.9), WindowSize.medium);
    });

    test('is expanded from 840', () {
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
      expect(WindowSize.fromWidth(1920), WindowSize.expanded);
    });
  });

  testWidgets('BuildContext.windowSize follows the window width', (
    tester,
  ) async {
    late WindowSize seen;
    setWindowSize(tester, 390);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            seen = context.windowSize;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, WindowSize.compact);

    setWindowSize(tester, 700);
    await tester.pump();
    expect(seen, WindowSize.medium);

    setWindowSize(tester, 1200);
    await tester.pump();
    expect(seen, WindowSize.expanded);
  });
}
