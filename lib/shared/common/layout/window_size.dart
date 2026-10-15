import 'package:flutter/widgets.dart';

/// Material 3 window size classes: the single vocabulary for adaptive layouts.
enum WindowSize {
  compact,
  medium,
  expanded;

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;

  static WindowSize fromWidth(double width) {
    if (width >= expandedBreakpoint) return WindowSize.expanded;
    if (width >= mediumBreakpoint) return WindowSize.medium;
    return WindowSize.compact;
  }
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
