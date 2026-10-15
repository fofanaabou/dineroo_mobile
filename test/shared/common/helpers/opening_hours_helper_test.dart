import 'package:dineroo_mobile/shared/common/helpers/opening_hours_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('OpeningHoursHelper', () {
    test('detects restaurant open for an all-day current range', () {
      expect(
        OpeningHoursHelper.restaurantIsOpen([
          OpeningHours(
            day: _today(),
            timeRanges: [TimeRange(start: '00:00', end: '23:59')],
          ),
        ]),
        isTrue,
      );
    });

    test('detects restaurant closed with empty or invalid ranges', () {
      expect(OpeningHoursHelper.restaurantIsOpen([]), isFalse);
      expect(
        OpeningHoursHelper.restaurantIsOpen([
          OpeningHours(
            day: _today(),
            timeRanges: [TimeRange(start: 'fermé', end: '23:59')],
          ),
        ]),
        isFalse,
      );
    });

    test('returns next opening for future slot today', () {
      final future = DateTime.now().add(const Duration(minutes: 30));
      final later = future.add(const Duration(hours: 1));
      final hours = [
        OpeningHours(
          day: _today(),
          timeRanges: [TimeRange(start: _time(future), end: _time(later))],
        ),
      ];

      expect(OpeningHoursHelper.nextOpeningDateTime(hours), isNotNull);
      expect(OpeningHoursHelper.nextOpeningHour(hours), _time(future));
      expect(
        OpeningHoursHelper.restaurantOpensWithin(
          hours,
          const Duration(hours: 2),
        ),
        isTrue,
      );
    });

    test(
      'returns null next opening when no slot has a valid start time',
      () {
        final hours = [
          OpeningHours(
            day: DateFormat('EEEE').format(DateTime.now()).toUpperCase(),
            timeRanges: [TimeRange(start: 'fermé', end: '10:00')],
          ),
          OpeningHours(
            day: DateFormat('EEEE')
                .format(DateTime.now().add(const Duration(days: 1)))
                .toUpperCase(),
            timeRanges: [TimeRange(start: 'fermé', end: '10:00')],
          ),
        ];

        expect(OpeningHoursHelper.nextOpeningDateTime(hours), isNull);
        expect(OpeningHoursHelper.nextOpeningHour(hours), isNull);
        expect(
          OpeningHoursHelper.restaurantOpensWithin(
            hours,
            const Duration(hours: 2),
          ),
          isFalse,
        );
      },
    );

    test('formats and parses TimeOfDay values', () {
      expect(
        OpeningHoursHelper.formatTime(const TimeOfDay(hour: 9, minute: 5)),
        '09:05',
      );
      expect(
        OpeningHoursHelper.parseTimeOfDay('09:05'),
        const TimeOfDay(hour: 9, minute: 5),
      );
      expect(OpeningHoursHelper.parseTimeOfDay(null), isNull);
      expect(OpeningHoursHelper.parseTimeOfDay('bad'), isNull);
    });

    test('validates and compares time ranges', () {
      const nine = TimeOfDay(hour: 9, minute: 0);
      const ten = TimeOfDay(hour: 10, minute: 0);
      const nineThirty = TimeOfDay(hour: 9, minute: 30);
      const eleven = TimeOfDay(hour: 11, minute: 0);

      expect(OpeningHoursHelper.toMinutes(nine), 540);
      expect(OpeningHoursHelper.isValidRange(nine, ten), isTrue);
      expect(OpeningHoursHelper.isValidRange(nine, nine), isFalse);
      expect(OpeningHoursHelper.isValidRange(null, ten), isFalse);
      expect(
        OpeningHoursHelper.isOverlappingRangeList(
          [nine, nineThirty],
          [ten, eleven],
        ),
        isTrue,
      );
      expect(
        OpeningHoursHelper.isOverlappingRangeList(
          [nine, ten],
          [nineThirty, eleven],
        ),
        isFalse,
      );
      expect(OpeningHoursHelper.isOverlappingRangeList([nine], [ten]), isFalse);
    });

    test('formatRanges returns "Fermé" for empty list', () {
      expect(OpeningHoursHelper.formatRanges([]), 'Fermé');
    });

    test('formatRanges formats single range', () {
      expect(
        OpeningHoursHelper.formatRanges([
          TimeRange(start: '08:00', end: '22:00'),
        ]),
        '08:00 - 22:00',
      );
    });

    test('formatRanges joins multiple ranges with slash', () {
      expect(
        OpeningHoursHelper.formatRanges([
          TimeRange(start: '08:00', end: '12:00'),
          TimeRange(start: '14:00', end: '18:00'),
        ]),
        '08:00 - 12:00 / 14:00 - 18:00',
      );
    });

    test('currentDayRanges returns ranges for current day', () {
      final todayKey = _today();
      final hours = [
        OpeningHours(
          day: todayKey,
          timeRanges: [TimeRange(start: '09:00', end: '17:00')],
        ),
      ];
      final ranges = OpeningHoursHelper.currentDayRanges(hours);
      expect(ranges, hasLength(1));
      expect(ranges.single.start, '09:00');
    });

    test('currentDayRanges returns empty for no match', () {
      expect(OpeningHoursHelper.currentDayRanges([]), isEmpty);
    });

    test('nextOpeningLabel returns "Ouvre aujourd’hui" for future slot today', () {
      final future = DateTime.now().add(const Duration(minutes: 30));
      final later = future.add(const Duration(hours: 2));
      final hours = [
        OpeningHours(
          day: _today(),
          timeRanges: [TimeRange(start: _time(future), end: _time(later))],
        ),
      ];
      final label = OpeningHoursHelper.nextOpeningLabel(hours);
      expect(label, contains('Ouvre aujourd’hui'));
    });

    test('nextOpeningLabel returns null when no future slot', () {
      expect(OpeningHoursHelper.nextOpeningLabel([]), isNull);
    });
  });
}

String _today() => DateFormat('EEEE').format(DateTime.now()).toUpperCase();

String _time(DateTime dateTime) =>
    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
