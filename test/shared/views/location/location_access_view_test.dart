import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/views/location/location_access_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/window_size_helper.dart';

// The view only reads its providers when the button is tapped, so none are needed to render it.
void main() {
  group('LocationAccessView', () {
    testWidgets('keeps the full-width button on a phone', (tester) async {
      setWindowSize(tester, 390, 844);
      await tester.pumpWidget(const MaterialApp(home: LocationAccessView()));

      expect(tester.getSize(find.byType(AppButton)).width, 326);
    });

    testWidgets('centers a capped column on a wide window', (tester) async {
      setWindowSize(tester, 1200, 800);
      await tester.pumpWidget(const MaterialApp(home: LocationAccessView()));

      final button = find.byType(AppButton);
      expect(tester.getSize(button).width, lessThanOrEqualTo(420));
      expect(tester.getCenter(button).dx, closeTo(600, 0.5));
    });
  });
}
