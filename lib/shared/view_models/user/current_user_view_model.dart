import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:flutter/material.dart';

class CurrentUserViewModel extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  void setUser(User currentUser) {
    _currentUser = currentUser;
    notifyListeners();
  }

  void clear() {
    _currentUser = null;
    notifyListeners();
  }
}
