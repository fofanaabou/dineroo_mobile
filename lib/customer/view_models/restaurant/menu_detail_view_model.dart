import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/menu_detail.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/repositories/menu_repository.dart';

class MenuDetailViewModel extends ChangeNotifier {
  final MenuRepository _repository;

  MenuDetailViewModel(this._repository);

  MenuDetail? _menuDetail;
  Restaurant? _restaurant;
  bool isLoading = true;
  String? error;

  MenuDetail? get menuDetail => _menuDetail;
  Restaurant? get restaurant => _restaurant;

  Future<void> fetchWithRestaurant(Restaurant restaurant, String menuId) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.getMenuDetailWithRestaurant(
        restaurant,
        menuId,
      );
      _menuDetail = result.menuDetail;
      _restaurant = result.restaurant;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
