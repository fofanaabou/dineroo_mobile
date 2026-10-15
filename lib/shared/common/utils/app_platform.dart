import 'package:flutter/foundation.dart';

/// Web-safe platform checks. `dart:io` `Platform.isX` throws on web, and
/// `defaultTargetPlatform` reports the browser's OS there (a phone browser looks
/// like iOS/Android), so the native checks are false whenever running on web.
class AppPlatform {
  const AppPlatform._();

  static bool get isWeb => kIsWeb;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
