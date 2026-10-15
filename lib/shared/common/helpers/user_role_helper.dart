import 'package:dineroo_mobile/shared/common/constants/user_role_constants.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';

String canonicalizeRole(dynamic role) {
  final r = (role ?? '').toString().toUpperCase().replaceAll(
    RegExp(r'[-_\s]'),
    '',
  );
  switch (r) {
    case rawRoleRestaurantManager:
      return normalizedRestaurantManager;
    case rawRoleDriver:
      return rawRoleDriver;
    case rawRoleGuest:
      return rawRoleGuest;
    case rawRoleCustomer:
    default:
      return rawRoleCustomer;
  }
}

UserRole parseUserRole(dynamic role) {
  final canonical = canonicalizeRole(role);
  switch (canonical) {
    case normalizedRestaurantManager:
      return UserRole.restaurantManager;
    case rawRoleDriver:
      return UserRole.driver;
    case rawRoleGuest:
      return UserRole.guest;
    case rawRoleCustomer:
    default:
      return UserRole.customer;
  }
}

String expectedRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return 'client';
    case UserRole.driver:
      return 'livreur';
    case UserRole.guest:
      return 'livreur (invité)';
    case UserRole.restaurantManager:
      return 'restaurateur';
  }
}
