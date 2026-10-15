import 'package:dineroo_mobile/driver/enums/driver_status.dart';
import 'package:dineroo_mobile/driver/models/dto/driver_status_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverStatusResponseDto', () {
    test('parses driver id and status', () {
      final dto = DriverStatusResponseDto.fromJson({
        'driverId': 1,
        'status': 'ONLINE',
      });

      expect(dto.driverId, '1');
      expect(dto.status, DriverStatus.online);
    });

    test('uses offline fallback for missing status', () {
      final dto = DriverStatusResponseDto.fromJson({});

      expect(dto.driverId, '');
      expect(dto.status, DriverStatus.offline);
    });
  });
}
