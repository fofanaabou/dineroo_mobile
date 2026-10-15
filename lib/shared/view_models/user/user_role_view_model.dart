import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';

class UserRoleViewModel extends ChangeNotifier {
  UserRole? _role;

  UserRole? get role => _role;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void clear() {
    _role = null;
    notifyListeners();
  }

  bool get isCustomer => _role == UserRole.customer;
  bool get isDriver => _role == UserRole.driver;
  bool get isGuest => _role == UserRole.guest;
  bool get isRestaurantManager => _role == UserRole.restaurantManager;
}
