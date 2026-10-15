import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/models/domain/menu.dart';
import 'package:dineroo_mobile/manager/repositories/manager_menus_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerCatalogMenusViewModel extends ChangeNotifier {
  final ManagerMenusRepository _repository;

  ManagerCatalogMenusViewModel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  List<Menu> _menus = [];
  List<Menu> get menus => _menus;

  Future<void> fetchMenus(String restaurantId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _menus = await _repository.fetchMenus(restaurantId);
    } catch (e, stack) {
      logger.e(
        '[ManagerCatalogMenus] Failed to fetch menus',
        error: e,
        stackTrace: stack,
      );
      _hasError = true;
      _menus = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(String restaurantId, String menuId) async {
    final index = _menus.indexWhere((m) => m.id == menuId);
    if (index == -1) return false;

    final currentValue = _menus[index].available;
    _menus[index].available = !currentValue;
    notifyListeners();

    try {
      await _repository.updateAvailability(restaurantId, menuId, !currentValue);
      return true;
    } on RestaurantSuspendedException {
      _menus[index].available = currentValue;
      notifyListeners();
      rethrow;
    } catch (e, stack) {
      _menus[index].available = currentValue;
      notifyListeners();
      logger.e(
        '[ManagerCatalogMenus] Failed to update availability',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
