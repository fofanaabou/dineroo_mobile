import 'package:dineroo_mobile/shared/common/utils/text_utils.dart';
import 'package:dineroo_mobile/shared/models/domain/contact.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';

class ContactFactory {
  const ContactFactory._();

  static Contact publicCustomer({
    OrderDeliveryContact? deliveryContact,
    String? fullName,
    String? phoneNumber,
    String? subtitle,
  }) {
    final name =
        deliveryContact != null
            ? deliveryContact.shortDisplayName
            : extractFirstName(fullName, fallback: 'Client');

    final phone =
        deliveryContact != null
            ? deliveryContact.phoneNumber
            : (phoneNumber ?? '');

    return Contact(name: name, phoneNumber: phone, subtitle: subtitle);
  }

  static Contact publicDriver({
    required String? fullName,
    required String phoneNumber,
    String? subtitle,
    String? imageUrl,
  }) {
    return Contact(
      name: extractFirstName(fullName, fallback: 'Livreur'),
      phoneNumber: phoneNumber,
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
  }
}
