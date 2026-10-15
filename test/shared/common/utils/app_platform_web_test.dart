@TestOn('browser')
library;

import 'package:dineroo_mobile/shared/common/utils/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('AppPlatform in a browser', () {
    test('is web', () {
      expect(AppPlatform.isWeb, isTrue);
    });

    test('does not treat a mobile browser on iOS as native iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(AppPlatform.isIOS, isFalse);
    });

    test('does not treat a mobile browser on Android as native Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppPlatform.isAndroid, isFalse);
    });
  });
}
