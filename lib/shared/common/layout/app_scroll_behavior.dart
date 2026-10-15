import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Flutter ignores mouse drags on scrollables by default, which breaks pull-to-refresh and
/// horizontal carousels in a desktop browser. Desktop scrollbars come from [MaterialScrollBehavior].
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
