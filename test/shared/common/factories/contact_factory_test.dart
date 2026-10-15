import 'package:dineroo_mobile/shared/common/factories/contact_factory.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactFactory', () {
    test('builds public customer from delivery contact', () {
      final contact = ContactFactory.publicCustomer(
        deliveryContact: const OrderDeliveryContact(
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          address: 'Kipé',
        ),
        subtitle: 'Client fidèle',
      );

      expect(contact.name, 'Aminata');
      expect(contact.displayName, 'Aminata');
      expect(contact.phoneNumber, '620000000');
      expect(contact.subtitle, 'Client fidèle');
    });

    test('builds public customer from full name fallback', () {
      final contact = ContactFactory.publicCustomer(
        fullName: 'Mamadou Bah',
        phoneNumber: '621111111',
      );

      expect(contact.name, 'Mamadou');
      expect(contact.phoneNumber, '621111111');
    });

    test('builds public driver', () {
      final contact = ContactFactory.publicDriver(
        fullName: 'Ibrahima Camara',
        phoneNumber: '622222222',
        subtitle: 'Livreur',
        imageUrl: 'https://example.com/avatar.png',
      );

      expect(contact.name, 'Ibrahima');
      expect(contact.phoneNumber, '622222222');
      expect(contact.subtitle, 'Livreur');
      expect(contact.imageUrl, 'https://example.com/avatar.png');
    });

    test('uses default display names when names are blank', () {
      expect(ContactFactory.publicCustomer().displayName, 'Client');
      expect(
        ContactFactory.publicDriver(fullName: ' ', phoneNumber: '').displayName,
        'Livreur',
      );
    });
  });
}
