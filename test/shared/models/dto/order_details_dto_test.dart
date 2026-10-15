import 'package:dineroo_mobile/shared/models/dto/order_details_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDetailsDto', () {
    test('parses json and converts to domain', () {
      final dto = OrderDetailsDto.fromJson({
        'orderId': 'order-1',
        'driverDetails': {
          'id': 'driver-1',
          'firstName': 'Mamadou',
          'lastName': 'Bah',
          'phoneNumber': '620000000',
        },
        'customerDetails': {'phone': '621111111', 'name': 'Aminata Diallo'},
      });

      expect(dto.orderId, 'order-1');
      expect(dto.driverDetails?.id, 'driver-1');
      expect(dto.driverDetails?.lastName, 'Bah');
      expect(dto.customerDetails?.name, 'Aminata Diallo');

      final domain = dto.toDomain();
      expect(domain.orderId, 'order-1');
      expect(domain.driverDetails?.fullName, 'Mamadou Bah');
      expect(domain.customerDetails?.displayName, 'Aminata Diallo');
      expect(domain.hasAssignedDriver, isTrue);
    });

    test('uses safe defaults when optional nested details are missing', () {
      final dto = OrderDetailsDto.fromJson({});

      expect(dto.orderId, '');
      expect(dto.driverDetails, isNull);
      expect(dto.customerDetails, isNull);
      expect(dto.toDomain().hasAssignedDriver, isFalse);
    });
  });

  group('DriverDetailsDto', () {
    test('keeps nullable last name and converts to domain', () {
      final dto = DriverDetailsDto.fromJson({
        'id': 1,
        'firstName': 'Mamadou',
        'phoneNumber': 620000000,
      });

      expect(dto.id, '1');
      expect(dto.lastName, isNull);
      expect(dto.phoneNumber, '620000000');
      expect(dto.toDomain().fullName, 'Mamadou');
    });
  });

  group('CustomerDetailsDto', () {
    test('falls back to Client when name is empty in domain', () {
      final dto = CustomerDetailsDto.fromJson({'phone': 621111111});

      expect(dto.phone, '621111111');
      expect(dto.name, isNull);
      expect(dto.toDomain().displayName, 'Client');
    });
  });
}
