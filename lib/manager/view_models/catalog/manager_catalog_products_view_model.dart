import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/manager/repositories/manager_products_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';

class ManagerCatalogProductsViewModel extends ChangeNotifier {
  final ManagerProductsRepository _repository;

  ManagerCatalogProductsViewModel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  List<Product> _products = [];
  List<Product> get allProducts => List.unmodifiable(_products);
  List<Product> get products => _products
      .where((product) => product.canBeSoldAlone)
      .toList(growable: false);

  Future<void> fetchProducts(String restaurantId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _products = await _repository.fetchProducts(restaurantId);
    } catch (e, stack) {
      logger.e(
        '[ManagerCatalogProducts] Failed to fetch products',
        error: e,
        stackTrace: stack,
      );
      _hasError = true;
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(String restaurantId, String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final currentValue = _products[index].available;
    _products[index].available = !currentValue;
    notifyListeners();

    try {
      await _repository.updateAvailability(
        restaurantId,
        productId,
        !currentValue,
      );

      return true;
    } on RestaurantSuspendedException {
      _products[index].available = currentValue;
      notifyListeners();
      rethrow;
    } catch (e, stack) {
      _products[index].available = currentValue;
      notifyListeners();
      logger.e(
        '[ManagerCatalogProducts] Failed to update availability',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
