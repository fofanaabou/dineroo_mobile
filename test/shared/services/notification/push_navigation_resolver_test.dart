import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/views/wallet/customer_wallet_view.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:dineroo_mobile/shared/services/notification/push_navigation_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNavigationResolver', () {
    test('routes customer wallet notifications to wallet screen', () {
      const resolver = PushNavigationResolver();

      for (final type in [
        PushNotificationType.walletRecredited,
        PushNotificationType.walletCredited,
        PushNotificationType.walletDebited,
      ]) {
        final screen = resolver.resolve(
          currentUser: _customer,
          payload: PushNotificationPayload(type: type),
        );

        expect(screen, isA<CustomerWalletView>());
      }
    });
  });
}

final _customer = User(
  id: 'customer-1',
  firstName: 'Aminata',
  lastName: 'Diallo',
  phoneNumber: '620000000',
  role: 'CUSTOMER',
  isTemporaryPin: false,
);
