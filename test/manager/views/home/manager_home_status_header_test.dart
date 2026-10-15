import 'package:dineroo_mobile/manager/views/home/manager_home_status_header.dart';
import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });
  group('ManagerHomeStatusHeader', () {
    final todayKey = DateFormat('EEEE').format(DateTime.now()).toUpperCase();
    final openHours = [
      OpeningHours(
        day: todayKey,
        timeRanges: [TimeRange(start: '00:00', end: '23:59')],
      ),
    ];

    testWidgets('shows loading state when opening hours are not loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagerHomeStatusHeader(
              openingHours: const [],
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status badge and hours when loaded and open', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagerHomeStatusHeader(
              openingHours: openHours,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Restaurant ouvert'), findsOneWidget);
      expect(find.textContaining('00:00'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows loading spinner on hours line during refresh', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagerHomeStatusHeader(
              openingHours: openHours,
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Restaurant ouvert'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagerHomeStatusHeader(
              openingHours: openHours,
              isLoading: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Modifier'));
      expect(tapped, isTrue);
    });

    testWidgets('locks the opening-hours editor and says why when suspended', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagerHomeStatusHeader(
              openingHours: openHours,
              isLoading: false,
              isSuspended: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text('Modifier'));
      await tester.pump();

      expect(tapped, isFalse);
      expect(find.text(ManagerSuspensionNotice.lockedActionReason), findsOneWidget);
    });
  });
}
