@TestOn('vm')
library;

import 'package:dineroo_mobile/shared/common/utils/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('AppPlatform on a native runtime', () {
    test('is not web', () {
      expect(AppPlatform.isWeb, isFalse);
    });

    test('reports iOS when the target platform is iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(AppPlatform.isIOS, isTrue);
      expect(AppPlatform.isAndroid, isFalse);
    });

    test('reports Android when the target platform is Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppPlatform.isAndroid, isTrue);
      expect(AppPlatform.isIOS, isFalse);
    });

    test('reports neither mobile OS on a desktop target', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(AppPlatform.isIOS, isFalse);
      expect(AppPlatform.isAndroid, isFalse);
    });
  });
}
