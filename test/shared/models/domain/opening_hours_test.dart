import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpeningHours', () {
    test('parses opening hours and time ranges from JSON', () {
      final openingHours = OpeningHours.fromJson({
        'day': 'MONDAY',
        'timeRanges': [
          {'start': '08:00', 'end': '12:00'},
          {'start': '14:00', 'end': '18:00'},
        ],
      });

      expect(openingHours.day, 'MONDAY');
      expect(openingHours.timeRanges, hasLength(2));
      expect(openingHours.timeRanges.first.start, '08:00');
      expect(openingHours.timeRanges.first.end, '12:00');
    });

    test('uses an empty time range list when missing', () {
      final openingHours = OpeningHours.fromJson({'day': 'SUNDAY'});

      expect(openingHours.day, 'SUNDAY');
      expect(openingHours.timeRanges, isEmpty);
    });
  });
}
