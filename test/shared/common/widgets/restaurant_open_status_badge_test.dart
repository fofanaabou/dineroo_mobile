import 'package:dineroo_mobile/shared/common/widgets/restaurant_open_status_badge.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('RestaurantOpenStatusBadge', () {
    testWidgets('shows "Restaurant ouvert" when open', (tester) async {
      final todayKey = DateFormat('EEEE').format(DateTime.now()).toUpperCase();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestaurantOpenStatusBadge(
              openingHours: [
                OpeningHours(
                  day: todayKey,
                  timeRanges: [TimeRange(start: '00:00', end: '23:59')],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Restaurant ouvert'), findsOneWidget);
    });

    testWidgets('shows "Restaurant fermé" when closed and showNextOpening false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestaurantOpenStatusBadge(
              openingHours: const [],
              showNextOpening: false,
            ),
          ),
        ),
      );

      expect(find.text('Restaurant fermé'), findsOneWidget);
    });
  });
}
