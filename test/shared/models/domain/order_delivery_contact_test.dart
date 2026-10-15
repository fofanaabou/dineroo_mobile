import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDeliveryContact', () {
    test('builds full address from non-empty parts', () {
      const contact = OrderDeliveryContact(
        phoneNumber: '620000000',
        address: ' Rue 1 ',
        district: '  Kaloum ',
        commune: ' Conakry ',
      );

      expect(contact.fullAddress, 'Rue 1, Kaloum, Conakry');
    });

    test('builds display names with fallback to Client', () {
      const named = OrderDeliveryContact(
        phoneNumber: '620000000',
        address: 'Rue 1',
        firstName: ' Aminata ',
        lastName: ' Diallo ',
      );
      const anonymous = OrderDeliveryContact(
        phoneNumber: '620000000',
        address: 'Rue 1',
      );

      expect(named.fullName, 'Aminata Diallo');
      expect(named.displayName, 'Aminata Diallo');
      expect(named.shortDisplayName, 'Aminata');
      expect(anonymous.displayName, 'Client');
      expect(anonymous.shortDisplayName, 'Client');
    });
  });
}
