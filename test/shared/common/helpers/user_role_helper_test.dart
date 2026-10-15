import 'package:dineroo_mobile/shared/common/helpers/user_role_helper.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('user_role_helper', () {
    test('canonicalizes role variants', () {
      expect(canonicalizeRole('restaurant-manager'), 'RESTAURANT_MANAGER');
      expect(canonicalizeRole('restaurant_manager'), 'RESTAURANT_MANAGER');
      expect(canonicalizeRole('driver'), 'DRIVER');
      expect(canonicalizeRole('guest'), 'GUEST');
      expect(canonicalizeRole(null), 'CUSTOMER');
      expect(canonicalizeRole('unsupported'), 'CUSTOMER');
    });

    test('parses user roles', () {
      expect(parseUserRole('restaurant manager'), UserRole.restaurantManager);
      expect(parseUserRole('DRIVER'), UserRole.driver);
      expect(parseUserRole('GUEST'), UserRole.guest);
      expect(parseUserRole('CUSTOMER'), UserRole.customer);
    });

    test('returns expected French labels', () {
      expect(expectedRoleLabel(UserRole.customer), 'client');
      expect(expectedRoleLabel(UserRole.driver), 'livreur');
      expect(expectedRoleLabel(UserRole.guest), 'livreur (invité)');
      expect(expectedRoleLabel(UserRole.restaurantManager), 'restaurateur');
    });
  });
}
