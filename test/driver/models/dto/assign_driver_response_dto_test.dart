import 'package:dineroo_mobile/driver/models/dto/assign_driver_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssignDriverResponseDto', () {
    test('parses json and serializes back', () {
      final dto = AssignDriverResponseDto.fromJson({
        'driverId': 1,
        'deliveryId': 'delivery-1',
        'driverStatus': 'ON_DELIVERY',
        'deliveryStatus': 'ASSIGNED',
      });

      expect(dto.driverId, '1');
      expect(dto.deliveryId, 'delivery-1');
      expect(dto.driverStatus, 'ON_DELIVERY');
      expect(dto.deliveryStatus, 'ASSIGNED');
      expect(dto.toJson(), {
        'driverId': '1',
        'deliveryId': 'delivery-1',
        'driverStatus': 'ON_DELIVERY',
        'deliveryStatus': 'ASSIGNED',
      });
    });

    test('uses empty string defaults', () {
      final dto = AssignDriverResponseDto.fromJson({});

      expect(dto.driverId, '');
      expect(dto.deliveryId, '');
      expect(dto.driverStatus, '');
      expect(dto.deliveryStatus, '');
    });
  });
}
