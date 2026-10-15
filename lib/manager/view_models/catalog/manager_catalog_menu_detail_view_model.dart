import 'package:flutter/material.dart';
import 'package:dineroo_mobile/manager/models/manager_menu_detail.dart';
import 'package:dineroo_mobile/manager/services/manager_menu_detail_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerCatalogMenuDetailViewModel extends ChangeNotifier {
  final ManagerMenuDetailService _service;
  final String restaurantId;

  ManagerCatalogMenuDetailViewModel(this._service, this.restaurantId);

  ManagerMenuDetail? _menuDetail;
  ManagerMenuDetail? get menuDetail => _menuDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  Future<void> fetchMenuDetail(String menuId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final json = await _service.fetchMenuDetail(restaurantId, menuId);
      _menuDetail = ManagerMenuDetail.fromJson(json);
    } catch (e, stack) {
      logger.e(
        '[ManagerCatalogMenuDetail] Failed to fetch detail',
        error: e,
        stackTrace: stack,
      );
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleItemAvailability(String groupId, String itemId) async {
    if (_menuDetail == null) return false;

    ManagerMenuItem? foundItem;
    for (final group in _menuDetail!.groups) {
      if (group.id != groupId) continue;
      for (final item in group.items) {
        if (item.id == itemId) {
          foundItem = item;
          break;
        }
      }
      if (foundItem != null) break;
    }
    if (foundItem == null) return false;

    final currentValue = foundItem.available;
    foundItem.available = !currentValue;
    notifyListeners();

    try {
      await _service.updateItemAvailability(
        restaurantId,
        _menuDetail!.id,
        groupId,
        itemId,
        !currentValue,
      );
      return true;
    } on RestaurantSuspendedException {
      foundItem.available = currentValue;
      notifyListeners();
      rethrow;
    } catch (e, stack) {
      foundItem.available = currentValue;
      notifyListeners();
      logger.e(
        '[ManagerCatalogMenuDetail] Failed to toggle item availability',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
