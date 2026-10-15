import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the logical window size for the rest of the test. The default test window is 800x600,
/// which is already a medium width, so adaptive tests must always set their own size.
void setWindowSize(WidgetTester tester, double width, [double height = 900]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}
