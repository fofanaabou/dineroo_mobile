import 'package:dineroo_mobile/shared/models/dto/opening_hours_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpeningHoursDto', () {
    test('parses opening hours DTO with time ranges', () {
      final dto = OpeningHoursDto.fromJson({
        'day': 'FRIDAY',
        'timeRanges': [
          {'start': '09:00', 'end': '17:00'},
        ],
      });

      expect(dto.day, 'FRIDAY');
      expect(dto.timeRanges, hasLength(1));
      expect(dto.timeRanges.first.start, '09:00');
      expect(dto.timeRanges.first.end, '17:00');
    });

    test('time range DTO uses safe defaults', () {
      final dto = TimeRangeDto.fromJson({});

      expect(dto.start, '');
      expect(dto.end, '');
    });
  });
}
