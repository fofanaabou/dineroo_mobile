import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryAddress', () {
    test('builds display label from non-empty address parts', () {
      final address = DeliveryAddress(
        phoneNumber: '620000000',
        address: '  Rue KA 011  ',
        district: '  Almamya ',
        commune: ' Kaloum ',
      );

      expect(address.displayLabel, 'Rue KA 011, Almamya, Kaloum');
    });

    test('ignores empty display label parts', () {
      final address = DeliveryAddress(
        phoneNumber: '620000000',
        address: ' ',
        district: 'Kipé',
        commune: '',
      );

      expect(address.displayLabel, 'Kipé');
    });

    test('uses full name as display name when available', () {
      final address = DeliveryAddress(
        phoneNumber: '620000000',
        address: 'Taouyah',
        district: 'Ratoma',
        firstName: '  Aissatou ',
        lastName: ' Diallo ',
      );

      expect(address.fullName, 'Aissatou Diallo');
      expect(address.displayName, 'Aissatou Diallo');
    });

    test('falls back to Client when no name is available', () {
      final address = DeliveryAddress(
        phoneNumber: '620000000',
        address: 'Taouyah',
        district: 'Ratoma',
      );

      expect(address.fullName, '');
      expect(address.displayName, 'Client');
    });

    test('copyWith updates selected fields and keeps the others', () {
      final address = DeliveryAddress(
        phoneNumber: '620000000',
        address: 'Taouyah',
        district: 'Ratoma',
        commune: 'Ratoma',
        instructions: 'Devant la pharmacie',
        firstName: 'Mamadou',
        lastName: 'Barry',
      );

      final copy = address.copyWith(
        phoneNumber: '621111111',
        district: 'Dixinn',
      );

      expect(copy.phoneNumber, '621111111');
      expect(copy.address, 'Taouyah');
      expect(copy.district, 'Dixinn');
      expect(copy.commune, 'Ratoma');
      expect(copy.instructions, 'Devant la pharmacie');
      expect(copy.displayName, 'Mamadou Barry');
    });
  });
}
